extends MeshInstance3D

# Billboard script to make the sprite always face the camera
var camera: Camera3D

func _ready():
	# Find the main camera
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	
	# Set the material to use transparency
	if get_surface_override_material_count() > 0:
		var material = StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		set_surface_override_material(0, material)

func _process(_delta):
	if camera:
		# Make the billboard face the camera
		look_at(camera.global_position, Vector3.UP)
		# Rotate 180 degrees so the front of the sprite faces the camera
		rotate_object_local(Vector3.UP, PI)
