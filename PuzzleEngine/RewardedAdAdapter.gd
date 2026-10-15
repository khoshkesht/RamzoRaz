class_name PuzzleRewardedAdAdapter
extends RefCounted

signal event_received(kind: String, request_id: int, level_id: int)

var simulated: bool = OS.has_feature("editor") and OS.is_debug_build()
var auto_open: bool = true
var active: Dictionary = {}
var time_source: Callable = Time.get_ticks_usec

func request(request_id: int, level_id: int) -> bool:
	if not active.is_empty():
		return false
	active = {"request_id": request_id, "level_id": level_id, "started": int(time_source.call()), "opened": false}
	if not simulated:
		deliver.call_deferred("unavailable", request_id, level_id)
	elif auto_open:
		deliver.call_deferred("opened", request_id, level_id)
	return true

# Real SDK implementations must dispatch through this main-thread entry point.
func deliver(kind: String, request_id: int, level_id: int) -> void:
	if active.get("request_id") == request_id and active.get("level_id") == level_id:
		if kind == "opened":
			active["opened"] = true
		if kind in ["closed", "failed", "unavailable"]:
			active.clear()
	event_received.emit(kind, request_id, level_id)

func poll() -> void:
	if not active.is_empty() and not active["opened"] and int(time_source.call()) - int(active["started"]) >= 30000000:
		deliver("unavailable", int(active["request_id"]), int(active["level_id"]))

func finish_simulation(reward: bool) -> void:
	if not simulated or active.is_empty() or not active["opened"]:
		return
	var id := int(active["request_id"])
	var level := int(active["level_id"])
	if reward:
		deliver("rewarded", id, level)
	deliver("closed", id, level)
