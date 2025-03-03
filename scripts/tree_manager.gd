extends Node

# Central manager for the tree's growth and structural integrity
class_name TreeManager

# Tree properties
var tree_age: float = 0.0
var growth_speed: float = 1.0
var health: float = 100.0
var nutrients: float = 50.0
var water: float = 50.0
var max_resources: float = 100.0

# Tree components
var trunk_sections: Array = []
var branches: Array = []
var roots: Array = []
var all_components: Array = []

# Growth thresholds
var next_trunk_threshold: float = 10.0
var next_branch_threshold: float = 15.0
var next_root_threshold: float = 8.0

# Growth rings (annual growth)
var growth_rings: int = 0
var ring_formation_threshold: float = 60.0  # Time to form a new ring
var ring_timer: float = 0.0

# Trunk expansion rate (how much the trunk expands with each ring)
var trunk_expansion_rate: float = 0.1  # 10% increase per ring

# Leaf density parameters
var leaf_growth_rate: float = 0.05  # How quickly leaves fill in
var max_leaf_density: float = 1.0  # Maximum leaf density

# Signals
signal tree_grew(component_type, component)
signal component_stressed(component)
signal component_broke(component)
signal resources_updated(nutrients, water)
signal growth_ring_added(ring_count)

func _ready():
	# Initialize the tree manager
	pass

func _process(delta):
	# Age the tree
	tree_age += delta * growth_speed
	
	# Process annual growth ring formation
	process_growth_rings(delta)
	
	# Gather resources from roots
	gather_resources(delta)
	
	# Consume resources for growth
	consume_resources(delta)
	
	# Check growth thresholds
	check_growth_thresholds()
	
	# Update all components
	update_components(delta)
	
	# Check structural integrity of the whole tree
	check_tree_integrity()

func process_growth_rings(delta):
	# Accumulate time for ring formation
	ring_timer += delta * growth_speed
	
	# Check if it's time to form a new growth ring
	if ring_timer >= ring_formation_threshold:
		ring_timer = 0
		growth_rings += 1
		
		# Expand trunk diameter with new ring
		expand_trunk_with_new_ring()
		
		# Increase leaf density on existing branches
		increase_leaf_density()
		
		# Signal that a new ring has been added
		emit_signal("growth_ring_added", growth_rings)
		print("Tree has formed a new growth ring! Total rings: ", growth_rings)

func expand_trunk_with_new_ring():
	# Expand all trunk sections, with lower sections expanding more
	for i in range(trunk_sections.size()):
		var trunk = trunk_sections[i]
		if trunk.has_node("TrunkComponent"):
			var trunk_component = trunk.get_node("TrunkComponent")
			
			# Lower trunk sections expand more than upper ones
			var expansion_factor = trunk_expansion_rate * (1.0 - (i / float(trunk_sections.size() + 1)))
			trunk_component.expand_with_ring(expansion_factor)

func increase_leaf_density():
	# Increase leaf density on all branches
	for branch in branches:
		if branch.has_node("BranchComponent"):
			var branch_component = branch.get_node("BranchComponent")
			
			# Increase leaf density up to maximum
			var new_density = min(branch_component.leaf_density + leaf_growth_rate, max_leaf_density)
			branch_component.set_leaf_density(new_density)

func gather_resources(delta):
	# Gather resources from all roots
	var nutrients_gathered = 0.0
	var water_gathered = 0.0
	
	for root in roots:
		if root.has_node("RootComponent"):
			var root_component = root.get_node("RootComponent")
			var resources = root_component.gather_resources()
			nutrients_gathered += resources.nutrients * delta
			water_gathered += resources.water * delta
	
	# Add gathered resources
	nutrients = min(nutrients + nutrients_gathered, max_resources)
	water = min(water + water_gathered, max_resources)
	
	# Emit signal for UI updates
	emit_signal("resources_updated", nutrients, water)

func consume_resources(delta):
	# Basic consumption for tree maintenance
	var base_consumption = 0.1 * delta
	
	# Additional consumption based on tree size
	var size_factor = (trunk_sections.size() * 0.05 + 
					   branches.size() * 0.02 + 
					   roots.size() * 0.01)
	
	# Consume resources
	nutrients = max(0, nutrients - (base_consumption + size_factor))
	water = max(0, water - (base_consumption * 2 + size_factor))
	
	# Emit signal for UI updates
	emit_signal("resources_updated", nutrients, water)
	
	# Adjust growth speed based on available resources
	adjust_growth_speed()

func adjust_growth_speed():
	# Calculate growth speed based on available resources
	var resource_factor = min(nutrients / 50.0, water / 50.0)
	growth_speed = max(0.1, resource_factor)  # Minimum growth speed of 0.1

func check_growth_thresholds():
	# Check if it's time to add new components
	if tree_age >= next_trunk_threshold and can_grow_component("trunk"):
		add_trunk_section()
		next_trunk_threshold += 15.0 + trunk_sections.size() * 5.0
	
	if tree_age >= next_branch_threshold and can_grow_component("branch"):
		add_branch()
		next_branch_threshold += 10.0 + branches.size() * 2.0
	
	if tree_age >= next_root_threshold and can_grow_component("root"):
		add_root()
		next_root_threshold += 8.0 + roots.size() * 1.5

func can_grow_component(component_type: String) -> bool:
	# Check if there are enough resources to grow a new component
	var required_nutrients = 0.0
	var required_water = 0.0
	
	match component_type:
		"trunk":
			required_nutrients = 20.0
			required_water = 30.0
		"branch":
			required_nutrients = 15.0
			required_water = 20.0
		"root":
			required_nutrients = 10.0
			required_water = 25.0
	
	return nutrients >= required_nutrients and water >= required_water

func add_trunk_section():
	# Create a new trunk section
	var trunk_scene = preload("res://scenes/tree_parts/trunk.tscn")
	var new_trunk = trunk_scene.instantiate()
	
	# Add TrunkComponent script
	var trunk_component = TrunkComponent.new()
	new_trunk.add_child(trunk_component)
	trunk_component.name = "TrunkComponent"
	
	# Set properties
	trunk_component.height_level = trunk_sections.size()
	
	# Position the trunk - always on top of the previous trunk section
	var y_position = 0.5
	if trunk_sections.size() > 0:
		var last_trunk = trunk_sections[trunk_sections.size() - 1]
		y_position = last_trunk.position.y + 0.5
	
	new_trunk.position = Vector3(0, y_position, 0)
	
	# Add to the tree
	var tree_pivot = get_node("/root/Main/TreePivot")
	if tree_pivot:
		tree_pivot.add_child(new_trunk)
	
	# Connect to parent trunk if it exists
	if trunk_sections.size() > 0:
		var parent_trunk = trunk_sections[trunk_sections.size() - 1]
		if parent_trunk.has_node("TrunkComponent"):
			var parent_component = parent_trunk.get_node("TrunkComponent")
			parent_component.add_child_component(trunk_component)
	
	# Add to lists
	trunk_sections.append(new_trunk)
	all_components.append(new_trunk)
	
	# Consume resources
	nutrients -= 20.0
	water -= 30.0
	
	# Emit signal
	emit_signal("tree_grew", "trunk", new_trunk)
	
	return new_trunk

func add_branch():
	# Find a suitable trunk section to attach to
	var potential_trunks = []
	
	for trunk in trunk_sections:
		if trunk.has_node("TrunkComponent"):
			var trunk_component = trunk.get_node("TrunkComponent")
			if trunk_component.can_add_branch():
				potential_trunks.append(trunk)
	
	if potential_trunks.size() == 0:
		return null  # No suitable trunk found
	
	# Prefer newer trunk sections for more realistic growth pattern
	# Sort trunks by height (higher index = newer/higher trunk)
	potential_trunks.sort_custom(func(a, b): 
		return trunk_sections.find(a) > trunk_sections.find(b)
	)
	
	# Higher chance to select newer trunks, but still possible to add to older ones
	var trunk_index = 0
	var random_value = randf()
	
	if random_value < 0.7 and potential_trunks.size() > 1:
		# 70% chance to select from the top half of potential trunks
		trunk_index = randi() % max(1, potential_trunks.size() / 2)
	else:
		# 30% chance to select from any potential trunk
		trunk_index = randi() % potential_trunks.size()
	
	var selected_trunk = potential_trunks[trunk_index]
	var trunk_component = selected_trunk.get_node("TrunkComponent")
	
	# Create a new branch
	var branch_scene = preload("res://scenes/tree_parts/branch.tscn")
	var new_branch = branch_scene.instantiate()
	
	# Add BranchComponent script
	var branch_component = BranchComponent.new()
	new_branch.add_child(branch_component)
	branch_component.name = "BranchComponent"
	
	# Set properties
	branch_component.branch_level = 0
	
	# Determine branch direction based on existing branches on this trunk
	# to ensure balanced growth
	var branch_direction = determine_branch_direction(selected_trunk)
	branch_component.branch_direction = branch_direction
	
	# Create a branch holder node
	var branch_holder = Node3D.new()
	branch_holder.name = "BranchHolder"
	selected_trunk.add_child(branch_holder)
	
	# Position the branch holder at a position on the trunk that doesn't already have a branch
	var y_offset = find_available_branch_position(selected_trunk)
	branch_holder.position.y = y_offset
	
	# Add the branch to the holder
	branch_holder.add_child(new_branch)
	
	# Position the branch
	var distance = 0.5  # Distance from trunk center
	if branch_component.branch_direction > 0:
		# Right side
		new_branch.position.x = distance
	else:
		# Left side
		new_branch.position.x = -distance
		new_branch.rotation.y = PI  # Rotate 180 degrees
	
	# Connect to parent trunk
	trunk_component.add_child_component(branch_component)
	trunk_component.add_branch()
	
	# Add to lists
	branches.append(new_branch)
	all_components.append(new_branch)
	
	# Consume resources
	nutrients -= 15.0
	water -= 20.0
	
	# Emit signal
	emit_signal("tree_grew", "branch", new_branch)
	
	return new_branch

func determine_branch_direction(trunk_node) -> int:
	# Count branches on each side of the trunk
	var left_branches = 0
	var right_branches = 0
	
	for child in trunk_node.get_children():
		if child.name == "BranchHolder":
			for branch_child in child.get_children():
				if branch_child.has_node("BranchComponent"):
					var branch_comp = branch_child.get_node("BranchComponent")
					if branch_comp.branch_direction > 0:
						right_branches += 1
					else:
						left_branches += 1
	
	# Choose the side with fewer branches
	if left_branches < right_branches:
		return -1  # Left side
	elif right_branches < left_branches:
		return 1   # Right side
	else:
		# If equal, choose randomly
		return [-1, 1][randi() % 2]

func find_available_branch_position(trunk_node) -> float:
	# Find positions where branches already exist
	var existing_positions = []
	
	for child in trunk_node.get_children():
		if child.name == "BranchHolder":
			existing_positions.append(child.position.y)
	
	# Try to find a position that's not too close to existing branches
	var min_distance = 0.2  # Minimum distance between branches
	var attempts = 10
	
	while attempts > 0:
		var position = randf_range(-0.3, 0.3)
		var too_close = false
		
		for existing_pos in existing_positions:
			if abs(position - existing_pos) < min_distance:
				too_close = true
				break
		
		if not too_close:
			return position
		
		attempts -= 1
	
	# If we couldn't find a good position, just return a random one
	return randf_range(-0.3, 0.3)

func add_root():
	# Create a new root
	var root_scene = preload("res://scenes/tree_parts/root.tscn")
	var new_root = root_scene.instantiate()
	
	# Add RootComponent script
	var root_component = RootComponent.new()
	new_root.add_child(root_component)
	root_component.name = "RootComponent"
	
	# Set properties - roots should get deeper as the tree grows
	var max_depth = min(3, trunk_sections.size() / 2)
	root_component.root_depth = randi() % (max_depth + 1)
	
	# Position the root - spread out in a more natural pattern
	var angle = find_available_root_angle()
	var distance = randf_range(0.5, 1.0 + trunk_sections.size() * 0.1)
	var y_position = -0.5 - root_component.root_depth * 0.3
	
	new_root.position = Vector3(
		cos(angle) * distance,
		y_position,
		sin(angle) * distance
	)
	
	# Add to the tree
	var tree_pivot = get_node("/root/Main/TreePivot")
	if tree_pivot:
		tree_pivot.add_child(new_root)
	
	# Add to lists
	roots.append(new_root)
	all_components.append(new_root)
	
	# Consume resources
	nutrients -= 10.0
	water -= 25.0
	
	# Emit signal
	emit_signal("tree_grew", "root", new_root)
	
	return new_root

func find_available_root_angle() -> float:
	# Find angles where roots already exist
	var existing_angles = []
	
	for root in roots:
		var angle = atan2(root.position.z, root.position.x)
		existing_angles.append(angle)
	
	# Try to find an angle that's not too close to existing roots
	var min_angle_diff = PI / 8  # Minimum angle between roots
	var attempts = 10
	
	while attempts > 0:
		var angle = randf() * 2 * PI
		var too_close = false
		
		for existing_angle in existing_angles:
			var diff = abs(angle - existing_angle)
			while diff > PI:
				diff = 2 * PI - diff
			
			if diff < min_angle_diff:
				too_close = true
				break
		
		if not too_close:
			return angle
		
		attempts -= 1
	
	# If we couldn't find a good angle, just return a random one
	return randf() * 2 * PI

func update_components(delta):
	# Update all components
	for component in all_components:
		if component.has_node("TrunkComponent"):
			component.get_node("TrunkComponent")._process(delta)
		elif component.has_node("BranchComponent"):
			component.get_node("BranchComponent")._process(delta)
		elif component.has_node("RootComponent"):
			component.get_node("RootComponent")._process(delta)

func check_tree_integrity():
	# Check the structural integrity of the whole tree
	# This could involve more complex calculations based on the
	# weight distribution, wind effects, etc.
	
	# For now, just check if any components are stressed
	for component in all_components:
		var tree_component = null
		
		if component.has_node("TrunkComponent"):
			tree_component = component.get_node("TrunkComponent")
		elif component.has_node("BranchComponent"):
			tree_component = component.get_node("BranchComponent")
		elif component.has_node("RootComponent"):
			tree_component = component.get_node("RootComponent")
		
		if tree_component and tree_component.current_weight > tree_component.max_weight * 0.8:
			emit_signal("component_stressed", component)
