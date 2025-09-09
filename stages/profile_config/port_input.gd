extends SpinBox


func _ready() -> void:
	self.value = Profile.config.vts_port
	self.value_changed.connect(_on_value_changed)


func _on_value_changed(port: float) -> void:
	Profile.config.vts_port = int(port)

