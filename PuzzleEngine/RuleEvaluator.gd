class_name PuzzleRuleEvaluator
extends Node

signal level_completed(level_id: int, run_id: int)
signal runtime_error(error: Dictionary)
signal debug_trace(entry: Dictionary)

const MAX_CHAIN_EVENTS: int = 128
const MAX_CHAIN_ACTIONS: int = 512

var definition: Dictionary = {}
var puzzle_state: PuzzleState
var object_nodes: Dictionary = {}
var action_runner: PuzzleActionRunner
var active: bool = false
var execution_guard: Callable
var debug_log: Array[Dictionary] = []

var _queue: Array[Dictionary] = []
var _processing: bool = false
var _event_count: int = 0
var _action_count: int = 0
var _current_rule_id: String = ""


func configure(level_definition: Dictionary, state: PuzzleState, nodes: Dictionary, runner: PuzzleActionRunner) -> void:
	stop()
	definition = level_definition
	puzzle_state = state
	object_nodes = nodes
	action_runner = runner
	active = true
	debug_log.clear()


func begin() -> void:
	if not active or puzzle_state == null:
		return
	enqueue_event({"type": "level_started", "source": "$level", "payload": {}, "run_id": puzzle_state.run_id})

func resume_pending() -> void:
	if active and not _processing and not _queue.is_empty():
		_process_queue()


func stop() -> void:
	active = false
	_queue.clear()
	if is_instance_valid(action_runner):
		action_runner.cancel_all()
	_processing = false
	_event_count = 0
	_action_count = 0
	_current_rule_id = ""


func enqueue_event(event: Dictionary) -> bool:
	if not active or puzzle_state == null or event.get("run_id") != puzzle_state.run_id:
		return false
	_queue.append(event.duplicate(true))
	if not _processing:
		_process_queue()
	return true


func evaluate_condition(condition: Dictionary, event: Dictionary = {}) -> bool:
	match condition["type"]:
		"visible":
			return bool(puzzle_state.objects[condition["target"]]["visible"])
		"variable":
			return _compare(puzzle_state.variables[condition["name"]], condition["operator"], condition["value"])
		"object_state":
			return _compare(puzzle_state.objects[condition["target"]]["state"][condition["key"]], condition["operator"], condition["value"])
		"event_value":
			var payload: Dictionary = event.get("payload", {})
			return payload.has(condition["field"]) and _compare(payload[condition["field"]], condition["operator"], condition["value"])
		"moved_distance_at_least":
			return float(event.get("payload", {}).get("distance", -1.0)) >= float(condition["value"])
		"inside":
			var source := object_nodes.get(condition["target"]) as PuzzleObject
			var zone := object_nodes.get(condition["zone"]) as PuzzleObject
			return source != null and zone != null and is_instance_valid(source) and is_instance_valid(zone) and zone.contains_world_point(source.global_position)
		"all":
			for child: Dictionary in condition["conditions"]:
				if not evaluate_condition(child, event):
					return false
			return true
		"any":
			for child: Dictionary in condition["conditions"]:
				if evaluate_condition(child, event):
					return true
			return false
		"not":
			return not evaluate_condition(condition["condition"], event)
	return false


func _process_queue() -> void:
	_processing = true
	_event_count = 0
	_action_count = 0
	while active and not _queue.is_empty():
		if not _execution_allowed():
			break
		_event_count += 1
		if _event_count > MAX_CHAIN_EVENTS:
			_fail("Event chain exceeded %d events." % MAX_CHAIN_EVENTS)
			break
		var event: Dictionary = _queue.pop_front()
		_trace("event", event.get("type", ""), event)
		_process_event(event)
		if _execution_allowed() and evaluate_condition(definition["win_condition"], event):
			_complete()
	_processing = false
	_current_rule_id = ""


func _process_event(event: Dictionary) -> void:
	for rule: Dictionary in definition.get("rules", []):
		if not _execution_allowed():
			return
		if not _rule_matches(rule, event):
			continue
		_current_rule_id = rule["id"]
		if rule.get("once", true):
			puzzle_state.consumed_rules[rule["id"]] = true
		_trace("rule", rule["id"], event)
		for action: Dictionary in rule["actions"]:
			if not _execution_allowed():
				return
			_action_count += 1
			if _action_count > MAX_CHAIN_ACTIONS:
				_fail("Event chain exceeded %d actions." % MAX_CHAIN_ACTIONS)
				return
			_trace("action", action["type"], action)
			var result := action_runner.run_action(action, puzzle_state.run_id)
			if not result["ok"]:
				_fail(result["error"])
				return
			for generated: Dictionary in result["events"]:
				_queue.append(generated)
			if not _execution_allowed():
				return
			if result["success_requested"] or evaluate_condition(definition["win_condition"]):
				_complete()
				return


func _rule_matches(rule: Dictionary, event: Dictionary) -> bool:
	if rule["event"] != event.get("type"):
		return false
	if rule.has("source") and rule["source"] != event.get("source"):
		return false
	if rule.has("target") and rule["target"] != event.get("target"):
		return false
	if rule.get("once", true) and puzzle_state.consumed_rules.has(rule["id"]):
		return false
	for condition: Dictionary in rule.get("conditions", []):
		if not evaluate_condition(condition, event):
			return false
	return true


func _complete() -> void:
	if not _execution_allowed():
		return
	active = false
	_queue.clear()
	action_runner.cancel_all()
	_trace("complete", str(puzzle_state.level_id), {})
	level_completed.emit(puzzle_state.level_id, puzzle_state.run_id)

func _execution_allowed() -> bool:
	return active and (not execution_guard.is_valid() or bool(execution_guard.call()))


func _fail(message: String) -> void:
	if not active:
		return
	active = false
	_queue.clear()
	action_runner.cancel_all()
	var error := {
		"level_id": puzzle_state.level_id,
		"run_id": puzzle_state.run_id,
		"rule_id": _current_rule_id,
		"message": message,
	}
	_trace("error", message, error)
	runtime_error.emit(error)


func _trace(kind: String, name: String, data: Dictionary) -> void:
	var entry := {"kind": kind, "name": name, "run_id": puzzle_state.run_id, "data": data.duplicate(true)}
	debug_log.append(entry)
	if debug_log.size() > 256:
		debug_log.pop_front()
	debug_trace.emit(entry)
	print_verbose("PUZZLE_TRACE %s" % JSON.stringify(entry))


static func _compare(left: Variant, operator: String, right: Variant) -> bool:
	var both_numbers := (left is int or left is float) and (right is int or right is float)
	match operator:
		"eq": return (both_numbers or typeof(left) == typeof(right)) and left == right
		"ne": return not ((both_numbers or typeof(left) == typeof(right)) and left == right)
		"gt": return both_numbers and float(left) > float(right)
		"gte": return both_numbers and float(left) >= float(right)
		"lt": return both_numbers and float(left) < float(right)
		"lte": return both_numbers and float(left) <= float(right)
	return false
