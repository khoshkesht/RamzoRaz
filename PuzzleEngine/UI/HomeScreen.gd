class_name PuzzleHomeScreen
extends Control

signal play_requested
signal reload_requested

const BACKGROUND_DRIFT_RANGE := 0.082
const BACKGROUND_SWAY_PERIOD := Vector2(28.0, 33.0)
const BACKGROUND_SECONDARY_PERIOD := Vector2(67.0, 79.0)

var _background_rng := RandomNumberGenerator.new()
var _background_phase := Vector2.ZERO
var _background_secondary_phase := Vector2.ZERO
var _background_offset := Vector2.ZERO
var _background_suspended := false

@onready var background_artwork: TextureRect = $Background/Artwork
@onready var layout: Control = $SafeMargin/Layout
@onready var toolbar: Control = $SafeMargin/Layout/Toolbar
@onready var status_label: Label = $SafeMargin/Layout/Toolbar/Next
@onready var stats_label: Label = $SafeMargin/Layout/Toolbar/Score
@onready var time_label: Label = $SafeMargin/Layout/Toolbar/Time
@onready var solved_label: Label = $SafeMargin/Layout/Toolbar/Solved
@onready var total_score_label: Label = $SafeMargin/Layout/Toolbar/TotalScore
@onready var stars_root: PuzzleAverageStars = $SafeMargin/Layout/Toolbar/Stars
var average_stars: float = 0.0
@onready var play_button: Button = $SafeMargin/Layout/Toolbar/Play
@onready var reload_button: Button = $SafeMargin/Layout/Feedback/Content/Reload
@onready var message_label: Label = $SafeMargin/Layout/Feedback/Content/Message

func _ready() -> void:
	_background_rng.randomize()
	_background_phase = Vector2(_background_rng.randf_range(0.0, TAU), _background_rng.randf_range(0.0, TAU))
	_background_secondary_phase = Vector2(_background_rng.randf_range(0.0, TAU), _background_rng.randf_range(0.0, TAU))
	_update_background_offset()
	_apply_background_offset()
	resized.connect(_apply_background_offset)
	play_button.pressed.connect(func() -> void: play_requested.emit())
	reload_button.pressed.connect(func() -> void: reload_requested.emit())
	layout.resized.connect(_fit)
	resized.connect(_fit)
	$SafeMargin/Layout/Feedback.minimum_size_changed.connect(func() -> void: _fit.call_deferred())
	_connect_footer.call_deferred()
	_fit.call_deferred()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _background_suspended:
		return
	# Cap a delayed frame so returning from background cannot jump the image.
	var step := minf(delta, 0.1) * TAU
	_background_phase.x = fposmod(_background_phase.x + step / BACKGROUND_SWAY_PERIOD.x, TAU)
	_background_phase.y = fposmod(_background_phase.y + step / BACKGROUND_SWAY_PERIOD.y, TAU)
	_background_secondary_phase.x = fposmod(_background_secondary_phase.x + step / BACKGROUND_SECONDARY_PERIOD.x, TAU)
	_background_secondary_phase.y = fposmod(_background_secondary_phase.y + step / BACKGROUND_SECONDARY_PERIOD.y, TAU)
	_update_background_offset()
	_apply_background_offset()

func _update_background_offset() -> void:
	# Overlapping waves keep velocity continuous: no destination, timed arrival
	# or stop between legs. Unequal periods and random phases vary the path.
	var primary := Vector2(sin(_background_phase.x), cos(_background_phase.y))
	var secondary := Vector2(sin(_background_secondary_phase.x), sin(_background_secondary_phase.y))
	_background_offset = (primary * 0.8 + secondary * 0.2) * BACKGROUND_DRIFT_RANGE

func _apply_background_offset() -> void:
	var offset := size * _background_offset
	background_artwork.offset_left = offset.x
	background_artwork.offset_right = offset.x
	background_artwork.offset_top = offset.y
	background_artwork.offset_bottom = offset.y

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_background_suspended = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_background_suspended = false

func _connect_footer() -> void:
	var menu := get_node_or_null("../../MainMenuLayer/MainMenu") as PuzzleMainMenu
	if menu != null and is_instance_valid(menu.panel):
		menu.panel.resized.connect(func() -> void: _fit.call_deferred())
	_fit()

func _fit() -> void:
	if layout.size.x <= 0 or layout.size.y <= 0:
		return
	var feedback: PanelContainer = $SafeMargin/Layout/Feedback
	var feedback_height := feedback.get_combined_minimum_size().y if feedback.visible else 0.0
	var bottom := layout.size.y * 0.8
	var menu := get_node_or_null("../../MainMenuLayer/MainMenu") as PuzzleMainMenu
	if menu != null and is_instance_valid(menu.panel) and menu.panel.size.y > 0.0:
		bottom = minf(bottom, menu.panel.get_global_rect().position.y - layout.get_global_rect().position.y - 16.0)
	var top := 12.0
	var available_height := maxf(0.0, bottom - top - feedback_height - 12.0)
	var texture: Texture2D = $SafeMargin/Layout/Toolbar/Artwork.texture
	var ratio := float(texture.get_width()) / texture.get_height()
	var width := minf(layout.size.x * 0.8, available_height * ratio)
	var height := width / ratio
	toolbar.offset_left = -width * 0.5
	toolbar.offset_right = width * 0.5
	toolbar.offset_top = top
	toolbar.offset_bottom = top + height
	toolbar.visible = height > 0.0
	for label: Label in [total_score_label, stats_label, time_label, status_label, solved_label]:
		var available := width * (label.anchor_right - label.anchor_left) - 8.0
		var font := label.get_theme_font("font")
		var font_size := 36 if label == total_score_label else 30
		while font_size > 24 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
	feedback.offset_top = top + height + 12.0
	feedback.offset_bottom = feedback.offset_top + feedback_height

func display_progress(data: Dictionary, manifest: Dictionary) -> void:
	var levels: Array = manifest["levels"]
	solved_label.text = "حل‌شده: %s از %s" % [PuzzleHUD._persian(str(data["results"].size())), PuzzleHUD._persian(str(PuzzleAppConfig.AUTHORED_LEVEL_COUNT))]
	var total_score := PuzzleProgressStore.available_score(data)
	var total_stars := 0
	for result: Dictionary in data["results"].values():
		total_stars += int(result["stars"])
	total_score_label.text = PuzzleHUD._persian(str(total_score))
	average_stars = float(total_stars) / data["results"].size() if not data["results"].is_empty() else 0.0
	stars_root.set_average(average_stars)
	var current: Variant = data["current_level_id"]
	var pending: bool = data["pending_result_level_id"] != null
	var index := -1
	for i in range(levels.size()):
		if levels[i]["id"] == current:
			index = i
	# A pending result belongs to a solved stage; preview its successor.
	var next_index := index + 1 if pending else index
	stats_label.text = "امتیاز مرحله: —"
	time_label.text = "زمان مرحله: —"
	status_label.text = "مرحلهٔ بعد: —"
	message_label.text = ""
	reload_button.hide()
	play_button.disabled = current == null
	play_button.text = "شروع بازی"
	if levels.is_empty():
		message_label.text = "هنوز مرحله‌ای برای بازی آماده نیست."
		play_button.text = "مراحل در حال آماده‌سازی"
	elif current == null:
		message_label.text = "همهٔ مراحل موجود را حل کرده‌اید!"
		play_button.text = "بازی به پایان رسیده"
	elif pending:
		message_label.text = "نتیجهٔ مرحله آماده است؛ برای دیدن نتیجه و ادامه، شروع را بزنید."
		play_button.text = "دیدن نتیجه و ادامه"
	if current != null and next_index >= 0 and next_index < levels.size():
		var loaded := PuzzleLoader.new().load_level(levels[next_index])
		if not loaded["ok"]:
			message_label.text = "اطلاعات مرحلهٔ بعد بارگذاری نشد. دوباره تلاش کنید."
			play_button.disabled = not pending
			reload_button.show()
		else:
			var definition: Dictionary = loaded["data"]
			stats_label.text = "امتیاز مرحله: %s" % PuzzleHUD._persian(str(int(definition["base_score"])))
			var seconds := int(ceil(float(definition["time_limit_seconds"])))
			# Isolate the LTR clock from its surrounding Persian phrase.
			time_label.text = "زمان مرحله: \u2066%s\u2069" % PuzzleHUD._persian("%d:%02d" % [int(seconds / 60.0), seconds % 60])
			status_label.text = "مرحلهٔ بعد: %s" % PuzzleHUD._persian(str(next_index + 1))
	_update_text()

func display_error() -> void:
	message_label.text = "بازیابی پیشرفت انجام نشد. دوباره تلاش کنید."
	for label: Label in [total_score_label, stats_label, time_label, status_label, solved_label]:
		label.text = "—"
	average_stars = 0.0
	stars_root.set_average(average_stars)
	play_button.disabled = true
	play_button.text = "بازیابی پیشرفت انجام نشد"
	reload_button.show()
	_update_text()

func _update_text() -> void:
	play_button.tooltip_text = play_button.text
	message_label.visible = not message_label.text.is_empty()
	$SafeMargin/Layout/Feedback.visible = message_label.visible or reload_button.visible
	total_score_label.tooltip_text = "جمع امتیاز: %s" % total_score_label.text
	for label: Label in [stats_label, time_label, status_label, solved_label]:
		label.tooltip_text = label.text
	_fit.call_deferred()
