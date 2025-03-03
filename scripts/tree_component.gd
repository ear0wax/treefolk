extends Node

# Base class for all tree components (trunk, branches, roots)
class_name TreeComponent

# Component properties
var component_age: float = 0.0  # Age in game time units
var growth_stage: int = 0  # Current growth stage
var max_growth_stage: int = 3  # Maximum growth stage
var growth_rate: float = 1.0  # How fast this component grows

# Physical properties
var thickness: float = 1.0  # Base thickness of the component
var strength: float = 10.0  # How much weight this component can support
var current_weight: float = 1.0  # Current weight on this component
var max_weight: float = 10.0  # Maximum weight before breaking
var health: float = 100.0  # Health of the component (affects strength)

# Trauma and damage
var trauma: float = 0.0  # Accumulated trauma (0-100)
var damage: float = 0.0  # Physical damage (0-100)
var rot: float = 0.0  # Rot/decay (0-100)
var rot_resistance: float = 1.0  # Resistance to rot (multiplier)

# References
var parent_component: TreeComponent = null  # Parent component (e.g., trunk for a branch)
var child_components: Array = []  # Child components (e.g., branches for a trunk)

# Visual properties
var base_scale: Vector3 = Vector3(1, 1, 1)
var visual_node: Node3D = null  # Reference to the visual representation (sprite, mesh, etc.)

func _ready():
	# Initialize the component
	base_scale = get_parent().scale
	
	# Find the visual node (Sprite3D or MeshInstance3D)
	if get_parent().has_node("Sprite3D"):
		visual_node = get_parent().get_node("Sprite3D")
	elif get_parent().has_node("MeshInstance3D"):
		visual_node = get_parent().get_node("MeshInstance3D")
	
	update_appearance()

func _process(delta):
	# Age the component
	component_age += delta * growth_rate
	
	# Check if we should grow to the next stage
	if growth_stage < max_growth_stage and component_age > growth_stage_threshold():
		grow_to_next_stage()
	
	# Update weight calculations
	calculate_weight()
	
	# Process rot and damage
	process_rot_and_damage(delta)
	
	# Check for stress/breaking
	check_structural_integrity()

func growth_stage_threshold() -> float:
	# Return the age threshold for the next growth stage
	return (growth_stage + 1) * 10.0  # Example: stages at age 10, 20, 30...

func grow_to_next_stage():
	growth_stage += 1
	
	# Increase thickness and strength with growth
	thickness = base_thickness() * (1.0 + growth_stage * 0.5)
	strength = base_strength() * (1.0 + growth_stage * 0.7)
	max_weight = base_max_weight() * (1.0 + growth_stage * 0.8)
	
	# Update visual appearance
	update_appearance()
	
	print(get_parent().name + " grew to stage " + str(growth_stage))

func base_thickness() -> float:
	return 1.0  # Base value, override in subclasses

func base_strength() -> float:
	return 10.0  # Base value, override in subclasses

func base_max_weight() -> float:
	return 10.0  # Base value, override in subclasses

func calculate_weight():
	# Start with this component's own weight
	current_weight = own_weight()
	
	# Add weight of all child components
	for child in child_components:
		if child is TreeComponent:
			current_weight += child.current_weight
	
	# Transfer weight to parent
	if parent_component != null:
		# Weight is already accounted for in parent's calculation
		pass

func own_weight() -> float:
	# Calculate this component's own weight based on size/thickness
	return thickness * 1.0  # Simple calculation, can be more complex

func process_rot_and_damage(delta):
	# Process rot progression
	if rot > 0:
		# Rot spreads slowly based on current rot level and resistance
		var rot_increase = delta * (rot / 100.0) * (1.0 / rot_resistance)
		rot = min(rot + rot_increase, 100.0)
		
		# Rot reduces strength and health
		if rot > 20:  # Only affect strength after 20% rot
			strength = base_strength() * (1.0 - (rot - 20) / 100.0)
		
		# Update appearance to show rot
		update_rot_appearance()
	
	# Process damage effects
	if damage > 0:
		# Damage reduces strength directly
		strength = base_strength() * (1.0 - damage / 100.0)
		
		# Damage can lead to rot over time
		if damage > 30 and rot < 10:  # Significant damage can start rot
			rot = max(rot, 5.0)  # Initialize some rot
	
	# Process trauma effects
	if trauma > 0:
		# Trauma slowly decreases over time (healing)
		trauma = max(0, trauma - delta * 0.1)
		
		# Severe trauma can lead to damage
		if trauma > 70 and randf() < delta * 0.1:
			damage += 5.0  # Add some physical damage
			trauma -= 10.0  # Reduce trauma as it converts to damage

func update_rot_appearance():
	# Update visual appearance based on rot level
	if visual_node and rot > 0:
		if visual_node is Sprite3D or visual_node is MeshInstance3D:
			# Gradually darken and add brown tint as rot increases
			var rot_factor = rot / 100.0
			visual_node.modulate = Color(
				1.0,
				1.0 - rot_factor * 0.3,
				1.0 - rot_factor * 0.5,
				1.0
			)

func check_structural_integrity():
	# Check if this component is overloaded
	if current_weight > max_weight:
		# Component is stressed
		health -= (current_weight - max_weight) * 0.1
		
		# Visual indication of stress
		if visual_node:
			if visual_node is Sprite3D or visual_node is MeshInstance3D:
				visual_node.modulate = Color(1.5, 0.7, 0.7)  # Reddish tint
	else:
		# Component is fine
		health = min(health + 0.1, 100.0)  # Slowly recover
		if visual_node and rot == 0 and damage == 0:  # Only reset if no rot or damage
			if visual_node is Sprite3D or visual_node is MeshInstance3D:
				visual_node.modulate = Color(1, 1, 1)  # Normal color
	
	# Check if component breaks
	if health <= 0 or rot >= 90 or damage >= 90:
		break_component()

func break_component():
	# Handle breaking of this component
	print(get_parent().name + " has broken!")
	
	# Visual indication
	if visual_node:
		if visual_node is Sprite3D or visual_node is MeshInstance3D:
			visual_node.modulate = Color(0.5, 0.3, 0.3)  # Dark/dead appearance
	
	# Notify parent components
	if parent_component:
		parent_component.child_broke(self)
	
	# Notify tree manager if available
	var tree_manager = find_tree_manager()
	if tree_manager:
		tree_manager.emit_signal("component_broke", get_parent())

func child_broke(child_component):
	# Handle when a child component breaks
	# Remove it from our child components
	child_components.erase(child_component)
	
	# Add trauma from the breaking event
	trauma += 20.0
	
	# Recalculate weight
	calculate_weight()

func find_tree_manager():
	# Find the tree manager in the scene
	var root = get_tree().get_root()
	if root.has_node("Main"):
		var main = root.get_node("Main")
		if main.has_node("TreeManager"):
			return main.get_node("TreeManager")
		elif main.tree_manager:
			return main.tree_manager
	return null

func add_rot(amount: float):
	# Add rot to this component
	rot = min(rot + amount, 100.0)
	update_rot_appearance()

func add_damage(amount: float):
	# Add damage to this component
	damage = min(damage + amount, 100.0)
	
	# Damage reduces health
	health = max(0, health - amount * 0.5)
	
	# Update appearance
	update_appearance()

func add_trauma(amount: float):
	# Add trauma to this component
	trauma = min(trauma + amount, 100.0)

func update_appearance():
	# Update the visual appearance based on growth stage and health
	var growth_scale = 1.0 + (growth_stage * 0.3)
	
	# Scale differently based on component type
	match get_component_type():
		"trunk":
			# Trunks get thicker but not much taller
			get_parent().scale = Vector3(
				base_scale.x * growth_scale,
				base_scale.y,
				base_scale.z * growth_scale
			)
		"branch":
			# Branches get longer and slightly thicker
			get_parent().scale = Vector3(
				base_scale.x * (1.0 + growth_stage * 0.2),
				base_scale.y * growth_scale,
				base_scale.z * (1.0 + growth_stage * 0.2)
			)
		"root":
			# Roots get longer and spread out more
			get_parent().scale = Vector3(
				base_scale.x * growth_scale,
				base_scale.y * (1.0 + growth_stage * 0.1),
				base_scale.z * growth_scale
			)
	
	# Update texture/sprite if needed
	if visual_node and visual_node is Sprite3D:
		visual_node.pixel_size = 0.02 * (1.0 + growth_stage * 0.2)  # Adjust pixel size with growth
		
		# Apply damage and health effects to appearance
		var health_factor = health / 100.0
		var damage_factor = damage / 100.0
		
		if damage > 0:
			visual_node.modulate = Color(
				1.0,
				1.0 - damage_factor * 0.3,
				1.0 - damage_factor * 0.5,
				1.0
			)

func get_component_type() -> String:
	# Determine the type of component based on name or class
	var parent_name = get_parent().name
	if parent_name.begins_with("Trunk"):
		return "trunk"
	elif parent_name.begins_with("Branch"):
		return "branch"
	elif parent_name.begins_with("Root"):
		return "root"
	else:
		return "unknown"

func add_child_component(component: TreeComponent):
	# Add a child component and set up the parent-child relationship
	child_components.append(component)
	component.parent_component = self

func remove_child_component(component: TreeComponent):
	# Remove a child component
	child_components.erase(component)
	component.parent_component = null
