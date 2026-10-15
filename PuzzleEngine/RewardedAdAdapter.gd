class_name PuzzleRewardedAdAdapter
extends RefCounted

signal event_received(kind: String, request_id: int, level_id: int)

var simulated: bool = OS.has_feature("editor") and OS.is_debug_build()
var auto_open: bool = true
var active: Dictionary = {}
var time_source: Callable = Time.get_ticks_usec
var show_guard: Callable
var _native: Object
var _native_requests: Dictionary = {}
var _initialized: bool = false

func initialize(backend: Object = null) -> void:
	if _initialized:
		return
	_initialized = true
	if backend != null:
		_native = backend
	elif OS.get_name() == "Android" and Engine.has_singleton(PuzzleAdiveryConfig.SINGLETON_NAME):
		_native = Engine.get_singleton(PuzzleAdiveryConfig.SINGLETON_NAME)
	if _native == null:
		return
	simulated = false
	_native.connect("ad_event", _on_native_event, CONNECT_DEFERRED)
	_native.call("initialize", PuzzleAdiveryConfig.APP_ID, PuzzleAdiveryConfig.REWARDED_PLACEMENT_ID, OS.is_debug_build())

func shutdown() -> void:
	if is_instance_valid(_native):
		if _native.is_connected("ad_event", _on_native_event):
			_native.disconnect("ad_event", _on_native_event)
	_native = null
	show_guard = Callable()

func request(request_id: int, level_id: int) -> bool:
	if not active.is_empty():
		return false
	active = {"request_id": request_id, "level_id": level_id, "started": int(time_source.call()), "opened": false}
	if is_instance_valid(_native) and not simulated:
		var token := int(_native.call("reserve_rewarded"))
		if token > 0:
			_native_requests[token] = {"request_id": request_id, "level_id": level_id}
			active["native_token"] = token
		else:
			deliver.call_deferred("unavailable", request_id, level_id)
	elif not simulated:
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
		if active.has("native_token") and is_instance_valid(_native):
			_native.call("cancel_rewarded", int(active["native_token"]))
		deliver("unavailable", int(active["request_id"]), int(active["level_id"]))

func _on_native_event(kind: String, token: int) -> void:
	if not _native_requests.has(token):
		return
	var request_data: Dictionary = _native_requests[token]
	var id := int(request_data["request_id"])
	var level := int(request_data["level_id"])
	if kind == "ready":
		var current: bool = active.get("native_token", 0) == token
		if current and int(time_source.call()) - int(active["started"]) < 30000000 and show_guard.is_valid() and bool(show_guard.call()):
			_native.call("show_rewarded", token)
		else:
			_native.call("cancel_rewarded", token)
			if current:
				deliver("unavailable", id, level)
		return
	if kind == "released":
		_native_requests.erase(token)
		return
	if active.get("native_token", 0) != token:
		return
	if kind not in ["opened", "rewarded", "closed", "failed", "unavailable"]:
		return
	# The native bridge serializes the rewarded/closed pair; the original IDs never change.
	deliver(kind, id, level)
	if kind in ["closed", "failed"]:
		_native_requests.erase(token)

func finish_simulation(reward: bool) -> void:
	if not simulated or active.is_empty() or not active["opened"]:
		return
	var id := int(active["request_id"])
	var level := int(active["level_id"])
	if reward:
		deliver("rewarded", id, level)
	deliver("closed", id, level)
