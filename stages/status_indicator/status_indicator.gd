extends StatusIndicator


func _ready() -> void:
	get_tree().root.unfocusable = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
