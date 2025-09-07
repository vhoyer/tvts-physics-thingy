class_name SyncedAudioStreamPlayer
extends AudioStreamPlayer

signal beat(position_in_beats: int)


## bpm of the audio
@export var bpm: int = 120


## how many beats exist in a bar
@export var beats_in_bar: int = 4


@export
var note_division: int = 1:
	set(value):
		note_division = value
		note_position = int(floor(sec_position / sec_per_note_division))

# Tracking the beat and song position
@onready var sec_per_beat: float:
	get(): return 60.0 / bpm


# Tracking the beat and song position
@onready var sec_per_note_division: float:
	get(): return 60.0 / bpm / note_division


var beat_in_bar:= 0


var sec_position:= 0.0:
	set(value):
		sec_position = value
		beat_position = int(floor(sec_position / sec_per_beat))
		note_position = int(floor(sec_position / sec_per_note_division))


var note_position:= 1


var beat_position:= 1:
	set(value):
		if beat_position == value: return
		beat_position = value

		beat_in_bar += 1
		if beat_in_bar > beats_in_bar:
			beat_in_bar = 1

		beat.emit(beat_position)


func sec_position_from_beat(beat: int) -> float:
	return beat * sec_per_beat


func get_closest_in_beat_timestamp() -> float:
	return sec_position_from_beat(beat_position)


func get_closest_timestamp_in_note_division() -> float:
	return sec_per_note_division * note_position


func _ready() -> void:
	self.finished.connect(func():
		sec_position = self.stream.get_length())


func _process(_delta):
	if !self.playing: return

	var new_sec = (self.get_playback_position() + AudioServer.get_time_since_last_mix()) - AudioServer.get_output_latency()
	new_sec -= AudioServer.get_output_latency()
	sec_position = new_sec
