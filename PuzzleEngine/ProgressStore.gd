class_name PuzzleProgressStore
extends RefCounted

var path: String = "user://progress.json"
var persistent: bool = true
var data: Dictionary = {}
var error: String = ""
var manifest: Dictionary = {}
var fail_writes: bool = false # Fault injection for isolated checks.

func open(content: Dictionary) -> bool:
	manifest = content.duplicate(true)
	error = ""
	# No playable content: leave any previous progress files untouched.
	if manifest["levels"].is_empty():
		data = {"save_version": 1, "manifest_version": manifest["manifest_version"], "current_level_id": null, "pending_result_level_id": null, "unlocked_hints": [], "results": {}}
		return true
	if not persistent or (not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".backup")):
		data = {"save_version": 1, "manifest_version": manifest["manifest_version"], "current_level_id": manifest["levels"][0]["id"], "pending_result_level_id": null, "unlocked_hints": [], "results": {}}
		return true
	for candidate: String in [path, path + ".backup"]:
		var parsed: Variant = _read(candidate)
		if valid(parsed):
			data = parsed
			for i in range(data["unlocked_hints"].size()):
				data["unlocked_hints"][i] = int(data["unlocked_hints"][i])
			for result: Dictionary in data["results"].values():
				for field: String in ["level_id", "score", "stars"]:
					result[field] = int(result[field])
			return true
	# Preserve known main catalogs when stages are appended.
	for candidate: String in [path, path + ".backup"]:
		var expanded := _migrate_main_progress(_read(candidate))
		if not expanded.is_empty():
			if not _archive_sample_files(".pre-expanded-content"):
				return false
			return commit(expanded) and commit(expanded)
	# The user chose to carry sample progress into the main stages.
	for candidate: String in [path, path + ".backup"]:
		var migrated := _migrate_sample_progress(_read(candidate))
		if not migrated.is_empty():
			if not _archive_sample_files():
				return false
			# Populate both the primary and recovery copy with the new ID scheme.
			return commit(migrated) and commit(migrated)
	error = "No valid progress file or backup; original files preserved."
	return false

func _migrate_sample_progress(value: Variant) -> Dictionary:
	if _is_expanded_main_catalog():
		var original := PuzzleProgressStore.new()
		original.manifest = {"manifest_version": 3, "levels": [{"id": 1}, {"id": 2}]}
		var mapped := original._migrate_sample_progress(value)
		return _migrate_main_progress(mapped) if not mapped.is_empty() else {}
	if manifest.get("manifest_version") != 3 or manifest.get("levels", []).size() != 2 or manifest["levels"][0]["id"] != 1 or manifest["levels"][1]["id"] != 2:
		return {}
	var previous := PuzzleProgressStore.new()
	previous.manifest = {"manifest_version": 1, "levels": [{"id": 12}, {"id": 24}]}
	if not previous.valid(value):
		return {}
	var mapping := {12: 1, 24: 2}
	var next: Dictionary = value.duplicate(true)
	next["manifest_version"] = 3
	for field: String in ["current_level_id", "pending_result_level_id"]:
		if next[field] != null:
			next[field] = mapping[int(next[field])]
	for i in range(next["unlocked_hints"].size()):
		next["unlocked_hints"][i] = mapping[int(next["unlocked_hints"][i])]
	var migrated_results: Dictionary = {}
	for result: Dictionary in next["results"].values():
		var migrated_id: int = mapping[int(result["level_id"])]
		result["level_id"] = migrated_id
		result["score"] = int(result["score"])
		result["stars"] = int(result["stars"])
		migrated_results[str(migrated_id)] = result
	next["results"] = migrated_results
	return next if valid(next) else {}

func _is_expanded_main_catalog() -> bool:
	var count := 5 if manifest.get("manifest_version") == 4 else 10 if manifest.get("manifest_version") == 5 else 20 if manifest.get("manifest_version") == 6 else 30 if manifest.get("manifest_version") == 7 else 0
	if count == 0 or manifest.get("levels", []).size() != count:
		return false
	for i in range(count):
		if manifest["levels"][i]["id"] != i + 1:
			return false
	return true

func _migrate_main_progress(value: Variant) -> Dictionary:
	if not _is_expanded_main_catalog():
		return {}
	if not value is Dictionary:
		return {}
	var old_version: Variant = value.get("manifest_version")
	var old_count := 2 if old_version == 3 else 5 if old_version == 4 else 10 if old_version == 5 else 20 if old_version == 6 else 0
	if old_count == 0 or old_version >= manifest["manifest_version"]:
		return {}
	var previous := PuzzleProgressStore.new()
	var entries: Array[Dictionary] = []
	for i in range(old_count):
		entries.append({"id": i + 1})
	previous.manifest = {"manifest_version": old_version, "levels": entries}
	if not previous.valid(value):
		return {}
	var next: Dictionary = value.duplicate(true)
	next["manifest_version"] = manifest["manifest_version"]
	# Pending results stay pending; finished catalogs resume at the first new stage.
	if next["current_level_id"] == null:
		next["current_level_id"] = old_count + 1
	return next if valid(next) else {}

func _archive_sample_files(archive_suffix: String = ".pre-main-content") -> bool:
	for candidate: String in [path, path + ".backup"]:
		if not FileAccess.file_exists(candidate):
			continue
		var archive := candidate + archive_suffix
		var suffix := 1
		while FileAccess.file_exists(archive):
			if FileAccess.get_file_as_string(archive) == FileAccess.get_file_as_string(candidate):
				break
			archive = candidate + archive_suffix + ".%d" % suffix
			suffix += 1
		if not FileAccess.file_exists(archive) and DirAccess.copy_absolute(candidate, archive) != OK:
			error = "Cannot preserve previous progress before migration."
			return false
	return true

func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 6:
		return false
	for field: String in ["save_version", "manifest_version", "current_level_id", "pending_result_level_id", "unlocked_hints", "results"]:
		if not value.has(field):
			return false
	if not _integer(value.get("save_version")) or not _integer(value.get("manifest_version")) or value.get("save_version") != 1 or value.get("manifest_version") != manifest["manifest_version"]:
		return false
	if not value.get("results") is Dictionary or not value.get("unlocked_hints") is Array:
		return false
	var ids: Array = []
	for entry: Dictionary in manifest["levels"]:
		ids.append(int(entry["id"]))
	var hints: Array = value["unlocked_hints"]
	var normalized_hints: Array[int] = []
	for id: Variant in hints:
		if not _integer(id) or int(id) not in ids or int(id) in normalized_hints:
			return false
		normalized_hints.append(int(id))
	var saved: Dictionary = value["results"]
	if saved.size() > ids.size():
		return false
	for key: Variant in saved:
		var result: Variant = saved[key]
		if not result is Dictionary or result.size() != 5 or not _integer(result.get("level_id")) or str(int(result["level_id"])) != key or int(result["level_id"]) not in ids:
			return false
		for field: String in ["score", "stars", "elapsed_seconds"]:
			if not result.get(field) is float and not result.get(field) is int:
				return false
			if not is_finite(float(result[field])) or result[field] < 0:
				return false
		if result["score"] != floor(float(result["score"])) or not _integer(result["stars"]) or int(result["stars"]) not in [1, 2, 3] or not result.get("hint_received") is bool:
			return false
		if result["hint_received"] != (int(result["level_id"]) in normalized_hints):
			return false
	var current: Variant = value.get("current_level_id")
	var pending: Variant = value.get("pending_result_level_id")
	if current != null and (not _integer(current) or int(current) not in ids):
		return false
	if pending != null and (not _integer(pending) or pending != current or not saved.has(str(int(pending)))):
		return false
	var completed_count := saved.size()
	if pending != null:
		completed_count -= 1
	if completed_count < 0 or completed_count > ids.size():
		return false
	for i in range(saved.size()):
		if not saved.has(str(ids[i])):
			return false
	return current == (ids[completed_count] if completed_count < ids.size() else null)

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

func _read(candidate: String) -> Variant:
	if not FileAccess.file_exists(candidate):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(candidate)) != OK:
		return null
	return parser.data

func commit(next: Dictionary) -> bool:
	error = ""
	if not valid(next) or fail_writes:
		error = "Progress validation or write failed."
		return false
	if persistent:
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file == null:
			error = "Cannot open temporary save."
			return false
		file.store_string(JSON.stringify(next))
		file.flush()
		var write_error := file.get_error()
		file.close()
		if write_error != OK or not valid(_read(path + ".tmp")):
			error = "Temporary save failed validation."
			return false
		# Back up only a valid primary; a corrupt primary must not destroy recovery.
		if FileAccess.file_exists(path) and valid(_read(path)):
			if DirAccess.copy_absolute(path, path + ".backup.tmp") != OK or DirAccess.rename_absolute(path + ".backup.tmp", path + ".backup") != OK:
				error = "Cannot preserve backup."
				return false
		if DirAccess.rename_absolute(path + ".tmp", path) != OK:
			error = "Cannot replace progress file."
			return false
	data = next.duplicate(true)
	return true

func hint_unlocked(level_id: int) -> bool:
	return level_id in data.get("unlocked_hints", [])

func reset_progress() -> bool:
	if manifest.get("levels", []).is_empty():
		error = "Cannot reset without a valid manifest."
		return false
	var fresh := {"save_version": 1, "manifest_version": manifest["manifest_version"], "current_level_id": manifest["levels"][0]["id"], "pending_result_level_id": null, "unlocked_hints": [], "results": {}}
	# The second atomic commit replaces the old backup with fresh progress too.
	# A reset is complete only once recovery cannot resurrect previous results.
	return commit(fresh) and commit(fresh)

func save_hint(level_id: int) -> bool:
	var next := data.duplicate(true)
	if level_id not in next["unlocked_hints"]:
		next["unlocked_hints"].append(level_id)
	if next["results"].has(str(level_id)):
		next["results"][str(level_id)]["hint_received"] = true
	return commit(next)

func save_result(result: Dictionary) -> bool:
	var next := data.duplicate(true)
	var id := int(result["level_id"])
	if next["results"].has(str(id)):
		return true
	next["results"][str(id)] = result.duplicate(true)
	next["pending_result_level_id"] = id
	return commit(next)

func advance() -> bool:
	var next := data.duplicate(true)
	if next["pending_result_level_id"] == null:
		return false
	var index: int = next["results"].size()
	next["pending_result_level_id"] = null
	next["current_level_id"] = manifest["levels"][index]["id"] if index < manifest["levels"].size() else null
	return commit(next)
