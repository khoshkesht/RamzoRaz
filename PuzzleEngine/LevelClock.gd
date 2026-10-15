class_name PuzzleLevelClock
extends RefCounted

# Injectable monotonic source keeps deadline and pause tests deterministic.
var time_source: Callable = Time.get_ticks_usec
var limit_usec: int = 0
var elapsed_usec: int = 0
var running: bool = false
var pause_reasons: Dictionary = {}
var _last_usec: int = 0

func start(seconds: float) -> void:
	limit_usec = maxi(1, int(round(seconds * 1000000.0)))
	elapsed_usec = 0
	pause_reasons.clear()
	_last_usec = int(time_source.call())
	running = true

func update() -> void:
	var now := int(time_source.call())
	if running and pause_reasons.is_empty():
		elapsed_usec = mini(limit_usec, elapsed_usec + maxi(0, now - _last_usec))
	_last_usec = now

func set_paused(reason: String, paused: bool) -> void:
	update()
	if paused:
		pause_reasons[reason] = true
	else:
		pause_reasons.erase(reason)

func stop() -> void:
	update()
	running = false

func remaining_usec() -> int:
	return maxi(0, limit_usec - elapsed_usec)

func countdown_seconds() -> int:
	return int(ceil(remaining_usec() / 1000000.0))

func expired() -> bool:
	return elapsed_usec >= limit_usec
