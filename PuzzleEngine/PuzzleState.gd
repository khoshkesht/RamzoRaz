class_name PuzzleState
extends RefCounted

static var _next_run_id: int = 0
var run_id: int = 0
var level_id: int = 0
var variables: Dictionary = {}
var objects: Dictionary = {}
var consumed_rules: Dictionary = {}

func initialize(definition: Dictionary) -> void:
	_next_run_id += 1
	run_id = _next_run_id
	level_id = int(definition["id"])
	variables = definition.get("variables", {}).duplicate(true)
	objects.clear()
	consumed_rules.clear()
	for item: Dictionary in definition["objects"]:
		objects[item["id"]] = item.duplicate(true)

func object_snapshot(object_id: String) -> Dictionary:
	return objects.get(object_id, {}).duplicate(true)

func set_object_property(object_id: String, property_name: String, value: Variant) -> bool:
	if not objects.has(object_id):
		return false
	objects[object_id][property_name] = value.duplicate(true) if value is Dictionary or value is Array else value
	return true

func set_object_state(object_id: String, key: String, value: Variant) -> bool:
	if not objects.has(object_id) or not objects[object_id].get("state", {}) is Dictionary or not objects[object_id]["state"].has(key):
		return false
	objects[object_id]["state"][key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return true

func clear() -> void:
	variables.clear()
	objects.clear()
	consumed_rules.clear()
	level_id = 0

