extends Node

# This script ensures all required textures exist before the game starts
# It should be added to the main scene and run during _ready()

func _ready():
	ensure_all_textures()

func ensure_all_textures():
	print("Ensuring all textures exist...")
	
	# Create textures directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
		print("Created textures directory")
	
	# Check and generate each texture if needed
	ensure_texture("res://textures/seed.png", generate_seed_texture)
	ensure_texture("res://textures/root.png", generate_root_texture)
	ensure_texture("res://textures/trunk.png", generate_trunk_texture)
	ensure_texture("res://textures/branch.png", generate_branch_texture)
	ensure_texture("res://textures/leaf.png", generate_leaf_texture)
	
	# Generate trunk variations
	ensure_texture("res://textures/trunk_plain.png", func(): return generate_trunk_texture(0))
	ensure_texture("res://textures/trunk_branch_left.png", func(): return generate_trunk_texture(1))
	ensure_texture("res://textures/trunk_branch_right.png", func(): return generate_trunk_texture(2))
	ensure_texture("res://textures/trunk_double_branch.png", func(): return generate_trunk_texture(3))
	ensure_texture("res://textures/trunk_multi_branch.png", func(): return generate_trunk_texture(4))
	
	print("All textures verified")

func ensure_texture(path: String, generator_func: Callable):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Generating missing texture: " + path)
		var texture = generator_func.call()
		var img = texture.get_image()
		img.save_png(path)
	else:
		file.close()
		print("Texture exists: " + path)

func generate_seed_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Seed body (acorn shape)
	var seed_color = Color(0.6, 0.4, 0.2)  # Brown
	var cap_color = Color(0.4, 0.25, 0.1)  # Darker brown for cap
	
	# Draw the seed body (oval shape)
	for y in range(12, 28):
		for x in range(12, 20):
			var dist_x = abs(x - 16)
			var dist_y = abs(y - 20)
			if dist_x*dist_x + dist_y*dist_y*2 < 36:
				img.set_pixel(x, y, seed_color)
	
	# Draw the seed cap
	for y in range(10, 14):
		for x in range(11, 21):
			var dist = abs(x - 16)
			if dist < 5 - (y - 10):
				img.set_pixel(x, y, cap_color)
	
	# Add some details/highlights
	for y in range(14, 26):
		for x in range(13, 19):
			if (x + y) % 5 == 0 and img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, seed_color.lightened(0.2))
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func generate_root_texture() -> ImageTexture:
	var img = Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var root_color = Color(0.5, 0.35, 0.2)  # Brown
	var detail_color = Color(0.4, 0.25, 0.1)  # Darker brown
	
	# Main root body
	for y in range(8, 40):
		for x in range(24, 40):
			var center_x = 32
			var center_y = 24
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a root shape
			if dist_x < 8 - dist_y/8:
				img.set_pixel(x, y, root_color)
	
	# Add some smaller roots branching out
	for i in range(3):
		var angle = randf() * PI
		var length = randf_range(10, 20)
		var start_x = 32
		var start_y = 24
		
		for j in range(int(length)):
			var x = start_x + cos(angle) * j
			var y = start_y + sin(angle) * j
			
			if x >= 0 and x < 64 and y >= 0 and y < 48:
				img.set_pixel(int(x), int(y), root_color)
				
				# Add some width to the roots
				for k in range(-1, 2):
					for l in range(-1, 2):
						var nx = int(x) + k
						var ny = int(y) + l
						if nx >= 0 and nx < 64 and ny >= 0 and ny < 48 and abs(k) + abs(l) == 1:
							if randf() > 0.5:
								img.set_pixel(nx, ny, root_color.darkened(0.2))
	
	# Add some texture details
	for y in range(8, 40):
		for x in range(24, 40):
			if img.get_pixel(x, y).a > 0 and randf() > 0.8:
				img.set_pixel(x, y, detail_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func generate_trunk_texture(type: int = 0) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var trunk_color = Color(0.45, 0.3, 0.15)  # Brown
	var bark_color = Color(0.35, 0.2, 0.1)  # Darker brown for bark
	var highlight_color = Color(0.55, 0.4, 0.25)  # Lighter for highlights
	
	# Draw the trunk
	for y in range(4, 60):
		for x in range(24, 40):
			var center_x = 32
			var width = 7 + sin(y * 0.1) * 2
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add branch connection points based on trunk type
	var branch_positions = []
	
	match type:
		0:  # Plain
			# No branches
			pass
			
		1:  # Single branch left
			# Add a single branch on the left
			var branch_y = randi_range(20, 40)
			draw_branch_connection(img, 24, branch_y, -1, trunk_color, bark_color)
			
		2:  # Single branch right
			# Add a single branch on the right
			var branch_y = randi_range(20, 40)
			draw_branch_connection(img, 40, branch_y, 1, trunk_color, bark_color)
			
		3:  # Double branch
			# Add branches on both sides
			var branch_y1 = randi_range(15, 30)
			var branch_y2 = randi_range(35, 50)
			draw_branch_connection(img, 24, branch_y1, -1, trunk_color, bark_color)
			draw_branch_connection(img, 40, branch_y2, 1, trunk_color, bark_color)
			
		4:  # Multi branch
			# Add multiple branches on both sides
			var num_branches = randi_range(3, 5)
			for i in range(num_branches):
				var branch_y = randi_range(10, 55)
				var side = 1 if randf() > 0.5 else -1
				var x_pos = 40 if side > 0 else 24
				draw_branch_connection(img, x_pos, branch_y, side, trunk_color, bark_color)
	
	# Add bark texture
	for y in range(4, 60):
		for x in range(24, 40):
			if img.get_pixel(x, y).a > 0:
				# Create vertical bark lines
				if (x + y*3) % 7 == 0 or (x - y*2) % 5 == 0:
					img.set_pixel(x, y, bark_color)
				
				# Add some random highlights
				if randf() > 0.9:
					img.set_pixel(x, y, highlight_color)
	
	# Add some knots in the wood
	for i in range(2):
		var knot_x = randf_range(26, 38)
		var knot_y = randf_range(15, 50)
		var knot_size = randf_range(1.5, 3)
		
		for y in range(int(knot_y - knot_size), int(knot_y + knot_size) + 1):
			for x in range(int(knot_x - knot_size), int(knot_x + knot_size) + 1):
				var dist = sqrt(pow(x - knot_x, 2) + pow(y - knot_y, 2))
				if dist <= knot_size and x >= 0 and x < 64 and y >= 0 and y < 64:
					if img.get_pixel(x, y).a > 0:
						img.set_pixel(x, y, bark_color.darkened(0.3))
	
	var texture = ImageTexture.create_from_image(img)
	return texture

# Draw a branch connection point on the trunk
func draw_branch_connection(img: Image, x_start: int, y_pos: int, direction: int, trunk_color: Color, bark_color: Color) -> void:
	var branch_length = 8
	var branch_width = 3
	
	# Draw the branch base
	for i in range(branch_length):
		var x = x_start + i * direction
		if x >= 0 and x < 64:
			for y in range(y_pos - branch_width, y_pos + branch_width + 1):
				if y >= 0 and y < 64:
					# Create a tapered branch
					var dist_y = abs(y - y_pos)
					if dist_y <= branch_width - i * 0.3:
						img.set_pixel(x, y, trunk_color)
						
						# Add some bark texture
						if (x + y) % 5 == 0:
							img.set_pixel(x, y, bark_color)

func generate_branch_texture() -> ImageTexture:
	var img = Image.create(96, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var branch_color = Color(0.4, 0.25, 0.1)  # Brown
	var detail_color = Color(0.3, 0.2, 0.1)  # Darker brown
	var leaf_color = Color(0.2, 0.5, 0.2)  # Green
	var leaf_highlight = Color(0.3, 0.6, 0.3)  # Lighter green
	
	# Draw the main branch - starting from the left edge
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 88
	var branch_end_y = 16
	
	# Draw the branch with varying thickness
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 3.0 * (1.0 - progress * 0.7)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					img.set_pixel(x, py, branch_color)
	
	# Add some bark texture
	for y in range(0, 32):
		for x in range(0, 88):
			if img.get_pixel(x, y).a > 0 and x % 5 == 0:
				img.set_pixel(x, y, detail_color)
	
	# Add some leaves
	for i in range(15):
		var leaf_x = randf_range(30, 90)
		var leaf_y = randf_range(8, 24)
		var leaf_size = randf_range(1, 3)
		
		# Only place leaves near the branch
		if abs(leaf_y - 16) > 4 and abs(leaf_y - 16) < 8:
			for y in range(int(leaf_y - leaf_size), int(leaf_y + leaf_size) + 1):
				for x in range(int(leaf_x - leaf_size), int(leaf_x + leaf_size) + 1):
					var dist = sqrt(pow(x - leaf_x, 2) + pow(y - leaf_y, 2))
					if dist <= leaf_size and x >= 0 and x < 96 and y >= 0 and y < 32:
						if randf() > 0.3:
							img.set_pixel(x, y, leaf_color)
						else:
							img.set_pixel(x, y, leaf_highlight)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func generate_leaf_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var leaf_color = Color(0.2, 0.5, 0.2)  # Green
	var vein_color = Color(0.3, 0.6, 0.3)  # Lighter green
	
	# Draw a simple leaf shape
	for y in range(8, 24):
		for x in range(8, 24):
			var center_x = 16
			var center_y = 16
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a leaf shape
			if dist_x + dist_y < 12 - (dist_x * dist_y) / 16:
				img.set_pixel(x, y, leaf_color)
	
	# Add leaf veins
	for y in range(8, 24):
		for x in range(8, 24):
			if img.get_pixel(x, y).a > 0:
				# Central vein
				if abs(x - 16) < 1:
					img.set_pixel(x, y, vein_color)
				
				# Side veins
				if (y - 8) % 3 == 0 and abs(x - 16) < 8 - abs(y - 16) / 2:
					img.set_pixel(x, y, vein_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture
