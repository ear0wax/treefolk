extends TreeComponent

class_name RootComponent

# Root-specific properties
var root_depth: int = 0  # How deep the root goes
var nutrient_gathering: float = 1.0  # How much nutrients this root gathers
var water_gathering: float = 1.0  # How much water this root gathers
var spread_factor: float = 1.0  # How much this root spreads out
var root_length: float = 1.0  # Length of the root
var root_branches: int = 0  # Number of small branches on this root

func _ready():
	# Initialize root-specific properties
	update_root_properties()
	super._ready()

func update_root_properties():
	# Set base values based on root depth
	growth_rate = 1.0 - (root_depth * 0.1)  # Deeper roots grow slower
	max_growth_stage = 4 - min(root_depth, 3)  # Deeper roots can grow less
	
	# Adjust gathering abilities based on depth and growth
	nutrient_gathering = 1.0 + (root_depth * 0.5) + (growth_stage * 0.3)
	water_gathering = 1.0 + (root_depth * 0.3) + (growth_stage * 0.2)
	
	# Adjust spread based on growth stage
	spread_factor = 1.0 + (growth_stage * 0.3)
	
	# Root length increases with growth
	root_length = 1.0 + (growth_stage * 0.5) + (root_depth * 0.2)
	
	# Root branches increase with growth
	root_branches = growth_stage + root_depth

func base_thickness() -> float:
	return 1.2 - (root_depth * 0.2)  # Roots get thinner as they go deeper

func base_strength() -> float:
	return 15.0 - (root_depth * 1.5)  # Roots get slightly weaker as they go deeper

func base_max_weight() -> float:
	return 20.0 - (root_depth * 2.0)  # Roots support less weight as they go deeper

func gather_resources() -> Dictionary:
	# Calculate resources gathered by this root
	# Deeper roots gather more nutrients, longer roots gather more water
	var nutrient_factor = nutrient_gathering * (1.0 + root_depth * 0.2)
	var water_factor = water_gathering * (1.0 + root_length * 0.1)
	
	# Root branches increase overall gathering
	var branch_factor = 1.0 + (root_branches * 0.1)
	
	return {
		"nutrients": nutrient_factor * branch_factor,
		"water": water_factor * branch_factor
	}

func grow_longer(amount: float):
	# Increase root length
	root_length += amount
	update_root_properties()
	update_appearance()

func add_root_branch():
	# Add a small branch to this root
	root_branches += 1
	update_root_properties()
	update_appearance()

func update_appearance():
	# Update root appearance based on growth stage
	super.update_appearance()
	
	# Root-specific visual updates
	if visual_node and visual_node is Sprite3D:
		# Make roots spread out more as they grow
		visual_node.scale = Vector3(
			spread_factor,
			root_length,
			spread_factor
		)
		
		# Adjust color based on depth
		var depth_factor = 1.0 - (root_depth * 0.1)
		visual_node.modulate = Color(
			depth_factor,
			depth_factor,
			depth_factor,
			1.0
		)
