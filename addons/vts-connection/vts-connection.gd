@tool
extends EditorPlugin

const autoload_singletons = [
	['GodotVTS', "res://addons/vts-connection/vts.gd"],
]


func _enable_plugin() -> void:
	for autoload in autoload_singletons:
		add_autoload_singleton.call(autoload[0], autoload[1])


func _disable_plugin() -> void:
	for autoload in autoload_singletons:
		remove_autoload_singleton(autoload[0])


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
