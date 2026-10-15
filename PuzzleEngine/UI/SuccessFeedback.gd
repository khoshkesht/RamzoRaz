class_name PuzzleSuccessFeedback
extends Control

const STAR := preload("res://assets/ui/star.png")
const DURATION: float = 1.1
const PARTICLE_COUNT: int = 24
var elapsed: float = 0.0
var active: bool = false

func _ready() -> void:
	resized.connect(queue_redraw)
	stop()

func play() -> void:
	elapsed = 0.0
	active = true
	show()
	queue_redraw()

func stop() -> void:
	active = false
	hide()
	queue_redraw()

# The controller advances presentation with the same pause policy as its result delay.
func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(DURATION, elapsed + maxf(delta, 0.0))
	if elapsed >= DURATION:
		stop()
	else:
		queue_redraw()

func _draw() -> void:
	if not active or size.x <= 0.0 or size.y <= 0.0:
		return
	var progress := elapsed / DURATION
	var fade := 1.0 - smoothstep(0.55, 1.0, progress)
	var appear := smoothstep(0.0, 0.12, progress)
	var center := size * Vector2(0.5, 0.42)
	var radius := minf(size.x, size.y) * 0.19
	var spread := 1.0 - pow(1.0 - progress, 3.0)
	for i in range(PARTICLE_COUNT):
		var angle := TAU * float(i) / PARTICLE_COUNT
		var direction := Vector2(cos(angle), sin(angle))
		var distance := radius * (0.50 + float(i % 5) * 0.12) * spread
		var point := center + direction * distance + Vector2(0.0, radius * progress * progress * 0.25)
		var star_size := lerpf(14.0, 30.0, float(i % 4) / 3.0) * appear
		var dimensions := Vector2(star_size, star_size * STAR.get_height() / STAR.get_width())
		draw_set_transform(point, angle + progress * (1.0 if i % 2 == 0 else -1.0))
		draw_texture_rect(STAR, Rect2(-dimensions * 0.5, dimensions), false, Color(1.0, 1.0, 1.0, fade))
	draw_set_transform(Vector2.ZERO)
	var badge_radius := minf(52.0, radius * 0.30) * appear
	draw_circle(center, badge_radius, Color(0.02, 0.24, 0.23, 0.85 * fade))
	draw_arc(center, badge_radius, 0.0, TAU, 64, Color(1.0, 0.82, 0.40, fade), 3.0, true)
	var check := PackedVector2Array([
		center + Vector2(-0.45, 0.0) * badge_radius,
		center + Vector2(-0.10, 0.33) * badge_radius,
		center + Vector2(0.48, -0.35) * badge_radius
	])
	draw_polyline(check, Color(1.0, 0.88, 0.52, fade), 7.0, true)
