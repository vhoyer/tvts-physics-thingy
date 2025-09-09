extends SpinBox


func _ready() -> void:
	self.value = Profile.config.port
	self.value_changed.connect(_on_value_changed)


func _on_value_changed(port: float) -> void:
	Profile.config.port = int(port)

