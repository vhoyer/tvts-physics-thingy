class_name ProfileNew
extends Control

@onready var profile_name: LineEdit = %ProfileName
@onready var remeber_me: CheckBox = %RemeberMe
@onready var label_error: Label = %LabelError
@onready var create: Button = %Create

var storage:= JSONStorage.new("profiles")

var list: Array = []

func _ready() -> void:
	_on_profile_name_text_changed('')
	list = Profile.list_profiles()


func _on_cancel_pressed() -> void:
	StageManager.go_back()


func _on_create_pressed() -> void:
	if remeber_me.button_pressed:
		storage.set_item('remember', profile_name.text)

	var profile = Profile.get_config(profile_name.text)
	profile.set_item('twitch_username', %TwitchUsername.text)
	profile.set_item('twitch_broadcaster', %TwitchBroadcaster.text)

	# TODO: this should go to tts view
	StageManager.push_stage("uid://c4isnucsiucux", {
		'profile': profile_name.text
	})


func _on_profile_name_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		var has_in_list: bool = list.has(new_text)
		label_error.visible = has_in_list
		create.disabled = has_in_list
	else:
		create.disabled = true
		label_error.hide()
		
