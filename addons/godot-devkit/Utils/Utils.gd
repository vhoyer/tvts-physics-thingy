class_name Util


static func remove_children(node: Node, include_internal: bool = false):
	var free_me_later = []

	if node.is_inside_tree():
		for child in node.get_children(include_internal):
			node.remove_child(child)
			free_me_later.push_back(child)
		await node.get_tree().process_frame
	else:
		free_me_later = node.get_children(include_internal)

	for child: Node in free_me_later:
		child.queue_free()

static func to_token_name(original: String) -> String:
	return original.to_lower()\
		.replace('!', '')\
		.replace('.', '')\
		.replace(',', '')\
		.replace('/', '')\
		.replace('(', '')\
		.replace(')', '')\
		.replace(' ', '_')

static func time_display(seconds: float) -> String:
	var h = floor(seconds / 3600)
	var mins = fmod(seconds, 3600) / 60
	var s = fmod(seconds, 60)
	var ms = fmod(seconds, 1) * 1000
	return "%02d:%02d:%02d.%03d" % [h, mins, s, ms]

static func parse_time_display(time_str: String) -> float:
	# Split milliseconds from the rest
	var time_parts = time_str.split(".")
	if time_parts.size() != 2:
		return -1.0  # Invalid format

	var main_time = time_parts[0]
	var milliseconds = time_parts[1].substr(0, 3)  # Ensure only 3 digits

	# Split hours, minutes, seconds
	var components = main_time.split(":")
	if components.size() != 3:
		return -1.0  # Invalid format

	# Convert all parts to integers
	var h = components[0].to_int()
	var m = components[1].to_int()
	var s = components[2].to_int()
	var ms = milliseconds.to_int()

	# Calculate total seconds
	return h * 3600.0 + m * 60.0 + s + ms / 1000.0

static func generate_uuid() -> String:
	var uuid = ""
	for i in 16:
		uuid += "%02x" % randi_range(0, 255)
	return uuid.insert(8, "-").insert(13, "-").insert(18, "-")
