extends Node

# Fungus texture generator for 16-bit style pixel art
# This script generates pixel art textures for different types of fungi

func _ready():
	generate_fungus_textures()

func generate_fungus_textures():
	# Create textures directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	if not dir.dir_exists("textures/gameplay"):
		dir.make_dir("textures/gameplay")
	
	# Generate and save fungus textures
	var normal_fungus = generate_fungus_texture(0)
	save_texture(normal_fungus, "res://textures/gameplay/fungus_normal.png")
	
	var red_fungus = generate_fungus_texture(1)
	save_texture(red_fungus, "res://textures/gameplay/fungus_red.png")
	
	var blue_fungus = generate_fungus_texture(2)
	save_texture(blue_fungus, "res://textures/gameplay/fungus_blue.png")
	
	var glow_fungus = generate_fungus_texture(3)
	save_texture(glow_fungus, "res://textures/gameplay/fungus_glow.png")
	
	print("Fungus textures generated successfully")

func generate_fungus_texture(fungus_type: int = 0) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Base colors for different fungus types
	var cap_color = Color(1.0, 0.9, 0.8)  # Default cream/white
	var stem_color = Color(0.9, 0.85, 0.7)  # Default light tan
	var detail_color = Color(0.8, 0.75, 0.6)  # Default darker tan
	var accent_color = Color(1.0, 1.0, 0.9)  # Default highlight
	
	# Adjust colors based on fungus type
	match fungus_type:
		1:  # Red fungus
			cap_color = Color(0.9, 0.3, 0.2)  # Red
			stem_color = Color(0.8, 0.6, 0.5)  # Pinkish tan
			detail_color = Color(0.7, 0.2, 0.1)  # Dark red
			accent_color = Color(1.0, 0.5, 0.4)  # Light red
		
		2:  # Blue fungus
			cap_color = Color(0.4, 0.5, 0.8)  # Blue
			stem_color = Color(0.5, 0.6, 0.7)  # Bluish gray
			detail_color = Color(0.3, 0.4, 0.6)  # Dark blue
			accent_color = Color(0.6, 0.7, 1.0)  # Light blue
		
		3:  # Glowing fungus
			cap_color = Color(0.7, 0.9, 0.5)  # Greenish
			stem_color = Color(0.6, 0.7, 0.4)  # Lighter green
			detail_color = Color(0.5, 0.6, 0.3)  # Dark green
			accent_color = Color(0.9, 1.0, 0.7)  # Bright green-yellow
	
	# Randomly select a fungus shape
	var shape = randi() % 4
	
	match shape:
		0:  # Classic mushroom
			draw_classic_mushroom(img, cap_color, stem_color, detail_color, accent_color)
		1:  # Shelf fungus
			draw_shelf_fungus(img, cap_color, stem_color, detail_color, accent_color)
		2:  # Cluster fungus
			draw_cluster_fungus(img, cap_color, stem_color, detail_color, accent_color)
		3:  # Tall mushroom
			draw_tall_mushroom(img, cap_color, stem_color, detail_color, accent_color)
	
	# Add glow effect for type 3
	if fungus_type == 3:
		add_glow_effect(img)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_classic_mushroom(img: Image, cap_color: Color, stem_color: Color, detail_color: Color, accent_color: Color):
	# Draw the stem
	for y in range(16, 26):
		for x in range(13, 19):
			if abs(x - 16) < 3:
				img.set_pixel(x, y, stem_color)
				
				# Add some texture to the stem
				if (x + y) % 3 == 0:
					img.set_pixel(x, y, detail_color)
	
	# Draw the cap
	for y in range(10, 16):
		for x in range(8, 24):
			var center_x = 16
			var center_y = 13
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a mushroom cap shape
			var cap_width = 8 - (y - 10) * 1.5
			if dist_x < cap_width:
				img.set_pixel(x, y, cap_color)
				
				# Add some texture/detail to the cap
				if dist_x > cap_width - 2 or y == 10:
					img.set_pixel(x, y, detail_color)
				
				# Add spots/highlights
				if (x + y) % 5 == 0 and dist_x < cap_width - 2:
					img.set_pixel(x, y, accent_color)

func draw_shelf_fungus(img: Image, cap_color: Color, stem_color: Color, detail_color: Color, accent_color: Color):
	# Shelf fungi grow on the side, no real stem
	
	# Draw the main shelf body
	for y in range(12, 24):
		for x in range(10, 22):
			var center_x = 16
			var center_y = 18
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			// Create a semicircular shelf shape
			if dist_x*dist_x + dist_y*dist_y < 64 and x <= center_x:
				img.set_pixel(x, y, cap_color)
				
				// Add some texture/detail
				if dist_x*dist_x + dist_y*dist_y > 49:
					img.set_pixel(x, y, detail_color)
				
				// Add growth rings
				if (dist_x*dist_x + dist_y*dist_y) % 10 < 2:
					img.set_pixel(x, y, accent_color)
	
	// Add attachment point to the "tree"
	for y in range(14, 22):
		for x in range(20, 24):
			if x > 21:
				img.set_pixel(x, y, stem_color)

func draw_cluster_fungus(img: Image, cap_color: Color, stem_color: Color, detail_color: Color, accent_color: Color):
	// Draw multiple small mushrooms in a cluster
	
	// Define cluster positions
	var positions = [
		Vector2(12, 18),  // Bottom left
		Vector2(16, 20),  // Bottom center
		Vector2(20, 19),  // Bottom right
		Vector2(14, 14),  // Middle left
		Vector2(18, 15)   // Middle right
	]
	
	// Draw each mushroom in the cluster
	for pos in positions:
		var size = randf_range(1.5, 3.0)
		
		// Draw stem
		for y in range(int(pos.y), int(pos.y + 4)):
			for x in range(int(pos.x - 1), int(pos.x + 2)):
				img.set_pixel(x, y, stem_color)
		
		// Draw cap
		for y in range(int(pos.y - size), int(pos.y + 1)):
			for x in range(int(pos.x - size), int(pos.x + size + 1)):
				var dist = sqrt(pow(x - pos.x, 2) + pow(y - pos.y, 2))
				if dist <= size:
					img.set_pixel(x, y, cap_color)
					
					// Add some detail to the cap edge
					if dist > size - 1:
						img.set_pixel(x, y, detail_color)
					
					// Add some spots
					if (x + y) % 3 == 0 and dist < size - 1:
						img.set_pixel(x, y, accent_color)

func draw_tall_mushroom(img: Image, cap_color: Color, stem_color: Color, detail_color: Color, accent_color: Color):
	// Draw a tall, thin mushroom
	
	// Draw the stem
	for y in range(10, 26):
		for x in range(14, 19):
			if abs(x - 16) < 2:
				img.set_pixel(x, y, stem_color)
				
				// Add some texture to the stem
				if (x + y) % 4 == 0:
					img.set_pixel(x, y, detail_color)
	
	// Draw the cap (pointy)
	for y in range(5, 10):
		for x in range(10, 22):
			var center_x = 16
			var center_y = 10
			var dist_x = abs(x - center_x)
			var dist_y = center_y - y
			
			// Create a conical cap shape
			if dist_x < 6 - dist_y:
				img.set_pixel(x, y, cap_color)
				
				// Add some texture/detail to the cap
				if dist_x > 4 - dist_y or y == 5:
					img.set_pixel(x, y, detail_color)
				
				// Add some highlights
				if (x * y) % 7 == 0 and dist_x < 4 - dist_y:
					img.set_pixel(x, y, accent_color)

func add_glow_effect(img: Image):
	// Add a subtle glow around the fungus
	var temp_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	temp_img.copy_from(img)
	
	// For each non-transparent pixel, add a glow around it
	for y in range(0, 32):
		for x in range(0, 32):
			if img.get_pixel(x, y).a > 0:
				// Add glow in a small radius
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var nx = x + dx
						var ny = y + dy
						
						if nx >= 0 and nx < 32 and ny >= 0 and ny < 32:
							var dist = sqrt(dx*dx + dy*dy)
							if dist <= 2 and temp_img.get_pixel(nx, ny).a == 0:
								var intensity = (2 - dist) / 2.0
								var glow_color = Color(0.9, 1.0, 0.7, intensity * 0.5)
								temp_img.set_pixel(nx, ny, glow_color)
	
	// Copy back to original
	img.copy_from(temp_img)

func save_texture(texture: ImageTexture, path: String) -> void:
	var img = texture.get_image()
	img.save_png(path)
	print("Saved texture to: " + path)
