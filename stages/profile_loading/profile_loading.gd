extends Control

const LOAD_STATE_REPORTER = preload("uid://cqjip38ayguqc")


@onready var loader_holder: VBoxContainer = %LoaderHolder

@export_file("*.tscn", "*.scn")
var next_scene: String

var reporters: Array[StatusReporter] = []
var done_timer: SceneTreeTimer

func _ready() -> void:
	var profile: String = StageManager.get_payload('profile', '')

	if not profile:
		push_error('Error: profile expected to be passed as payload to profile loading stage')

	Profile.current = profile

	loader_twitch()
	loader_vts()


func loader_vts() -> void:
	var inst = LOAD_STATE_REPORTER.instantiate()
	loader_holder.add_child(inst)
	inst.id = GodotVTS.GVTS
	inst.label = 'VtubeStudio'
	inst.reporter = GodotVTS.status

	reporters.push_back(GodotVTS.status)

	await get_tree().process_frame

	GodotVTS.sign_in()


func loader_twitch() -> void:
	var username = Profile.config.twitch_username
	if not username:
		push_error('Error: twitch expects username present, but none found')

	var inst = LOAD_STATE_REPORTER.instantiate()
	loader_holder.add_child(inst)
	inst.id = Yatc.YATC
	inst.label = 'Twitch'
	inst.reporter = Yatc.status

	reporters.push_back(Yatc.status)

	await get_tree().process_frame

	Yatc.sign_in(Profile.config.twitch_username, Profile.config.twitch_broadcaster)


func _on_done_detector_timeout() -> void:
	if reporters.all(func(reporter): return reporter.all_ok()):
		if not done_timer:
			done_timer = get_tree().create_timer(1)
			await done_timer.timeout
			StageManager.push_stage(next_scene)
