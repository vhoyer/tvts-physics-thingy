@tool
@icon("res://addons/godot-devkit/UI/ui_elements/wheel_picker_button/h_wheel_picker_button.svg")
class_name HWheelPickerButton
extends BaseButton

signal _model_updated()
signal item_selected(index: int)

@export
var selected: int = 0:
	set(value):
		selected = wrapi(value, 0, _items.size())
		_model_updated.emit()
		item_selected.emit(selected)


@export_group('Styling')
@export
var label_style_previous: String = '<'
@export
var label_style_next: String = '>'
@export_subgroup('label_settings', 'label_settings')
@export
var label_settings_focused:= LabelSettings.new()
@export
var label_settings_pressed:= LabelSettings.new()
@export
var label_settings_hover:= LabelSettings.new()
@export
var label_settings_disabled:= LabelSettings.new()


class Item extends RefCounted:
	var text: String
	var metadata: Variant

var _items: Array[Item]:
	get():
		if not _items:
			_items = []
		return _items

func add_item(text: String, metadata: Variant = null) -> int:
	var index = _items.size()

	var new_item = Item.new()
	new_item.text = text
	new_item.metadata = metadata

	_items.push_back(new_item)
	_model_updated.emit()
	return index

func remove_item(index: int) -> void:
	_items.remove_at(index)
	_model_updated.emit()

func clear_items() -> void:
	_items.resize(0)
	_model_updated.emit()

func get_item_metadata(index: int) -> Variant:
	return _items.get(index).metadata

func set_item_metadata(index: int, metadata: Variant) -> void:
	_items.get(index).metadata = metadata
	_model_updated.emit()

func get_item_text(index: int) -> String:
	return _items.get(index).text

func set_item_text(index: int, text: String) -> void:
	_items.get(index).text = text
	_model_updated.emit()

func get_index_by_metadata(metadata: Variant) -> int:
	return _items.find_custom(func(item: Item):
		return item.metadata == metadata)


var _layout: HBoxContainer
var _selected_text: Label
var _btn_prev: Button
var _btn_next: Button


func _init() -> void:
	self.pressed.connect(_select_next_item)
	self.ready.connect(func():
		self.focus_entered.connect(_on_focus_entered)
		self.focus_exited.connect(_on_focus_exited)
		self.mouse_entered.connect(_on_mouse_entered)
		self.mouse_exited.connect(_on_mouse_exited)
		self.button_down.connect(_on_pressed)
		self.button_up.connect(_on_released)

		item_selected.connect(_item_selected)

		_model_updated.connect(_update_view)
		_update_view())

	_layout = HBoxContainer.new()
	self.add_child(_layout)
	_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.resized.connect(func():
		self.custom_minimum_size = _layout.size)

	_btn_prev = Button.new()
	_layout.add_child(_btn_prev)
	_btn_prev.text = label_style_previous
	_btn_prev.flat = true
	_btn_prev.theme_type_variation = &"FlatButton"
	_btn_prev.focus_mode = Control.FOCUS_NONE
	_btn_prev.size = Vector2.ZERO
	_btn_prev.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	_btn_prev.pressed.connect(_select_prev_item)

	_selected_text = Label.new()
	_layout.add_child(_selected_text)
	_selected_text.text = ' '
	_selected_text.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	_btn_next = _btn_prev.duplicate()
	_layout.add_child(_btn_next)
	_btn_next.text = label_style_next
	_btn_next.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_btn_next.pressed.connect(_select_next_item)


func _update_view() -> void:
	if selected < _items.size():
		_selected_text.text = get_item_text(selected)
	else:
		_selected_text.text = ' '

func _on_focus_entered():
	_selected_text.label_settings = label_settings_focused

func _on_focus_exited():
	_selected_text.label_settings = null

func _on_mouse_entered():
	_selected_text.label_settings = label_settings_hover

func _on_mouse_exited():
	_selected_text.label_settings = null

func _on_pressed():
	_selected_text.label_settings = label_settings_pressed

func _on_released():
	if self.has_focus():
		_on_focus_entered()
	else:
		_selected_text.label_settings = null

func _on_disabled():
	_selected_text.label_settings = label_settings_disabled

func _on_enabled():
	_selected_text.label_settings = null


func _set(property: StringName, value: Variant) -> bool:
	if property == 'disabled':
		if value:
			_on_disabled()
		else:
			_on_enabled()
	return false


func _input(event: InputEvent) -> void:
	if not self.has_focus(): return

	if event.is_action_pressed('ui_left'):
		accept_event()
		_select_prev_item()
	elif event.is_action_pressed('ui_right'):
		accept_event()
		_select_next_item()


func _select_next_item() -> void:
	selected += 1
	self.grab_focus()

func _select_prev_item() -> void:
	selected -= 1
	self.grab_focus()


func _item_selected(index: int) -> void:
	pass
