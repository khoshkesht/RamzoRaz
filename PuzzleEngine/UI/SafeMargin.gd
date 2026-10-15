class_name PuzzleSafeMargin
extends MarginContainer

@export var padding: int = PuzzleAppConfig.UI_PADDING

var use_display_safe_area: bool = OS.has_feature("android") or OS.has_feature("ios")
var safe_area_provider: Callable = DisplayServer.get_display_safe_area
var _refresh_queued: bool = false
var _refreshing: bool = false

func _ready() -> void:
	get_viewport().size_changed.connect(queue_refresh)
	resized.connect(queue_refresh)
	queue_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_inside_tree():
		queue_refresh()

func queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh_deferred.call_deferred()

func _refresh_deferred() -> void:
	_refresh_queued = false
	if is_inside_tree():
		refresh()

func refresh() -> void:
	# Theme changes can synchronously emit resized. Never query Android insets
	# from a nested layout callback, even when refresh is called directly.
	if _refreshing or size.x <= 0 or size.y <= 0:
		return
	_refreshing = true
	var logical_safe := Rect2(Vector2.ZERO, size)
	if use_display_safe_area:
		var transform := get_viewport().get_screen_transform() * get_global_transform_with_canvas()
		var render_rect := Rect2(transform * Vector2.ZERO, transform * size - transform * Vector2.ZERO)
		var physical_safe := Rect2(safe_area_provider.call())
		logical_safe = map_safe_rect(physical_safe, render_rect, size)
	var margins := {
		"margin_left": int(ceil(logical_safe.position.x)) + padding,
		"margin_top": int(ceil(logical_safe.position.y)) + padding,
		"margin_right": int(ceil(size.x - logical_safe.end.x)) + padding,
		"margin_bottom": int(ceil(size.y - logical_safe.end.y)) + padding,
	}
	for key: String in margins:
		if get_theme_constant(key) != margins[key]:
			add_theme_constant_override(key, margins[key])
	_refreshing = false

static func map_safe_rect(physical_safe: Rect2, render_rect: Rect2, logical_size: Vector2) -> Rect2:
	if render_rect.size.x <= 0 or render_rect.size.y <= 0 or physical_safe.size.x <= 0 or physical_safe.size.y <= 0:
		return Rect2(Vector2.ZERO, logical_size)
	var intersection := physical_safe.intersection(render_rect)
	if not intersection.has_area():
		return Rect2(Vector2.ZERO, logical_size)
	var factor := logical_size / render_rect.size
	return Rect2((intersection.position - render_rect.position) * factor, intersection.size * factor)

