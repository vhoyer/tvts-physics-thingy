extends RigidBody3D


@onready
var timer: Timer = $Timer

@export
var force_magnitute: float = 100


var starting_transform: Transform3D


func _ready() -> void:
	self.freeze = true
	starting_transform = self.transform
	timer.timeout.connect(_on_timeout)
	Yatc.channel_points_reward_redeemed.connect(_on_channel_points_reward_redeemed)


func _on_timeout() -> void:
	self.transform = starting_transform
	self.freeze = true


func simulate() -> void:
	timer.start()
	self.freeze = false
	self.sleeping = true
	await get_tree().process_frame

	var rand_dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	self.apply_central_force(Vector3.UP * force_magnitute)
	self.apply_torque_impulse(rand_dir)


func _on_channel_points_reward_redeemed(reward: YatcPointsRedeemedReward) -> void:
	if reward.reward_id != Profile.config.push_redeem: return
	starting_transform = self.transform
	simulate()


func _process(_delta: float) -> void:
	if self.freeze:
		var vts = GodotVTS.model.position
		self.global_position = Vector3(vts.x, vts.y, (GodotVTS.model.size / 100)) * 4 + Vector3(0, 4, -4)
	pass
