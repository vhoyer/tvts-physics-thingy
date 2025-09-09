class_name Profile
extends Object

const PROFILES_DIR = 'profiles'
const PROFILES_DIR_PATH = 'user://%s' % PROFILES_DIR

static var _storage:= InMemoryStorage.new('profile')
static var current: String:
	set(value):
		_storage.set_item('current', value)
	get():
		return _storage.get_item('current', '')


static var config: Config:
	get():
		if not config:
			config = Config.new(get_config(current, ''))
		return config


static func get_current_config(prefix:= '') -> JSONStorage:
	assert(current != '', 'Error: no profile logged-in')
	return get_config(current, prefix)


static func get_config(profile: String, prefix: String = '') -> JSONStorage:
	return JSONStorage.new(prefix, '%s/%s/config' % [PROFILES_DIR, profile])


static func list_profiles() -> PackedStringArray:
	var dir:= DirAccess.open(PROFILES_DIR_PATH)
	if dir == null:
		return []
	return dir.get_directories()


class Config:
	var config: JSONStorage
	var memory: InMemoryStorage

	func _init(_config: JSONStorage) -> void:
		self.config = _config
		self.memory = InMemoryStorage.new('', Profile.current)
		self.memory._override_with(self.config)

	func save() -> void:
		config._override_with(memory)
	func reset() -> void:
		memory._override_with(config)

	var push_redeem: String:
		get():
			return memory.get_item('push_redeem', '')
		set(value):
			memory.set_item('push_redeem', value)

	var port: int:
		get():
			return memory.get_item('port', 8001)
		set(value):
			memory.set_item('port', value)
