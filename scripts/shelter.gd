extends Node3D

# Visual representation of a treefolk shelter
var shelter_data = null

func _ready():
	# Set up random appearance variations
	randomize_appearance()
	
	# Play build animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1, 1, 1), 0.5).from(Vector3(0, 0, 0))

func initialize(data):
	shelter_data = data
	
	# Set initial position if not attached to a branch
	if get_parent().name != "Branch":
		position = shelter_data.position

func randomize_appearance():
	# Randomize shelter appearance
	var color_variation = randf_range(0.8, 1.2)
	$ShelterModel.modulate = Color(
		color_variation, 
		color_variation * 0.8, 
		color_variation * 0.6
	)
	
	# Randomize rotation slightly for variety
	rotation.y = randf_range(-0.2, 0.2)
