class_name StatusReporter
extends RefCounted

const DEFAULT = 'waiting'

signal changed(id: String, status: String)

var statuses: Dictionary[String, String] = {}

func report(id: String, status: String) -> void:
	if statuses.get(id) == status: return
	statuses.set(id, status)
	changed.emit(id, status)

func get_status(id: String) -> String:
	return statuses.get(id, DEFAULT)

func all_ok() -> bool:
	return statuses.values().all(func(item): return item == 'ok')

func any_error() -> bool:
	return statuses.values().any(func(item): return item == 'error')
