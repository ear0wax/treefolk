extends TreeComponent

class_name TrunkComponent

# Trunk-specific properties
var height_level: int = 0  # Position in the trunk stack (0 = bottom)
var branch_capacity: int = 2  # How many branches this trunk section can support
var branches_attached: int = 0  # Current number of attached branches
var ring_count: int = 0  # Number of growth rings
var diameter_multiplier: float = 1.0  # Multiplier for trunk diameter based on rings

func _ready():
	# Initialize trunk-specific properties
	update_trunk_properties()
	super._ready()

func update_trunk_properties():
	# Set base values based on height level
	growth_rate = 1.0 - (height_level * 0.1)  # Lower sections grow faster
	max_growth_stage = 4 - min(height_level, 3)  # Lower sections can grow more
	
	# Adjust strength and weight capacity based on height and rings
	strength = base_strength() * (1.0 - (height_level * 0.15)) * (1.0 + ring_count * 0.2)
	max_weight = base_max_weight() * (1.0 - (height_level * 0.1)) * (1.0 + ring_count * 0.15)
	
	# Update branch capacity based on trunk diameter
	branch_capacity = 2 + growth_stage + int(ring_count * 0.5)

func base_thickness() -> float:
	return (1.5 - (height_level * 0.2)) * diameter_multiplier  # Lower trunk sections are thicker

func base_strength() -> float:
	return 20.0 - (height_level * 2.0)  # Lower trunk sections are stronger

func base_max_weight() -> float:
	return 30.0 - (height_level * 3.0)  # Lower trunk sections can support more weight

func can_add_branch() -> bool:
	# Check if this trunk section can support another branch
	return branches_attached < branch_capacity

func add_branch():
	# Track when a branch is added
	branches_attached += 1

func expand_with_ring(expansion_factor: float):
	# Add a growth ring to the trunk
	ring_count += 1
	
	# Increase diameter based on expansion factor
	diameter_multiplier += expansion_factor
	
	# Update properties based on new ring
	update_trunk_properties()
	
	# Update visual appearance
	update_appearance()
	
	print("Trunk section at height " + str(height_level) + " expanded with new ring. Diameter multiplier: " + str(diameter_multiplier))

func update_appearance():
	# Update trunk appearance based on growth stage and rings
	super.update_appearance()
	
	# Trunk-specific visual updates
	if visual_node and visual_node is Sprite3D:
		# Make lower trunk sections visibly thicker
		var thickness_factor = base_thickness()
		visual_node.scale = Vector3(thickness_factor, 1.0, thickness_factor)
