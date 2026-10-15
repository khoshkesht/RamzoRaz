class_name PuzzleLoader
extends RefCounted

var validator := PuzzleValidator.new()
var manifest_path: String

func _init(content_path: String = PuzzleAppConfig.MANIFEST_PATH) -> void:
	manifest_path = content_path

func load_manifest(path: String = "") -> Dictionary:
	if path.is_empty():
		path = manifest_path
	var result := read_json(path)
	if not result["ok"]:
		return result
	return validator.validate_manifest(result["data"], path)

func load_level(entry: Dictionary) -> Dictionary:
	var path: String = entry.get("path", "")
	var result := read_json(path)
	if not result["ok"]:
		return result
	return validator.validate_level(result["data"], path, int(entry.get("id", 0)))

func validate_all() -> Dictionary:
	var manifest := load_manifest()
	if not manifest["ok"]:
		return manifest
	var errors: Array = []
	var definitions: Array = []
	for entry: Dictionary in manifest["data"]["levels"]:
		var result := load_level(entry)
		if result["ok"]:
			definitions.append(result["data"])
		else:
			errors.append_array(result["errors"])
	return {"ok": errors.is_empty(), "data": definitions if errors.is_empty() else [], "errors": errors}

static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(path, "$", "Cannot read JSON file (%s)." % error_string(FileAccess.get_open_error()))
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return _failure(path, "line:%d" % parser.get_error_line(), parser.get_error_message())
	return {"ok": true, "data": parser.data, "errors": []}

static func _failure(path: String, field: String, message: String) -> Dictionary:
	return {"ok": false, "data": {}, "errors": [{"file": path, "level_id": 0, "rule_id": "", "path": field, "message": message}]}
