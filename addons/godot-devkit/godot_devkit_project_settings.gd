class_name GodotDevkitSettings
extends RefCounted

const ROOT = 'godot_devkit'
const CONFIG:= {
	'transition_scene': '%s/stage_manager/transition_scene' % ROOT,
}


static func setup_settings() -> void:
	ProjectSettings.set_setting(CONFIG['transition_scene'], transition_scene)
	ProjectSettings.set_initial_value(CONFIG['transition_scene'], transition_scene)
	ProjectSettings.set_as_basic(CONFIG['transition_scene'], true)
	ProjectSettings.add_property_info({
		"name": CONFIG['transition_scene'],
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tscn,*.scn"
	})


static func get_config(id: String, default: Variant = null) -> Variant:
	var key = "%s/%s" % [ROOT, id]
	if ProjectSettings.has_setting(key):
		return ProjectSettings.get_setting_with_override(key)
	else:
		return default


static var transition_scene: String:
	get(): return get_config('stage_manager/transition_scene', 'res://addons/godot-devkit/StageManager/transition/stage_manager_transition.tscn')
