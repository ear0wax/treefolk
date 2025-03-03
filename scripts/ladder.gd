extends Node3D

# Visual representation of a rope ladder
var ladder_data = null

func _ready():
	# Play build animation
	var tween = create_tween()
	tween.tween_property(self, "scale:y", 1, 0.5).from(0)

func initialize(data):
	ladder_data = data
	
	# Set position
	position = data.position
	
	# Find the connected trunk sections
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	var start_trunk = null
	var end_trunk = null
	
	for part in tree_parts:
		if part.get_instance_id() == ladder_data.start_id:
			start_trunk = part
		elif part.get_instance_id() == ladder_data.end_id:
			end_trunk = part
	
	if start_trunk and end_trunk:
		# Orient the ladder between the two trunk sections
		look_at_from_position(position, end_trunk.global_position, Vector3.UP)
		
		# Scale the ladder to match the distance
		var distance = start_trunk.global_position.distance_to(end_trunk.global_position)
		scale.y = distance / 2.0  # Adjust based on your ladder model
