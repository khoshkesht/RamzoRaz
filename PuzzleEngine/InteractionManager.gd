class_name PuzzleInteractionManager
extends Node

signal interaction_event(event: Dictionary)

const MOUSE_POINTER_ID: int = -1

var object_root: Node2D
var object_nodes: Dictionary = {}
var puzzle_state: PuzzleState
var ui_roots: Array[Control] = []
var gameplay_enabled: bool = false
var input_guard: Callable

var _active_pointer: int = -2
var _active_object: PuzzleObject
var _press_position: Vector2
var _last_position: Vector2
var _object_start_position: Vector2
var _press_time_usec: int = 0
var _dragging: bool = false
var _drag_config: Dictionary = {}
var _max_pointer_distance: float = 0.0
var _hold_fired: bool = false
var _path_points: Array = []
var _path_overflow: bool = false
var _trace_line: Line2D
var time_source: Callable = func() -> int: return Time.get_ticks_usec()


func configure(stage_root: Node2D, nodes: Dictionary, state: PuzzleState, controls: Array[Control]) -> void:
	cancel_active_pointer()
	if is_instance_valid(_trace_line):
		if _trace_line.get_parent() != null:
			_trace_line.get_parent().remove_child(_trace_line)
		_trace_line.queue_free()
	_trace_line = null
	_path_points.clear()
	object_root = stage_root
	object_nodes = nodes
	puzzle_state = state
	ui_roots = controls
	gameplay_enabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			pointer_pressed(touch.position, touch.index)
		else:
			pointer_released(touch.position, touch.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		pointer_moved(drag.position, drag.index)
		get_viewport().set_input_as_handled()
	elif not OS.has_feature("android") and event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			pointer_pressed(button.position, MOUSE_POINTER_ID)
		else:
			pointer_released(button.position, MOUSE_POINTER_ID)
		get_viewport().set_input_as_handled()
	elif not OS.has_feature("android") and event is InputEventMouseMotion and _active_pointer == MOUSE_POINTER_ID:
		pointer_moved((event as InputEventMouseMotion).position, MOUSE_POINTER_ID)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	cancel_if_active_invalid()
	_update_hold()


func _update_hold() -> void:
	if _active_object == null or _hold_fired or _dragging or not _input_allowed() or not _active_object_valid():
		return
	var config := _active_object.interaction("hold")
	if config.is_empty() or _max_pointer_distance > float(config["max_distance"]):
		return
	if _elapsed_seconds() >= float(config["duration"]):
		_hold_fired = true
		_emit_movement("hold", _active_object, _press_position, _last_position)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		cancel_active_pointer()


func pointer_pressed(viewport_position: Vector2, pointer_id: int) -> bool:
	if not _input_allowed():
		return false
	if not gameplay_enabled or _active_pointer != -2 or object_root == null or puzzle_state == null:
		return false
	if _ui_blocks_point(viewport_position):
		return false
	var stage_position := viewport_to_stage(viewport_position)
	var candidate := _pick_object(stage_position)
	if candidate == null:
		return false
	_active_pointer = pointer_id
	_active_object = candidate
	_press_position = stage_position
	_last_position = stage_position
	_object_start_position = candidate.position
	_press_time_usec = int(time_source.call())
	_hold_fired = false
	_dragging = false
	_drag_config = candidate.interaction("drag")
	_max_pointer_distance = 0.0
	_path_points = [[candidate.position.x, candidate.position.y]]
	_path_overflow = false
	if candidate.definition.get("state", {}).get("trace", false):
		if not is_instance_valid(_trace_line):
			_trace_line = Line2D.new()
			_trace_line.width = 7.0
			_trace_line.default_color = Color("#256f81")
			_trace_line.z_index = 4
			object_root.add_child(_trace_line)
		_trace_line.clear_points()
		_trace_line.modulate = candidate.modulate
		_trace_line.add_point(candidate.position)
	return true


func pointer_moved(viewport_position: Vector2, pointer_id: int) -> bool:
	if not _input_allowed():
		return false
	if not gameplay_enabled or pointer_id != _active_pointer or not _active_object_valid():
		return false
	var stage_position := viewport_to_stage(viewport_position)
	_last_position = stage_position
	if _active_object.definition.get("state", {}).get("trace", false):
		var trace_delta := _constrain_delta(stage_position-_press_position,_drag_config.get("axis","both"))
		var trace_position := _clamp_to_bounds(_object_start_position+trace_delta,_drag_config)
		var sample_distance := Vector2(_path_points[-1][0],_path_points[-1][1]).distance_to(trace_position)
		if _path_points.size()>=4096 and sample_distance>=2.0:
			_path_overflow = true
		if _path_points.size()<4096 and sample_distance>=2.0:
			_path_points.append([trace_position.x,trace_position.y])
			if is_instance_valid(_trace_line):
				_trace_line.add_point(trace_position)
	_max_pointer_distance = maxf(_max_pointer_distance, _press_position.distance_to(stage_position))
	if _drag_config.is_empty():
		return true
	var constrained_delta := _constrain_delta(stage_position - _press_position, _drag_config.get("axis", "both"))
	if not _dragging and constrained_delta.length() >= float(_drag_config["start_distance"]):
		_dragging = true
		var first_position := _clamp_to_bounds(_object_start_position + constrained_delta, _drag_config)
		_active_object.position = first_position
		_sync_position(_active_object)
		_emit_movement("drag_start", _active_object, _object_start_position, first_position, "")
		return true
	if _dragging:
		var desired := _object_start_position + constrained_delta
		_active_object.position = _clamp_to_bounds(desired, _drag_config)
		_sync_position(_active_object)
	return true


func pointer_released(viewport_position: Vector2, pointer_id: int) -> bool:
	if not _input_allowed():
		return false
	if not gameplay_enabled or pointer_id != _active_pointer or not _active_object_valid():
		return false
	var release_position := viewport_to_stage(viewport_position)
	pointer_moved(viewport_position, pointer_id)
	if not gameplay_enabled or not _active_object_valid():
		return false
	var released_object := _active_object
	var run_id := puzzle_state.run_id
	var duration := _elapsed_seconds()
	var pointer_start_position := _press_position
	var max_pointer_distance := _max_pointer_distance
	var was_dragging := _dragging
	var start_position := _object_start_position
	var end_position := released_object.position
	var drop_target: PuzzleObject = null
	if was_dragging and released_object.has_interaction("drop_on"):
		drop_target = _pick_drop_zone(released_object)
	var return_invalid := bool(_drag_config.get("return_on_invalid", false))
	_update_hold()
	if not gameplay_enabled or not _active_object_valid() or not _run_is_current(run_id):
		return true
	var held := _hold_fired
	_reset_pointer(false)
	if was_dragging:
		_emit_movement("drag_end", released_object, start_position, end_position, "", run_id, duration)
		if not gameplay_enabled or not _run_is_current(run_id) or not is_instance_valid(released_object):
			return true
		if drop_target != null and is_instance_valid(drop_target):
			_emit_movement("drop_on", released_object, start_position, end_position, drop_target.object_id, run_id, duration)
		elif return_invalid:
			released_object.position = start_position
			_sync_position(released_object)
	elif held:
		return true
	elif _valid_swipe(released_object, release_position - pointer_start_position, duration):
		_emit_movement("swipe", released_object, pointer_start_position, release_position, "", run_id, duration)
	elif released_object.has_interaction("tap"):
		var config := released_object.interaction("tap")
		if max_pointer_distance <= float(config["max_distance"]) and duration <= float(config["max_duration"]):
			_emit_movement("tap", released_object, pointer_start_position, release_position, "", run_id, duration)
	return true


func _valid_swipe(item: PuzzleObject, movement: Vector2, duration: float) -> bool:
	var config := item.interaction("swipe")
	if config.is_empty() or movement.length() < float(config["min_distance"]) or duration > float(config["max_duration"]):
		return false
	var direction: String = config["direction"]
	if direction == "any":
		return true
	var axes := {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}
	var axis: Vector2 = axes[direction]
	return movement.normalized().dot(axis) >= cos(deg_to_rad(30.0))


func cancel_active_pointer() -> void:
	if _active_pointer != -2 and is_instance_valid(_trace_line):
		_trace_line.clear_points()
	_reset_pointer(true)

func _input_allowed() -> bool:
	return gameplay_enabled and (not input_guard.is_valid() or bool(input_guard.call()))


func set_gameplay_enabled(value: bool) -> void:
	if not value:
		cancel_active_pointer()
	gameplay_enabled = value


func cancel_if_active_invalid() -> void:
	if _active_object != null and (not is_instance_valid(_active_object) or not _active_object.visible or not _active_object.interactive):
		cancel_active_pointer()


func viewport_to_stage(viewport_position: Vector2) -> Vector2:
	if object_root == null:
		return viewport_position
	return object_root.get_global_transform_with_canvas().affine_inverse() * viewport_position


func stage_to_viewport(stage_position: Vector2) -> Vector2:
	if object_root == null:
		return stage_position
	return object_root.get_global_transform_with_canvas() * stage_position


func _pick_object(stage_position: Vector2) -> PuzzleObject:
	var candidates: Array[PuzzleObject] = []
	var world_position := object_root.to_global(stage_position)
	for value: Variant in object_nodes.values():
		var item := value as PuzzleObject
		if item != null and item.can_start_interaction() and item.contains_world_point(world_position):
			candidates.append(item)
	candidates.sort_custom(func(a: PuzzleObject, b: PuzzleObject) -> bool:
		return a.z_index > b.z_index if a.z_index != b.z_index else a.draw_order > b.draw_order
	)
	return candidates[0] if not candidates.is_empty() else null


func _pick_drop_zone(source: PuzzleObject) -> PuzzleObject:
	var candidates: Array[PuzzleObject] = []
	for value: Variant in object_nodes.values():
		var zone := value as PuzzleObject
		if zone == null or zone == source or zone.definition.get("scene") != "DropZone":
			continue
		if not zone.visible or not zone.interactive or not zone.accepts_source(source.object_id):
			continue
		if zone.contains_world_point(source.global_position):
			candidates.append(zone)
	candidates.sort_custom(func(a: PuzzleObject, b: PuzzleObject) -> bool:
		return a.z_index > b.z_index if a.z_index != b.z_index else a.draw_order > b.draw_order
	)
	return candidates[0] if not candidates.is_empty() else null


func _ui_blocks_point(viewport_position: Vector2) -> bool:
	for root: Control in ui_roots:
		if is_instance_valid(root) and _control_blocks_point(root, viewport_position):
			return true
	return false


func _control_blocks_point(control: Control, point: Vector2) -> bool:
	if not control.is_visible_in_tree():
		return false
	var enabled_stop := control.mouse_filter == Control.MOUSE_FILTER_STOP
	if control is BaseButton and (control as BaseButton).disabled:
		enabled_stop = false
	if enabled_stop and control.get_global_rect().has_point(point):
		return true
	for child: Node in control.get_children():
		if child is Control and _control_blocks_point(child as Control, point):
			return true
	return false


func _constrain_delta(delta: Vector2, axis: String) -> Vector2:
	match axis:
		"x": return Vector2(delta.x, 0.0)
		"y": return Vector2(0.0, delta.y)
		_: return delta


func _clamp_to_bounds(value: Vector2, config: Dictionary) -> Vector2:
	var bounds := Rect2(Vector2.ZERO, PuzzleAppConfig.DESIGN_SIZE)
	if config.has("bounds"):
		var raw: Array = config["bounds"]
		bounds = Rect2(Vector2(float(raw[0]), float(raw[1])), Vector2(float(raw[2]), float(raw[3])))
	var minimum_y := bounds.position.y
	if is_instance_valid(_active_object):
		# Reserve the complete toolbar/question/counter area during dragging too.
		var extent := _active_object.hit_size
		if _active_object.sprite.texture != null:
			extent = extent.max(_active_object.sprite.texture.get_size())
		var transform := _active_object.transform
		transform.origin = Vector2.ZERO
		var top_offset := 0.0
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			top_offset = minf(top_offset, (transform * (corner * extent * 0.5)).y)
		for ui: Control in ui_roots:
			if ui is PuzzleHUD and ui.is_visible_in_tree():
				minimum_y = maxf(minimum_y, viewport_to_stage(Vector2(0, ui.gameplay_top())).y - top_offset)
	return Vector2(clampf(value.x, bounds.position.x, bounds.end.x), clampf(value.y, minimum_y, maxf(minimum_y, bounds.end.y)))


func _emit_movement(type: String, source: PuzzleObject, start_position: Vector2, end_position: Vector2, target: String = "", run_id: int = -1, duration: float = -1.0) -> void:
	var actual_duration := _elapsed_seconds() if duration < 0.0 else duration
	var payload := {
		"start_position": [start_position.x, start_position.y],
		"end_position": [end_position.x, end_position.y],
		"distance": start_position.distance_to(end_position),
		"duration": actual_duration,
	}
	if type == "drag_end" and source.definition.get("state", {}).get("trace", false):
		payload["path"] = _path_points.duplicate(true)
		payload["path_overflow"] = _path_overflow
	var event: Dictionary = {
		"type": type,
		"source": source.object_id,
		"payload": payload,
		"run_id": puzzle_state.run_id if run_id < 0 else run_id,
	}
	if not target.is_empty():
		event["target"] = target
	interaction_event.emit(event)


func _sync_position(item: PuzzleObject) -> void:
	if puzzle_state != null:
		puzzle_state.set_object_property(item.object_id, "position", [item.position.x, item.position.y])


func _active_object_valid() -> bool:
	if _active_object == null or not is_instance_valid(_active_object):
		_reset_pointer(false)
		return false
	if not _active_object.visible or not _active_object.interactive:
		_reset_pointer(true)
		return false
	return true


func _reset_pointer(restore_position: bool) -> void:
	if restore_position and _active_object != null and is_instance_valid(_active_object):
		_active_object.position = _object_start_position
		_sync_position(_active_object)
	_active_pointer = -2
	_active_object = null
	_press_position = Vector2.ZERO
	_last_position = Vector2.ZERO
	_object_start_position = Vector2.ZERO
	_press_time_usec = 0
	_dragging = false
	_drag_config = {}
	_max_pointer_distance = 0.0
	_hold_fired = false


func _elapsed_seconds() -> float:
	return float(int(time_source.call()) - _press_time_usec) / 1000000.0 if _active_pointer != -2 else 0.0


func _run_is_current(run_id: int) -> bool:
	return puzzle_state != null and puzzle_state.run_id == run_id
