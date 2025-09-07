class_name SaveDataEmpty
extends SaveData

func _init() -> void:
	_short_term = InMemoryStorage.new('', 'save_empty')


func consolidate_memory() -> void:
	pass


func remember() -> void:
	pass


func empty() -> bool:
	return true


func increment_deaths() -> void:
	pass


func complete_levels() -> void:
	pass
