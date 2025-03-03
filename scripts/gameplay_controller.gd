extends Node

# Gameplay Controller for Norse Tree Builder
# Handles resource management, treefolk, and game progression

# Resources
var logs = 0
var treefolk = []
var shelters = []
var ladders = []

# Game state
var game_started = false
var next_crow_time = 0
var crow_interval_min = 5.0  # Minimum seconds between crows
var crow_interval_max = 15.0  # Maximum seconds between crows
var crow_timer = 0

# Task types
enum TaskType {
	IDLE,
	COLLECT_LOG,
	BUILD_SHELTER,
	BUILD_LADDER,
	MAINTAIN_TREE,
	COLLECT_FUNGUS
}

# Signals
signal resource_updated(resource_type, amount)
signal treefolk_added(treefolk)
signal structure_built(structure_type, position)

# Fungus collection
var fungus_collected = 0
var fungus_types_collected = [0, 0, 0, 0]  # Count of each fungus type collected

func _ready():
	randomize()
	# Start with a delay before first crow
	next_crow_time = randf_range(2.0, 5.0)

func _process(delta):
	if game_started:
		# Handle crow spawning
		crow_timer += delta
		if crow_timer >= next_crow_time:
			spawn_crow()
			crow_timer = 0
			next_crow_time = randf_range(crow_interval_min, crow_interval_max)
		
		# Process treefolk tasks
		process_treefolk(delta)

func start_game():
	game_started = true
	print("Game started!")

func spawn_crow():
	# Create a crow instance
	var crow = preload("res://scenes/gameplay/crow.tscn").instantiate()
	
	# Set random position for the crow to fly from
	var viewport_size = get_viewport().get_visible_rect().size
	var start_x = -100  # Start off-screen
	var start_y = randf_range(viewport_size.y * 0.3, viewport_size.y * 0.7)
	
	# Set random position for the crow to drop the log
	var drop_x = randf_range(viewport_size.x * 0.3, viewport_size.x * 0.7)
	var drop_y = start_y
	
	# Configure the crow
	crow.position = Vector2(start_x, start_y)
	crow.set_drop_position(Vector2(drop_x, drop_y))
	
	# Add the crow to the scene
	add_child(crow)
	
	print("Crow spawned, will drop log at: ", drop_x, ", ", drop_y)

func add_log():
	logs += 1
	emit_signal("resource_updated", "logs", logs)
	print("Log added! Total logs: ", logs)

func use_log():
	if logs > 0:
		logs -= 1
		emit_signal("resource_updated", "logs", logs)
		return true
	return false

func add_fungus(fungus_type: int = 0):
	fungus_collected += 1
	fungus_types_collected[fungus_type] += 1
	emit_signal("resource_updated", "fungus", fungus_collected)
	print("Fungus added! Type: ", fungus_type, ", Total: ", fungus_collected)

func spawn_treefolk():
	if use_log():
		var treefolk_instance = {
			"id": treefolk.size(),
			"name": generate_treefolk_name(),
			"task": TaskType.IDLE,
			"position": Vector3(0, 0, 0),
			"target": Vector3(0, 0, 0),
			"progress": 0.0,
			"efficiency": randf_range(0.8, 1.2)  # Efficiency multiplier
		}
		
		treefolk.append(treefolk_instance)
		emit_signal("treefolk_added", treefolk_instance)
		
		print("Treefolk spawned: ", treefolk_instance.name)
		
		# Create visual representation
		spawn_treefolk_visual(treefolk_instance)
		
		# Assign initial task
		assign_task(treefolk_instance)
		
		return treefolk_instance
	
	return null

func generate_treefolk_name():
	var prefixes = ["Bark", "Leaf", "Root", "Twig", "Branch", "Moss", "Oak", "Pine", "Elm", "Ash", "Birch", "Fungus", "Spore", "Mycel"]
	var suffixes = ["heart", "soul", "walker", "tender", "keeper", "friend", "whisperer", "guardian", "warden", "harvester", "collector"]
	
	var prefix = prefixes[randi() % prefixes.size()]
	var suffix = suffixes[randi() % suffixes.size()]
	
	return prefix + suffix

func spawn_treefolk_visual(treefolk_data):
	var treefolk_visual = preload("res://scenes/gameplay/treefolk.tscn").instantiate()
	treefolk_visual.initialize(treefolk_data)
	
	# Add to the scene at a suitable position on the tree
	var main_node = get_node("/root/Main")
	var tree_pivot = main_node.get_node("TreePivot")
	
	# Find a suitable branch or trunk to place the treefolk
	var placement_node = find_treefolk_placement()
	if placement_node:
		placement_node.add_child(treefolk_visual)
	else:
		# Fallback to tree pivot if no suitable placement found
		tree_pivot.add_child(treefolk_visual)
		treefolk_visual.position.y = 1.0  # Place slightly above ground

func find_treefolk_placement():
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	# Filter to find trunk sections or branches
	var potential_placements = []
	
	for part in tree_parts:
		if part.name.begins_with("Trunk") or part.name.begins_with("Branch"):
			potential_placements.append(part)
	
	if potential_placements.size() > 0:
		return potential_placements[randi() % potential_placements.size()]
	
	return null

func assign_task(treefolk_data):
	# Determine what task is most needed
	var needed_task = determine_needed_task()
	
	# Assign the task
	treefolk_data.task = needed_task
	treefolk_data.progress = 0.0
	
	# Set target position based on task
	set_task_target(treefolk_data)
	
	print("Assigned task to ", treefolk_data.name, ": ", TaskType.keys()[treefolk_data.task])

func determine_needed_task():
	# Simple task determination logic
	# This can be expanded with more complex priority calculations
	
	# Check if there are any rotting logs with fungus to collect
	var rotting_logs = find_rotting_logs_with_fungus()
	if rotting_logs.size() > 0 and randf() > 0.7:
		return TaskType.COLLECT_FUNGUS
	
	# If we have no shelters, prioritize building one
	if shelters.size() < treefolk.size() / 2:
		return TaskType.BUILD_SHELTER
	
	# If we have few ladders, build some
	if ladders.size() < treefolk.size() / 3:
		return TaskType.BUILD_LADDER
	
	# Randomly choose between maintenance, resource collection, and fungus collection
	var roll = randf()
	if roll > 0.7:
		return TaskType.MAINTAIN_TREE
	elif roll > 0.4:
		return TaskType.COLLECT_LOG
	else:
		return TaskType.COLLECT_FUNGUS

func find_rotting_logs_with_fungus():
	var logs_with_fungus = []
	
	# Find all logs in the scene
	var logs = get_tree().get_nodes_in_group("logs")
	
	# Filter for logs with fungus
	for log in logs:
		if log.has_method("get_fungus_count") and log.get_fungus_count() > 0:
			logs_with_fungus.append(log)
	
	return logs_with_fungus

func set_task_target(treefolk_data):
	var main_node = get_node("/root/Main")
	var tree_pivot = main_node.get_node("TreePivot")
	
	match treefolk_data.task:
		TaskType.COLLECT_LOG:
			# Set target to a random position around the tree
			var angle = randf() * 2 * PI
			var distance = randf_range(2.0, 5.0)
			treefolk_data.target = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		TaskType.BUILD_SHELTER:
			# Find a suitable branch to build shelter on
			var branch = find_suitable_branch_for_shelter()
			if branch:
				treefolk_data.target = branch.global_position
			else:
				# Fallback if no suitable branch
				treefolk_data.target = Vector3(0, 2, 0)
		
		TaskType.BUILD_LADDER:
			# Find a suitable position between trunk sections
			var ladder_position = find_suitable_ladder_position()
			treefolk_data.target = ladder_position
		
		TaskType.MAINTAIN_TREE:
			# Choose a random tree part to maintain
			var tree_parts = main_node.current_tree_parts
			if tree_parts.size() > 0:
				var random_part = tree_parts[randi() % tree_parts.size()]
				treefolk_data.target = random_part.global_position
			else:
				treefolk_data.target = Vector3(0, 1, 0)
		
		TaskType.COLLECT_FUNGUS:
			# Find a log with fungus
			var logs_with_fungus = find_rotting_logs_with_fungus()
			if logs_with_fungus.size() > 0:
				var target_log = logs_with_fungus[randi() % logs_with_fungus.size()]
				treefolk_data.target = target_log.global_position
			else:
				# Fallback to random position if no fungus found
				var angle = randf() * 2 * PI
				var distance = randf_range(2.0, 5.0)
				treefolk_data.target = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		
		_:  # IDLE or default
			treefolk_data.target = Vector3(0, 0, 0)

func find_suitable_branch_for_shelter():
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	# Filter to find branches
	var branches = []
	for part in tree_parts:
		if part.name.begins_with("Branch"):
			# Check if this branch already has a shelter
			var has_shelter = false
			for shelter in shelters:
				if shelter.branch_id == part.get_instance_id():
					has_shelter = true
					break
			
			if not has_shelter:
				branches.append(part)
	
	if branches.size() > 0:
		return branches[randi() % branches.size()]
	
	return null

func find_suitable_ladder_position():
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	# Filter to find trunk sections
	var trunks = []
	for part in tree_parts:
		if part.name.begins_with("Trunk"):
			trunks.append(part)
	
	# Sort trunks by height
	trunks.sort_custom(func(a, b): return a.position.y < b.position.y)
	
	# Find a pair of trunks to connect with a ladder
	for i in range(trunks.size() - 1):
		var lower_trunk = trunks[i]
		var upper_trunk = trunks[i + 1]
		
		# Check if there's already a ladder here
		var has_ladder = false
		for ladder in ladders:
			if ladder.start_id == lower_trunk.get_instance_id() and ladder.end_id == upper_trunk.get_instance_id():
				has_ladder = true
				break
		
		if not has_ladder:
			# Return a position halfway between the trunks
			return (lower_trunk.global_position + upper_trunk.global_position) / 2
	
	# Fallback position
	return Vector3(0, 2, 0)

func process_treefolk(delta):
	for treefolk_data in treefolk:
		# Update task progress
		treefolk_data.progress += delta * treefolk_data.efficiency
		
		# Check if task is complete
		if treefolk_data.progress >= get_task_duration(treefolk_data.task):
			complete_task(treefolk_data)
			
			# Assign a new task
			assign_task(treefolk_data)

func get_task_duration(task_type):
	match task_type:
		TaskType.COLLECT_LOG:
			return 10.0
		TaskType.BUILD_SHELTER:
			return 20.0
		TaskType.BUILD_LADDER:
			return 15.0
		TaskType.MAINTAIN_TREE:
			return 12.0
		TaskType.COLLECT_FUNGUS:
			return 8.0
		_:  # IDLE or default
			return 5.0

func complete_task(treefolk_data):
	match treefolk_data.task:
		TaskType.COLLECT_LOG:
			add_log()
			print(treefolk_data.name, " collected a log!")
		
		TaskType.BUILD_SHELTER:
			build_shelter(treefolk_data.target)
			print(treefolk_data.name, " built a shelter!")
		
		TaskType.BUILD_LADDER:
			build_ladder(treefolk_data.target)
			print(treefolk_data.name, " built a ladder!")
		
		TaskType.MAINTAIN_TREE:
			# Tree maintenance improves growth speed or health
			var main_node = get_node("/root/Main")
			main_node.growth_timer += 1.0  # Boost growth
			print(treefolk_data.name, " maintained the tree!")
		
		TaskType.COLLECT_FUNGUS:
			# Collect fungus from a rotting log
			var fungus_type = randi() % 4  # Random fungus type for now
			add_fungus(fungus_type)
			print(treefolk_data.name, " collected fungus type ", fungus_type, "!")
		
		_:  # IDLE or default
			print(treefolk_data.name, " finished resting.")

func build_shelter(position):
	# Create shelter data
	var shelter_data = {
		"id": shelters.size(),
		"position": position,
		"branch_id": find_branch_at_position(position).get_instance_id() if find_branch_at_position(position) else 0,
		"capacity": 2,  # How many treefolk can live here
		"residents": []
	}
	
	shelters.append(shelter_data)
	
	# Create visual representation
	spawn_shelter_visual(shelter_data)
	
	emit_signal("structure_built", "shelter", position)

func build_ladder(position):
	# Find the connected trunk sections
	var connected_trunks = find_connected_trunks(position)
	
	if connected_trunks.size() >= 2:
		var ladder_data = {
			"id": ladders.size(),
			"position": position,
			"start_id": connected_trunks[0].get_instance_id(),
			"end_id": connected_trunks[1].get_instance_id(),
			"length": (connected_trunks[0].global_position - connected_trunks[1].global_position).length()
		}
		
		ladders.append(ladder_data)
		
		# Create visual representation
		spawn_ladder_visual(ladder_data)
		
		emit_signal("structure_built", "ladder", position)

func find_branch_at_position(position):
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	for part in tree_parts:
		if part.name.begins_with("Branch"):
			if part.global_position.distance_to(position) < 1.0:
				return part
	
	return null

func find_connected_trunks(position):
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	var nearby_trunks = []
	
	for part in tree_parts:
		if part.name.begins_with("Trunk"):
			if part.global_position.distance_to(position) < 3.0:
				nearby_trunks.append(part)
	
	# Sort by distance to the position
	nearby_trunks.sort_custom(func(a, b): 
		return a.global_position.distance_to(position) < b.global_position.distance_to(position)
	)
	
	# Return the two closest trunks
	if nearby_trunks.size() >= 2:
		return [nearby_trunks[0], nearby_trunks[1]]
	
	return nearby_trunks

func spawn_shelter_visual(shelter_data):
	var shelter_visual = preload("res://scenes/gameplay/shelter.tscn").instantiate()
	shelter_visual.initialize(shelter_data)
	
	# Find the branch to attach to
	var main_node = get_node("/root/Main")
	var tree_parts = main_node.current_tree_parts
	
	for part in tree_parts:
		if part.get_instance_id() == shelter_data.branch_id:
			part.add_child(shelter_visual)
			return
	
	# Fallback if branch not found
	main_node.get_node("TreePivot").add_child(shelter_visual)
	shelter_visual.global_position = shelter_data.position

func spawn_ladder_visual(ladder_data):
	var ladder_visual = preload("res://scenes/gameplay/ladder.tscn").instantiate()
	ladder_visual.initialize(ladder_data)
	
	# Add to the scene
	var main_node = get_node("/root/Main")
	main_node.get_node("TreePivot").add_child(ladder_visual)
	ladder_visual.global_position = ladder_data.position
