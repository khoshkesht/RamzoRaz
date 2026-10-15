extends PanelContainer

func _ready() -> void:
	get_parent().resized.connect(_fit)
	_fit.call_deferred()

func _fit() -> void:
	var available := (get_parent() as Control).size.x
	if available > 0:
		custom_minimum_size.x = minf(1050.0, available * 0.75)
