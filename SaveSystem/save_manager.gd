# class_name SaveManager
extends Node


var data: SaveData = SaveDataEmpty.new()


func load_data(_data: SaveData) -> void:
	data = _data if _data else SaveDataEmpty.new()



var config: ConfigData = ConfigData.new()

func _init() -> void:
	_register_volume_handlers()
	_register_screen_handlers()
	_register_language_handlers()


func _register_language_handlers() -> void:
	if Engine.is_editor_hint(): return

	config.set_on_config('language', func set_locale_from_config(locale: String):
		TranslationServer.set_locale(locale))


func _register_screen_handlers() -> void:
	if Engine.is_editor_hint(): return

	config.set_on_config('fullscreen', func set_window_mode_from_config(mode: int):
		DisplayServer.window_set_mode(mode))

func _register_volume_handlers() -> void:
	const search:= {
		'Master': 'volume_master',
		'BGM': 'volume_bgm',
		'SFX': 'volume_sfx',
	}

	var actuator:= func set_volume_from_config(volume: float, id: int):
		AudioServer.set_bus_volume_linear(id, volume)

	for id: int in AudioServer.bus_count:
		var bus_name:= AudioServer.get_bus_name(id)
		var mapped_config:= search.get(bus_name, '') as String
		if not mapped_config: continue
		config.set_on_config(mapped_config, actuator.bind(id))

