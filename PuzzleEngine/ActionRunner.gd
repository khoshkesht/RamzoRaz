class_name PuzzleActionRunner
extends Node

signal event_generated(event: Dictionary)

var puzzle_state: PuzzleState
var object_nodes: Dictionary = {}
var run_id: int = 0
var _generation: int = 0
var execution_guard: Callable
var _animation_players: Array[AnimationPlayer] = []
var _sound_players: Array[AudioStreamPlayer] = []

func _exit_tree() -> void:
	cancel_all()


func _process(delta: float) -> void:
	if _animation_players.is_empty() and _sound_players.is_empty():
		return
	var allowed := not execution_guard.is_valid() or bool(execution_guard.call())
	for player: AudioStreamPlayer in _sound_players:
		if is_instance_valid(player):
			player.stream_paused = not allowed
	if not allowed:
		return
	var completed: Array[Dictionary] = []
	var generation := _generation
	for index in range(_animation_players.size() - 1, -1, -1):
		var player := _animation_players[index]
		if not is_instance_valid(player):
			_animation_players.remove_at(index)
			continue
		var animation_name := String(player.current_animation)
		player.advance(delta)
		if not player.is_playing():
			_animation_players.remove_at(index)
			var item := player.get_parent() as PuzzleObject
			completed.append({"type": "custom:animation_finished", "source": item.object_id, "payload": {"animation": animation_name}, "run_id": run_id})
	# Dispatch after iterating: a rule may complete the level and cancel all players.
	for event: Dictionary in completed:
		if generation == _generation and event["run_id"] == run_id and (not execution_guard.is_valid() or bool(execution_guard.call())):
			event_generated.emit(event)


func configure(state: PuzzleState, nodes: Dictionary) -> void:
	cancel_all()
	puzzle_state = state
	object_nodes = nodes
	run_id = state.run_id


func cancel_all() -> void:
	_generation += 1
	for player: AnimationPlayer in _animation_players:
		if is_instance_valid(player):
			player.seek(0.0, true)
			player.stop()
	_animation_players.clear()
	for player: AudioStreamPlayer in _sound_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_sound_players.clear()


func run_action(action: Dictionary, expected_run_id: int) -> Dictionary:
	if puzzle_state == null or expected_run_id != run_id or expected_run_id != puzzle_state.run_id:
		return _error("Action belongs to an inactive run.")
	var type: String = action["type"]
	match type:
		"show", "hide":
			var item := _object(action["target"])
			if item == null:
				return _error("Action target is unavailable: %s" % action["target"])
			var new_visibility: bool = type == "show"
			item.visible = new_visibility
			item.definition["visible"] = new_visibility
			puzzle_state.set_object_property(item.object_id, "visible", new_visibility)
			return _ok()
		"move":
			if float(action.get("duration", 0.0)) > 0.0:
				return _timed_action_error(type)
			var item := _object(action["target"])
			if item == null:
				return _error("Action target is unavailable: %s" % action["target"])
			var value := _vector(action["position"])
			item.position = value
			item.definition["position"] = [value.x, value.y]
			puzzle_state.set_object_property(item.object_id, "position", [value.x, value.y])
			return _ok()
		"rotate":
			if float(action.get("duration", 0.0)) > 0.0:
				return _timed_action_error(type)
			var item := _object(action["target"])
			if item == null:
				return _error("Action target is unavailable: %s" % action["target"])
			var degrees := float(action["degrees"])
			item.rotation_degrees = degrees
			item.definition["rotation_degrees"] = degrees
			puzzle_state.set_object_property(item.object_id, "rotation_degrees", degrees)
			return _ok()
		"scale":
			if float(action.get("duration", 0.0)) > 0.0:
				return _timed_action_error(type)
			var item := _object(action["target"])
			if item == null:
				return _error("Action target is unavailable: %s" % action["target"])
			var value := _vector(action["value"])
			item.scale = value
			item.definition["scale"] = [value.x, value.y]
			puzzle_state.set_object_property(item.object_id, "scale", [value.x, value.y])
			return _ok()
		"replace_sprite":
			var item := _object(action["target"])
			if item == null:
				return _error("Action target is unavailable: %s" % action["target"])
			if not item.replace_sprite(action["sprite"]):
				return _error("Could not load replacement texture: %s" % action["sprite"])
			puzzle_state.set_object_property(item.object_id, "sprite", action["sprite"])
			return _ok()
		"set_variable":
			var name: String = action["name"]
			var old_value: Variant = puzzle_state.variables[name]
			var new_value: Variant = action["value"]
			if action["operation"] == "increment":
				new_value = old_value + action["value"]
			puzzle_state.variables[name] = _copy_value(new_value)
			var generated: Array[Dictionary] = []
			if not _same_value(old_value, new_value):
				generated.append({
					"type": "variable_changed",
					"source": "$level",
					"payload": {"name": name, "old_value": old_value, "new_value": new_value},
					"run_id": expected_run_id,
				})
			return _ok(generated)
		"set_state":
			var target: String = action["target"]
			if not puzzle_state.set_object_state(target, action["key"], action["value"]):
				return _error("Could not update state key %s.%s" % [target, action["key"]])
			var item := _object(target)
			if item != null:
				item.definition["state"][action["key"]] = _copy_value(action["value"])
			return _ok()
		"fail_level":
			var result := _ok()
			result["failure_requested"] = true
			return result
		"complete_level":
			var result := _ok()
			result["success_requested"] = true
			return result
		"play_animation":
			# Nonblocking feedback is advanced manually with the gameplay guard.
			if action.get("wait", true):
				return _timed_action_error(type)
			var item := _object(action["target"])
			if item == null:
				return _error("Animation target is unavailable.")
			var player := item.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if player == null or not player.has_animation(action["animation"]):
				return _error("Object animation is unavailable.")
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			if player in _animation_players:
				player.seek(0.0, true)
				player.stop()
			player.play(action["animation"])
			player.seek(0.0, true)
			if player not in _animation_players:
				_animation_players.append(player)
			return _ok()
		"play_sound":
			if action.get("wait", false):
				return _timed_action_error(type)
			var stream := load(action["sound"]) as AudioStream
			if stream == null:
				return _error("Sound resource is unavailable.")
			# Repeated feedback replaces the prior sound instead of piling up voices.
			for previous: AudioStreamPlayer in _sound_players:
				if is_instance_valid(previous) and previous.stream == stream:
					previous.stop()
					_sound_players.erase(previous)
					previous.queue_free()
					break
			var player := AudioStreamPlayer.new()
			player.stream = stream
			add_child(player)
			_sound_players.append(player)
			player.finished.connect(func() -> void:
				_sound_players.erase(player)
				player.queue_free()
			)
			player.play()
			return _ok()
		"shake":
			return _timed_action_error(type)
		_:
			return _error("Unsupported action type: %s" % type)


func _object(object_id: String) -> PuzzleObject:
	var value: Variant = object_nodes.get(object_id)
	if value is PuzzleObject and is_instance_valid(value):
		return value as PuzzleObject
	return null


func _timed_action_error(type: String) -> Dictionary:
	return _error("Timed action '%s' is scheduled for implementation step 7." % type)


func _ok(events: Array[Dictionary] = []) -> Dictionary:
	return {"ok": true, "events": events, "success_requested": false, "error": ""}


func _error(message: String) -> Dictionary:
	return {"ok": false, "events": [], "success_requested": false, "error": message}


static func _vector(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


static func _copy_value(value: Variant) -> Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _same_value(left: Variant, right: Variant) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return float(left) == float(right)
	return typeof(left) == typeof(right) and left == right
