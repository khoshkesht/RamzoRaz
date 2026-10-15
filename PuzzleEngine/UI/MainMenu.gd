class_name PuzzleMainMenu
extends Control

signal home_requested
signal exit_requested
signal settings_requested
signal guide_requested

@export var footer_clearance: float = 0.0
@onready var layout: Control = $SafeMargin/Layout
@onready var panel: Control = $SafeMargin/Layout/Panel
@onready var home_button: Button = $SafeMargin/Layout/Panel/Home
@onready var exit_button: Button = $SafeMargin/Layout/Panel/Exit
@onready var settings_button: Button = $SafeMargin/Layout/Panel/Settings
@onready var guide_button: Button = $SafeMargin/Layout/Panel/Guide
var persistent: bool = false

func _ready() -> void:
	home_button.pressed.connect(func() -> void: home_requested.emit())
	exit_button.pressed.connect(func() -> void: exit_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	guide_button.pressed.connect(func() -> void: guide_requested.emit())
	gui_input.connect(_on_backdrop_input)
	layout.resized.connect(_fit)
	resized.connect(_fit)
	_fit.call_deferred()

func show_home_menu() -> void:
	persistent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show()
	_fit.call_deferred()

func show_game_menu() -> void:
	persistent = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_fit.call_deferred()

func close_menu() -> void:
	if not persistent:
		hide()

func hide_menu() -> void:
	persistent = false
	hide()

func set_navigation_enabled(enabled: bool) -> void:
	home_button.disabled = not enabled
	exit_button.disabled = not enabled
	settings_button.disabled = not enabled
	guide_button.disabled = not enabled

func _fit() -> void:
	if layout.size.x <= 0 or layout.size.y <= 0:
		return
	var texture: Texture2D = $SafeMargin/Layout/Panel/Artwork.texture
	var width := minf(size.x * 0.9, layout.size.x)
	var height := width * texture.get_height() / texture.get_width()
	# Center in the game frame, then constrain the artwork to real safe insets.
	var center := get_global_rect().get_center().x - layout.get_global_rect().position.x
	center = clampf(center, width * 0.5, layout.size.x - width * 0.5)
	var shift := center - layout.size.x * 0.5
	var clearance := minf(footer_clearance, maxf(0.0, layout.size.y - height))
	panel.offset_left = shift - width * 0.5
	panel.offset_right = shift + width * 0.5
	panel.offset_top = -clearance - height
	panel.offset_bottom = -clearance

func _on_backdrop_input(event: InputEvent) -> void:
	if persistent:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		# Consume the entire click, including release, before hiding the blocker.
		if not event.pressed:
			close_menu()
	elif event is InputEventScreenTouch:
		accept_event()
		if not event.pressed:
			close_menu()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and not persistent and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu()
