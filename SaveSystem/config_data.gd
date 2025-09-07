class_name ConfigData
extends SaveData

const SAVE_ID:= 'config'

const DEFAULT_META:= {
	'default': null,
}

var _meta: Dictionary[String, Dictionary] = {}
var _subscriptions: Dictionary = {}

func _init() -> void:
	super(-1)
	# override base memory objects with a new better key for configurations
	_long_term = JSONStorage.new('', SAVE_ID)
	_short_term = InMemoryStorage.new('', SAVE_ID)
	_short_term._override_with(_long_term)

	register_config('volume_master', 0.5)
	register_config('volume_bgm', 0.5)
	register_config('volume_sfx', 0.5)
	register_config('volume_voice', 0.5)
	register_config('fullscreen', DisplayServer.WINDOW_MODE_FULLSCREEN)
	register_config('language', 'en')
	register_config('screen_shake', 1.0)

## override config is always not empty
func empty() -> bool:
	return false


func register_config(key: String, default: Variant) -> void:
	_meta.set(key, {
		'default': default,
		})

func get_config(key: String) -> Variant:
	var meta:= _meta.get(key, DEFAULT_META) as Dictionary
	var default_value = meta.get('default', DEFAULT_META['default'])
	return _short_term.get_item(key, default_value)

func set_config(key: String, value: Variant) -> void:
	if _short_term.get_item(key, null) == value:
		return
	_short_term.set_item(key, value)
	_subscriptions.get(key, _dummy_listener.unbind(1)).call(value)
	changed.emit(key)

func _dummy_listener() -> void:
	pass


func set_on_config(key: String, fn: Callable) -> void:
	_subscriptions.set(key, fn)
	fn.call(get_config(key))


var volume_master: float:
	get(): return get_config('volume_master')
	set(value): set_config('volume_master', value)

var volume_bgm: float:
	get(): return get_config('volume_bgm')
	set(value): set_config('volume_bgm', value)

var volume_sfx: float:
	get(): return get_config('volume_sfx')
	set(value): set_config('volume_sfx', value)

var volume_voice: float:
	get(): return get_config('volume_voice')
	set(value): set_config('volume_voice', value)

var fullscreen: int:
	get(): return get_config('fullscreen')
	set(value): set_config('fullscreen', value)

var language: String:
	get(): return get_config('language')
	set(value): set_config('language', value)

var screen_shake: float:
	get(): return get_config('screen_shake')
	set(value): set_config('screen_shake', value)
