extends SceneTree

class FakeNative extends RefCounted:
	signal ad_event(kind: String, token: int)
	var token: int = 0
	var shown: Array[int] = []
	var canceled: Array[int] = []
	var identifiers: Array[String] = []
	func initialize(app_id: String, placement_id: String, _debug: bool) -> void:
		identifiers = [app_id, placement_id]
	func reserve_rewarded() -> int:
		token += 1
		return token
	func show_rewarded(value: int) -> void:
		shown.append(value)
	func cancel_rewarded(value: int) -> void:
		canceled.append(value)

var now_usec: int = 0
var failures: Array[String] = []
var events: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var native := FakeNative.new()
	var adapter := PuzzleRewardedAdAdapter.new()
	adapter.time_source = func() -> int: return now_usec
	adapter.show_guard = func() -> bool: return true
	adapter.initialize(native)
	adapter.event_received.connect(func(kind: String, id: int, level: int) -> void: events.append([kind, id, level]))
	check(native.identifiers == [PuzzleAdiveryConfig.APP_ID, PuzzleAdiveryConfig.REWARDED_PLACEMENT_ID], "Publisher IDs reach the bridge")
	check(adapter.request(7, 12), "Accept request")
	check(not adapter.request(8, 24), "Reject concurrent request")
	native.ad_event.emit("ready", 1)
	await process_frame
	check(native.shown == [1], "Only explicit valid ready request triggers show")
	native.ad_event.emit("opened", 1)
	native.ad_event.emit("rewarded", 1)
	native.ad_event.emit("closed", 1)
	await process_frame
	check(events == [["opened", 7, 12], ["rewarded", 7, 12], ["closed", 7, 12]], "Ordered reward/close preserves original IDs")
	native.ad_event.emit("rewarded", 1)
	await process_frame
	check(events.size() == 3 and adapter.active.is_empty(), "Duplicate terminal callback cannot grant twice")

	events.clear()
	adapter.request(9, 24)
	native.ad_event.emit("opened", 2)
	native.ad_event.emit("closed", 2)
	await process_frame
	check(events == [["opened", 9, 24], ["closed", 9, 24]], "Close without reward cannot produce rewarded")

	events.clear()
	adapter.request(1, 12)
	now_usec = 30000000
	adapter.poll()
	check(native.canceled == [3] and adapter.active.is_empty(), "Startup timeout cancels the native token and releases request")
	adapter.request(1, 12)
	native.ad_event.emit("opened", 3)
	native.ad_event.emit("rewarded", 3)
	native.ad_event.emit("closed", 3)
	native.ad_event.emit("released", 3)
	await process_frame
	check(events == [["unavailable", 1, 12]] and adapter.active.get("native_token") == 4, "Old token cannot affect reused request/level IDs")
	adapter.show_guard = func() -> bool: return false
	native.ad_event.emit("ready", 4)
	await process_frame
	check(native.shown == [1] and native.canceled == [3, 4] and adapter.active.is_empty(), "Expired gameplay guard prevents queued display")
	adapter.shutdown()
	check(not native.ad_event.is_connected(adapter._on_native_event), "Shutdown detaches native listener")
	for failure: String in failures:
		push_error(failure)
	print("ADIVERY_ADAPTER: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
