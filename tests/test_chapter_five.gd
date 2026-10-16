extends "res://tests/test_chapter_four.gd"
# Reuse the established real-pointer helpers; this suite has its own entry point,
# routes, assertions and in-memory progress. No user save is opened.

func _solve(c: PuzzleController, id: int) -> void:
	match id:
		51: _drop(c, "guard", "candle_zone")
		52:
			_swipe(c, "curtain_2")
			_tap(c, "window_2")
		53: _drop(c, "tile_0", "gap")
		54:
			for i in range(3): _drop(c, "water", "fill_%d" % i)
			_hold(c, "test", 3.0)
			_tap(c, "jug_1")
		55:
			for i in range(3): _drop(c, "hat_%d" % i, "head_%d" % i)
			for i in range(2): _drop(c, "link_%d" % i, "relation_%d" % i)
		56: _drag(c, "shelf_right", Vector2(1590, 650))
		57: _drop(c, "glass_1", "glass_zone_4")
		58:
			_cross_bridge(c, [0, 1], "right_bank")
			_cross_bridge(c, [0], "left_bank")
			_cross_bridge(c, [2, 3], "right_bank")
			_cross_bridge(c, [1], "left_bank")
			_cross_bridge(c, [0, 1], "right_bank")
		59:
			_tap(c, "box_2")
			_drop(c, "label_0", "label_zone_2")
			_drop(c, "label_1", "label_zone_0")
			_drop(c, "label_2", "label_zone_1")
		60:
			for i in range(3): _drop(c, "coin_%d" % i, "left")
			for i in range(3, 6): _drop(c, "coin_%d" % i, "right")
			_tap(c, "weigh")
			for i in range(6): _drop(c, "coin_%d" % i, "tray")
			_drop(c, "coin_6", "left")
			_drop(c, "coin_7", "right")
			_tap(c, "weigh")
			_tap(c, "coin_6")
		61:
			_cross_river(c, 1, "right_bank")
			_cross_river(c, -1, "left_bank")
			_cross_river(c, 0, "right_bank")
			_cross_river(c, 1, "left_bank")
			_cross_river(c, 2, "right_bank")
			_cross_river(c, -1, "left_bank")
			_cross_river(c, 1, "right_bank")
		62:
			_hold(c, "door_2")
			_swipe(c, "door_2")
		63:
			_tap(c, "start")
			_tap(c, "next")
			_swipe(c, "glass7")
			_feedback(c)
			_tap(c, "next")
			_swipe(c, "glass7")
			_feedback(c)
			_tap(c, "next")
			_tap(c, "confirm")
		64: _hold(c, "brick_4")
		65:
			_tap(c, "coin")
			c.action_runner._process(2.1)
			_tap(c, "cup_a")
		66: _drag(c, "rope_1", Vector2(960, 1030))
		67: _drop(c, "jug_0", "light_position")
		68: _drag(c, "book_1", Vector2(960, 890))
		69: _drop(c, "piece", "rug_gap_1")
		70:
			_swipe(c, "card_0")
			_swipe(c, "card_3")

func _cross_bridge(c: PuzzleController, people: Array, bank: String) -> void:
	for i: int in people: _drop(c, "person_%d" % i, "bridge")
	_drop(c, "lamp", bank)

func _cross_river(c: PuzzleController, cargo: int, bank: String) -> void:
	if cargo >= 0:
		_drop(c, "cargo_%d" % cargo, "boat_load_right" if c.state.variables["bank"] == 1 else "boat_load")
	_drop(c, "boat", bank)

func _trap(c: PuzzleController, id: int, second: bool) -> void:
	match id:
		51:
			if second: _swipe(c, "vane", Vector2(0, 110))
			else: _drop(c, "opaque", "lantern_zone")
		52:
			if second: _hold(c, "photo")
			else: _tap(c, "yellow_light")
		53:
			if second: _hold(c, "stencil")
			else: _drop(c, "tile_1", "gap")
		54:
			if second: _tap(c, "cap")
			else: _drop(c, "cloth", "floor")
		55:
			if second: _hold(c, "brothers")
			else: _drop(c, "hat_3", "empty_person")
		56:
			if second: _swipe(c, "old_map", Vector2(0, -110))
			else: _drag(c, "chest", Vector2(420, 900))
		57:
			if second: _drop(c, "spoon", "spoon_zone")
			else: _drop(c, "coaster", "coaster_zone")
		58:
			if second: _drag(c, "short_rope", Vector2(1100, 580))
			else: _hold(c, "decorative_lamp")
		59:
			if second: _tap(c, "color_stamp")
			else: _drop(c, "unknown", "label_zone_0")
		60:
			if second: _drop(c, "souvenir", "decoration")
			else: _hold(c, "magnifier")
		61:
			if second: _drag(c, "broken_bridge", Vector2(1010, 810))
			else: _drop(c, "bush", "goat_trap")
		62:
			if second: _hold(c, "shield")
			else: _drop(c, "water", "fire_zone")
		63:
			if second: _drag(c, "ruler", Vector2(1550, 650))
			else: _tap(c, "clock_frame")
		64:
			if second: _swipe(c, "brush")
			else: _tap(c, "brick_0")
		65:
			if second: _hold(c, "mirror")
			else: _tap(c, "red_label")
		66:
			if second: _tap(c, "small_bell")
			else: _swipe(c, "pulley")
		67:
			if second: _swipe(c, "lever", Vector2(0, -110))
			else: _drop(c, "jug_3", "light_position")
		68:
			if second: _hold(c, "frame")
			else: _drag(c, "book_0", Vector2(800, 890))
		69:
			if second: _tap(c, "axis_stencil")
			else: _drop(c, "false_piece", "rug_gap_1")
		70:
			if second: _tap(c, "stamp")
			else: _hold(c, "reverse_rule")
	_feedback(c)

func _run() -> void:
	var packaged := PuzzleLoader.new().validate_all()
	check(packaged["ok"], "New content validates with all packaged resources: %s" % str(packaged["errors"]))
	if not packaged["ok"]:
		_finish()
		return
	var c := _controller()
	await process_frame
	for id in range(51, 71):
		check(c.load_level_index(id - 1), "Load stage %d" % id)
		for second: bool in [false, true]: _trap(c, id, second)
		check(c.run_status == "PLAYING" and not c.state.variables["solved"], "Neither trap solves stage %d" % id)
		_solve(c, id)
		check(c.run_status == "COMPLETED", "Real pointer solution completes stage %d" % id)
		c._process(1.1)
		check(c.overlay.visible and c.overlay.continue_button.visible, "Stage %d presents the result" % id)
	_negative_routes(c)
	_migration()
	c.free()
	await _progression()
	_finish()

func _negative_routes(c: PuzzleController) -> void:
	c.load_level_index(50)
	c.action_runner._process(10.1)
	check(c.run_status == "FAILED" and c.current_result.is_empty(), "Wind extinguishes the unprotected candle without success")
	c.retry_level()
	check(c.object_nodes["flame"].visible and c.run_status == "PLAYING", "Retry restores the burning candle")
	var stale := {"type": "custom:animation_finished", "source": "wind", "run_id": c.state.run_id}
	c.load_level_index(51)
	c._on_interaction_event(stale)
	check(c.run_status == "PLAYING", "Old animation cannot fail the replacement stage")
	_tap(c, "curtain_2")
	check(c.run_status == "PLAYING", "A covered window supplies no evidence")
	c.load_level_index(52)
	_drop(c, "tile_1", "gap")
	check(c.run_status == "PLAYING", "Same background color with mismatched edges is rejected")
	c.load_level_index(53)
	_tap(c, "jug_1")
	_hold(c, "test", 3.0)
	check(not c.state.variables["tested"], "Leak test requires all three filled jars")
	c.load_level_index(56)
	_drop(c, "glass_0", "glass_zone_4")
	check(c.run_status == "FAILED", "The only pickup cannot be spent on a different glass")
	c.retry_level()
	check(c.state.variables["lifts"] == 0, "Retry restores the pickup budget")
	c.load_level_index(57)
	_drop(c, "person_0", "bridge")
	_drop(c, "person_1", "bridge")
	_drop(c, "person_2", "bridge")
	check(c.state.variables["aboard"] == 2 and c.state.variables["selection"] == 3, "A third traveller cannot board")
	_drop(c, "lamp", "right_bank")
	check(c.state.variables["people"] == 3 and c.state.variables["minutes"] == 2, "Crossing cost is the slower traveller, not two separate trips")
	c.load_level_index(58)
	_tap(c, "box_0")
	check(c.run_status == "FAILED", "An uninformative draw spends the single sample")
	c.load_level_index(59)
	_tap(c, "coin_6")
	check(c.run_status == "PLAYING", "Packaged identity alone cannot select the light coin")
	_drop(c, "coin_0", "left")
	_tap(c, "weigh")
	check(c.state.variables["weighings"] == 1 and c.state.variables["candidates"] == 9, "An unequal-count weighing spends budget without eliminating candidates")
	c.load_level_index(59)
	_drop(c, "coin_6", "left")
	_drop(c, "coin_7", "right")
	_tap(c, "weigh")
	check(c.state.variables["candidates"] == 1, "A one-versus-one lighter result uniquely identifies that candidate")
	_tap(c, "coin_6")
	check(c.run_status == "COMPLETED", "A valid one-weighing deduction is accepted")
	c.load_level_index(60)
	_cross_river(c, 0, "right_bank")
	check(c.run_status == "FAILED" and c.current_result.is_empty(), "Unattended goat and cabbage fail immediately")
	c.retry_level()
	check(c.state.variables["mask"] == 0 and c.state.variables["cargo"] == -1, "Retry restores both banks and empty boat")
	c.load_level_index(61)
	_swipe(c, "door_2")
	check(c.run_status == "PLAYING", "Lion door requires its motionless clue")
	c.load_level_index(62)
	_tap(c, "start")
	_tap(c, "next")
	check(c.state.variables["minutes"] == 7 and c.state.variables["remaining11"] == 4, "Next event advances real sand amounts")
	_tap(c, "confirm")
	check(c.run_status == "PLAYING", "Seven simulated minutes cannot count as fifteen")
	_swipe(c, "glass7")
	_feedback(c)
	_tap(c, "next")
	check(c.state.variables["minutes"] == 11 and c.state.variables["remaining7"] == 3, "Second boundary leaves three minutes of sand above")
	_swipe(c, "glass7")
	_feedback(c)
	check(c.state.variables["remaining7"] == 4, "A partially full flip measures the complementary four minutes")
	c.load_level_index(64)
	_tap(c, "cup_a")
	check(c.run_status == "PLAYING", "Coin cannot be chosen before shuffling")
	_tap(c, "coin")
	c.set_pause_reason("test", true)
	c.action_runner._process(3.0)
	check(not c.state.variables["ready"], "Shuffling pauses with gameplay")
	c.set_pause_reason("test", false)
	c.action_runner._process(2.1)
	check(c.object_nodes["cup_a"].position.x == 1360 and c.object_nodes["cup_b"].position.x == 560, "Persistent identities end at the documented positions")
	c.load_level_index(68)
	_drop(c, "false_piece", "rug_gap_1")
	check(c.run_status == "PLAYING", "An inverted motif cannot repair the rug")
	for pair: Array in [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3]]:
		c.load_level_index(69)
		for i: int in pair: _swipe(c, "card_%d" % i)
		check(c.run_status == "FAILED" and c.state.variables["flips"] == 2, "Wrong Wason pair spends exactly two flips")
	c.load_level_index(69)
	_swipe(c, "card_3")
	_swipe(c, "card_0")
	check(c.run_status == "COMPLETED", "A and seven work in the reverse order too")

func _old_progress(version: int = 8, count: int = 50, pending: bool = false) -> Dictionary:
	var old := super._old_progress(version, count, pending)
	return old

func _migration() -> void:
	var store := PuzzleProgressStore.new()
	store.manifest = PuzzleLoader.new().load_manifest()["data"]
	store.persistent = false
	for config: Array in [[3, 2], [4, 5], [5, 10], [6, 20], [7, 30], [8, 50]]:
		for pending: bool in [false, true]:
			var old := _old_progress(config[0], config[1], pending)
			if config[1] == 2:
				old["unlocked_hints"] = []
				old["hint_points_spent"] = 0
			var migrated := store._migrate_main_progress(old)
			check(store.valid(migrated) and migrated.get("manifest_version") == 9, "Known catalog migrates to seventy stages")
			check(migrated.get("results") == old["results"] and migrated.get("unlocked_hints") == old["unlocked_hints"] and migrated.get("hint_points_spent") == old["hint_points_spent"], "Migration preserves earned and spent points and hints")
			store.data = migrated
			if pending: check(store.advance(), "Pending old result advances only on Continue")
			check(store.data.get("current_level_id") == config[1] + 1, "Old completion unlocks the first new stage")
	var broken := _old_progress()
	broken["results"]["50"]["stars"] = 8
	check(store._migrate_main_progress(broken).is_empty(), "Broken progress is not silently reset")
	broken = _old_progress()
	broken["manifest_version"] = 99
	check(store._migrate_main_progress(broken).is_empty(), "Unknown catalog remains on the recovery path")

func _progression() -> void:
	var c := _controller()
	await process_frame
	c.allow_development_loading = false
	check(c.progress_store.commit(c.progress_store._migrate_main_progress(_old_progress())), "Prepare completed fifty-stage catalog in memory")
	check(c.load_level_index(50), "Normal play resumes at fifty-one")
	for id in range(51, 71):
		check(c.state.level_id == id, "Normal progression reaches %d" % id)
		_solve(c, id)
		check(c.progress_store.data["pending_result_level_id"] == id, "Result is saved once at %d" % id)
		c._process(1.1)
		c.continue_to_next_level()
	check(c.progress_store.data["current_level_id"] == null and c.progress_store.data["results"].size() == 70, "Seventy results finish the catalog")
	check(not c.load_level_index(50), "Completed appended stages cannot be replayed")
	c.free()

func _finish() -> void:
	for failure: String in failures: printerr(failure)
	print("CHAPTER FIVE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
