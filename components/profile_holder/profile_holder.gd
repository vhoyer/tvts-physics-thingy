@tool
class_name AccountHolder
extends VBoxContainer


const BLANK_PROFILE_PICTURE = preload("uid://j75en6s12yga")
const SQUARE_PLUS_SHARP_SOLID = preload("uid://dii38nk3t5kvo")

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

signal _model_updated()
signal pressed()

@export
var add_profile: bool = false:
	set(value):
		add_profile = value
		_model_updated.emit()

@export
var profile_picture: Texture2D = BLANK_PROFILE_PICTURE:
	set(value):
		profile_picture = value
		_model_updated.emit()

@export
var profile_name: String = 'ironmouse':
	set(value):
		profile_name = value
		_model_updated.emit()


func _ready() -> void:
	view_updated()
	_model_updated.connect(view_updated)
	pressed.connect(_pressed)
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)


func view_updated() -> void:
	if add_profile:
		texture_rect.texture = SQUARE_PLUS_SHARP_SOLID
		label.text = tr('Add Profile')
	else:
		texture_rect.texture = profile_picture
		label.text = profile_name



func _pressed() -> void:
	pass


var hover_tween: Tween

func hover_animation(target: int) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	hover_tween.tween_property(self, 'theme_override_constants/separation', target, 0.3)

func _mouse_entered() -> void:
	hover_animation(16)

func _mouse_exited() -> void:
	hover_animation(4)


func _gui_input(event: InputEvent) -> void:	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed.emit()
	elif event.is_action_pressed("ui_select") or event.is_action_pressed("ui_accept"):
		pressed.emit()
