extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var gesture_usec: int = 1000000

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)

func _controller() -> PuzzleController:
	var c := (load("res://PuzzleEngine/PuzzleScene.tscn") as PackedScene).instantiate() as PuzzleController
	c.progress_store.persistent = false
	c.allow_development_loading = true
	c.clock.time_source = func() -> int: return 0
	root.add_child(c)
	c.interaction_manager.time_source = func() -> int: return gesture_usec
	return c

func _press(c: PuzzleController, id: String) -> Vector2:
	var m := c.interaction_manager
	var point := m.stage_to_viewport(c.object_nodes[id].position)
	check(m.pointer_pressed(point, 0), "Pointer picks " + id)
	check(m._active_object == c.object_nodes[id], "Hit testing selects " + id)
	return point

func _tap(c: PuzzleController, id: String) -> void:
	var point := _press(c, id)
	c.interaction_manager.pointer_released(point, 0)

func _hold(c: PuzzleController, id: String, seconds: float = 0.6) -> void:
	var point := _press(c, id)
	gesture_usec += int(seconds * 1000000)
	c.interaction_manager._process(0.0)
	c.interaction_manager.pointer_released(point, 0)

func _swipe(c: PuzzleController, id: String, movement: Vector2 = Vector2(100, 0)) -> void:
	var point := _press(c, id)
	gesture_usec += 200000
	c.interaction_manager.pointer_released(point + movement, 0)

func _drag(c: PuzzleController, id: String, destination: Vector2) -> void:
	var m := c.interaction_manager
	var start := _press(c, id)
	m.pointer_moved(start + Vector2(25, 0), 0)
	m.pointer_moved(m.stage_to_viewport(destination), 0)
	m.pointer_released(m.stage_to_viewport(destination), 0)

func _drop(c: PuzzleController, id: String, zone: String) -> void:
	_drag(c, id, c.object_nodes[zone].position)

func _feedback(c: PuzzleController) -> void:
	c.action_runner._process(0.4)

func _set_wheel(c: PuzzleController, name: String, target: int, size: int, increment: String) -> void:
	var steps := (target - int(c.state.variables[name]) + size) % size
	for step in range(steps): _tap(c, increment)

func _solve(c: PuzzleController, id: int) -> void:
	match id:
		31: _swipe(c, "match")
		32: _drag(c, "hand", Vector2(1330, 650))
		33:
			_tap(c, "window")
			_feedback(c)
		34: _tap(c, "hands")
		35: _tap(c, "fish")
		36:
			for letter: String in ["a", "b", "c"]: _drop(c, "fruit_" + letter, "pan")
			_tap(c, "fruit_c")
		37:
			_drag(c, "rug_1", Vector2(960, 830))
			_tap(c, "hatch")
		38: _drop(c, "key_b", "lock")
		39:
			_hold(c, "samovar_1")
			_tap(c, "samovar_1")
		40:
			_swipe(c, "jug_2")
			_feedback(c)
			_tap(c, "jug_2")
		41: _drag(c, "cage", Vector2(1320, 610))
		42:
			_hold(c, "switch_0", 3.0)
			_tap(c, "switch_0")
			_tap(c, "switch_1")
			_tap(c, "enter")
			for bulb in range(3): _tap(c, "lamp_%d" % bulb)
			for bulb in range(3): _drop(c, "choice_%d" % [1, 2, 0][bulb], "lamp_zone_%d" % bulb)
			_tap(c, "confirm")
		43:
			_tap(c, "five")
			_tap(c, "fill")
			_tap(c, "pour")
			_tap(c, "three")
			_tap(c, "empty")
			_tap(c, "five")
			_tap(c, "pour")
			_tap(c, "fill")
			_tap(c, "pour")
		44:
			_tap(c, "front_counter")
			_tap(c, "back_counter")
			_tap(c, "answer24")
		45:
			_set_wheel(c, "yesterday", 1, 7, "yesterday_next")
			_set_wheel(c, "today", 2, 7, "today_next")
			_tap(c, "confirm")
		46: _drop(c, "right", "answer")
		47:
			_set_wheel(c, "tens", 3, 10, "tens_plus")
			_set_wheel(c, "units", 8, 10, "units_plus")
			_tap(c, "confirm")
		48:
			for living in range(9): _tap(c, "sheep_%d" % living)
			_tap(c, "confirm")
		49:
			_drop(c, "six", "tens")
			_drop(c, "three", "units")
			_tap(c, "confirm")
		50:
			for step in range(4): _swipe(c, "trail_%d" % step)
			_tap(c, "chest_0")

func _trap(c: PuzzleController, id: int, second: bool) -> void:
	match id:
		31:
			if second: _tap(c, "switch")
			else: _tap(c, "lighter")
		32:
			if second: _swipe(c, "agreement", Vector2(0, 100))
			else: _tap(c, "glass")
		33:
			if second: _hold(c, "blanket")
			else: _drop(c, "snowball", "basket_zone")
		34:
			if second: _swipe(c, "photo")
			else: _drag(c, "car", Vector2(700, 850))
		35:
			if second: _swipe(c, "flower", Vector2(0, -100))
			else: _hold(c, "samanu")
		36:
			if second: _tap(c, "hammer")
			else: _drop(c, "ribbon", "base")
		37:
			if second: _swipe(c, "broom")
			else: _drag(c, "doormat", Vector2(450, 900))
		38:
			if second: _hold(c, "handle")
			else: _drop(c, "oil", "hinge")
		39:
			if second: _drop(c, "cloth", "tray")
			else: _tap(c, "glass")
		40:
			if second: _tap(c, "lid")
			else: _hold(c, "pebbles")
		41:
			if second: _tap(c, "seed")
			else: _drop(c, "key", "front_lock")
		42:
			if second: _drop(c, "color_label", "guess")
			else: _hold(c, "torch")
		43:
			if second: _hold(c, "ruler")
			else: _drop(c, "measure", "tap_zone")
		44:
			if second: _drag(c, "flag", Vector2(1350, 880))
			else: _tap(c, "answer25")
		45:
			if second: _tap(c, "clock")
			else:
				_set_wheel(c, "yesterday", 1, 7, "yesterday_next")
				_set_wheel(c, "today", 1, 7, "today_next")
				_tap(c, "confirm")
		46:
			if second: _hold(c, "decoy")
			else: _drop(c, "wrong", "answer")
		47:
			if second: _swipe(c, "double")
			else:
				_set_wheel(c, "tens", 3, 10, "tens_plus")
				_set_wheel(c, "units", 6, 10, "units_plus")
				_tap(c, "confirm")
		48:
			if second: _swipe(c, "gate", Vector2(-100, 0))
			else: _tap(c, "eight")
		49:
			if second: _tap(c, "mirror")
			else:
				_drop(c, "four", "tens")
				_drop(c, "five", "units")
				_tap(c, "confirm")
		50:
			if second: _drop(c, "stamp", "paper_zone")
			else: _drop(c, "coin", "right_chest")
	_feedback(c)

func _run() -> void:
	var all := PuzzleLoader.new().validate_all()
	check(all["ok"], "Packaged levels and resources validate: %s" % str(all["errors"]))
	if not all["ok"]:
		_finish()
		return
	var c := _controller()
	await process_frame
	for id in range(31, 51):
		for order: Array in [[], [false], [true], [false, true], [true, false]]:
			check(c.load_level_index(id - 1), "Load stage %d" % id)
			for second: bool in order:
				for repeat in range(2): _trap(c, id, second)
			check(c.run_status == "PLAYING" and not c.state.variables["solved"], "Traps preserve stage %d" % id)
			_solve(c, id)
			check(c.run_status == "COMPLETED", "Correct route solves stage %d after traps" % id)
			c._process(2.0)
			check(c.overlay.visible, "Stage %d presents its answer" % id)
	# Measurement, sequence and conjunction gates cannot be bypassed by selection.
	for pair: Array in [[36, "fruit_c"], [39, "samovar_1"], [40, "jug_2"], [50, "chest_0"]]:
		c.load_level_index(pair[0] - 1)
		_tap(c, pair[1])
		check(c.run_status == "PLAYING", "Evidence is required in stage %d" % pair[0])
	c.load_level_index(41)
	_tap(c, "switch_0")
	check(c.state.variables["switch_0"] and not c.state.variables["warm_0"], "A quick tap lights a cold bulb without faking heat")
	_tap(c, "switch_0")
	check(not c.state.variables["switch_0"], "A second tap turns the switch off")
	_tap(c, "enter")
	check(c.run_status == "PLAYING" and not c.state.variables["entered"], "An indistinguishable preparation does not consume the only visit")
	check(c.object_nodes["entry_warning"].visible and c.object_nodes["switch_0"].visible, "The player receives feedback and can correct the switches")
	c.clock.elapsed_usec = c.clock.limit_usec
	c._process(0.0)
	c.retry_level()
	check(not c.state.variables["entered"] and c.object_nodes["enter"].visible, "Retry restores the visit and all temperatures")
	for warm in range(3):
		for lit in range(3):
			if lit == warm: continue
			c.load_level_index(41)
			_hold(c, "switch_%d" % warm, 3.0)
			_tap(c, "switch_%d" % warm)
			_tap(c, "switch_%d" % lit)
			_tap(c, "enter")
			check(c.state.variables["entered"] and not c.object_nodes["enter"].visible, "A valid preparation enters once and hides the switches")
			if warm == 0 and lit == 1:
				_drop(c, "choice_0", "lamp_zone_0")
				check(c.object_nodes["choice_0"].position == Vector2(520, 910) and not c.state.variables["assigned_0"], "A premature card returns instead of covering the bulb")
				check(c.object_nodes["inspect_first"].visible, "A premature card explains the required observation")
			for bulb in range(3): _tap(c, "lamp_%d" % bulb)
			if warm == 0 and lit == 1:
				_tap(c, "confirm")
				check(c.object_nodes["missing_mapping"].visible and c.run_status == "PLAYING", "Confirm explains missing choices")
				for bulb in range(3): _drop(c, "choice_%d" % bulb, "lamp_zone_%d" % bulb)
				_tap(c, "confirm")
				check(c.object_nodes["wrong_mapping"].visible and c.run_status == "PLAYING", "A wrong complete mapping has visible feedback and remains editable")
			for bulb in range(3): _drop(c, "choice_%d" % [1, 2, 0][bulb], "lamp_zone_%d" % bulb)
			_tap(c, "confirm")
			check(c.run_status == "COMPLETED", "Every choice of warm and lit switch can solve the observations")
	c.load_level_index(32)
	_tap(c, "window")
	c.action_runner.execution_guard = func() -> bool: return false
	_feedback(c)
	check(c.run_status == "PLAYING", "Paused shivering cannot complete stage thirty-three")
	c.action_runner.execution_guard = c.can_process_gameplay
	var old_run := c.state.run_id
	c.load_level_index(32)
	c._on_interaction_event({"type": "custom:animation_finished", "source": "person", "payload": {"animation": "chapter_two/rattle"}, "run_id": old_run})
	check(c.run_status == "PLAYING" and not c.state.variables["opened"], "A cancelled shiver cannot solve a fresh run")
	_tap(c, "window")
	c.clock.elapsed_usec = c.clock.limit_usec
	_feedback(c)
	check(c.run_status == "FAILED", "Time expiry takes priority over shiver completion")
	c.load_level_index(47)
	_tap(c, "sheep_9")
	check(c.state.variables["removed"] == 1, "One distinct dead sheep is counted")
	_tap(c, "confirm")
	check(c.run_status == "PLAYING", "Removing a dead sheep does not count any living sheep")
	c.load_level_index(48)
	_drop(c, "three", "tens")
	_drop(c, "six", "units")
	_tap(c, "confirm")
	check(c.run_status == "PLAYING", "The reversed number has the wrong signed difference")
	c.load_level_index(49)
	_swipe(c, "trail_3")
	check(c.state.variables["trail"] == 0, "Following a disconnected last segment does not count")
	_queue_controls(c)
	_redesigned_controls(c)
	_water_transitions(c)
	_result_delay_and_hint_price(c)
	c.free()
	await _progression()
	_migration()
	_finish()

func _result_delay_and_hint_price(c: PuzzleController) -> void:
	c.load_level_index(30)
	_solve(c, 31)
	check(c._result_delay_remaining == 1.0 and PuzzleSuccessFeedback.DURATION == 1.0, "Result and success effect both wait one second")
	c._process(0.5)
	check(not c.overlay.visible, "Result does not appear early")
	c._process(0.5)
	check(c.overlay.visible, "Result appears after one second")
	for gross in [349, 350, 400]:
		var store := PuzzleProgressStore.new()
		store.manifest = c.manifest
		store.persistent = false
		var saved := {"save_version": 1, "manifest_version": 8, "current_level_id": 3, "pending_result_level_id": null, "unlocked_hints": [1], "hint_points_spent": 100, "results": {
			"1": {"level_id": 1, "score": 200, "stars": 3, "elapsed_seconds": 1, "hint_received": true},
			"2": {"level_id": 2, "score": gross - 200, "stars": 3, "elapsed_seconds": 1, "hint_received": false}}}
		check(store.commit(saved), "Legacy purchases retain their original cost")
		var before := store.data.duplicate(true)
		if gross == 349:
			check(not store.buy_hint(3) and store.data == before, "249 points cannot buy or charge a hint")
		else:
			store.fail_writes = true
			check(not store.buy_hint(3) and store.data == before, "A failed purchase preserves the balance and hint")
			store.fail_writes = false
			check(store.buy_hint(3) and store.data["hint_points_spent"] == 350, "New purchase charges 250 after a legacy purchase")
			check(store.buy_hint(3) and store.data["hint_points_spent"] == 350, "An unlocked hint is never charged again")
			check(store.valid(JSON.parse_string(JSON.stringify(store.data))), "Mixed old and new spending survives serialization")

func _redesigned_controls(c: PuzzleController) -> void:
	for id in [45, 47, 48]:
		c.load_level_index(id - 1)
		for item: PuzzleObject in c.object_nodes.values():
			check(not item.has_interaction("drag") and not item.has_interaction("drop_on"), "Stage %d has no draggable cards or hidden drop operations" % id)
	c.load_level_index(44)
	_tap(c, "confirm")
	check(c.run_status == "PLAYING" and c.object_nodes["yesterday_error"].visible, "Weekday feedback identifies the first unsatisfied relation")
	_tap(c, "yesterday_previous")
	check(c.state.variables["yesterday"] == 6 and c.object_nodes["yesterday_day_6"].visible, "Previous weekday wraps to Friday")
	_tap(c, "yesterday_next")
	_tap(c, "yesterday_next")
	check(c.state.variables["yesterday"] == 1, "Each weekday tap advances exactly one step")
	_tap(c, "today_next")
	_tap(c, "confirm")
	check(c.run_status == "PLAYING" and c.object_nodes["today_error"].visible, "Sunday today does not satisfy the second relation")
	_tap(c, "clock")
	check(c.state.variables["yesterday"] == 1 and c.state.variables["today"] == 1, "The clock cannot change either day display")
	_tap(c, "today_next")
	_tap(c, "confirm")
	check(c.run_status == "COMPLETED", "Correcting the second relation solves the timeline")
	c.load_level_index(46)
	_tap(c, "units_minus")
	check(c.state.variables["units"] == 9 and c.object_nodes["units_digit_9"].visible, "Digit decrement wraps once")
	_tap(c, "units_plus")
	check(c.state.variables["units"] == 0, "Digit increment wraps once")
	for i in range(4):
		_tap(c, "difference_%d" % i)
		check(c.object_nodes["diff_value_%d" % i].visible and not c.object_nodes["difference_%d" % i].visible, "Each gap reveals its own difference")
	_set_wheel(c, "tens", 3, 10, "tens_plus")
	_set_wheel(c, "units", 6, 10, "units_plus")
	_tap(c, "confirm")
	check(c.run_status == "PLAYING" and c.object_nodes["wrong_difference"].visible, "Thirty-six explains the repeated difference")
	_tap(c, "units_plus")
	_tap(c, "units_plus")
	_tap(c, "confirm")
	check(c.run_status == "COMPLETED", "A numeric correction solves the sequence")
	c.load_level_index(47)
	_tap(c, "confirm")
	check(c.run_status == "PLAYING" and c.object_nodes["incomplete"].visible, "The animal count needs living animals to be marked")
	_tap(c, "sheep_0")
	_tap(c, "sheep_0")
	check(c.state.variables["living"] == 1 and c.object_nodes["marked_0"].visible and c.object_nodes["already_counted"].visible, "Repeated taps never count a living animal twice")
	_tap(c, "sheep_9")
	check(c.state.variables["living"] == 1 and c.state.variables["removed"] == 1 and c.object_nodes["dead_feedback"].visible, "Dead animals cannot inflate the living count")
	for i in range(8, 0, -1): _tap(c, "sheep_%d" % i)
	_tap(c, "eight")
	check(c.run_status == "PLAYING" and c.state.variables["living"] == 9, "The wrong remaining count cannot win or erase marked animals")
	_tap(c, "confirm")
	check(c.run_status == "COMPLETED", "Living animals may be counted in any order")
	for id in [45, 47, 48]:
		c.load_level_index(id - 1)
		match id:
			45: _tap(c, "today_next")
			47: _tap(c, "units_plus")
			48:
				_tap(c, "sheep_0")
				_tap(c, "sheep_9")
		c.clock.elapsed_usec = c.clock.limit_usec
		c._process(0.0)
		c.retry_level()
		check(c.run_status == "PLAYING" and c.clock.elapsed_usec == 0, "Retry restores stage %d and its clock" % id)
		match id:
			45: check(c.state.variables["today"] == 0 and c.state.variables["yesterday"] == 0, "Retry resets both day displays")
			47: check(c.state.variables["units"] == 0 and c.state.variables["tens"] == 0 and c.object_nodes["difference_0"].visible, "Retry resets the number and hidden differences")
			48: check(c.state.variables["living"] == 0 and c.state.variables["removed"] == 0 and c.object_nodes["sheep_9"].visible and not c.object_nodes["marked_0"].visible, "Retry restores every animal and clears marks")

func _queue_controls(c: PuzzleController) -> void:
	for reverse: bool in [false, true]:
		c.load_level_index(43)
		_tap(c, "answer24")
		check(c.run_status == "PLAYING" and c.object_nodes["count_first"].visible, "The answer requires both visible counts")
		var first := "back_counter" if reverse else "front_counter"
		var second := "front_counter" if reverse else "back_counter"
		_tap(c, first)
		_tap(c, first)
		check(c.state.variables["back"] == reverse and c.state.variables["front"] == (not reverse), "Repeated count does not complete the other side")
		_tap(c, "answer24")
		check(c.run_status == "PLAYING", "One side alone cannot confirm the total")
		_tap(c, second)
		_tap(c, second)
		check(c.object_nodes["front_number_9"].visible and c.object_nodes["back_number_9"].visible and c.object_nodes["shared_note"].visible, "The same target is visibly counted as ten and fifteen")
		check(c.object_nodes["front_number_0"].visible and c.object_nodes["back_number_23"].visible, "Both ends of the queue are included")
		_tap(c, "answer25")
		check(c.run_status == "PLAYING" and c.object_nodes["wrong_answer"].visible, "Double-counting has explicit feedback and preserves the correct route")
		_tap(c, "answer24")
		check(c.run_status == "COMPLETED", "Either count order can solve the queue")
	c.load_level_index(43)
	_tap(c, "front_counter")
	c.clock.elapsed_usec = c.clock.limit_usec
	c._process(0.0)
	c.retry_level()
	check(not c.state.variables["front"] and not c.state.variables["back"] and not c.object_nodes["front_number_9"].visible and not c.object_nodes["shared_note"].visible, "Retry clears counts, highlights and feedback")

func _water_transitions(c: PuzzleController) -> void:
	c.load_level_index(42)
	for command: String in ["fill", "empty", "pour"]:
		_tap(c, command)
		check(c.object_nodes["choose_first"].visible and c.state.variables["five"] == 0 and c.state.variables["three"] == 0, "Commands require an explicit vessel selection")
	_tap(c, "five")
	check(c.object_nodes["five_selected"].visible and not c.object_nodes["three_selected"].visible, "The selected vessel has a unique visible marker")
	_tap(c, "empty")
	check(c.object_nodes["already_empty"].visible, "Emptying an empty vessel explains the no-op")
	_tap(c, "fill")
	check(c.state.variables["five"] == 5 and c.object_nodes["five_reading_5"].visible and c.object_nodes["five"].definition["sprite"].ends_with("measuring_jug_5_5.svg"), "Filling updates both the measured number and visible water")
	check(c.object_nodes["filled"].visible and not c.object_nodes["already_full"].visible, "A real fill retains its own feedback")
	_tap(c, "fill")
	check(c.object_nodes["already_full"].visible, "Filling a full vessel has explicit feedback")
	_tap(c, "three")
	_tap(c, "pour")
	check(c.object_nodes["source_empty"].visible, "Pouring from an empty vessel explains the problem")
	_tap(c, "fill")
	_tap(c, "five")
	_tap(c, "pour")
	check(c.object_nodes["destination_full"].visible and c.state.variables["five"] == 5 and c.state.variables["three"] == 3, "A full destination preserves both volumes")
	_tap(c, "three")
	_tap(c, "empty")
	_tap(c, "five")
	_tap(c, "pour")
	check(c.state.variables["five"] == 2 and c.state.variables["three"] == 3 and c.object_nodes["five_reading_2"].visible and c.object_nodes["three_reading_3"].visible, "Pouring updates both vessels together")
	c.clock.elapsed_usec = c.clock.limit_usec
	c._process(0.0)
	c.retry_level()
	check(c.state.variables["selected"] == "" and c.state.variables["five"] == 0 and c.state.variables["three"] == 0, "Retry restores empty vessels and clears selection")
	# Check the whole legal volume space, not only the documented six moves.
	for five in range(6):
		for three in range(4):
			for source: String in ["five", "three"]:
				c.load_level_index(42)
				c.state.variables["five"] = five
				c.state.variables["three"] = three
				var amount := mini(five, 3 - three) if source == "five" else mini(three, 5 - five)
				_tap(c, source)
				_tap(c, "pour")
				var expected_five := five - amount if source == "five" else five + amount
				var expected_three := three + amount if source == "five" else three - amount
				check(c.state.variables["five"] == expected_five and c.state.variables["three"] == expected_three, "Pour conserves volume and respects capacities at %d/%d from %s" % [five, three, source])

func _old_progress(version: int = 7, count: int = 30, pending: bool = false) -> Dictionary:
	var results: Dictionary = {}
	for id in range(1, count + 1):
		results[str(id)] = {"level_id": id, "score": 45, "stars": 2, "elapsed_seconds": 17, "hint_received": id == 3}
	return {"save_version": 1, "manifest_version": version, "current_level_id": count if pending else null, "pending_result_level_id": count if pending else null, "unlocked_hints": [3], "hint_points_spent": 100, "results": results}

func _progression() -> void:
	var c := _controller()
	await process_frame
	c.allow_development_loading = false
	check(c.progress_store.commit(c.progress_store._migrate_main_progress(_old_progress())), "Prepare completed old catalog in isolated memory")
	check(c.load_level_index(30), "Normal play starts at stage thirty-one")
	for id in range(31, 51):
		check(c.state.level_id == id, "Normal progression reaches %d" % id)
		_solve(c, id)
		check(c.progress_store.data["pending_result_level_id"] == id, "Result is saved once at %d" % id)
		c._process(2.0)
		c.continue_to_next_level()
	check(c.progress_store.data["current_level_id"] == null and c.progress_store.data["results"].size() == 50, "Continue after fifty completes the catalog")
	check(not c.load_level_index(30), "Normal play cannot replay a completed level")
	c.free()

func _migration() -> void:
	var store := PuzzleProgressStore.new()
	store.manifest = PuzzleLoader.new().load_manifest()["data"]
	store.persistent = false
	for config: Array in [[4, 5], [5, 10], [6, 20], [7, 30]]:
		for pending: bool in [false, true]:
			var old := _old_progress(config[0], config[1], pending)
			var expanded := store._migrate_main_progress(old)
			check(store.valid(expanded) and expanded["manifest_version"] == 8, "Known catalogs migrate to eight")
			check(expanded["results"] == old["results"] and expanded["unlocked_hints"] == old["unlocked_hints"] and expanded["hint_points_spent"] == 100, "Migration retains scores, times, stars, hints and purchases")
			store.data = expanded
			if pending:
				check(store.data["pending_result_level_id"] == config[1] and store.advance(), "Pending result requires Continue")
			check(store.data["current_level_id"] == config[1] + 1, "Migration resumes at first appended stage")
	var broken := _old_progress()
	broken["results"]["15"]["stars"] = 8
	check(store._migrate_main_progress(broken).is_empty(), "Corrupt saves cannot migrate")
	broken = _old_progress()
	broken["manifest_version"] = 99
	check(store._migrate_main_progress(broken).is_empty(), "Unknown saves keep the recovery path")
	# Use only test-owned files; never read or modify user://progress.json.
	DirAccess.make_dir_recursive_absolute("res://test_outputs")
	store.path = "res://test_outputs/chapter-four-progress.json"
	store.persistent = true
	var serialized := JSON.stringify(_old_progress(7, 30, true))
	for suffix: String in ["", ".backup"]:
		var file := FileAccess.open(store.path + suffix, FileAccess.WRITE)
		file.store_string(serialized)
		file.close()
	store.fail_writes = true
	check(not store.open(store.manifest) and FileAccess.get_file_as_string(store.path) == serialized, "A failed migration write preserves old progress")
	store.fail_writes = false
	check(store.open(store.manifest) and store.data["pending_result_level_id"] == 30, "Persistent migration preserves pending thirty")
	check(store.valid(store._read(store.path)) and store.valid(store._read(store.path + ".backup")), "Both new save copies are valid")
	for suffix: String in ["", ".backup"]:
		check(FileAccess.get_file_as_string(store.path + suffix + ".pre-expanded-content") == serialized, "Prior save copies are archived")

func _finish() -> void:
	for failure: String in failures: printerr(failure)
	print("CHAPTER FOUR: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
