extends Control

const DISPLAY_SECONDS: float = 1.5
const APPLICATION_SCENE: String = "res://PuzzleEngine/Application.tscn"

var _elapsed: float = 0.0
var _backgrounded: bool = false

func _process(delta: float) -> void:
	if _backgrounded:
		return
	_elapsed += delta
	if _elapsed >= DISPLAY_SECONDS:
		set_process(false)
		var error := get_tree().change_scene_to_file(APPLICATION_SCENE)
		if error != OK:
			push_error("Could not open application after splash: %s" % error_string(error))

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_backgrounded = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_backgrounded = false
