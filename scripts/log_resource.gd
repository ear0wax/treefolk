extends Node3D

# Log resource that can be clicked to collect or long-pressed to spawn treefolk
signal log_clicked
signal log_long_pressed

var can_interact = true
var long_press_time = 0.5  # Time in seconds to hold for spawning treefolk
var press_duration = 0.0
var is_pressing = false
var log_type = 0  # 0=normal, 1=mossy, 2=old

# Rotting mechanic
var rot_stage = 0  # 0=fresh, 1=starting, 2=advanced, 3=decayed, 4=fungus, 5=gone
var rot_timer = 0.0
var rot_speed = 1.0  # Base speed of rotting
var rot_stage_duration = 30.0  # Seconds per rot stage
var fungus_growth = 0.0  # Amount of fungus (0-1)
var fungus_type = 0  # 0=normal, 1=red, 2=blue, 3=glowing
var fungus_instances = []

func _ready():
	# Randomly select log type
	log_type = randi() % 3
	
	# Randomly select fungus type
	fungus_type = randi() % 4
	
	# Set up random rotation for visual variety
	rotation.y = randf() * 2 * PI
	
	# Load the appropriate texture based on log type
	var texture_path = "res://textures/gameplay/log.png"
	if log_type == 1:
		texture_path = "res://textures/gameplay/log_moss.png"
	elif log_type == 2:
		texture_path = "res://textures/gameplay/log_old.png"
	
	# Apply texture to the log mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.2)  # Base wood color
	
	var texture = load(texture_path)
	if texture:
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		$LogMesh.set_surface_override_material(0, material)
	
	# Add a small animation when spawned
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1, 1, 1), 0.3).from(Vector3(0, 0, 0))
	tween.tween_property(self, "position:y", position.y, 0.5).from(position.y + 1.0)
	
	# Adjust rot speed based on log type
	if log_type == 1:  # Mossy logs rot faster
		rot_speed = 1.5
	elif log_type == 2:  # Old logs rot faster
		rot_speed = 2.0

func _process(delta):
	if is_pressing:
		press_duration += delta
		
		# Visual feedback for long press
		if press_duration < long_press_time:
			var progress = press_duration / long_press_time
			$ProgressIndicator.visible = true
			$ProgressIndicator.value = progress * 100
		else:
			$ProgressIndicator.visible = false
	
	# Process rotting
	if rot_stage < 5:  # Not completely gone yet
		rot_timer += delta * rot_speed
		
		# Check if we should advance to the next rot stage
		if rot_timer >= rot_stage_duration:
			rot_timer = 0
			advance_rot_stage()
		
		# Update visual appearance based on rot progress
		update_rot_appearance(delta)

func _input(event):
	# Check for mouse input on this log
	if event is InputEventMouseButton and can_interact:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var camera = get_viewport().get_camera_3d()
			var ray_origin = camera.project_ray_origin(event.position)
			var ray_direction = camera.project_ray_normal(event.position)
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 100)
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == $LogCollider:
				if event.pressed:
					# Start tracking press duration
					is_pressing = true
					press_duration = 0.0
				else:
					# Button released
					if is_pressing:
						if press_duration < long_press_time:
							# Short click - collect log
							emit_signal("log_clicked")
							collect_log()
						else:
							# Long press - spawn treefolk
							emit_signal("log_long_pressed")
							spawn_treefolk()
						
						is_pressing = false
						$ProgressIndicator.visible = false

func collect_log():
	if can_interact:
		can_interact = false
		
		# Get the gameplay controller
		var gameplay_controller = get_node("/root/Main/GameplayController")
		gameplay_controller.add_log()
		
		# Play collection animation
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0, 0, 0), 0.3)
		tween.tween_callback(queue_free)

func spawn_treefolk():
	if can_interact:
		can_interact = false
		
		# Get the gameplay controller
		var gameplay_controller = get_node("/root/Main/GameplayController")
		var treefolk = gameplay_controller.spawn_treefolk()
		
		if treefolk:
			# Play hatching animation
			var tween = create_tween()
			tween.tween_property(self, "rotation", Vector3(0, PI * 4, 0), 0.5)
			tween.parallel().tween_property(self, "scale", Vector3(0, 0, 0), 0.3)
			tween.tween_callback(queue_free)
		else:
			# If treefolk couldn't be spawned, allow interaction again
			can_interact = true

func advance_rot_stage():
	rot_stage += 1
	print("Log advancing to rot stage: ", rot_stage)
	
	match rot_stage:
		1:  # Starting to rot
			# Darken the log slightly
			var material = $LogMesh.get_surface_override_material(0)
			if material:
				material.albedo_color = Color(0.5, 0.35, 0.15)
		
		2:  # Advanced rot
			# Darken more and add some green tint
			var material = $LogMesh.get_surface_override_material(0)
			if material:
				material.albedo_color = Color(0.4, 0.3, 0.1)
			
			# Start growing fungus
			spawn_initial_fungus()
		
		3:  # Decayed
			# Very dark and more green
			var material = $LogMesh.get_surface_override_material(0)
			if material:
				material.albedo_color = Color(0.3, 0.25, 0.1)
			
			# Grow more fungus
			spawn_more_fungus()
		
		4:  # Fungus dominated
			# Log barely visible
			var material = $LogMesh.get_surface_override_material(0)
			if material:
				material.albedo_color = Color(0.2, 0.2, 0.1)
				material.albedo_color.a = 0.7
			
			# Maximum fungus
			spawn_final_fungus()
		
		5:  # Gone
			# Log disappears, leaving only fungus
			var tween = create_tween()
			tween.tween_property($LogMesh, "scale", Vector3(0, 0, 0), 2.0)
			tween.tween_callback(func(): $LogMesh.visible = false)
			
			# Make fungus persist for a while then disappear
			var fungus_timer = Timer.new()
			add_child(fungus_timer)
			fungus_timer.wait_time = 60.0  # Fungus persists for 1 minute
			fungus_timer.one_shot = true
			fungus_timer.timeout.connect(func(): queue_free())
			fungus_timer.start()
			
			# Disable interaction
			can_interact = false

func update_rot_appearance(delta):
	# Update visual appearance based on current rot stage and progress
	if rot_stage > 0:
		# Calculate progress within current stage
		var stage_progress = rot_timer / rot_stage_duration
		
		# Update fungus growth
		if rot_stage >= 2:  # Fungus starts at stage 2
			fungus_growth = min(fungus_growth + delta * 0.02 * rot_speed, 1.0)
			update_fungus_appearance()

func spawn_initial_fungus():
	# Spawn 1-3 small fungus instances
	var count = 1 + randi() % 3
	
	for i in range(count):
		spawn_fungus_instance(0.3)  # Small size

func spawn_more_fungus():
	# Spawn 2-4 medium fungus instances
	var count = 2 + randi() % 3
	
	for i in range(count):
		spawn_fungus_instance(0.6)  # Medium size

func spawn_final_fungus():
	# Spawn 3-5 large fungus instances
	var count = 3 + randi() % 3
	
	for i in range(count):
		spawn_fungus_instance(1.0)  # Full size

func spawn_fungus_instance(size_factor):
	# Create a fungus instance
	var fungus = Node3D.new()
	fungus.name = "Fungus" + str(fungus_instances.size())
	add_child(fungus)
	
	# Position randomly on the log
	var angle = randf() * 2 * PI
	var radius = randf_range(0.1, 0.3)
	var height = randf_range(-0.1, 0.1)
	
	fungus.position = Vector3(
		cos(angle) * radius,
		height,
		sin(angle) * radius
	)
	
	# Random rotation
	fungus.rotation.y = randf() * 2 * PI
	
	# Create sprite
	var sprite = Sprite3D.new()
	fungus.add_child(sprite)
	
	# Set up sprite properties
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.01
	sprite.texture = load_fungus_texture()
	
	# Set initial scale (will grow over time)
	sprite.scale = Vector3(size_factor, size_factor, size_factor)
	
	# Add to tracking array
	fungus_instances.append(fungus)
	
	return fungus

func update_fungus_appearance():
	# Update all fungus instances based on growth
	for i in range(fungus_instances.size()):
		var fungus = fungus_instances[i]
		if fungus and is_instance_valid(fungus):
			# Get the sprite
			var sprite = fungus.get_child(0) if fungus.get_child_count() > 0 else null
			if sprite and sprite is Sprite3D:
				# Calculate individual growth factor
				var individual_growth = min(fungus_growth * (1.0 + randf_range(-0.2, 0.2)), 1.0)
				
				# Update scale
				var target_scale = Vector3(individual_growth, individual_growth, individual_growth)
				sprite.scale = sprite.scale.lerp(target_scale, 0.05)
				
				# Update color based on fungus type and growth
				match fungus_type:
					0:  # Normal (white/tan)
						sprite.modulate = Color(1.0, 0.9, 0.8)
					1:  # Red
						sprite.modulate = Color(1.0, 0.5, 0.4)
					2:  # Blue
						sprite.modulate = Color(0.6, 0.7, 1.0)
					3:  # Glowing
						# Pulse the glow
						var pulse = (sin(Time.get_ticks_msec() * 0.001) + 1.0) * 0.5
						sprite.modulate = Color(0.8 + pulse * 0.4, 0.9 + pulse * 0.2, 0.6 + pulse * 0.4)

func load_fungus_texture():
	# Load the appropriate fungus texture based on type
	var texture_path = "res://textures/gameplay/fungus_normal.png"
	
	match fungus_type:
		0:  # Normal
			texture_path = "res://textures/gameplay/fungus_normal.png"
		1:  # Red
			texture_path = "res://textures/gameplay/fungus_red.png"
		2:  # Blue
			texture_path = "res://textures/gameplay/fungus_blue.png"
		3:  # Glowing
			texture_path = "res://textures/gameplay/fungus_glow.png"
	
	# Try to load the texture
	var texture = load(texture_path)
	
	# If texture doesn't exist yet, use a placeholder and queue generation
	if not texture:
		# Return a placeholder and request texture generation
		request_fungus_texture_generation()
		return load("res://icon.png")  # Use icon as placeholder
	
	return texture

func request_fungus_texture_generation():
	# Find the fungus texture generator
	var root = get_tree().get_root()
	if root.has_node("Main/FungusTextureGenerator"):
		var generator = root.get_node("Main/FungusTextureGenerator")
		generator.generate_fungus_textures()
	else:
		# Create the generator if it doesn't exist
		var main = root.get_node("Main")
		if main:
			var generator_script = load("res://scripts/fungus_texture_generator.gd")
			if generator_script:
				var generator = generator_script.new()
				generator.name = "FungusTextureGenerator"
				main.add_child(generator)
				generator.generate_fungus_textures()
