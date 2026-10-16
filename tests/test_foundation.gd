extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var packaged := PuzzleLoader.new().load_manifest()
	check(packaged["ok"] and packaged["data"]["manifest_version"] == 10 and packaged["data"]["levels"].size() == 101, "Main catalog contains one hundred and one production stages")
	if packaged["ok"]:
		for i in range(101):
			check(packaged["data"]["levels"][i]["id"] == i + 1, "Production catalog keeps authored order")
	var production := PuzzleLoader.new().validate_all()
	check(production["ok"], "All main stages validate: %s" % str(production["errors"]))
	var authored_settings: Dictionary = {}
	for line: String in FileAccess.get_file_as_string("res://docs/100_interactive_persian_puzzles.md").split("\n"):
		var cells := line.split("|")
		if cells.size() < 2 or not cells[1].strip_edges().is_valid_int():
			continue
		if cells.size() != 12:
			check(false, "Scenario row has all ten columns: " + cells[1])
			continue
		var id := int(cells[1].strip_edges())
		var time_text := cells[6].strip_edges()
		var score_text := cells[7].strip_edges()
		var seconds := int(time_text)
		var score := int(score_text)
		check(time_text.is_valid_int() and seconds >= 30 and seconds <= 240 and seconds % 5 == 0, "Scenario time is in range and a whole multiple of five: %d" % id)
		check(score_text.is_valid_int() and score >= 50 and score <= 250 and score % 5 == 0, "Scenario base score is in range and a multiple of five: %d" % id)
		check(not authored_settings.has(id), "Scenario IDs remain unique: %d" % id)
		authored_settings[id] = [seconds, score]
	check(authored_settings.size() == 101, "All 101 scenarios have authored time and score")
	for id in range(1, 102):
		check(authored_settings.has(id), "Scenario settings exist: %d" % id)
	for stage: Dictionary in production["data"]:
		check(authored_settings.get(stage["id"]) == [stage["time_limit_seconds"], stage["base_score"]], "Production JSON agrees with its scenario settings: %d" % stage["id"])
	var loader := PuzzleLoader.new("res://tests/fixture_manifest.json")
	var manifest := loader.load_manifest()
	check(manifest["ok"], "Engine fixture manifest is valid")
	var all := loader.validate_all()
	check(all["ok"], "All engine fixtures are valid: %s" % str(all["errors"]))
	check(all["data"].size() == 2, "Two isolated engine fixtures are available")
	var raw := PuzzleLoader.read_json("res://tests/fixture_012.json")["data"] as Dictionary
	var pristine: Dictionary = raw.duplicate(true)
	var normalized := PuzzleValidator.new().validate_level(raw)
	check(raw == pristine, "Normalization must not mutate source JSON")
	check(normalized["data"]["rules"][0]["once"] == true, "Default one-shot rule")
	check(normalized["data"]["objects"][2]["interactions"][0]["start_distance"] == 12.0, "Interaction defaults normalized")

	var bad: Dictionary = raw.duplicate(true)
	var dialogue: Dictionary = PuzzleLoader.read_json("res://PuzzleEngine/PuzzleData/003.json")["data"]
	for invalid_color: Variant in ["white", "#XYZXYZ", "#12345600", 123]:
		var wrong_color := dialogue.duplicate(true)
		wrong_color["objects"][4]["text_color"] = invalid_color
		rejected(wrong_color, "objects[4].text_color", "Invalid dialogue text color")
	bad["objects"][0]["text_color"] = "#26383B"
	rejected(bad, "objects[0].text_color", "Text color is restricted to text objects")
	bad = raw.duplicate(true)
	check(normalized["data"]["success"]["result_delay_seconds"] == 1.0, "Result presentation gives visible feedback by default")
	for delay: Variant in [-1.0, 5.1, "1.5", true]:
		bad = raw.duplicate(true)
		bad["success"] = {"result_delay_seconds": delay}
		rejected(bad, "success.result_delay_seconds", "Invalid presentation duration")
	for delay: float in [0.0, 1.5, 5.0]:
		bad = raw.duplicate(true)
		bad["success"] = {"result_delay_seconds": delay}
		check(PuzzleValidator.new().validate_level(bad)["ok"], "Valid presentation duration")
	bad = raw.duplicate(true)
	bad["schema_version"] = 2
	rejected(bad, "schema_version", "Unknown schema")
	bad = raw.duplicate(true)
	bad["hint"] = "   "
	rejected(bad, "hint", "Empty hint")
	bad = raw.duplicate(true)
	bad.erase("answer")
	rejected(bad, "answer", "Missing answer")
	for answer: Variant in ["", "   ", 12, null]:
		bad = raw.duplicate(true)
		bad["answer"] = answer
		rejected(bad, "answer", "Invalid answer")
	for value: Variant in [0, -1, true, "60", INF, NAN, 0.00000001, 25, 32, 33, 35.5, 245]:
		bad = raw.duplicate(true)
		bad["time_limit_seconds"] = value
		rejected(bad, "time_limit_seconds", "Invalid time: %s" % str(value))
	for value: Variant in [0, -5, 2.5, true, 45, 52, 53, 55.5, 255]:
		bad = raw.duplicate(true)
		bad["base_score"] = value
		rejected(bad, "base_score", "Invalid score")
	for settings: Array in [[30, 50], [35, 55], [240, 250]]:
		var valid_stage := raw.duplicate(true)
		valid_stage["time_limit_seconds"] = settings[0]
		valid_stage["base_score"] = settings[1]
		check(PuzzleValidator.new().validate_level(valid_stage)["ok"], "Time and score limits and steps of five are accepted")
	bad = raw.duplicate(true)
	bad["unexpected"] = 1
	rejected(bad, "unexpected", "Unknown level field")
	bad = raw.duplicate(true)
	bad["objects"][1]["id"] = "man"
	rejected(bad, "objects[1].id", "Duplicate object ID")
	bad = raw.duplicate(true)
	bad["objects"][0]["position"] = [0]
	rejected(bad, "objects[0].position", "Malformed position")
	bad = raw.duplicate(true)
	bad["objects"][0]["scale"] = [0, 1]
	rejected(bad, "objects[0].scale", "Nonpositive scale")
	bad = raw.duplicate(true)
	bad["objects"][0]["sprite"] = "res://assets/samples/missing.svg"
	rejected(bad, "objects[0].sprite", "Missing packaged texture")
	bad = raw.duplicate(true)
	bad["objects"][0]["sprite"] = PuzzleAppConfig.FONT_PATH
	rejected(bad, "objects[0].sprite", "Wrong resource type")
	bad = raw.duplicate(true)
	bad["objects"][2]["interactions"] = ["drag", "swipe"]
	rejected(bad, "objects[2].interactions", "Conflicting gestures")
	bad = raw.duplicate(true)
	bad["objects"][2]["interactions"] = ["drop_on"]
	rejected(bad, "objects[2].interactions", "Drop without drag")
	bad = raw.duplicate(true)
	bad["objects"][2]["interactions"] = [{"type": "drag", "axis": "z"}]
	rejected(bad, "axis", "Unknown axis")
	bad = raw.duplicate(true)
	bad["rules"][0]["actions"][0]["target"] = "missing"
	rejected(bad, "target", "Unknown action target")
	bad = raw.duplicate(true)
	bad["rules"][0]["event"] = "unknown"
	rejected(bad, "event", "Unknown event")
	bad = raw.duplicate(true)
	bad["rules"][0]["actions"][0]["type"] = "execute_script"
	rejected(bad, "type", "Unknown action")
	bad = raw.duplicate(true)
	bad["rules"][0]["actions"] = [{"type": "play_animation", "target": "man", "animation": "missing"}]
	rejected(bad, "animation", "Missing scene animation")
	bad = raw.duplicate(true)
	bad["win_condition"] = {"type": "moved_distance_at_least", "value": 1}
	rejected(bad, "win_condition", "Event-dependent win condition")
	bad = raw.duplicate(true)
	bad["win_condition"] = {"type": "visible", "target": "man"}
	rejected(bad, "win_condition", "Initially completed puzzle")
	bad = raw.duplicate(true)
	bad["rules"].append(bad["rules"][0].duplicate(true))
	rejected(bad, "rules[1].id", "Duplicate rule ID")
	bad = raw.duplicate(true)
	bad["win_condition"] = null
	rejected(bad, "win_condition", "Null win without custom handler")
	bad = raw.duplicate(true)
	bad["objects"][2]["interactions"] = [{"type": "drag", "bounds": [0, 0, -10, 20]}]
	rejected(bad, "bounds", "Invalid drag bounds")
	var deep: Dictionary = {"type": "visible", "target": "bald_head"}
	for i in range(10):
		deep = {"type": "not", "condition": deep}
	bad = raw.duplicate(true)
	bad["win_condition"] = deep
	rejected(bad, "win_condition", "Condition depth guard")
	var wrong_id := PuzzleValidator.new().validate_level(raw, "fixture.json", 999)
	check(not wrong_id["ok"], "Manifest identity mismatch rejected")
	check(wrong_id["errors"][0]["file"] == "fixture.json" and wrong_id["errors"][0]["level_id"] == 12, "Structured error context")
	var wrong_manifest: Dictionary = manifest["data"].duplicate(true)
	wrong_manifest["levels"].append(wrong_manifest["levels"][0].duplicate(true))
	check(not PuzzleValidator.new().validate_manifest(wrong_manifest)["ok"], "Duplicate manifest entries rejected")
	check(not PuzzleLoader.read_json("res://tests/fixtures/malformed.json")["ok"], "Syntax errors rejected")
	check(not PuzzleLoader.read_json("res://tests/fixtures/missing.json")["ok"], "Missing file rejected")

	var state := PuzzleState.new()
	state.initialize(all["data"][1])
	var old_run: int = state.run_id
	state.variables["ground_state"] = 7
	state.objects["shovel"]["position"][0] = 1
	check(all["data"][1]["variables"]["ground_state"] == 0, "Variables independent from initial data")
	check(all["data"][1]["objects"][2]["position"][0] == 525, "Object state deeply isolated")
	var snapshot := state.object_snapshot("shovel")
	snapshot["position"][0] = 99
	check(state.objects["shovel"]["position"][0] == 1, "Snapshot cannot mutate runtime")
	state.initialize(all["data"][1])
	check(state.run_id != old_run and state.variables["ground_state"] == 0, "Reinitialization creates new run and restores defaults")

	var safe := PuzzleSafeMargin.map_safe_rect(Rect2(320, 0, 2080, 1080), Rect2(240, 0, 1920, 1080), Vector2(1920, 1080))
	check(safe == Rect2(80, 0, 1840, 1080), "Safe area intersects letterboxed render region")
	safe = PuzzleSafeMargin.map_safe_rect(Rect2(0, 0, 2400, 1080), Rect2(240, 0, 1920, 1080), Vector2(1920, 1080))
	check(safe == Rect2(0, 0, 1920, 1080), "Letterbox inset not applied twice")
	safe = PuzzleSafeMargin.map_safe_rect(Rect2(60, 0, 1140, 675), Rect2(0, 0, 1200, 675), Vector2(1920, 1080))
	check(safe == Rect2(96, 0, 1824, 1080), "Physical inset converted to logical coordinates")
	var font := load(PuzzleAppConfig.FONT_PATH) as Font
	check(font != null and font.has_char(0x0645) and font.has_char(0x06CC), "Bundled font supports Persian glyphs")

	var scene := load("res://PuzzleEngine/PuzzleScene.tscn") as PackedScene
	var controller := scene.instantiate() as PuzzleController
	controller.loader.manifest_path = "res://tests/fixture_manifest.json"
	controller.progress_store.persistent = false
	controller.allow_development_loading = true
	root.add_child(controller)
	await process_frame
	await process_frame
	check(controller.state.level_id == 12 and controller.object_nodes.size() == 4, "Scene builds first manifest stage including optional distraction")
	var old_object: PuzzleObject = controller.object_nodes["man"]
	check(not controller.object_nodes["bald_head"].visible, "Hidden state applied")
	check(controller.load_level_index(1), "Second stage loads")
	check(old_object.get_parent() == null, "Old objects detached immediately")
	await process_frame
	check(not is_instance_valid(old_object), "Old objects freed after stage replacement")
	check(controller.object_root.get_child_count() == 6 and controller.state.level_id == 24, "No stale objects after replacement")
	check(controller.object_nodes["ground_label"].text_label.text == "زمین", "TextObject presentation configured")
	check(controller.object_nodes["ground"].interactive, "DropZone defaults to interactive")
	for kind: String in PuzzleAppConfig.SCENE_PATHS:
		var packed := load(PuzzleAppConfig.SCENE_PATHS[kind]) as PackedScene
		var object := packed.instantiate() as PuzzleObject
		root.add_child(object)
		var definition: Dictionary = all["data"][0]["objects"][0].duplicate(true)
		definition["scene"] = kind
		if kind == "TextObject":
			definition["text"] = "آزمون فارسی"
		object.configure(definition, 0)
		check(object.object_id == "man", "Registry scene instantiates: " + kind)
		object.free()
	controller.free()

	var report := {"checks": checks, "failures": failures, "engine": Engine.get_version_info()["string"]}
	DirAccess.make_dir_recursive_absolute("res://test_outputs")
	var output := FileAccess.open("res://test_outputs/foundation.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("FOUNDATION: %d checks, %d failures" % [checks, failures.size()])
	for failure: String in failures:
		printerr(failure)
	quit(0 if failures.is_empty() else 1)

func rejected(data: Dictionary, field: String, description: String) -> void:
	var result := PuzzleValidator.new().validate_level(data, "negative-fixture.json")
	var found: bool = false
	for error: Dictionary in result["errors"]:
		if field in error["path"]:
			found = true
	check(not result["ok"] and found, description + ": " + str(result["errors"]))

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
