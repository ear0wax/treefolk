extends Node3D

# Visual representation of a treefolk worker
var treefolk_data = null
var move_speed = 1.0
var is_moving = false
var target_position = Vector3()
var treefolk_type = 0  # 0=normal, 1=elder, 2=sapling

func _ready():
	# Randomly select treefolk type with weighted probability
	var roll = randf()
	if roll < 0.15:
		treefolk_type = 1  # Elder (15% chance)
	elif roll < 0.35:
		treefolk_type = 2  # Sapling (20% chance)
	else:
		treefolk_type = 0  # Normal (65% chance)
	
	# Set up random appearance variations
	randomize_appearance()
	
	# Load the appropriate texture based on treefolk type
	var texture_path = "res://textures/gameplay/treefolk_sprite.png"
	if treefolk_type == 1:
		texture_path = "res://textures/gameplay/treefolk_elder.png"
	elif treefolk_type == 2:
		texture_path = "res://textures/gameplay/treefolk_sapling.png"
	
	# Apply texture to the sprite
	var texture = load(texture_path)
	if texture:
		$AnimatedSprite3D.sprite_frames.clear_all()
		$AnimatedSprite3D.sprite_frames.add_animation("idle")
		$AnimatedSprite3D.sprite_frames.add_animation("walk")
		$AnimatedSprite3D.sprite_frames.add_animation("action")
		$AnimatedSprite3D.sprite_frames.add_animation("rest")
		
		# Set frame rate
		$AnimatedSprite3D.sprite_frames.set_animation_speed("idle", 5)
		$AnimatedSprite3D.sprite_frames.set_animation_speed("walk", 8)
		$AnimatedSprite3D.sprite_frames.set_animation_speed("action", 5)
		$AnimatedSprite3D.sprite_frames.set_animation_speed("rest", 3)
		
		# Add frames from the spritesheet
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(0, 0, 32, 32)
		$AnimatedSprite3D.sprite_frames.add_frame("idle", atlas_texture, 0)
		
		for i in range(3):
			var walk_texture = AtlasTexture.new()
			walk_texture.atlas = texture
			walk_texture.region = Rect2((i+1) * 32, 0, 32, 32)
			$AnimatedSprite3D.sprite_frames.add_frame("walk", walk_texture, 0)
		
		var action_texture = AtlasTexture.new()
		action_texture.atlas = texture
		action_texture.region = Rect2(0, 32, 32, 32)
		$AnimatedSprite3D.sprite_frames.add_frame("action", action_texture, 0)
		
		var rest_texture = AtlasTexture.new()
		rest_texture.atlas = texture
		rest_texture.region = Rect2(32, 32, 32, 32)
		$AnimatedSprite3D.sprite_frames.add_frame("rest", rest_texture, 0)

func _process(delta):
	if treefolk_data:
		# Update position based on task
		if is_moving:
			var direction = (target_position - position).normalized()
			position += direction * move_speed * delta
			
			# Look in the direction of movement
			if direction.length_squared() > 0.01:
				look_at(position + Vector3(direction.x, 0, direction.z), Vector3.UP)
			
			# Check if we've reached the target
			if position.distance_to(target_position) < 0.1:
				is_moving = false
				
				# Play idle animation
				$AnimatedSprite3D.play("idle")
		
		# Update task progress indicator
		update_progress_indicator()

func initialize(data):
	treefolk_data = data
	
	# Set initial position
	position = Vector3(0, 0, 0)
	
	# Set target position
	set_target(treefolk_data.target)
	
	# Set name label
	$NameLabel/Viewport/Label.text = treefolk_data.name
	
	# Adjust efficiency based on treefolk type
	if treefolk_type == 1:  # Elder
		treefolk_data.efficiency = 1.3  # 30% more efficient
	elif treefolk_type == 2:  # Sapling
		treefolk_data.efficiency = 0.9  # 10% less efficient

func set_target(target):
	target_position = target
	is_moving = true
	
	# Play walking animation
	$AnimatedSprite3D.play("walk")

func randomize_appearance():
	# Randomize treefolk appearance
	var color_variation = randf_range(0.8, 1.2)
	$AnimatedSprite3D.modulate = Color(
		color_variation, 
		color_variation, 
		color_variation
	)
	
	# Randomize scale slightly
	var scale_variation = randf_range(0.9, 1.1)
	scale = Vector3(scale_variation, scale_variation, scale_variation)
	
	# Adjust scale based on type
	if treefolk_type == 1:  # Elder - larger
		scale = scale * 1.2
	elif treefolk_type == 2:  # Sapling - smaller
		scale = scale * 0.8

func update_progress_indicator():
	if treefolk_data:
		var task_duration = get_task_duration(treefolk_data.task)
		var progress = treefolk_data.progress / task_duration
		
		$TaskProgressBar.visible = progress > 0 and progress < 1
		$TaskProgressBar.value = progress * 100
		
		# Update task icon
		update_task_icon(treefolk_data.task)
		
		# Update animation based on task
		if !is_moving and progress > 0:
			if treefolk_data.task == 0:  # IDLE
				$AnimatedSprite3D.play("rest")
			else:
				$AnimatedSprite3D.play("action")

func get_task_duration(task_type):
	# This should match the durations in gameplay_controller.gd
	match task_type:
		0:  # IDLE
			return 5.0
		1:  # COLLECT_LOG
			return 10.0
		2:  # BUILD_SHELTER
			return 20.0
		3:  # BUILD_LADDER
			return 15.0
		4:  # MAINTAIN_TREE
			return 12.0
		_:
			return 5.0

func update_task_icon(task_type):
	# Hide all icons first
	$TaskIcons/IdleIcon.visible = false
	$TaskIcons/LogIcon.visible = false
	$TaskIcons/ShelterIcon.visible = false
	$TaskIcons/LadderIcon.visible = false
	$TaskIcons/MaintainIcon.visible = false
	
	# Show the appropriate icon
	match task_type:
		0:  # IDLE
			$TaskIcons/IdleIcon.visible = true
		1:  # COLLECT_LOG
			$TaskIcons/LogIcon.visible = true
		2:  # BUILD_SHELTER
			$TaskIcons/ShelterIcon.visible = true
		3:  # BUILD_LADDER
			$TaskIcons/LadderIcon.visible = true
		4:  # MAINTAIN_TREE
			$TaskIcons/MaintainIcon.visible = true
