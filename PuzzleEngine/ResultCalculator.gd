class_name PuzzleResultCalculator
extends RefCounted

static func calculate(level_id: int, elapsed_usec: int, limit_usec: int, base_score: int, hint_received: bool = false) -> Dictionary:
	if limit_usec <= 0 or elapsed_usec < 0 or elapsed_usec >= limit_usec:
		return {}
	# Integer comparisons preserve the exact 10%, 30% and 60% boundaries.
	var stars := 3 if elapsed_usec * 10 <= limit_usec * 3 else (2 if elapsed_usec * 10 <= limit_usec * 6 else 1)
	var raw_score := float(base_score)
	if elapsed_usec * 10 > limit_usec:
		raw_score *= float(limit_usec - elapsed_usec) / (float(limit_usec) * 0.9)
	return {"level_id": level_id, "score": clampi(int(floor(raw_score + 0.5)), 0, base_score), "stars": stars, "elapsed_seconds": elapsed_usec / 1000000.0, "hint_received": hint_received}
