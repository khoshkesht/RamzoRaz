class_name PuzzleController
extends Node

signal level_loaded(level_id: int, run_id: int)
signal load_failed(errors: Array)
signal puzzle_event(event: Dictionary)
signal level_completed(level_id: int, run_id: int)
signal engine_error(error: Dictionary)
signal level_failed(level_id: int, run_id: int)
signal result_ready(result: Dictionary)
signal home_requested
signal menu_requested

const STATUS_LOADING := "LOADING"
const STATUS_PLAYING := "PLAYING"
const STATUS_COMPLETED := "COMPLETED"
const STATUS_ERROR := "ERROR"
const STATUS_FAILED := "FAILED"
const STATUS_TRANSITIONING := "TRANSITIONING"
const SUCCESS_SOUND := preload("res://assets/samples/radio_chime.wav")

var loader := PuzzleLoader.new()
var state := PuzzleState.new()
var manifest: Dictionary = {}
var current_definition: Dictionary = {}
var object_nodes: Dictionary = {}
var level_index: int = -1
var run_status: String = STATUS_LOADING
var log_runtime_errors: bool = true
var clock := PuzzleLevelClock.new()
var current_result: Dictionary = {}
var progress_store := PuzzleProgressStore.new()
var ad_adapter := PuzzleRewardedAdAdapter.new()
var allow_development_loading: bool = false
var return_to_home_after_advance: bool = false
var test_start_index: int = -1
var _save_operation: String = ""
var _purchase_level: int = 0
var _purchase_run: int = 0
var _requests: Dictionary = {}
var _request_serial: int = 0
var _pending_hint_requests: Array[int] = []
var results: Dictionary = {}
var _environment_pauses: Dictionary = {}
var _result_delay_remaining: float = 0.0
var _success_player: AudioStreamPlayer
var _timer_warning_played: bool = false
@onready var object_root: Node2D = $Stage/Objects
@onready var background: Sprite2D = $Stage/Background
@onready var hud: PuzzleHUD = $HUDLayer/HUD
@onready var interaction_manager: PuzzleInteractionManager = $InteractionManager
@onready var action_runner: PuzzleActionRunner = $ActionRunner
@onready var rule_evaluator: PuzzleRuleEvaluator = $RuleEvaluator
@onready var overlay: PuzzleOverlay = $OverlayLayer/OverlayRoot
@onready var success_feedback: PuzzleSuccessFeedback = $SuccessLayer/Root/SafeMargin/Feedback

func _ready() -> void:
	overlay.continue_requested.connect(continue_to_next_level)
	overlay.retry_requested.connect(retry_level)
	overlay.hint_action_requested.connect(_hint_action)
	overlay.hint_purchase_requested.connect(_buy_hint)
	overlay.dismiss_requested.connect(_dismiss_hint)
	hud.hint_button.pressed.connect(request_hint)
	hud.menu_requested.connect(func() -> void: menu_requested.emit())
	ad_adapter.event_received.connect(_on_ad_event)
	ad_adapter.show_guard = can_process_gameplay
	action_runner.event_generated.connect(_on_interaction_event)
	rule_evaluator.level_failed.connect(_on_puzzle_failed)
	interaction_manager.input_guard = can_process_gameplay
	rule_evaluator.execution_guard = can_process_gameplay
	var result := loader.load_manifest()
	if not result["ok"]:
		_report_failure(result["errors"])
		return
	manifest = result["data"]
	if test_start_index >= 0 and allow_development_loading and not progress_store.persistent:
		progress_store.open(manifest)
		load_level_index(test_start_index)
		return
	_restore_progress()

func load_level_index(index: int) -> bool:
	if index < 0 or index >= manifest.get("levels", []).size():
		_report_failure([{"file": PuzzleAppConfig.MANIFEST_PATH, "level_id": 0, "rule_id": "", "path": "levels", "message": "Level index out of range."}])
		return false
	var requested_id := int(manifest["levels"][index]["id"])
	if not allow_development_loading and (progress_store.data.get("current_level_id") != requested_id or progress_store.data.get("pending_result_level_id") != null or progress_store.data.get("results", {}).has(str(requested_id))):
		return false
	# Validate first: a failed replacement does not destroy the currently loaded stage.
	var result := loader.load_level(manifest["levels"][index])
	if not result["ok"]:
		_report_failure(result["errors"])
		return false
	_clear_stage()
	current_definition = result["data"].duplicate(true)
	state.initialize(current_definition)
	background.texture = load(current_definition["background"]) as Texture2D
	background.material = load(current_definition["background_material"]) as ShaderMaterial if current_definition.has("background_material") else null
	background.position = PuzzleAppConfig.DESIGN_SIZE * 0.5
	var texture_size := background.texture.get_size()
	background.scale = Vector2.ONE * minf(PuzzleAppConfig.DESIGN_SIZE.x / texture_size.x, PuzzleAppConfig.DESIGN_SIZE.y / texture_size.y)
	for i in range(current_definition["objects"].size()):
		var data: Dictionary = current_definition["objects"][i]
		var packed := load(PuzzleAppConfig.SCENE_PATHS[data["scene"]]) as PackedScene
		var object := packed.instantiate() as PuzzleObject
		object_root.add_child(object)
		object.configure(data, i)
		object_nodes[data["id"]] = object
	level_index = index
	hud.set_level(current_definition, index, manifest["levels"].size())
	hud.set_progress(results, int(progress_store.data.get("hint_points_spent", 0)))
	hud.get_node("SafeMargin/Layout/Toolbar/TestBadge").visible = test_start_index >= 0
	hud.hint_button.disabled = false
	action_runner.configure(state, object_nodes)
	action_runner.execution_guard = can_process_gameplay
	rule_evaluator.configure(current_definition, state, object_nodes, action_runner)
	var ui_roots: Array[Control] = [hud, $OverlayLayer/OverlayRoot]
	if get_parent().has_node("NavigationLayer/Root"):
		ui_roots.append(get_parent().get_node("NavigationLayer/Root"))
	if get_parent().has_node("MainMenuLayer/MainMenu"):
		ui_roots.append(get_parent().get_node("MainMenuLayer/MainMenu"))
	if get_parent().has_node("MessageLayer/MessageDialog"):
		ui_roots.append(get_parent().get_node("MessageLayer/MessageDialog"))
	if get_parent().has_node("SettingsLayer/SettingsDialog"):
		ui_roots.append(get_parent().get_node("SettingsLayer/SettingsDialog"))
	interaction_manager.configure(object_root, object_nodes, state, ui_roots)
	run_status = STATUS_PLAYING
	clock.start(float(current_definition["time_limit_seconds"]))
	for reason: String in _environment_pauses:
		clock.set_paused(reason, true)
	for request: Dictionary in _requests.values():
		if request["opened"] and not request["closed"]:
			clock.set_paused("ad:%s" % request["id"], true)
	interaction_manager.set_gameplay_enabled(clock.pause_reasons.is_empty())
	rule_evaluator.begin()
	level_loaded.emit(state.level_id, state.run_id)
	return true

func _clear_stage() -> void:
	_clear_success_sound()
	success_feedback.stop()
	GameAudio.stop_timer_warning()
	_timer_warning_played = false
	_result_delay_remaining = 0.0
	clock.stop()
	current_result.clear()
	overlay.hide()
	if is_instance_valid(interaction_manager):
		interaction_manager.set_gameplay_enabled(false)
	if is_instance_valid(rule_evaluator):
		rule_evaluator.stop()
	if is_instance_valid(action_runner):
		action_runner.cancel_all()
	run_status = STATUS_LOADING
	for child: Node in object_root.get_children():
		object_root.remove_child(child)
		child.queue_free()
	object_nodes.clear()
	current_definition.clear()
	state.clear()
	background.texture = null
	background.material = null

func _on_interaction_event(event: Dictionary) -> void:
	if event.get("run_id") == state.run_id and can_process_gameplay():
		rule_evaluator.enqueue_event(event)
		hud.update_counters(state.variables)
		interaction_manager.cancel_if_active_invalid()
		puzzle_event.emit(event)

func _on_level_completed(completed_level_id: int, completed_run_id: int) -> void:
	if completed_run_id != state.run_id or not can_process_gameplay():
		return
	hud.update_counters(state.variables)
	clock.stop()
	if clock.expired():
		_update_clock()
		return
	run_status = STATUS_COMPLETED
	hud.hint_button.disabled = true
	interaction_manager.set_gameplay_enabled(false)
	rule_evaluator.stop()
	current_result = PuzzleResultCalculator.calculate(state.level_id, clock.elapsed_usec, clock.limit_usec, int(current_definition["base_score"]), progress_store.hint_unlocked(state.level_id))
	_save_operation = "result"
	_retry_save()
	level_completed.emit(completed_level_id, completed_run_id)

func _on_puzzle_failed(failed_level_id: int, failed_run_id: int) -> void:
	if failed_run_id != state.run_id or not can_process_gameplay():
		return
	run_status = STATUS_FAILED
	clock.stop()
	interaction_manager.set_gameplay_enabled(false)
	rule_evaluator.stop()
	hud.hint_button.disabled = true
	overlay.show_failure(false)
	level_failed.emit(failed_level_id, failed_run_id)

func _on_runtime_error(error: Dictionary) -> void:
	if run_status != STATUS_PLAYING or error.get("run_id") != state.run_id:
		return
	run_status = STATUS_ERROR
	clock.stop()
	interaction_manager.set_gameplay_enabled(false)
	rule_evaluator.stop()
	overlay.show_error()
	if log_runtime_errors:
		push_error("Runtime puzzle error | level %s | rule %s: %s" % [error.get("level_id"), error.get("rule_id"), error.get("message")])
	engine_error.emit(error)

func _report_failure(errors: Array) -> void:
	if current_definition.is_empty():
		run_status = STATUS_ERROR
		hud.show_load_error()
		overlay.show_error()
	for error: Dictionary in errors:
		push_error("%s | level %s | %s | rule %s: %s" % [error["file"], error["level_id"], error["path"], error["rule_id"], error["message"]])
	load_failed.emit(errors)

func _process(delta: float) -> void:
	if is_instance_valid(_success_player):
		_success_player.stream_paused = not _environment_pauses.is_empty()
	if _environment_pauses.is_empty():
		success_feedback.advance(delta)
	ad_adapter.poll()
	if run_status == STATUS_PLAYING:
		_update_clock()
	elif run_status == STATUS_COMPLETED and _result_delay_remaining > 0.0 and _environment_pauses.is_empty():
		_result_delay_remaining = maxf(0.0, _result_delay_remaining - delta)
		if _result_delay_remaining == 0.0:
			_show_current_result()

func _update_clock() -> void:
	clock.update()
	hud.update_counters(state.variables)
	var seconds := clock.countdown_seconds()
	hud.set_countdown(seconds)
	if (
		run_status == STATUS_PLAYING and clock.running and clock.pause_reasons.is_empty()
		and seconds > 0 and seconds <= 10 and not _timer_warning_played
	):
		_timer_warning_played = true
		GameAudio.play_timer_warning()
	if run_status == STATUS_PLAYING and clock.expired():
		run_status = STATUS_FAILED
		clock.stop()
		interaction_manager.set_gameplay_enabled(false)
		rule_evaluator.stop()
		hud.hint_button.disabled = true
		overlay.show_failure()
		level_failed.emit(state.level_id, state.run_id)

func can_process_gameplay() -> bool:
	if run_status != STATUS_PLAYING:
		return false
	_update_clock()
	return run_status == STATUS_PLAYING and clock.pause_reasons.is_empty()

func set_pause_reason(reason: String, paused: bool) -> void:
	if run_status == STATUS_PLAYING:
		_update_clock()
	clock.set_paused(reason, paused)
	interaction_manager.set_gameplay_enabled(run_status == STATUS_PLAYING and clock.pause_reasons.is_empty())
	if run_status == STATUS_PLAYING and clock.pause_reasons.is_empty():
		rule_evaluator.resume_pending()

func _notification(what: int) -> void:
	var reason := ""
	var paused := false
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			reason = "background"
			paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			reason = "background"
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			reason = "application_focus"
			paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			reason = "application_focus"
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			reason = "window_focus"
			paused = true
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			reason = "window_focus"
	if reason.is_empty():
		return
	if paused:
		_environment_pauses[reason] = true
	else:
		_environment_pauses.erase(reason)
	if is_node_ready():
		set_pause_reason(reason, paused)

func retry_level() -> void:
	if not _save_operation.is_empty():
		_retry_save()
		return
	if run_status not in [STATUS_FAILED, STATUS_ERROR]:
		return
	if level_index < 0:
		_ready_reload_manifest()
		return
	load_level_index(level_index)

func _ready_reload_manifest() -> void:
	var result := loader.load_manifest()
	if result["ok"]:
		manifest = result["data"]
		_restore_progress()
	else:
		_report_failure(result["errors"])

func continue_to_next_level() -> void:
	if run_status != STATUS_COMPLETED or current_result.is_empty() or not _save_operation.is_empty() or _result_delay_remaining > 0.0:
		return
	run_status = STATUS_TRANSITIONING
	_save_operation = "advance"
	_retry_save()

func _restore_progress() -> void:
	if not progress_store.open(manifest):
		run_status = STATUS_ERROR
		_save_operation = "restore"
		overlay.show_save_error()
		return
	_save_operation = ""
	_sync_results()
	var current: Variant = progress_store.data["current_level_id"]
	if current == null:
		_show_finished()
		return
	for i in range(manifest["levels"].size()):
		if manifest["levels"][i]["id"] == current:
			level_index = i
	if progress_store.data["pending_result_level_id"] != null:
		current_result = results[int(current)].duplicate(true)
		run_status = STATUS_COMPLETED
		hud.hint_button.disabled = true
		_show_current_result()
	else:
		load_level_index(level_index)

func _sync_results() -> void:
	results.clear()
	for key: String in progress_store.data["results"]:
		results[int(key)] = progress_store.data["results"][key].duplicate(true)
	hud.set_progress(results, int(progress_store.data.get("hint_points_spent", 0)))

func _show_current_result(present_success: bool = false) -> void:
	if present_success and not current_definition.is_empty():
		GameAudio.stop_timer_warning()
		_play_success_sound()
		success_feedback.play()
		_result_delay_remaining = maxf(PuzzleSuccessFeedback.DURATION, float(current_definition.get("success", {}).get("result_delay_seconds", 1.0)))
		if _result_delay_remaining > 0.0:
			# The result is already recorded; leave the solved scene visible first.
			overlay.hide()
			return
	success_feedback.stop()
	var definition := current_definition
	if definition.is_empty():
		# A restored pending result needs its answer, without creating solved objects.
		var loaded := loader.load_level(manifest["levels"][level_index])
		if not loaded["ok"]:
			_save_operation = "restore"
			_report_failure(loaded["errors"])
			return
		definition = loaded["data"]
		hud.set_level(definition, level_index, manifest["levels"].size())
		hud.set_countdown(maxi(0, int(ceil(float(definition["time_limit_seconds"]) - float(current_result["elapsed_seconds"])))))
	overlay.show_result(current_result, level_index == manifest["levels"].size() - 1, definition["answer"])

func _play_success_sound() -> void:
	_clear_success_sound()
	var sound: String = current_definition.get("success", {}).get("sound", "")
	var stream: AudioStream = SUCCESS_SOUND if sound.is_empty() else load(sound) as AudioStream
	if stream == null:
		stream = SUCCESS_SOUND # A presentation failure must not undo the recorded result.
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	_success_player = player
	player.finished.connect(func() -> void:
		if _success_player == player:
			_success_player = null
		player.queue_free()
	)
	player.play()
	player.stream_paused = not _environment_pauses.is_empty()

func _clear_success_sound() -> void:
	if is_instance_valid(_success_player):
		_success_player.stop()
		_success_player.queue_free()
	_success_player = null

func _show_finished() -> void:
	var score := -int(progress_store.data.get("hint_points_spent", 0))
	var stars := 0
	for result: Dictionary in results.values():
		score += int(result["score"])
		stars += int(result["stars"])
	_clear_stage()
	run_status = STATUS_COMPLETED
	hud.hint_button.disabled = true
	overlay.show_game_finished(score, stars, manifest["levels"].size())

func _retry_save() -> void:
	# Explicit sandbox used by engine tests that visit levels out of manifest order.
	if allow_development_loading and not progress_store.persistent and _save_operation in ["result", "advance"]:
		var development_operation := _save_operation
		_save_operation = ""
		if development_operation == "result":
			results[state.level_id] = current_result.duplicate(true)
			hud.set_progress(results, int(progress_store.data.get("hint_points_spent", 0)))
			_show_current_result(true)
			result_ready.emit(current_result.duplicate(true))
		elif return_to_home_after_advance:
			home_requested.emit()
		elif level_index + 1 < manifest["levels"].size():
			load_level_index(level_index + 1)
		else:
			_show_finished()
		return
	if _save_operation == "restore":
		_restore_progress()
		return
	var operation := _save_operation
	var ok := false
	var relevant_hint: Dictionary = {}
	match operation:
		"buy_hint": ok = progress_store.buy_hint(_purchase_level)
		"result": ok = progress_store.save_result(current_result)
		"advance": ok = progress_store.advance()
		"hint":
			ok = true
			for id: int in _pending_hint_requests.duplicate():
				if not progress_store.save_hint(int(_requests[id]["level"])):
					ok = false
					break
				_requests[id]["saved"] = true
				if _requests[id]["run"] == state.run_id:
					relevant_hint = _requests[id]
				_pending_hint_requests.erase(id)
	if not ok:
		hud.hint_button.disabled = true
		overlay.show_save_error()
		return
	_save_operation = ""
	_sync_results()
	match operation:
		"buy_hint":
			hud.hint_button.disabled = run_status != STATUS_PLAYING or not ad_adapter.active.is_empty()
			if state.run_id == _purchase_run and run_status == STATUS_PLAYING:
				_update_clock()
			if state.run_id == _purchase_run and run_status == STATUS_PLAYING:
				overlay.show_hint(current_definition["hint"])
			elif run_status == STATUS_FAILED:
				overlay.show_failure()
		"result":
			_show_current_result(true)
			result_ready.emit(current_result.duplicate(true))
		"advance":
			if progress_store.data["current_level_id"] == null:
				_show_finished()
			elif return_to_home_after_advance:
				home_requested.emit()
			elif not load_level_index(level_index + 1):
				run_status = STATUS_ERROR
				level_index += 1
				overlay.show_error()
		"hint":
			hud.hint_button.disabled = run_status != STATUS_PLAYING or not ad_adapter.active.is_empty()
			if relevant_hint.is_empty() and overlay.mode == "save_error":
				if run_status == STATUS_PLAYING:
					overlay.hide()
				elif run_status == STATUS_FAILED:
					overlay.show_failure()
				elif run_status == STATUS_COMPLETED:
					if current_result.is_empty():
						_show_finished()
					else:
						_show_current_result()
			if not relevant_hint.is_empty():
				if run_status == STATUS_PLAYING:
					if relevant_hint["closed"]:
						_show_reward_hint(relevant_hint)
					elif ad_adapter.simulated:
						overlay.show_simulated_ad()
				elif run_status == STATUS_FAILED:
					overlay.show_failure()
				elif run_status == STATUS_COMPLETED and not current_result.is_empty():
					current_result = results[int(current_result["level_id"])].duplicate(true)
					_show_current_result()
	if not _pending_hint_requests.is_empty():
		_save_operation = "hint"
		_retry_save()

func request_hint() -> void:
	if not _save_operation.is_empty() or not can_process_gameplay() or not ad_adapter.active.is_empty():
		return
	interaction_manager.cancel_active_pointer()
	if progress_store.hint_unlocked(state.level_id):
		overlay.show_hint(current_definition["hint"])
	else:
		overlay.show_hint_offer(PuzzleProgressStore.available_score(progress_store.data))

func _buy_hint() -> void:
	if overlay.mode not in ["offer", "unavailable"] or not _save_operation.is_empty() or not ad_adapter.active.is_empty() or not can_process_gameplay():
		return
	if progress_store.hint_unlocked(state.level_id):
		overlay.show_hint(current_definition["hint"])
		return
	var score := PuzzleProgressStore.available_score(progress_store.data)
	if score < PuzzleProgressStore.HINT_COST:
		overlay.show_insufficient_points(score)
		return
	_purchase_level = state.level_id
	_purchase_run = state.run_id
	_save_operation = "buy_hint"
	_retry_save()

func _hint_action() -> void:
	if overlay.mode == "ad":
		ad_adapter.finish_simulation(true)
		return
	if overlay.mode not in ["offer", "unavailable"] or not _save_operation.is_empty() or not ad_adapter.active.is_empty() or not can_process_gameplay():
		return
	_request_serial += 1
	var id := _request_serial
	_requests[id] = {"id": id, "level": state.level_id, "run": state.run_id, "opened": false, "closed": false, "rewarded": false, "saved": false}
	hud.hint_button.disabled = true
	overlay.hide()
	if not ad_adapter.request(id, state.level_id):
		_on_ad_event("unavailable", id, state.level_id)

func _dismiss_hint() -> void:
	if overlay.mode == "finished":
		if run_status == STATUS_COMPLETED and current_result.is_empty() and _save_operation.is_empty() and ad_adapter.active.is_empty():
			home_requested.emit()
	elif overlay.mode == "ad":
		ad_adapter.finish_simulation(false)
	else:
		overlay.hide()

func _on_ad_event(kind: String, request_id: int, level_id: int) -> void:
	if not _requests.has(request_id) or _requests[request_id]["level"] != level_id:
		return
	var request: Dictionary = _requests[request_id]
	var same_run: bool = request["run"] == state.run_id and run_status == STATUS_PLAYING
	match kind:
		"opened":
			if request["closed"] or request["opened"]:
				return
			# Update deadline even when background is an overlapping pause.
			if same_run:
				_update_clock()
			if same_run and run_status != STATUS_PLAYING:
				if ad_adapter.simulated:
					ad_adapter.finish_simulation(false)
				return
			request["opened"] = true
			set_pause_reason("ad:%s" % request_id, true)
			if same_run and ad_adapter.simulated:
				overlay.show_simulated_ad()
		"rewarded":
			if request["rewarded"] or not request["opened"]:
				return
			request["rewarded"] = true
			_pending_hint_requests.append(request_id)
			if _save_operation.is_empty():
				_save_operation = "hint"
				_retry_save()
		"closed", "failed", "unavailable":
			if request["closed"]:
				return
			request["closed"] = true
			set_pause_reason("ad:%s" % request_id, false)
			if same_run and _save_operation.is_empty():
				hud.hint_button.disabled = not ad_adapter.active.is_empty()
				if not request["saved"]:
					overlay.show_ad_unavailable()
			_show_reward_hint(request)

func _show_reward_hint(request: Dictionary) -> void:
	if request["saved"] and request["closed"] and request["run"] == state.run_id and run_status == STATUS_PLAYING and _save_operation.is_empty() and ad_adapter.active.is_empty():
		overlay.show_hint(current_definition["hint"])

func _exit_tree() -> void:
	GameAudio.stop_timer_warning()
	if ad_adapter.event_received.is_connected(_on_ad_event):
		ad_adapter.event_received.disconnect(_on_ad_event)
	ad_adapter.show_guard = Callable()
	_clear_success_sound()
	clock.stop()
	if is_instance_valid(interaction_manager):
		interaction_manager.set_gameplay_enabled(false)
	if is_instance_valid(rule_evaluator):
		rule_evaluator.stop()
