@tool
extends TextureRect
class_name InputPrompt

enum Type {
	CONTROLLER,
	KEYBOARD,
}

@export var do_auto_detect: bool = true

@export
var default_type: Type:
	set(value):
		default_type = value
		current_type = value
		texture_change()

var current_type: Type:
	set(value):
		current_type = value
		texture_change()


@export
var controller_texture: Texture2D:
	set(value):
		controller_texture = value
		texture_change()
@export
var keyboard_texture: Texture2D:
	set(value):
		keyboard_texture = value
		texture_change()


func _ready() -> void:
	current_type = default_type
	if Engine.is_editor_hint(): return
	if do_auto_detect:
		current_type = Type.CONTROLLER \
			if Input.get_connected_joypads().size() > 0 \
			else Type.KEYBOARD


func _input(event: InputEvent) -> void:
	if not do_auto_detect: return

	if (event is InputEventJoypadButton) or (event is InputEventJoypadMotion):
		current_type = Type.CONTROLLER
	else:
		current_type = Type.KEYBOARD

	texture_change()


func texture_change() -> void:
	match current_type:
		Type.CONTROLLER:
			self.texture = controller_texture
		Type.KEYBOARD:
			self.texture = keyboard_texture
