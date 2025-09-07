class_name GlobalBGMRemote
extends AudioStreamPlayer


func _ready() -> void:
	GlobalBGM.push_bgm(self)
	self.playing = false
