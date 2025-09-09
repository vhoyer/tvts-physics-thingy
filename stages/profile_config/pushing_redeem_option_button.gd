extends OptionButton


var twitch_channel: YatcChannel:
	get():
		return Yatc.user


func _ready() -> void:
	for reward: YatcPointsCustomReward in twitch_channel.custom_rewards:
		var idx:= self.item_count
		self.add_item(reward.title)
		self.set_item_metadata(idx, reward.id)
	self.select(0)

	# select current saved push redeem
	if Profile.config.push_redeem:
		for i in self.item_count:
			var id = self.get_item_metadata(i)
			if id == Profile.config.push_redeem:
				self.select(i)
				break

	self.item_selected.connect(_on_item_selected)


func _on_item_selected(idx: int) -> void:
	var id = self.get_item_metadata(idx)
	Profile.config.push_redeem = id

