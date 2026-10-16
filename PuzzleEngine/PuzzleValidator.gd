class_name PuzzleValidator
extends RefCounted

const EVENTS := ["level_started", "tap", "hold", "swipe", "drag_start", "drag_end", "drop_on", "variable_changed"]
const OPERATORS := ["eq", "ne", "gt", "gte", "lt", "lte"]
const NUMERIC_OPERATORS := ["gt", "gte", "lt", "lte"]
const INTERACTIONS: Dictionary = {
	"tap": {"max_distance": 12.0, "max_duration": 0.30},
	"hold": {"max_distance": 12.0, "duration": 0.60},
	"drag": {"start_distance": 12.0, "axis": "both", "return_on_invalid": false},
	"drop_on": {},
	"swipe": {"min_distance": 80.0, "max_duration": 0.50, "direction": "any"},
}
var _errors: Array[Dictionary] = []
var _file: String = ""
var _level_id: int = 0
var _rule_id: String = ""
var _objects: Dictionary = {}
var _variables: Dictionary = {}

func validate_manifest(value: Variant, file_path: String = "") -> Dictionary:
	_begin(file_path)
	if not value is Dictionary:
		_error("$", "Manifest must be an object.")
		return _result({})
	var data: Dictionary = value
	_keys(data, ["schema_version", "manifest_version", "levels"], ["schema_version", "manifest_version", "levels"], "$")
	_version(data.get("schema_version"), "schema_version")
	_positive_integer(data.get("manifest_version"), "manifest_version")
	var levels: Variant = data.get("levels")
	if not levels is Array:
		_error("levels", "Expected an array.")
		return _result({})
	var ids: Dictionary = {}
	var paths: Dictionary = {}
	for i in range(levels.size()):
		var item: Variant = levels[i]
		var field := "levels[%d]" % i
		if not item is Dictionary:
			_error(field, "Expected a manifest entry object.")
			continue
		_keys(item, ["id", "path"], ["id", "path"], field)
		if _positive_integer(item.get("id"), field + ".id"):
			var id: int = int(item["id"])
			if ids.has(id):
				_error(field + ".id", "Duplicate level ID.")
			ids[id] = true
		var path: Variant = item.get("path")
		if _text(path, field + ".path"):
			if not path.begins_with("res://") or not path.ends_with(".json") or not FileAccess.file_exists(path):
				_error(field + ".path", "Expected an existing packaged JSON file.")
			if paths.has(path):
				_error(field + ".path", "Duplicate level path.")
			paths[path] = true
	return _result(data.duplicate(true))

func validate_level(value: Variant, file_path: String = "", expected_id: int = 0) -> Dictionary:
	_begin(file_path)
	if not value is Dictionary:
		_error("$", "Level must be an object.")
		return _result({})
	var data: Dictionary = value.duplicate(true)
	_keys(data, ["schema_version", "id", "question", "hint", "answer", "time_limit_seconds", "base_score", "background", "background_material", "objects", "variables", "counters", "rules", "win_condition", "success", "custom_handler"], ["schema_version", "id", "question", "hint", "answer", "time_limit_seconds", "base_score", "background", "objects", "rules", "win_condition"], "$")
	_version(data.get("schema_version"), "schema_version")
	if _positive_integer(data.get("id"), "id"):
		_level_id = int(data["id"])
		data["id"] = _level_id
		if expected_id > 0 and expected_id != _level_id:
			_error("id", "Level ID does not match its manifest entry.")
	_text(data.get("question"), "question")
	_text(data.get("hint"), "hint")
	_text(data.get("answer"), "answer")
	if _positive_integer(data.get("time_limit_seconds"), "time_limit_seconds"):
		var seconds := int(data["time_limit_seconds"])
		if seconds < 30 or seconds > 240 or seconds % 5 != 0:
			_error("time_limit_seconds", "Expected 30 to 240 whole seconds in steps of 5.")
		data["time_limit_seconds"] = seconds
	if _positive_integer(data.get("base_score"), "base_score"):
		var score := int(data["base_score"])
		if score < 50 or score > 250 or score % 5 != 0:
			_error("base_score", "Expected 50 to 250 base points in steps of 5.")
		data["base_score"] = score
	_resource(data.get("background"), "background", "Texture2D")
	if data.has("background_material"):
		_resource(data["background_material"], "background_material", "ShaderMaterial")
	var vars: Variant = data.get("variables", {})
	if _simple_dictionary(vars, "variables"):
		_variables = vars
	data["variables"] = _variables.duplicate(true)
	_validate_counters(data.get("counters", []))
	if not data.has("counters"):
		data["counters"] = []
	var objects: Variant = data.get("objects")
	if not objects is Array or objects.is_empty():
		_error("objects", "Expected at least one object.")
	else:
		for i in range(objects.size()):
			_validate_object(objects[i], "objects[%d]" % i)
		for i in range(objects.size()):
			if objects[i] is Dictionary and objects[i].get("accepted_sources") is Array:
				for j in range(objects[i]["accepted_sources"].size()):
					_reference(objects[i]["accepted_sources"][j], "objects[%d].accepted_sources[%d]" % [i, j])
	var rules: Variant = data.get("rules")
	if not rules is Array:
		_error("rules", "Expected an array.")
	else:
		var rule_ids: Dictionary = {}
		for i in range(rules.size()):
			_validate_rule(rules[i], "rules[%d]" % i, rule_ids)
	var handler: Variant = data.get("custom_handler")
	if data.has("custom_handler"):
		if _text(handler, "custom_handler"):
			if not handler.begins_with("res://PuzzleEngine/Custom/") or not ResourceLoader.exists(handler, "Script"):
				_error("custom_handler", "Expected a packaged Custom handler script.")
			else:
				var base := load(handler) as Script
				var handler_base := load("res://PuzzleEngine/PuzzleCustomHandler.gd") as Script
				while base != null and base != handler_base:
					base = base.get_base_script()
				if base == null:
					_error("custom_handler", "Handler must extend PuzzleCustomHandler.")
	if data.get("win_condition") == null:
		if not data.has("custom_handler"):
			_error("win_condition", "A null win condition requires a custom handler.")
	else:
		_validate_condition(data.get("win_condition"), "win_condition", "", true)
	if rules is Array and rules.is_empty() and not data.has("custom_handler"):
		_error("rules", "A data-driven stage requires at least one rule.")
	var success: Variant = data.get("success", {})
	if not success is Dictionary:
		_error("success", "Expected an object.")
	else:
		_keys(success, ["animation", "sound", "result_delay_seconds"], [], "success")
		var result_delay: Variant = success.get("result_delay_seconds", 1.0)
		if _number(result_delay, "success.result_delay_seconds") and (float(result_delay) < 0.0 or float(result_delay) > 5.0):
			_error("success.result_delay_seconds", "Expected a duration from zero to five seconds.")
		success["result_delay_seconds"] = result_delay
		if success.has("animation") and success["animation"] != "complete":
			_error("success.animation", "Unknown shared success animation.")
		if success.has("sound"):
			_resource(success["sound"], "success.sound", "AudioStream")
		if not success.has("animation"):
			success["animation"] = "complete"
		data["success"] = success
	if _errors.is_empty() and data.get("win_condition") != null and _initial_condition(data["win_condition"]):
		_error("win_condition", "Win condition is already satisfied in the initial state.")
	return _result(data)

func _validate_counters(raw: Variant) -> void:
	if not raw is Array:
		_error("counters", "Expected an array of HUD counters.")
		return
	var names: Dictionary = {}
	for i in range(raw.size()):
		var path := "counters[%d]" % i
		var counter: Variant = raw[i]
		if not counter is Dictionary:
			_error(path, "Expected a counter object.")
			continue
		_keys(counter, ["label", "variable", "target"], ["label", "variable", "target"], path)
		_text(counter.get("label"), path + ".label")
		var name: Variant = counter.get("variable")
		if not name is String or not _variables.has(name):
			_error(path + ".variable", "Counter must reference a declared variable.")
		else:
			if names.has(name):
				_error(path + ".variable", "Duplicate counter variable.")
			names[name] = true
			var value: Variant = _variables[name]
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0 or float(value) != floor(float(value)):
				_error(path + ".variable", "Counter initial value must be a nonnegative integer.")
		_positive_integer(counter.get("target"), path + ".target")

func _validate_object(raw: Variant, path: String) -> void:
	if not raw is Dictionary:
		_error(path, "Expected an object definition.")
		return
	var item: Dictionary = raw
	_keys(item, ["id", "scene", "position", "sprite", "text", "text_color", "tint", "visible", "interactive", "rotation_degrees", "scale", "z_index", "hit_size", "state", "interactions", "accepted_sources"], ["id", "scene", "position"], path)
	if _text(item.get("id"), path + ".id"):
		var object_id: String = item["id"]
		if object_id == "$level" or object_id.validate_node_name() != object_id:
			_error(path + ".id", "Invalid or reserved object ID.")
		if _objects.has(object_id):
			_error(path + ".id", "Duplicate object ID.")
		_objects[object_id] = item
	var kind: Variant = item.get("scene")
	if not kind is String or not PuzzleAppConfig.SCENE_PATHS.has(kind):
		_error(path + ".scene", "Unknown object scene type.")
	_vector(item.get("position"), path + ".position")
	if kind == "TextObject":
		_text(item.get("text"), path + ".text")
	elif kind != "DropZone":
		_resource(item.get("sprite"), path + ".sprite", "Texture2D")
	if kind in ["DropZone", "TextObject"] and item.has("sprite"):
		_resource(item["sprite"], path + ".sprite", "Texture2D")
	if item.has("text_color"):
		var color_pattern := RegEx.new()
		color_pattern.compile("^#[0-9a-fA-F]{6}$")
		if kind != "TextObject" or not item["text_color"] is String or color_pattern.search(item["text_color"]) == null:
			_error(path + ".text_color", "Expected an opaque #RRGGBB color on a TextObject.")
	if item.has("tint"):
		var tint_pattern := RegEx.new()
		tint_pattern.compile("^#[0-9a-fA-F]{6}$")
		if not item["tint"] is String or tint_pattern.search(item["tint"])==null:
			_error(path + ".tint", "Expected an opaque #RRGGBB instance tint.")
	for field: String in ["visible", "interactive"]:
		if item.has(field) and not item[field] is bool:
			_error(path + "." + field, "Expected a boolean.")
	if not item.has("visible"):
		item["visible"] = true
	if item.has("rotation_degrees"):
		_number(item["rotation_degrees"], path + ".rotation_degrees")
	else:
		item["rotation_degrees"] = 0.0
	if item.has("scale"):
		_vector(item["scale"], path + ".scale", true)
	else:
		item["scale"] = [1.0, 1.0]
	if item.has("z_index"):
		if not _integer(item["z_index"]) or abs(float(item["z_index"])) > 4096:
			_error(path + ".z_index", "Expected an integer in Godot's canvas Z range.")
	else:
		item["z_index"] = 0
	if item.has("hit_size"):
		_vector(item["hit_size"], path + ".hit_size", true)
	if item.has("accepted_sources"):
		if kind != "DropZone" or not item["accepted_sources"] is Array:
			_error(path + ".accepted_sources", "Only DropZone supports an array of accepted source IDs.")
	if not item.has("state"):
		item["state"] = {}
	_simple_dictionary(item["state"], path + ".state")
	var inputs: Variant = item.get("interactions", [])
	var normalized: Array[Dictionary] = []
	var types: Array[String] = []
	if not inputs is Array:
		_error(path + ".interactions", "Expected an array.")
	else:
		for i in range(inputs.size()):
			var input_path := path + ".interactions[%d]" % i
			var input: Variant = {"type": inputs[i]} if inputs[i] is String else inputs[i]
			if not input is Dictionary or not input.get("type") is String or not INTERACTIONS.has(input.get("type")):
				_error(input_path, "Unknown interaction type.")
				continue
			var type: String = input["type"]
			if types.has(type):
				_error(input_path, "Duplicate interaction type.")
			types.append(type)
			var defaults: Dictionary = INTERACTIONS[type].duplicate(true)
			var allowed: Array = defaults.keys() + ["type"]
			if type == "drag":
				allowed.append("bounds")
			_keys(input, allowed, ["type"], input_path)
			for key: String in defaults:
				var value: Variant = input.get(key, defaults[key])
				if defaults[key] is float:
					_positive_number(value, input_path + "." + key)
				elif defaults[key] is bool and not value is bool:
					_error(input_path + "." + key, "Expected a boolean.")
				defaults[key] = value
			if type == "drag" and defaults["axis"] not in ["x", "y", "both"]:
				_error(input_path + ".axis", "Expected x, y or both.")
			if type == "swipe" and defaults["direction"] not in ["left", "right", "up", "down", "any"]:
				_error(input_path + ".direction", "Unknown swipe direction.")
			if input.has("bounds"):
				var bounds: Variant = input["bounds"]
				if not bounds is Array or bounds.size() != 4:
					_error(input_path + ".bounds", "Expected [x,y,width,height].")
				else:
					_vector(bounds.slice(0, 2), input_path + ".bounds.position")
					_vector(bounds.slice(2, 4), input_path + ".bounds.size", true)
				defaults["bounds"] = bounds
			defaults["type"] = type
			normalized.append(defaults)
	item["interactions"] = normalized
	if types.has("drag") and types.has("swipe"):
		_error(path + ".interactions", "Drag and Swipe cannot share an object in schema 1.")
	if types.has("drop_on") and not types.has("drag"):
		_error(path + ".interactions", "DropOn requires Drag on the source.")
	if not item.has("interactive"):
		item["interactive"] = not normalized.is_empty() or kind == "DropZone"
	if not item.has("hit_size") and (kind == "DropZone" or (kind == "TextObject" and item["interactive"] == true)):
		_error(path + ".hit_size", "This object requires an explicit hit size.")

func _validate_rule(raw: Variant, path: String, ids: Dictionary) -> void:
	if not raw is Dictionary:
		_error(path, "Expected a rule object.")
		return
	var rule: Dictionary = raw
	_keys(rule, ["id", "event", "source", "target", "conditions", "actions", "once"], ["id", "event", "actions"], path)
	_rule_id = rule.get("id", "") if rule.get("id") is String else ""
	if _text(rule.get("id"), path + ".id"):
		if ids.has(rule["id"]):
			_error(path + ".id", "Duplicate rule ID.")
		ids[rule["id"]] = true
	var event: Variant = rule.get("event")
	var event_name: String = event if event is String else ""
	if event_name not in EVENTS and not (event_name.begins_with("custom:") and event_name.length() > 7):
		_error(path + ".event", "Unknown event type.")
	if rule.has("source"):
		if rule["source"] != "$level":
			_reference(rule["source"], path + ".source")
		elif event_name not in ["level_started", "variable_changed"]:
			_error(path + ".source", "This event requires an object source.")
		if event_name in ["level_started", "variable_changed"] and rule["source"] != "$level":
			_error(path + ".source", "This event uses $level as source.")
		elif _objects.has(rule.get("source")) and event_name in ["tap", "hold", "swipe", "drag_start", "drag_end", "drop_on"]:
			var needed := "drag" if event_name in ["drag_start", "drag_end"] else event_name
			var source: Dictionary = _objects[rule["source"]]
			if not _has_interaction(source, needed):
				_error(path + ".source", "Source does not declare the required interaction.")
	if rule.has("target"):
		_reference(rule["target"], path + ".target")
		if event_name == "drop_on" and _objects.has(rule["target"]) and _objects[rule["target"]].get("scene") != "DropZone":
			_error(path + ".target", "Drop target must be a DropZone.")
	if rule.has("once") and not rule["once"] is bool:
		_error(path + ".once", "Expected a boolean.")
	if not rule.has("once"):
		rule["once"] = true
	var conditions: Variant = rule.get("conditions", [])
	if not conditions is Array:
		_error(path + ".conditions", "Expected an array.")
	else:
		for i in range(conditions.size()):
			_validate_condition(conditions[i], path + ".conditions[%d]" % i, event_name)
	rule["conditions"] = conditions
	var actions: Variant = rule.get("actions")
	if not actions is Array or actions.is_empty():
		_error(path + ".actions", "Expected at least one action.")
	else:
		for i in range(actions.size()):
			_validate_action(actions[i], path + ".actions[%d]" % i)
	_rule_id = ""

func _validate_condition(raw: Variant, path: String, event: String, is_win: bool = false, depth: int = 0) -> void:
	if depth > 8:
		_error(path, "Condition nesting exceeds eight levels.")
		return
	if not raw is Dictionary or not raw.get("type") is String:
		_error(path, "Expected a typed condition object.")
		return
	var item: Dictionary = raw
	var type: String = item["type"]
	match type:
		"all", "any":
			_keys(item, ["type", "conditions"], ["conditions"], path)
			var children: Variant = item.get("conditions")
			if not children is Array or children.is_empty():
				_error(path + ".conditions", "Expected a nonempty condition array.")
			else:
				for i in range(children.size()):
					_validate_condition(children[i], path + ".conditions[%d]" % i, event, is_win, depth + 1)
		"not":
			_keys(item, ["type", "condition"], ["condition"], path)
			_validate_condition(item.get("condition"), path + ".condition", event, is_win, depth + 1)
		"visible":
			_keys(item, ["type", "target"], ["target"], path)
			_reference(item.get("target"), path + ".target")
		"inside":
			_keys(item, ["type", "target", "zone"], ["target", "zone"], path)
			_reference(item.get("target"), path + ".target")
			if _reference(item.get("zone"), path + ".zone") and _objects[item["zone"]].get("scene") != "DropZone":
				_error(path + ".zone", "Inside requires a DropZone.")
		"variable", "object_state", "event_value":
			var allowed: Array = ["type", "operator", "value"]
			var source_value: Variant = null
			if type == "variable":
				allowed.append("name")
				if not item.get("name") is String or not _variables.has(item.get("name")):
					_error(path + ".name", "Unknown variable.")
				else:
					source_value = _variables[item["name"]]
			elif type == "object_state":
				allowed.append_array(["target", "key"])
				if _reference(item.get("target"), path + ".target"):
					var states: Variant = _objects[item["target"]].get("state", {})
					if not states is Dictionary or not item.get("key") is String or not states.has(item.get("key")):
						_error(path + ".key", "Unknown state key.")
					else:
						source_value = states[item["key"]]
			else:
				allowed.append("field")
				if is_win:
					_error(path, "Win conditions cannot depend on event payload.")
				_text(item.get("field"), path + ".field")
			_keys(item, allowed, allowed, path)
			_comparison(item, path, source_value)
		"moved_distance_at_least":
			_keys(item, ["type", "value"], ["value"], path)
			if is_win or event not in ["drag_start", "drag_end", "drop_on", "swipe"]:
				_error(path, "Distance requires a movement event and cannot be a win condition.")
			_positive_number(item.get("value"), path + ".value")
		_:
			_error(path + ".type", "Unknown condition type.")

func _validate_action(raw: Variant, path: String) -> void:
	if not raw is Dictionary or not raw.get("type") is String:
		_error(path, "Expected a typed action object.")
		return
	var item: Dictionary = raw
	var type: String = item["type"]
	var allowed: Array = ["type"]
	var required: Array = ["type"]
	var needs_target := type in ["show", "hide", "move", "rotate", "scale", "replace_sprite", "play_animation", "shake", "set_state", "set_text", "set_lines"]
	if needs_target:
		allowed.append("target")
		required.append("target")
		_reference(item.get("target"), path + ".target")
	if type in ["move", "rotate", "scale", "play_animation", "play_sound", "shake"]:
		allowed.append("wait")
		if item.has("wait") and not item["wait"] is bool:
			_error(path + ".wait", "Expected a boolean.")
		if not item.has("wait"):
			item["wait"] = type != "play_sound"
	if type in ["move", "rotate", "scale", "shake"]:
		allowed.append("duration")
		var duration: Variant = item.get("duration", 0.2 if type == "shake" else 0.0)
		if _number(duration, path + ".duration") and float(duration) < 0:
			_error(path + ".duration", "Duration cannot be negative.")
		item["duration"] = duration
	if type in ["play_animation", "play_sound"]:
		allowed.append("timeout_seconds")
		_positive_number(item.get("timeout_seconds", 30.0), path + ".timeout_seconds")
		if not item.has("timeout_seconds"):
			item["timeout_seconds"] = 30.0
	match type:
		"set_lines":
			allowed.append_array(["segments", "color"])
			required.append("segments")
			var segments: Variant = item.get("segments")
			if not segments is Array or segments.size()>64:
				_error(path + ".segments", "Expected at most 64 line segments.")
			else:
				for i in range(segments.size()):
					if not segments[i] is Array or segments[i].size()!=2:
						_error(path + ".segments[%d]"%i, "A segment needs two points.")
					else:
						_vector(segments[i][0],path + ".segments[%d][0]"%i)
						_vector(segments[i][1],path + ".segments[%d][1]"%i)
			var color_pattern := RegEx.new()
			color_pattern.compile("^#[0-9a-fA-F]{6}$")
			if item.has("color") and (not item["color"] is String or color_pattern.search(item["color"])==null):
				_error(path + ".color", "Expected #RRGGBB.")
		"show", "hide", "complete_level", "fail_level":
			pass
		"move":
			allowed.append("position")
			required.append("position")
			_vector(item.get("position"), path + ".position")
		"rotate":
			allowed.append("degrees")
			required.append("degrees")
			_number(item.get("degrees"), path + ".degrees")
		"scale":
			allowed.append("value")
			required.append("value")
			_vector(item.get("value"), path + ".value", true)
		"set_text":
			allowed.append("text")
			required.append("text")
			_text(item.get("text"), path + ".text")
			if _objects.has(item.get("target")) and _objects[item["target"]].get("scene") != "TextObject":
				_error(path + ".target", "Expected a TextObject.")
		"replace_sprite":
			allowed.append("sprite")
			required.append("sprite")
			_resource(item.get("sprite"), path + ".sprite", "Texture2D")
		"play_animation":
			allowed.append("animation")
			required.append("animation")
			if _text(item.get("animation"), path + ".animation") and _objects.has(item.get("target")):
				_validate_animation(item, path)
		"play_sound":
			allowed.append("sound")
			required.append("sound")
			_resource(item.get("sound"), path + ".sound", "AudioStream")
		"shake":
			allowed.append("amplitude")
			_positive_number(item.get("amplitude", 8.0), path + ".amplitude")
			if not item.has("amplitude"):
				item["amplitude"] = 8.0
		"set_variable":
			allowed.append_array(["name", "operation", "value"])
			required.append_array(["name", "operation", "value"])
			if not item.get("name") is String or not _variables.has(item.get("name")):
				_error(path + ".name", "Unknown variable.")
			elif item.get("operation") == "increment":
				_number(_variables[item["name"]], path + ".name")
				_number(item.get("value"), path + ".value")
			if item.get("operation") not in ["assign", "increment"]:
				_error(path + ".operation", "Expected assign or increment.")
			_simple_value(item.get("value"), path + ".value")
		"set_state":
			allowed.append_array(["key", "value"])
			required.append_array(["key", "value"])
			if _objects.has(item.get("target")):
				var states: Variant = _objects[item["target"]].get("state", {})
				if not states is Dictionary or not item.get("key") is String or not states.has(item.get("key")):
					_error(path + ".key", "State key must exist initially.")
			_simple_value(item.get("value"), path + ".value")
		_:
			_error(path + ".type", "Unknown action type.")
	_keys(item, allowed, required, path)

func _validate_animation(action: Dictionary, path: String) -> void:
	var object: Dictionary = _objects[action["target"]]
	if not PuzzleAppConfig.SCENE_PATHS.has(object.get("scene")):
		return
	var packed := load(PuzzleAppConfig.SCENE_PATHS[object["scene"]]) as PackedScene
	if packed == null:
		_error(path + ".animation", "Cannot inspect object scene animations.")
		return
	var instance := packed.instantiate()
	var player := instance.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null or not player.has_animation(action["animation"]):
		_error(path + ".animation", "Animation does not exist in the object scene.")
	elif action.get("wait", true) and player.get_animation(action["animation"]).loop_mode != Animation.LOOP_NONE:
		_error(path + ".wait", "Cannot wait for a looping animation.")
	instance.free()

func _initial_condition(item: Dictionary) -> bool:
	match item["type"]:
		"visible":
			return _objects[item["target"]]["visible"]
		"all", "any":
			var all_value: bool = item["type"] == "all"
			for child: Dictionary in item["conditions"]:
				var result := _initial_condition(child)
				if item["type"] == "all" and not result:
					return false
				if item["type"] == "any" and result:
					return true
			return all_value
		"not":
			return not _initial_condition(item["condition"])
		"variable":
			return _compare(_variables[item["name"]], item["operator"], item["value"])
		"object_state":
			return _compare(_objects[item["target"]]["state"][item["key"]], item["operator"], item["value"])
		"inside":
			var source: Dictionary = _objects[item["target"]]
			var zone: Dictionary = _objects[item["zone"]]
			var point := Vector2(source["position"][0], source["position"][1])
			var transform := Transform2D(deg_to_rad(float(zone["rotation_degrees"])), Vector2(zone["position"][0], zone["position"][1]))
			transform = transform.scaled_local(Vector2(zone["scale"][0], zone["scale"][1]))
			var size := Vector2(zone["hit_size"][0], zone["hit_size"][1])
			return Rect2(-size * 0.5, size).has_point(transform.affine_inverse() * point)
	return false

static func _compare(left: Variant, op: String, right: Variant) -> bool:
	match op:
		"eq": return left == right
		"ne": return left != right
		"gt": return left > right
		"gte": return left >= right
		"lt": return left < right
		"lte": return left <= right
	return false

func _comparison(item: Dictionary, path: String, source: Variant) -> void:
	var op: Variant = item.get("operator")
	if op not in OPERATORS:
		_error(path + ".operator", "Unknown comparison operator.")
	var value: Variant = item.get("value")
	_simple_value(value, path + ".value")
	if op in NUMERIC_OPERATORS:
		_number(value, path + ".value")
		if source != null:
			_number(source, path)
	elif source != null and not ((_is_number(source) and _is_number(value)) or typeof(source) == typeof(value)):
		_error(path + ".value", "Equality requires values of the same logical type.")

func _has_interaction(item: Dictionary, type: String) -> bool:
	for interaction: Variant in item.get("interactions", []):
		if interaction is Dictionary and interaction.get("type") == type:
			return true
	return false

func _begin(path: String) -> void:
	_errors.clear()
	_objects.clear()
	_variables.clear()
	_file = path
	_level_id = 0
	_rule_id = ""

func _result(data: Dictionary) -> Dictionary:
	return {"ok": _errors.is_empty(), "data": data if _errors.is_empty() else {}, "errors": _errors.duplicate(true)}

func _error(path: String, message: String) -> void:
	_errors.append({"file": _file, "level_id": _level_id, "rule_id": _rule_id, "path": path, "message": message})

func _keys(data: Dictionary, allowed: Array, required: Array, path: String) -> void:
	for key: Variant in data:
		if key not in allowed:
			_error(path + "." + str(key), "Unknown field.")
	for key: String in required:
		if not data.has(key):
			_error(path + "." + key, "Required field is missing.")

func _version(value: Variant, path: String) -> void:
	if not _integer(value) or int(value) != PuzzleAppConfig.SCHEMA_VERSION:
		_error(path, "Unsupported schema version; expected 1.")

static func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _is_number(value) and floor(float(value)) == float(value)

func _number(value: Variant, path: String) -> bool:
	if not _is_number(value):
		_error(path, "Expected a finite number.")
		return false
	return true

func _positive_number(value: Variant, path: String) -> bool:
	if not _is_number(value) or float(value) <= 0:
		_error(path, "Expected a finite positive number.")
		return false
	return true

func _positive_integer(value: Variant, path: String) -> bool:
	if not _integer(value) or float(value) <= 0:
		_error(path, "Expected a positive integer.")
		return false
	return true

func _text(value: Variant, path: String) -> bool:
	if not value is String or value.strip_edges().is_empty():
		_error(path, "Expected a nonempty string.")
		return false
	return true

func _vector(value: Variant, path: String, positive: bool = false) -> bool:
	if not value is Array or value.size() != 2:
		_error(path, "Expected a two-number array.")
		return false
	var valid: bool = true
	for i in range(2):
		if not (_positive_number(value[i], "%s[%d]" % [path, i]) if positive else _number(value[i], "%s[%d]" % [path, i])):
			valid = false
	return valid

func _resource(value: Variant, path: String, type: String) -> bool:
	if not _text(value, path):
		return false
	if not value.begins_with("res://") or not ResourceLoader.exists(value, type):
		_error(path, "Expected an existing packaged %s resource." % type)
		return false
	var resource: Resource = ResourceLoader.load(value)
	if resource == null or not resource.is_class(type):
		_error(path, "Resource has the wrong type; expected %s." % type)
		return false
	return true

func _reference(value: Variant, path: String) -> bool:
	if not value is String or not _objects.has(value):
		_error(path, "Unknown object reference.")
		return false
	return true

func _simple_value(value: Variant, path: String) -> bool:
	if value is bool or value is String or _is_number(value):
		return true
	_error(path, "Expected a number, boolean or string.")
	return false

func _simple_dictionary(value: Variant, path: String) -> bool:
	if not value is Dictionary:
		_error(path, "Expected a dictionary of simple values.")
		return false
	var valid: bool = true
	for key: Variant in value:
		if not _text(key, path + ".key") or not _simple_value(value[key], path + "." + str(key)):
			valid = false
	return valid
