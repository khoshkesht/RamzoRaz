class_name PuzzleDevelopmentTools
extends Control

signal test_requested(index: int)
signal reset_requested

@onready var launcher: Button = $LauncherMargin/Layout/Row/Open
@onready var dialog: Control = $Dialog
@onready var center: CenterContainer = $Dialog/SafeMargin/Center
@onready var scroll: ScrollContainer = $Dialog/SafeMargin/Center/Panel/Padding/Content/Scroll
@onready var tools: VBoxContainer = $Dialog/SafeMargin/Center/Panel/Padding/Content/Scroll/Tools
@onready var test_toggle: Button = tools.get_node("TestToggle")
@onready var test_panel: VBoxContainer = tools.get_node("TestPanel")
@onready var number_input: LineEdit = tools.get_node("TestPanel/Row/Number")
@onready var test_error: Label = tools.get_node("TestPanel/Error")
@onready var reset_button: Button = tools.get_node("Reset")
@onready var reset_panel: VBoxContainer = tools.get_node("ResetPanel")
@onready var reset_error: Label = tools.get_node("ResetPanel/Error")
var level_count := 0
var enabled := false

func _ready() -> void:
	launcher.pressed.connect(open)
	($Dialog/SafeMargin/Center/Panel/Padding/Content/Close as Button).pressed.connect(close)
	test_toggle.pressed.connect(_toggle_test)
	(tools.get_node("TestPanel/Row/Start") as Button).pressed.connect(_submit_test)
	number_input.text_submitted.connect(func(_text: String) -> void: _submit_test())
	reset_button.pressed.connect(_ask_reset)
	(tools.get_node("ResetPanel/Actions/Confirm") as Button).pressed.connect(func() -> void:
		if enabled and is_visible_in_tree() and reset_panel.visible:
			reset_requested.emit())
	(tools.get_node("ResetPanel/Actions/Cancel") as Button).pressed.connect(_cancel_reset)
	center.resized.connect(_queue_fit)
	tools.minimum_size_changed.connect(_queue_fit)
	_queue_fit()

func configure(available: bool, count: int = 0) -> void:
	enabled = available and OS.is_debug_build()
	level_count = count
	close()
	number_input.text = ""
	number_input.placeholder_text = "۱ تا %s" % PuzzleHUD._persian(str(level_count))
	visible = enabled

func open() -> void:
	if not enabled or not is_visible_in_tree():
		return
	dialog.show()
	launcher.hide()
	_queue_fit()

func close() -> void:
	dialog.hide()
	test_panel.hide()
	test_error.text = ""
	_cancel_reset()
	launcher.show()

func _toggle_test() -> void:
	if not enabled or reset_panel.visible:
		return
	test_panel.visible = not test_panel.visible
	test_error.text = ""
	if test_panel.visible:
		number_input.grab_focus()

func _ask_reset() -> void:
	if not enabled or not is_visible_in_tree():
		return
	test_toggle.disabled = true
	test_panel.hide()
	reset_button.hide()
	reset_error.text = ""
	reset_panel.show()

func _cancel_reset() -> void:
	reset_panel.hide()
	reset_button.show()
	test_toggle.disabled = false
	reset_error.text = ""

func _submit_test() -> void:
	if not enabled or not is_visible_in_tree() or reset_panel.visible:
		return
	var number := number_input.text.strip_edges()
	for i in range(10):
		number = number.replace("۰۱۲۳۴۵۶۷۸۹"[i], str(i)).replace("٠١٢٣٤٥٦٧٨٩"[i], str(i))
	if number.is_empty() or not number.is_valid_int() or int(number) < 1 or int(number) > level_count:
		test_error.text = "شماره‌ای از ۱ تا %s وارد کنید." % PuzzleHUD._persian(str(level_count))
		return
	test_error.text = ""
	test_requested.emit(int(number) - 1)

func _queue_fit() -> void:
	_fit_scroll.call_deferred()

func _fit_scroll() -> void:
	if is_inside_tree() and center.size.y > 0:
		scroll.custom_minimum_size.y = minf(tools.get_combined_minimum_size().y, center.size.y * 0.55)
