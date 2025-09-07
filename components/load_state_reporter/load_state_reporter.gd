class_name LoadStateReporter
extends VBoxContainer

signal _model_updated()


@onready var label_name: Label = %LabelName
@onready var label_state: Label = %LabelState
@onready var sub_loaders_holder: VBoxContainer = %SubLoadersHolder


@export
var id: String = '':
	set(value):
		id = value
		_model_updated.emit()

@export
var label: String = '':
	set(value):
		label = value
		_model_updated.emit()

@export
var status: String = StatusReporter.DEFAULT:
	set(value):
		status = value
		_model_updated.emit()

var reporter: StatusReporter = StatusReporter.new():
	set(value):
		if reporter.changed.is_connected(_status_changed):
			reporter.changed.disconnect(_status_changed)
		reporter = value
		reporter.changed.connect(_status_changed)


var sub_loaders: Dictionary[String, LoadStateReporter] = {}


func _ready() -> void:
	update_view()
	_model_updated.connect(update_view)


func update_view() -> void:
	label_name.text = label if label else id
	label_state.text = status


func _status_changed(report_id: String, report_status: String) -> void:
	if id == report_id:
		status = report_status
	elif report_id.begins_with('%s.' % id):
		if sub_loaders.has(report_id): return
		var THIS_SCENE = load('uid://cqjip38ayguqc')
		var inst = THIS_SCENE.instantiate()
		inst.id = report_id
		inst.label = report_id.split('.', false, 1).get(1)
		inst.reporter = reporter
		sub_loaders_holder.add_child(inst)
		sub_loaders.set(report_id, inst)
	pass
