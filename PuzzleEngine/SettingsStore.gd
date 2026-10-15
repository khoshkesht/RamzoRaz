class_name PuzzleSettingsStore
extends RefCounted

const BACKGROUNDS: Array[String] = ["res://assets/ui/bg1.png", "res://assets/ui/bg2.png", "res://assets/ui/bg3.png", "res://assets/ui/bg4.png"]
const UNLOCK_SCORES: Array[int] = [0, 825, 2800, 6300]

var path: String = "user://settings.json"
var persistent: bool = true
var fail_writes: bool = false
var data: Dictionary = {"settings_version": 1, "music_enabled": false, "background": 1}
var error: String = ""

func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 3:
		return false
	if not value.get("music_enabled") is bool:
		return false
	var version: Variant = value.get("settings_version")
	var background: Variant = value.get("background")
	return _integer(version) and version == 1 and _integer(background) and background >= 1 and background <= BACKGROUNDS.size()

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

func _read(candidate: String) -> Variant:
	if not FileAccess.file_exists(candidate):
		return null
	var parser := JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(candidate)) == OK else null

func open() -> bool:
	error = ""
	if not persistent or (not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".backup")):
		return true
	for candidate: String in [path, path + ".backup"]:
		var value: Variant = _read(candidate)
		if valid(value):
			data = value.duplicate(true)
			data["background"] = int(data["background"])
			return true
	error = "تنظیمات بازیابی نشد؛ انتخاب خود را دوباره ذخیره کنید."
	return false

static func unlocked(background: int, score: int) -> bool:
	return background >= 1 and background <= UNLOCK_SCORES.size() and score >= UNLOCK_SCORES[background - 1]

func effective_background(score: int) -> int:
	var selected := int(data["background"])
	return selected if unlocked(selected, score) else 1

func save(music_enabled: bool, background: int, score: int) -> bool:
	error = ""
	if not unlocked(background, score):
		error = "این تصویر هنوز باز نشده است."
		return false
	var next := {"settings_version": 1, "music_enabled": music_enabled, "background": background}
	if fail_writes:
		error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
		return false
	if persistent:
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file == null:
			error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
			return false
		file.store_string(JSON.stringify(next))
		file.flush()
		var write_error := file.get_error()
		file.close()
		if write_error != OK or not valid(_read(path + ".tmp")):
			error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
			return false
		# A broken primary must not overwrite a usable recovery copy.
		if valid(_read(path)):
			if DirAccess.copy_absolute(path, path + ".backup.tmp") != OK or DirAccess.rename_absolute(path + ".backup.tmp", path + ".backup") != OK:
				error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
				return false
		elif not valid(_read(path + ".backup")):
			if DirAccess.copy_absolute(path + ".tmp", path + ".backup.tmp") != OK or DirAccess.rename_absolute(path + ".backup.tmp", path + ".backup") != OK:
				error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
				return false
		if DirAccess.rename_absolute(path + ".tmp", path) != OK:
			error = "ذخیره انجام نشد؛ دوباره تلاش کنید."
			return false
	data = next
	return true
