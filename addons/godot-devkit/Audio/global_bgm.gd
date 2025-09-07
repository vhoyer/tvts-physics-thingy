## class_name GlobalBGM
extends AudioStreamPlayer

var tween: Tween


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS


func push_bgm(remote: AudioStreamPlayer) -> void:
	var prop_list = [
		'volume_db',
		'pitch_scale',
		'stream_paused',
		'mix_target',
		'max_polyphony',
		'bus',
		'playback_type',
		'parameters/looping'
	]
	for prop in prop_list:
		self.set(prop, remote.get(prop))

	if self.stream == remote.stream:
		return

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, 'volume_linear', 0, 0.15)
	tween.tween_callback(func():
		self.stream = remote.stream
		self.play())
	tween.tween_property(self, 'volume_linear', remote.volume_linear, 0.15)

