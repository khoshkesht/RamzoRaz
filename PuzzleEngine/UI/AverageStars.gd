class_name PuzzleAverageStars
extends HBoxContainer

const EMPTY_STAR := preload("res://assets/ui/empty-star.png")
const FILLED_STAR := preload("res://assets/ui/star.png")

func _ready() -> void:
	for i in range(3):
		var slot := AspectRatioContainer.new()
		slot.name = "Star%d" % (i + 1)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.ratio = float(FILLED_STAR.get_width()) / FILLED_STAR.get_height()
		slot.stretch_mode = AspectRatioContainer.STRETCH_FIT
		add_child(slot)
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
	set_average(0.0)

func set_average(value: float) -> void:
	for i in range(get_child_count()):
		var fill: TextureProgressBar = get_child(i).get_node("Icon/Fill")
		fill.value = clampf(value - i, 0.0, 1.0) * 100.0
	tooltip_text = "میانگین ستاره‌های مراحل حل‌شده: %s از ۳" % PuzzleHUD._persian("%.2f" % value)
