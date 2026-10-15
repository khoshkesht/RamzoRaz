class_name PuzzleSettingsDialog
extends Control

signal save_requested(music_enabled: bool, background: int)
signal close_requested

const MUSIC_ON := preload("res://assets/ui/music_on.svg")
const MUSIC_OFF := preload("res://assets/ui/music_off.svg")
const LOCK_ICON := preload("res://assets/ui/background_lock.svg")
const BACKGROUND_NAMES: Array[String] = ["خانه آفتابی", "کارگاه ایرانی", "صبح آرام", "غروب تهران"]

var selected_background: int = 1
var music_enabled: bool = false
var total_score: int = 0
var background_buttons: Array[Button] = []
@onready var center: CenterContainer = $SafeMargin/Center
@onready var options: VBoxContainer = $SafeMargin/Center/Panel/Padding/Content/OptionsScroll/Options
@onready var grid: GridContainer = $SafeMargin/Center/Panel/Padding/Content/OptionsScroll/Options/Backgrounds
@onready var music_button: Button = $SafeMargin/Center/Panel/Padding/Content/OptionsScroll/Options/Music
@onready var message: Label = $SafeMargin/Center/Panel/Padding/Content/Message
@onready var save_button: Button = $SafeMargin/Center/Panel/Padding/Content/Buttons/Save
@onready var close_button: Button = $SafeMargin/Center/Panel/Padding/Content/Buttons/Close

func _ready() -> void:
	music_button.pressed.connect(func() -> void:
		music_enabled = not music_enabled
		_refresh()
	)
	save_button.pressed.connect(func() -> void: save_requested.emit(music_enabled, selected_background))
	close_button.pressed.connect(func() -> void: close_requested.emit())
	center.resized.connect(_fit_grid)
	for i in range(PuzzleSettingsStore.BACKGROUNDS.size()):
		var button := Button.new()
		button.name = "Background%d" % (i + 1)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(170, 150)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(button)
		background_buttons.append(button)
		var thumbnail := TextureRect.new()
		thumbnail.name = "Thumbnail"
		thumbnail.texture = load(PuzzleSettingsStore.BACKGROUNDS[i]) as Texture2D
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(thumbnail)
		thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		thumbnail.anchor_left = 0.06
		thumbnail.anchor_top = 0.04
		thumbnail.anchor_right = 0.94
		thumbnail.anchor_bottom = 0.74
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = LOCK_ICON
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(lock)
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock.anchor_left = 0.36
		lock.anchor_top = 0.18
		lock.anchor_right = 0.64
		lock.anchor_bottom = 0.64
		var caption := Label.new()
		caption.name = "Caption"
		caption.text = BACKGROUND_NAMES[i]
		caption.text_direction = Control.TEXT_DIRECTION_RTL
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 24)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption.anchor_top = 0.75
		button.pressed.connect(_select_background.bind(i + 1))
	_refresh()
	_fit_grid.call_deferred()

func _fit_grid() -> void:
	var available := center.size.x * 0.7 - 180.0
	grid.columns = 4 if available >= 728.0 else (2 if available >= 356.0 else 1)

func open(saved: Dictionary, score: int, warning: String = "") -> void:
	total_score = score
	music_enabled = bool(saved["music_enabled"])
	var selected := int(saved["background"])
	selected_background = selected if PuzzleSettingsStore.unlocked(selected, score) else 1
	message.text = warning
	message.tooltip_text = warning
	_refresh()
	$SafeMargin/Center/Panel/Padding/Content/OptionsScroll.scroll_vertical = 0
	show()
	_fit_grid.call_deferred()

func _select_background(background: int) -> void:
	if not PuzzleSettingsStore.unlocked(background, total_score):
		show_message("%s: نیازمند %s امتیاز" % [BACKGROUND_NAMES[background - 1], PuzzleHUD._persian(str(PuzzleSettingsStore.UNLOCK_SCORES[background - 1]))])
	else:
		selected_background = background
		show_message("")
	_refresh()

func show_message(text: String) -> void:
	message.text = text
	message.tooltip_text = text

func _refresh() -> void:
	music_button.text = "موسیقی: روشن" if music_enabled else "موسیقی: خاموش"
	music_button.icon = MUSIC_ON if music_enabled else MUSIC_OFF
	for i in range(background_buttons.size()):
		var button := background_buttons[i]
		var available := PuzzleSettingsStore.unlocked(i + 1, total_score)
		button.button_pressed = selected_background == i + 1
		(button.get_node("Caption") as Label).add_theme_color_override("font_color", button.get_theme_color("font_pressed_color" if button.button_pressed else "font_color"))
		(button.get_node("Thumbnail") as TextureRect).modulate.a = 1.0 if available else 0.35
		(button.get_node("Lock") as TextureRect).visible = not available

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()
