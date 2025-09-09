class_name GodotVTSModel
extends RefCounted


var model_id: String
var model_name: String


var position: Vector2:
	set(value):
		position = value.clamp(Vector2(-1, -1), Vector2(1, 1))


var rotation: float:
	set(value):
		rotation = wrap(value, -360, 360)


var size: float:
	set(value):
		size = clamp(value, -100, 100)
