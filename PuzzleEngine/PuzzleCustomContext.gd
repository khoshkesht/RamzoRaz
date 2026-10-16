class_name PuzzleCustomContext
extends RefCounted

var _state: PuzzleState
var _run_id: int
var _active: bool = true
var _actions: Array[Dictionary] = []
var _events: Array[Dictionary] = []

func _init(state: PuzzleState) -> void:
	_state = state
	_run_id = state.run_id

func valid() -> bool:
	return _active and _state.run_id == _run_id

func get_variable(key: String) -> Variant:
	return _state.variables.get(key) if valid() else null

func get_object_state(id: String, key: String) -> Variant:
	return _state.objects.get(id, {}).get("state", {}).get(key) if valid() else null

func run_actions(actions: Array) -> void:
	if valid():
		for action: Dictionary in actions:
			_actions.append(action.duplicate(true))

func emit_custom_event(type: String, source: String, payload: Dictionary = {}) -> void:
	if valid() and type.begins_with("custom:"):
		_events.append({"type": type, "source": source, "payload": payload.duplicate(true), "run_id": _run_id})

func request_success() -> void:
	run_actions([{"type": "complete_level"}])

func invalidate() -> void:
	_active = false
	_actions.clear()
	_events.clear()
