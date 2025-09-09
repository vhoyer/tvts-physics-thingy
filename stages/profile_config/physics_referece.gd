extends RigidBody3D


@onready
var timer: Timer = $Timer

@export
var force_magnitute: float = 100

@export
var gravity_curve: Curve


var starting_transform: Transform3D

@export
var offset: Vector3 = Vector3(0, 4, -4)


func _ready() -> void:
	offset = self.global_position
	self.freeze = true
	starting_transform = self.transform
	timer.timeout.connect(_on_timeout)
	Yatc.channel_points_reward_redeemed.connect(_on_channel_points_reward_redeemed)


func _on_timeout() -> void:
	self.transform = starting_transform
	sync_back(0.3)
	self.freeze = true


func simulate() -> void:
	if self.freeze:
		starting_transform = self.transform
	timer.start()
	self.freeze = false
	self.sleeping = true
	await get_tree().process_frame

	var rand_dir = Vector3(0, 0, randf_range(-0.5, 0.5) * PI)
	self.apply_torque_impulse(rand_dir)

	self.apply_central_force(Vector3(randf_range(-0.25, 0.25), 1, randf_range(-0.10, 0.025)) * force_magnitute)


func _on_channel_points_reward_redeemed(reward: YatcPointsRedeemedReward) -> void:
	if reward.reward_id != Profile.config.push_redeem: return
	simulate()


func _process(_delta: float) -> void:
	if self.freeze:
		var vts = GodotVTS.model.position
		self.global_position = Vector3(vts.x, vts.y, (GodotVTS.model.size / 100)) * 4 + offset
	else:
		sync_back()


func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	self.gravity_scale = gravity_curve.sample_baked(self.linear_velocity.y)


func sync_back(duration:= 0.0) -> void:
	var unstransformed = (self.global_position - offset)/4
	var unstranssized = unstransformed.z * 100

	var new_transform = GodotVTSModel.new()
	new_transform.position = Vector2(unstransformed.x, unstransformed.y)
	new_transform.size = unstranssized
	new_transform.rotation = -self.rotation_degrees.z
	GodotVTS.move_model(new_transform, false, duration)


func _on_push_pressed() -> void:
	simulate()
