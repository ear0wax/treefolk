extends TreeComponent

class_name BranchComponent

# Branch-specific properties
var branch_level: int = 0  # Distance from trunk (0 = directly on trunk)
var branch_angle: float = 0.0  # Angle of the branch
var branch_direction: int = 1  # 1 = right, -1 = left
var stress_factor: float = 1.0  # How much this branch is stressed (affects appearance)
var has_leaves: bool = false  # Whether this branch has leaves
var leaf_density: float = 0.0  # Density of leaves (0-1)
var leaf_health: float = 1.0  # Health of leaves (0-1)
var seasonal_state: int = 0  # 0=spring, 1=summer, 2=fall, 3=winter

func _ready():
	# Initialize branch-specific properties
	update_branch_properties()
	super._ready()

func update_branch_properties():
	# Set base values based on branch level
	growth_rate = 1.0 - (branch_level * 0.2)  # Branches further from trunk grow slower
	max_growth_stage = 3 - min(branch_level, 2)  # Branches further from trunk grow less
	
	# Adjust strength and weight capacity based on level
	strength = base_strength() * (1.0 - (branch_level * 0.25))
	max_weight = base_max_weight() * (1.0 - (branch_level * 0.2))
	
	# Leaf properties - branches start getting leaves after growth stage 1
	if growth_stage > 0:
		has_leaves = true
		if leaf_density == 0:  # Initialize leaf density if it hasn't been set
			leaf_density = 0.3  # Start with some leaves

func base_thickness() -> float:
	return 1.0 - (branch_level * 0.3)  # Branches get thinner further from trunk

func base_strength() -> float:
	return 8.0 - (branch_level * 2.0)  # Branches get weaker further from trunk

func base_max_weight() -> float:
	return 12.0 - (branch_level * 3.0)  # Branches can support less weight further out

func own_weight() -> float:
	# Calculate branch weight including leaves
	var base_weight = super.own_weight()
	
	if has_leaves:
		base_weight += leaf_density * 0.5  # Leaves add weight
	
	return base_weight

func check_structural_integrity():
	# Branch-specific integrity checks
	super.check_structural_integrity()
	
	# Calculate stress based on angle and weight
	var angle_stress = abs(sin(branch_angle)) * current_weight * 0.2
	stress_factor = current_weight / max_weight + angle_stress
	
	# Branches droop under weight
	update_branch_angle()

func update_branch_angle():
	# Make branches droop under weight
	var base_angle = branch_direction * (PI * 0.25)  # Base angle (45 degrees)
	var droop = min(stress_factor * 0.2, 0.4)  # Maximum droop of 0.4 radians
	
	# Apply the drooping effect
	var target_angle = base_angle + droop
	
	# Smoothly transition to the new angle
	get_parent().rotation.z = lerp(get_parent().rotation.z, target_angle, 0.1)

func set_leaf_density(new_density: float):
	# Set the leaf density and update appearance
	leaf_density = new_density
	update_appearance()
	
	print("Branch leaf density updated to: " + str(leaf_density))

func update_seasonal_state(season: int):
	# Update the seasonal state of the branch
	seasonal_state = season
	update_appearance()

func update_appearance():
	# Update branch appearance based on growth stage
	super.update_appearance()
	
	# Branch-specific visual updates
	if visual_node and visual_node is Sprite3D:
		# Update leaf appearance based on density and health
		if has_leaves:
			# Adjust color based on leaf density, health, and season
			var leaf_color = Color(1.0, 1.0, 1.0)  # Base color
			
			match seasonal_state:
				0:  # Spring - fresh green
					leaf_color = Color(0.7, 1.0, 0.7)
				1:  # Summer - deep green
					leaf_color = Color(0.5, 0.9, 0.5)
				2:  # Fall - orange/red
					leaf_color = Color(1.0, 0.7, 0.3)
				3:  # Winter - brown/sparse
					leaf_color = Color(0.7, 0.6, 0.5)
			
			# Apply leaf density as alpha in the green channel
			var density_factor = leaf_density * leaf_health
			
			visual_node.modulate = Color(
				1.0,
				1.0 + (leaf_color.g - 1.0) * density_factor,
				1.0 + (leaf_color.b - 1.0) * density_factor,
				1.0
			)
		
		# Show stress through slight color changes
		if stress_factor > 0.7:
			visual_node.modulate = visual_node.modulate * Color(1.1, 0.9, 0.9, 1.0)
