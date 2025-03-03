extends Node3D

# Camera parameters
var camera_distance = 10.0
var min_distance = 0.5    # Allow very close zoom
var max_distance = 50.0   # Allow far zoom
var vertical_offset = 0.0  # Vertical position of the camera
var rotation_speed = 0.01
var vertical_speed = 0.05
var zoom_speed = 1.0
var is_dragging = false
var last_mouse_pos = Vector2()

# Orbit parameters
var orbit_angle = 0.0
var orbit_height = 5.0

func _ready():
	# Set initial camera position
	update_camera_position()

func _process(_delta):
	# No need for look_at in process - we'll handle rotation directly
	pass

# Update camera position based on orbit parameters
func update_camera_position():
	# Calculate camera position based on orbit angle and distance
	var camera_x = sin(orbit_angle) * camera_distance
	var camera_z = cos(orbit_angle) * camera_distance
	var camera_y = vertical_offset
	
	# Set camera position
	transform.origin = Vector3(0, camera_y, 0)
	$Camera3D.transform.origin = Vector3(camera_x, 0, camera_z)
	
	# Make camera look at the tree
	$Camera3D.look_at(Vector3(0, camera_y, 0), Vector3.UP)

func _input(event):
	# Right mouse button for grabbing and manipulating the tree
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			if is_dragging:
				last_mouse_pos = event.position
				Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			else:
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		
		# Zoom with mouse wheel - no limits
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(0.1, camera_distance - zoom_speed)
			update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance += zoom_speed
			update_camera_position()
	
	# Handle tree manipulation with right-click drag
	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position - last_mouse_pos
		last_mouse_pos = event.position
		
		# Horizontal movement rotates the camera around the tree
		orbit_angle -= delta.x * rotation_speed
		
		# Vertical movement changes camera height
		vertical_offset += delta.y * vertical_speed
		
		# Update camera position based on new orbit parameters
		update_camera_position()
