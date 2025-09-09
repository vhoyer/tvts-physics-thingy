extends Control


const PROFILE_HOLDER = preload("res://components/profile_holder/profile_holder.tscn")


@onready var profile_list: HBoxContainer = %ProfileList


var storage:= JSONStorage.new("profiles")


func _ready() -> void:
	var list = Profile.list_profiles()

	var remember_me = storage.get_item('remember', '')
	if remember_me:
		StageManager.push_stage("uid://c4isnucsiucux", {
			'profile': remember_me,
		})

	for profile_name: String in list:
		var inst = PROFILE_HOLDER.instantiate()
		profile_list.add_child(inst)
		inst.pressed.connect(build_on_profile_pressed(profile_name))
		inst.profile_name = profile_name


func build_on_profile_pressed(profile_name: String) -> Callable:
	return func() -> void:
		storage.set_item('remember', profile_name)
		StageManager.push_stage("uid://c4isnucsiucux", {
			'profile': profile_name,
		})


func _on_add_account_pressed() -> void:
	StageManager.push_stage("uid://bto1k33xe0wh5")
