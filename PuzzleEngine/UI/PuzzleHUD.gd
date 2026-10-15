class_name PuzzleHUD
extends Control

signal menu_requested

const EMPTY_STAR := preload("res://assets/ui/empty-star.png")
const FILLED_STAR := preload("res://assets/ui/star.png")
const TIMER_NORMAL_COLOR := Color.WHITE
const TIMER_WARNING_COLOR := Color(1.0, 0.32, 0.25, 1.0)
@onready var toolbar: Control = $SafeMargin/Layout/Toolbar
@onready var question_label: Label = $SafeMargin/Layout/Toolbar/QuestionScroll/Question
@onready var timer_label: Label = $SafeMargin/Layout/Toolbar/Time
@onready var level_label: Label = $SafeMargin/Layout/Toolbar/Level
@onready var score_label: Label = $SafeMargin/Layout/Toolbar/Score
@onready var hint_button: Button = $SafeMargin/Layout/Toolbar/Hint
@onready var menu_button: Button = $SafeMargin/Layout/Toolbar/Menu
@onready var stars_root: HBoxContainer = $SafeMargin/Layout/Toolbar/Stars
@onready var counters_root: VBoxContainer = $SafeMargin/Layout/Counters
var counter_definitions: Array = []
var counter_labels: Array[Label] = []
var average_stars: float = 0.0

func _ready() -> void:
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	toolbar.resized.connect(_resize_toolbar)
	for i in range(3):
		var slot := AspectRatioContainer.new()
		slot.name = "Star%d" % (i + 1)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.ratio = float(FILLED_STAR.get_width()) / FILLED_STAR.get_height()
		slot.stretch_mode = AspectRatioContainer.STRETCH_FIT
		stars_root.add_child(slot)
		var icon := Control.new()
		icon.name = "Icon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var empty := TextureRect.new()
		empty.texture = EMPTY_STAR
		empty.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		empty.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(empty)
		empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var fill := TextureProgressBar.new()
		fill.name = "Fill"
		fill.texture_progress = FILLED_STAR
		fill.nine_patch_stretch = true
		fill.step = 0.0
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(fill)
		fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resize_toolbar()
	set_progress({})

func _resize_toolbar() -> void:
	# The artwork's aspect ratio owns the height; its children use normalized anchors.
	var texture: Texture2D = $SafeMargin/Layout/Toolbar/Artwork.texture
	toolbar.custom_minimum_size.y = toolbar.size.x * texture.get_height() / texture.get_width()

func set_progress(saved_results: Dictionary, hint_points_spent: int = 0) -> void:
	var score := -hint_points_spent
	var stars := 0
	for result: Dictionary in saved_results.values():
		score += int(result["score"])
		stars += int(result["stars"])
	average_stars = float(stars) / saved_results.size() if not saved_results.is_empty() else 0.0
	score_label.text = _persian(str(score))
	for i in range(stars_root.get_child_count()):
		var fill: TextureProgressBar = stars_root.get_child(i).get_node("Icon/Fill")
		fill.value = clampf(average_stars - i, 0.0, 1.0) * 100.0
	stars_root.tooltip_text = "میانگین ستاره‌های مراحل حل‌شده: %s از ۳" % _persian("%.2f" % average_stars)

func gameplay_top() -> float:
	var bottom := toolbar.get_global_rect().end.y
	if counters_root.visible:
		bottom = maxf(bottom, counters_root.get_global_rect().end.y)
	return maxf(size.y * 0.1, bottom)

func set_level(data: Dictionary, index: int, count: int) -> void:
	question_label.text = _persian(data["question"])
	$SafeMargin/Layout/Toolbar/QuestionScroll.scroll_vertical = 0
	level_label.text = "مرحله %s" % _persian("%d/%d" % [index + 1, count])
	var seconds := int(ceil(float(data["time_limit_seconds"])))
	set_countdown(seconds)
	hint_button.disabled = true
	for label: Label in counter_labels:
		counters_root.remove_child(label)
		label.queue_free()
	counter_labels.clear()
	counter_definitions = data.get("counters", []).duplicate(true)
	for counter: Dictionary in counter_definitions:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text_direction = Control.TEXT_DIRECTION_RTL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		counters_root.add_child(label)
		counter_labels.append(label)
	counters_root.visible = not counter_labels.is_empty()
	update_counters(data.get("variables", {}))

func update_counters(variables: Dictionary) -> void:
	for i in range(counter_definitions.size()):
		var counter: Dictionary = counter_definitions[i]
		var value: Variant = variables.get(counter["variable"], 0)
		# Rules own the underlying value. Clamp only the progress displayed by HUD.
		var current := clampi(int(value), 0, int(counter["target"])) if value is int or value is float else 0
		var text := "%s: %s از %s" % [counter["label"], _persian(str(current)), _persian(str(int(counter["target"])))]
		if counter_labels[i].text != text:
			counter_labels[i].text = text

func set_countdown(seconds: int) -> void:
	timer_label.text = _persian("%02d:%02d" % [int(seconds / 60.0), seconds % 60])
	var color := TIMER_WARNING_COLOR if seconds <= 10 else TIMER_NORMAL_COLOR
	if timer_label.get_theme_color("font_color") != color:
		timer_label.add_theme_color_override("font_color", color)

func show_load_error() -> void:
	question_label.text = "بارگذاری مرحله انجام نشد. لطفاً دوباره تلاش کنید."
	timer_label.text = "—"
	timer_label.add_theme_color_override("font_color", TIMER_NORMAL_COLOR)
	level_label.text = "رمز و راز"

static func _persian(value: String) -> String:
	var result := value
	for i in range(10):
		result = result.replace(str(i), "۰۱۲۳۴۵۶۷۸۹"[i])
	return result
