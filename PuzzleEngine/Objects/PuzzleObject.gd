class_name PuzzleObject
extends Node2D

var object_id: String = ""
var definition: Dictionary = {}
var interactive: bool = false
var hit_size: Vector2 = Vector2.ZERO
var draw_order: int = 0
var automatic_hit_size: bool = true
@onready var sprite: Sprite2D = $Sprite
@onready var text_label: Label = $Text

func _ready() -> void:
	text_label.resized.connect(_center_text)

func configure(data: Dictionary, order: int) -> void:
	definition = data.duplicate(true)
	object_id = data["id"]
	name = object_id
	draw_order = order
	position = _vector(data["position"])
	rotation_degrees = float(data["rotation_degrees"])
	scale = _vector(data["scale"])
	z_index = int(data["z_index"])
	z_as_relative = false
	visible = data["visible"]
	interactive = data["interactive"]
	sprite.texture = load(data["sprite"]) as Texture2D if data.has("sprite") else null
	sprite.visible = sprite.texture != null
	text_label.visible = data["scene"] == "TextObject"
	if text_label.visible:
		text_label.text = data["text"]
		if data.has("text_color"):
			text_label.add_theme_color_override("font_color", Color(data["text_color"]))
		else:
			text_label.remove_theme_color_override("font_color")
	var default_size := sprite.texture.get_size() if sprite.texture != null else Vector2(320, 80)
	automatic_hit_size = not data.has("hit_size")
	hit_size = _vector(data["hit_size"]) if data.has("hit_size") else default_size
	text_label.custom_minimum_size = Vector2.ZERO
	text_label.size = hit_size
	_center_text()

func _center_text() -> void:
	# Font/wrapping can enlarge the Label, including when hidden text is shown.
	# Center its actual rect so vertical alignment stays at the object position.
	text_label.position = -text_label.size * 0.5

func contains_world_point(point: Vector2) -> bool:
	return visible and interactive and Rect2(-hit_size * 0.5, hit_size).has_point(to_local(point))

func interaction(type: String) -> Dictionary:
	for item: Dictionary in definition.get("interactions", []):
		if item.get("type") == type:
			return item
	return {}

func has_interaction(type: String) -> bool:
	return not interaction(type).is_empty()

func can_start_interaction() -> bool:
	if not visible or not interactive:
		return false
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.is_playing():
		return false
	for type: String in ["tap", "drag", "hold", "swipe"]:
		if has_interaction(type):
			return true
	return false

func accepts_source(source_id: String) -> bool:
	var accepted: Variant = definition.get("accepted_sources")
	return accepted == null or source_id in accepted

func replace_sprite(path: String) -> bool:
	var texture := load(path) as Texture2D
	if texture == null:
		return false
	sprite.texture = texture
	sprite.visible = true
	definition["sprite"] = path
	if automatic_hit_size:
		hit_size = texture.get_size()
	return true

static func _vector(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

