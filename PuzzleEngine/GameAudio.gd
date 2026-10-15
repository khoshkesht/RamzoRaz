extends Node

# One input listener covers menus, dialogs and puzzle scenes, including future ones.
const CLICK := preload("res://assets/sounds/ui_click.wav")
const TIMER_WARNING := preload("res://assets/sounds/timer_warning.wav")
var _click_player: AudioStreamPlayer
var _warning_player: AudioStreamPlayer

func _ready() -> void:
	_click_player = _make_player(CLICK, -12.0)
	_warning_player = _make_player(TIMER_WARNING, -6.0)

func _make_player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	return player

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_click_player.play()
	elif event is InputEventMouseButton:
		# A touch already sounded above; ignore its emulated mouse event.
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			_click_player.play()

func play_timer_warning() -> void:
	_warning_player.play()

func stop_timer_warning() -> void:
	_warning_player.stop()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_click_player.stop()
		_warning_player.stop()
