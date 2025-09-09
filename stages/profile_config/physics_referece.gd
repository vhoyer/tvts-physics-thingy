extends RigidBody3D


@onready
var timer: Timer = $Timer

@export
var force_magnitute: float = 100


var starting_transform: Transform3D


func _ready() -> void:
	self.sleeping = true
	starting_transform = self.transform
	timer.timeout.connect(_on_timeout)
	Yatc.channel_points_reward_redeemed.connect(_on_channel_points_reward_redeemed)


func _on_timeout() -> void:
	self.sleeping = true
	self.transform = starting_transform


func simulate() -> void:
	timer.start()

	var rand_dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	self.apply_central_force(Vector3.UP * force_magnitute)
	self.apply_torque_impulse(rand_dir)


func _on_channel_points_reward_redeemed(reward: YatcPointsRedeemedReward) -> void:
	if reward.reward_id != Profile.config.push_redeem: return
	simulate()

