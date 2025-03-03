extends Node2D

# Crow that flies across the screen and drops logs
var speed = 200
var drop_position = Vector2(0, 0)
var has_dropped_log = false
var exit_after_drop = true
var viewport_size

func _ready():
	viewport_size = get_viewport_rect().size
	
	# Randomize crow appearance slightly
	scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
	# Play flying animation
	$AnimatedSprite2D.play("fly")

func _process(delta):
	# Move crow from left to right
	position.x += speed * delta
	
	# Check if we've reached the drop position
	if not has_dropped_log and position.x >= drop_position.x:
		drop_log()
		has_dropped_log = true
	
	# Remove crow when it exits the screen
	if position.x > viewport_size.x + 100:
		queue_free()

func set_drop_position(pos):
	drop_position = pos

func drop_log():
	# Create a log instance
	var log = preload("res://scenes/gameplay/log.tscn").instantiate()
	
	# Convert 2D position to 3D world position
	var camera = get_viewport().get_camera_3d()
	var drop_pos_3d = camera.project_position(drop_position, 10)
	
	# Adjust position to be on the ground near the tree
	drop_pos_3d.y = 0
	
	# Limit how far from the tree center the log can be
	var dir_to_center = Vector2(drop_pos_3d.x, drop_pos_3d.z).normalized()
	var distance = Vector2(drop_pos_3d.x, drop_pos_3d.z).length()
	distance = clamp(distance, 2, 8)  # Keep logs within reasonable distance
	drop_pos_3d.x = dir_to_center.x * distance
	drop_pos_3d.z = dir_to_center.y * distance
	
	# Set the log position
	log.position = drop_pos_3d
	
	# Add the log to the scene
	var main_node = get_node("/root/Main")
	main_node.add_child(log)
	
	# Play sound effect
	$DropSound.play()
