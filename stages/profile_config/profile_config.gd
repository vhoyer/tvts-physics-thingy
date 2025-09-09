extends Node


@onready
var aspect_ratio_container: AspectRatioContainer = %AspectRatioContainer


func _ready() -> void:
	aspect_ratio_container.ratio = GodotVTS.window_size.aspect()
	if Profile.config.push_redeem:
		set_background(true)


func _on_status_indicator_pressed(mouse_button: int, _mouse_position: Vector2i) -> void:
	if mouse_button == MOUSE_BUTTON_LEFT:
		set_background(false)


func set_background(is_background: bool) -> void:
	if is_background:
		get_tree().root.unfocusable = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	else:
		get_tree().root.unfocusable = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_hide_window_pressed() -> void:
	Profile.config.reset()
	set_background(true)


func _on_save_pressed() -> void:
	Profile.config.save()
	set_background(true)
