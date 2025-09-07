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
