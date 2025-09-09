class_name GodotVTubeStudioSettings
extends RefCounted

const ROOT = 'godot_vtube_studio'
const CONFIG:= {
	'plugin_name': {
		'category': 'config',
		'basic': true,
		'default': '',
		'type': TYPE_STRING,
		'hint': PROPERTY_HINT_PLACEHOLDER_TEXT,
		'hint_string': 'e.g.: my incredible plugin',
	},
	'plugin_developer': {
		'category': 'config',
		'basic': true,
		'default': '',
		'type': TYPE_STRING,
		'hint': PROPERTY_HINT_PLACEHOLDER_TEXT,
		'hint_string': 'e.g.: my incredible name',
	},
}


static func _get_key(name: String) -> String:
	return '%s/%s/%s' % [
		ROOT,
		CONFIG[name].category,
		name]


static func setup_settings() -> void:
	for name: String in CONFIG.keys():
		var config = CONFIG[name]
		var key = _get_key(name)
		ProjectSettings.set_setting(key, _get_config(name))
		ProjectSettings.set_initial_value(key, config.default)
		ProjectSettings.set_as_basic(key, config.basic)
		ProjectSettings.add_property_info({
			"name": key,
			"type": config.type,
			"hint": config.hint,
			"hint_string": config.hint_string,
		})


static func _get_config(name: String) -> Variant:
	var key = _get_key(name)
	if ProjectSettings.has_setting(key):
		return ProjectSettings.get_setting_with_override(key)
	else:
		return CONFIG[name].default


static var plugin_name: String:
	get(): return _get_config('plugin_name')


static var plugin_developer: String:
	get(): return _get_config('plugin_developer')
