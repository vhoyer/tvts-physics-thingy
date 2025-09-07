@tool
class_name CreditsRoll
extends ScrollContainer

signal _model_updated()
signal finished()

@export
var pixels_per_second: float = 100

@export_group('editor')

@export
var auto_scroll_enabled: bool = true

@export
var preview_margin: int = 16:
	set(value):
		preview_margin = value
		_model_updated.emit()


@onready
var scrolling_margin:= self.get_node_or_null(^'ScrollingMargin')

@onready
var vertical_margin: int:
	get():
		if Engine.is_editor_hint():
			return preview_margin
		else:
			return int(self.size.y)



func _init() -> void:
	self.ready.connect(_on_ready)
	self.child_entered_tree.connect(update_configuration_warnings.unbind(1))
	self.child_exiting_tree.connect(update_configuration_warnings.unbind(1))


func _get_configuration_warnings() -> PackedStringArray:
	var warns = PackedStringArray()
	for child: Node in self.get_children():
		if child != scrolling_margin:
			warns.push_back('All children must be placed under the "ScrollingMargin" node')
			break
	return warns


func _on_ready() -> void:
	self.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	self.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	if not scrolling_margin:
		scrolling_margin = MarginContainer.new()
		scrolling_margin.name = 'ScrollingMargin'
		self.add_child(scrolling_margin)
		scrolling_margin.owner = self.owner

	scrolling_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrolling_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL

	self.item_rect_changed.connect(_update_view)
	_model_updated.connect(_update_view)
	_update_view()


func _update_view() -> void:
	scrolling_margin.add_theme_constant_override('margin_top', vertical_margin)
	scrolling_margin.add_theme_constant_override('margin_bottom', vertical_margin)
	auto_scroll_enabled = true

var scroll_accumulator: float = 0:
	set(value):
		scroll_accumulator = clamp(value, 0, scrolling_margin.size.y)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not auto_scroll_enabled: return

	var old_scroll = self.scroll_vertical

	scroll_accumulator += pixels_per_second * delta
	self.scroll_vertical = int(scroll_accumulator)

	if old_scroll == self.scroll_vertical:
		auto_scroll_enabled = false
		finished.emit()
