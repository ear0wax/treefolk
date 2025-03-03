extends Node3D

# Tree component dictionaries
var trunk_types = {
	"plain": 0,
	"branch_left": 1,
	"branch_right": 2,
	"double_branch": 3,
	"multi_branch": 4
}

# Tree growth parameters
var tree_growth_stage = 0
var max_growth_stage = 10
var growth_timer = 0
var growth_interval = 5.0  # seconds between growth stages

# Current tree components
var current_tree_parts = []
var trunk_sections = []

# Seed for deterministic generation
var world_seed: int = 3146  # Default to seed 3146
var use_fixed_seed: bool = true  # Always use fixed seed by default

# Tree manager for advanced growth simulation
var tree_manager = null
# Color manager for handling color schemes
var color_manager = null
# Fungus manager for handling fungus growth
var fungus_manager = null
# Trauma system for handling tree trauma events
var trauma_system = null

# Season system
var current_season: int = 0  # 0=spring, 1=summer, 2=fall, 3=winter
var season_duration: float = 120.0  # seconds per season
var season_timer: float = 0.0

# Random event system
var event_timer: float = 0.0
var min_event_interval: float = 60.0  # Minimum seconds between random events
var max_event_interval: float = 180.0  # Maximum seconds between random events
var next_event_time: float = 120.0  # Time until next random event

func _ready():
	# Initialize color manager
	color_manager = load("res://scripts/color_manager.gd").new()
	add_child(color_manager)
	
	# Initialize fungus manager
	fungus_manager = load("res://scripts/fungus_manager.gd").new()
	add_child(fungus_manager)
	
	# Generate textures for logs and treefolk
	generate_gameplay_textures()
	
	# Initialize tree manager
	tree_manager = load("res://scripts/tree_manager.gd").new()
	add_child(tree_manager)
	
	# Initialize trauma system
	trauma_system = load("res://scripts/tree_trauma_system.gd").new()
	add_child(trauma_system)
	
	# Connect signals
	tree_manager.tree_grew.connect(_on_tree_grew)
	tree_manager.component_stressed.connect(_on_component_stressed)
	tree_manager.component_broke.connect(_on_component_broke)
	tree_manager.resources_updated.connect(_on_resources_updated)
	tree_manager.growth_ring_added.connect(_on_growth_ring_added)
	
	trauma_system.trauma_event_occurred.connect(_on_trauma_event)
	
	# Wait for textures to be generated first
	await get_tree().process_frame
	
	# Initialize the tree with a seed
	spawn_seed()
	
	# Start the gameplay
	$GameplayController.start_game()
	
func _process(delta):
	# Process seasonal changes
	process_seasons(delta)
	
	# Process random events
	process_random_events(delta)
	
	# Tree growth is now handled by the TreeManager
	# The old growth system is kept for compatibility but will be phased out
	growth_timer += delta
	if growth_timer >= growth_interval:
		growth_ 		growth_timer = 0
		grow_tree()

func process_seasons(delta):
	# Update season timer
	season_timer += delta
	
	# Check if it's time to change seasons
	if season_timer >= season_duration:
		season_timer = 0
		current_season = (current_season + 1) % 4
		update_all_branches_for_season()
		print("Season changed to: " + get_season_name(current_season))

func process_random_events(delta):
	# Update event timer
	event_timer += delta
	
	# Check if it's time for a random event
	if event_timer >= next_event_time:
		event_timer = 0
		
		# Set time for next event
		next_event_time = randf_range(min_event_interval, max_event_interval)
		
		# Trigger a random event
		trigger_random_event()

func trigger_random_event():
	# Only trigger events if the tree is established
	if tree_growth_stage < 3 or tree_manager.trunk_sections.size() < 2:
		return
	
	# Determine if an event should occur based on season
	var event_chance = 0.7  # Base chance
	
	# Adjust chance based on season
	match current_season:
		0:  # Spring - moderate chance
			event_chance = 0.6
		1:  # Summer - lower chance
			event_chance = 0.4
		2:  # Fall - higher chance
			event_chance = 0.7
		3:  # Winter - highest chance
			event_chance = 0.8
	
	# Roll for event
	if randf() > event_chance:
		return  # No event this time
	
	# Choose a random event type
	var event_types = trauma_system.TraumaType.keys()
	var weights = [
		0.1,  # LIGHTNING - rare
		0.2,  # DISEASE - common
		0.2,  # PEST - common
		0.15, # DROUGHT - moderate
		0.1,  # FLOOD - rare
		0.05, # FIRE - very rare
		0.15, # FROST - moderate
		0.05  # PHYSICAL - very rare
	]
	
	# Adjust weights based on season
	match current_season:
		0:  # Spring
			weights[trauma_system.TraumaType.FLOOD] *= 2.0  # More floods in spring
			weights[trauma_system.TraumaType.DISEASE] *= 1.5  # More disease in spring
		1:  # Summer
			weights[trauma_system.TraumaType.DROUGHT] *= 2.0  # More drought in summer
			weights[trauma_system.TraumaType.LIGHTNING] *= 2.0  # More lightning in summer
			weights[trauma_system.TraumaType.FIRE] *= 3.0  # More fire in summer
		2:  # Fall
			weights[trauma_system.TraumaType.PEST] *= 1.5  # More pests in fall
			weights[trauma_system.TraumaType.PHYSICAL] *= 2.0  # More physical damage in fall
		3:  # Winter
			weights[trauma_system.TraumaType.FROST] *= 3.0  # More frost in winter
			weights[trauma_system.TraumaType.PHYSICAL] *= 1.5  # More physical damage in winter
	
	# Select event type based on weights
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var cumulative_weight = 0.0
	var selected_event = 0
	
	for i in range(weights.size()):
		cumulative_weight += weights[i]
		if roll <= cumulative_weight:
			selected_event = i
			break
	
	# Determine severity (0.5 to 1.5)
	var severity = randf_range(0.5, 1.5)
	
	# Trigger the event
	trauma_system.trigger_trauma_event(selected_event, severity)

func get_season_name(season_index: int) -> String:
	match season_index:
		0: return "Spring"
		1: return "Summer"
		2: return "Fall"
		3: return "Winter"
		_: return "Unknown"

func update_all_branches_for_season():
	# Update all branches to reflect the new season
	for branch in tree_manager.branches:
		if branch.has_node("BranchComponent"):
			var branch_component = branch.get_node("BranchComponent")
			branch_component.update_seasonal_state(current_season)

# Generate textures for gameplay elements
func generate_gameplay_textures():
	# Create log texture generator
	var log_generator_script = load("res://scripts/log_texture_generator.gd")
	if log_generator_script:
		var log_generator = log_generator_script.new()
		add_child(log_generator)
	
	# Create treefolk texture generator
	var treefolk_generator_script = load("res://scripts/treefolk_texture_generator.gd")
	if treefolk_generator_script:
		var treefolk_generator = treefolk_generator_script.new()
		add_child(treefolk_generator)
	
	# Create fungus texture generator
	var fungus_generator_script = load("res://scripts/fungus_texture_generator.gd")
	if fungus_generator_script:
		var fungus_generator = fungus_generator_script.new()
		fungus_generator.name = "FungusTextureGenerator"
		add_child(fungus_generator)

# Set a specific seed for deterministic generation
func set_world_seed(seed_value: int) -> void:
	world_seed = seed_value
	use_fixed_seed = true
	print("World seed set to: ", world_seed)
	
	# Clear existing tree
	clear_tree()
	
	# Start a new tree with the new seed
	spawn_seed()

# Reset to random generation
func use_random_seed() -> void:
	randomize()
	world_seed = randi()
	use_fixed_seed = false
	print("Using random seed generation")

# Clear the current tree
func clear_tree() -> void:
	# Remove all tree parts
	for part in current_tree_parts:
		if is_instance_valid(part):
			part.queue_free()
	
	# Clear the arrays
	current_tree_parts.clear()
	trunk_sections.clear()
	
	# Reset growth stage
	tree_growth_stage = 0
	
	# Reset tree manager lists
	if tree_manager:
		tree_manager.trunk_sections.clear()
		tree_manager.branches.clear()
		tree_manager.roots.clear()
		tree_manager.all_components.clear()

func spawn_seed():
	# Create the initial seed
	var seed_instance = preload("res://scenes/tree_parts/seed.tscn").instantiate()
	$TreePivot.add_child(seed_instance)
	
	# Set the seed for deterministic generation if needed
	if use_fixed_seed and seed_instance.has_node("TextureGenerator"):
		seed_instance.get_node("TextureGenerator").generate_texture(world_seed)
	
	current_tree_parts.append(seed_instance)
	print("Seed spawned with seed value: ", world_seed)

func grow_tree():
	if tree_growth_stage >= max_growth_stage:
		return
		
	tree_growth_stage += 1
	print("Tree growing to stage: ", tree_growth_stage)
	
	match tree_growth_stage:
		1:
			# First roots and small sprout
			add_roots(1)
		2, 3:
			# Early trunk development
			add_trunk_section(trunk_types.plain)
		4, 5:
			# Add trunk with branches as tree grows taller
			var trunk_type
			if use_fixed_seed:
				var rng = RandomNumberGenerator.new()
				rng.seed = world_seed + tree_growth_stage * 100
				trunk_type = rng.randi_range(1, 3)  # branch_left, branch_right, or double_branch
			else:
				trunk_type = randi_range(1, 3)
				
			add_trunk_section(trunk_type)
		6, 7, 8:
			# More complex growth in middle stages
			var trunk_type
			if use_fixed_seed:
				var rng = RandomNumberGenerator.new()
				rng.seed = world_seed + tree_growth_stage * 100
				trunk_type = rng.randi_range(2, 4)  # branch_right, double_branch, or multi_branch
			else:
				trunk_type = randi_range(2, 4)
				
			add_trunk_section(trunk_type)
			add_roots(1)
		_:
			# Final growth stages
			var trunk_type
			if use_fixed_seed:
				var rng = RandomNumberGenerator.new()
				rng.seed = world_seed + tree_growth_stage * 100
				trunk_type = 4  # multi_branch for top sections
			else:
				trunk_type = 4
				
			add_trunk_section(trunk_type)
			add_roots(1)

func add_roots(count):
	for i in range(count):
		# In a full implementation, this would select from root_sections dictionary
		var root = preload("res://scenes/tree_parts/root.tscn").instantiate()
		
		# Position the root appropriately
		var position_seed
		var rng = RandomNumberGenerator.new()
		
		if use_fixed_seed:
			position_seed = world_seed + i + tree_growth_stage
		else:
			position_seed = randi()
			
		rng.seed = position_seed
		
		root.position = Vector3(
			rng.randf_range(-1, 1), 
			-0.5 * tree_growth_stage, 
			rng.randf_range(-1, 1)
		)
		
		$TreePivot.add_child(root)
		
		# Set the seed for deterministic generation if needed
		if use_fixed_seed and root.has_node("TextureGenerator"):
			# Use a different seed for each root based on position and growth stage
			var root_seed = world_seed + i * 100 + tree_growth_stage * 10
			root.get_node("TextureGenerator").generate_texture(root_seed)
		
		current_tree_parts.append(root)
		
		# Add to tree manager
		if tree_manager:
			tree_manager.roots.append(root)
			tree_manager.all_components.append(root)

func add_trunk_section(trunk_type = trunk_types.plain):
	var trunk = preload("res://scenes/tree_parts/trunk.tscn").instantiate()
	
	# Position the trunk section on top of the previous one
	var y_position = 0.5
	if trunk_sections.size() > 0:
		y_position = trunk_sections[trunk_sections.size() - 1].position.y + 0.5
		
	trunk.position = Vector3(0, y_position, 0)
	$TreePivot.add_child(trunk)
	
	# Set the seed for deterministic generation if needed
	if use_fixed_seed and trunk.has_node("TextureGenerator"):
		# Use a different seed for each trunk section based on growth stage
		var trunk_seed = world_seed + tree_growth_stage * 1000
		trunk.get_node("TextureGenerator").generate_texture(trunk_seed, trunk_type)
	
	current_tree_parts.append(trunk)
	trunk_sections.append(trunk)
	
	# Add to tree manager
	if tree_manager:
		tree_manager.trunk_sections.append(trunk)
		tree_manager.all_components.append(trunk)
	
	# Add branches based on trunk type
	if trunk.has_meta("branch_positions"):
		var branch_positions = trunk.get_meta("branch_positions")
		for branch_data in branch_positions:
			add_branch_at_position(trunk, branch_data.y, branch_data.side)

func add_branch_at_position(trunk_section, y_offset, side):
	# Create a branch instance
	var branch = preload("res://scenes/tree_parts/branch.tscn").instantiate()
	
	# Calculate position relative to the trunk section
	var trunk_height = 64.0  # Pixel height of trunk texture
	var normalized_y = float(y_offset) / trunk_height
	
	# Create a branch holder node that will be a child of the trunk
	var branch_holder = Node3D.new()
	branch_holder.name = "BranchHolder"
	trunk_section.add_child(branch_holder)
	
	# Position the holder at the correct height on the trunk
	branch_holder.position.y = normalized_y - 0.5  # Center offset
	
	# Add the branch to the holder
	branch_holder.add_child(branch)
	
	# Set the branch direction and position
	var distance = 0.5  # Distance from trunk center
	if side > 0:
		# Right side
		branch.position.x = distance
	else:
		# Left side
		branch.position.x = -distance
		branch.rotation.y = PI  # Rotate 180 degrees
	
	# Set the seed for deterministic generation if needed
	if use_fixed_seed and branch.has_node("TextureGenerator"):
		# Use a different seed for each branch based on position and trunk
		var branch_seed = world_seed + int(y_offset) * 200 + (1 if side > 0 else 2) * 300
		branch.get_node("TextureGenerator").generate_texture(branch_seed)
	
	current_tree_parts.append(branch)
	
	# Add to tree manager
	if tree_manager:
		tree_manager.branches.append(branch)
		tree_manager.all_components.append(branch)
		
		# Add BranchComponent if it doesn't exist
		if not branch.has_node("BranchComponent"):
			var branch_component = BranchComponent.new()
			branch.add_child(branch_component)
			branch_component.name = "BranchComponent"
			branch_component.branch_direction = side
			branch_component.update_seasonal_state(current_season)

# Signal handlers for tree manager
func _on_tree_grew(component_type, component):
	print("Tree grew a new " + component_type + ": " + component.name)
	
	# Add to our tracking arrays
	current_tree_parts.append(component)
	if component_type == "trunk":
		trunk_sections.append(component)

func _on_component_stressed(component):
	print("Component is stressed: " + component.name)
	
	# Visual indication
	if component.has_node("Sprite3D"):
		component.get_node("Sprite3D").modulate = Color(1.2, 0.8, 0.8)

func _on_component_broke(component):
	print("Component broke: " + component.name)
	
	# Handle breaking effects
	if component.has_node("Sprite3D"):
		component.get_node("Sprite3D").modulate = Color(0.5, 0.3, 0.3)

func _on_resources_updated(nutrients, water):
	# Update UI with resource information
	if has_node("UI/ResourcePanel"):
		var resource_panel = get_node("UI/ResourcePanel")
		if resource_panel.has_node("NutrientBar"):
			resource_panel.get_node("NutrientBar").value = nutrients
		if resource_panel.has_node("WaterBar"):
			resource_panel.get_node("WaterBar").value = water

func _on_growth_ring_added(ring_count):
	print("Tree has grown a new ring! Total rings: " + str(ring_count))
	
	# Update UI if needed
	if has_node("UI"):
		var ui = get_node("UI")
		if ui.has_node("TreeResourcePanel"):
			var panel = ui.get_node("TreeResourcePanel")
			if panel.has_node("RingCountLabel"):
				panel.get_node("RingCountLabel").text = "Rings: " + str(ring_count)

func _on_trauma_event(event_type, severity, affected_components):
	# Handle trauma event
	var event_name = trauma_system.TraumaType.keys()[event_type]
	print("Trauma event: " + event_name + " with severity " + str(severity))
	
	# Update UI to show the event
	if has_node("UI"):
		var ui = get_node("UI")
		if ui.has_node("EventPanel"):
			var panel = ui.get_node("EventPanel")
			if panel.has_node("EventLabel"):
				panel.get_node("EventLabel").text = "Event: " + event_name
				
				# Make the label flash
				var tween = create_tween()
				tween.tween_property(panel.get_node("EventLabel"), "modulate", Color(1, 0.3, 0.3, 1), 0.5)
				tween.tween_property(panel.get_node("EventLabel"), "modulate", Color(1, 1, 1, 1), 0.5)
