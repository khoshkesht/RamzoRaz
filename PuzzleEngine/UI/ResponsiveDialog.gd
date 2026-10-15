extends PanelContainer

@export var scroll_path: NodePath = NodePath("Padding/Content/DetailsScroll")
@export var content_path: NodePath = NodePath("Padding/Content/DetailsScroll/Details")

func _ready() -> void:
	get_parent().resized.connect(_fit_width)
	var details := get_node(content_path) as Control
	details.minimum_size_changed.connect(func() -> void: _fit_width.call_deferred())
	$Padding/Content.minimum_size_changed.connect(func() -> void: _fit_width.call_deferred())
	_fit_width.call_deferred()

func _fit_width() -> void:
	var available := (get_parent() as Control).size.x
	if available > 0:
		custom_minimum_size.x = minf(1100.0, available * 0.70)
	var scroll := get_node(scroll_path) as ScrollContainer
	var details := get_node(content_path) as Control
	var available_height := (get_parent() as Control).size.y
	var padding: MarginContainer = $Padding
	var content: VBoxContainer = $Padding/Content
	var reserved := get_theme_stylebox("panel").get_minimum_size().y + padding.get_theme_constant("margin_top") + padding.get_theme_constant("margin_bottom")
	var visible_count := 0
	for child: Node in content.get_children():
		if child is Control and (child as Control).visible:
			visible_count += 1
			if child != scroll:
				reserved += (child as Control).get_combined_minimum_size().y
	reserved += maxi(0, visible_count - 1) * content.get_theme_constant("separation")
	scroll.custom_minimum_size.y = minf(details.get_minimum_size().y, minf(available_height * 0.40, maxf(0.0, available_height - reserved)))
