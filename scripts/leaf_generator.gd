extends PixelArtBase

func _ready():
	# Generate the texture when the scene is loaded with default seed 3146
	generate_texture(3146)

func generate_texture(seed_value: int = 3146) -> void:
	initialize(seed_value)
	
	var texture = generate_leaf_texture()
	ensure_textures_dir()
	save_texture(texture, "res://textures/leaf.png")
	
	# Update the sprite if it exists
	var parent = get_parent()
	if parent and parent.has_node("Sprite3D"):
		var sprite = parent.get_node("Sprite3D")
		sprite.texture = texture

func generate_leaf_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Leaf style variations
	var leaf_styles = ["standard", "maple", "pine", "tropical", "magical", "crystal"]
	var style_index = 0
	
	if use_fixed_seed:
		style_index = generation_seed % leaf_styles.size()
	else:
		style_index = randi() % leaf_styles.size()
	
	var style = leaf_styles[style_index]
	
	# Base colors with high variation
	var leaf_color = Color(0.2, 0.5, 0.2)  # Default green
	var vein_color = Color(0.3, 0.6, 0.3)  # Default lighter green
	var highlight_color = Color(0.4, 0.7, 0.4)  # Default highlight
	
	# Dramatically vary the colors based on the seed
	if use_fixed_seed:
		# Use the seed to create very different color palettes
		var hue_shift = fmod(float(generation_seed) / 1000.0, 1.0)
		var saturation = fmod(float(generation_seed) / 500.0, 0.5) + 0.5
		var value = fmod(float(generation_seed) / 250.0, 0.3) + 0.7
		
		leaf_color = Color.from_hsv(hue_shift, saturation, value)
		vein_color = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation * 0.8, value * 1.2)
		highlight_color = Color.from_hsv(fmod(hue_shift - 0.05, 1.0), saturation * 0.7, value * 1.3)
		
		# Seasonal variations
		var season = generation_seed % 4
		match season:
			0:  # Spring - fresh green
				leaf_color = Color(0.2, 0.6, 0.2).lerp(leaf_color, 0.3)
				vein_color = Color(0.3, 0.7, 0.3).lerp(vein_color, 0.3)
			1:  # Summer - deep green
				leaf_color = Color(0.1, 0.4, 0.1).lerp(leaf_color, 0.3)
				vein_color = Color(0.2, 0.5, 0.2).lerp(vein_color, 0.3)
			2:  # Fall - orange/red
				leaf_color = Color(0.7, 0.3, 0.1).lerp(leaf_color, 0.3)
				vein_color = Color(0.8, 0.4, 0.1).lerp(vein_color, 0.3)
			3:  # Winter - brown/sparse
				leaf_color = Color(0.5, 0.4, 0.2).lerp(leaf_color, 0.3)
				vein_color = Color(0.6, 0.5, 0.3).lerp(vein_color, 0.3)
	
	# Draw the leaf based on style
	match style:
		"standard":
			draw_standard_leaf(img, leaf_color, vein_color, highlight_color)
		"maple":
			draw_maple_leaf(img, leaf_color, vein_color, highlight_color)
		"pine":
			draw_pine_needle(img, leaf_color, vein_color, highlight_color)
		"tropical":
			draw_tropical_leaf(img, leaf_color, vein_color, highlight_color)
		"magical":
			draw_magical_leaf(img, leaf_color, vein_color, highlight_color)
		"crystal":
			draw_crystal_leaf(img, leaf_color, vein_color, highlight_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_standard_leaf(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a simple oval leaf shape
	for y in range(8, 24):
		for x in range(8, 24):
			var center_x = 16
			var center_y = 16
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a leaf shape with seed-based variation
			var shape_factor
			if use_fixed_seed:
				shape_factor = 12 - (generation_seed % 3)
			else:
				shape_factor = 12
				
			if dist_x + dist_y < shape_factor - (dist_x * dist_y) / 16:
				img.set_pixel(x, y, leaf_color)
	
	# Add leaf veins
	for y in range(8, 24):
		for x in range(8, 24):
			if img.get_pixel(x, y).a > 0:
				# Central vein
				if abs(x - 16) < 1:
					img.set_pixel(x, y, vein_color)
				
				# Side veins with seed-based pattern
				var vein_pattern
				if use_fixed_seed:
					vein_pattern = (y - 8 + generation_seed % 3) % 3
				else:
					vein_pattern = (y - 8) % 3
					
				if vein_pattern == 0 and abs(x - 16) < 8 - abs(y - 16) / 2:
					img.set_pixel(x, y, vein_color)
	
	# Add some highlights
	for y in range(8, 24):
		for x in range(8, 24):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 7 == 0:
					img.set_pixel(x, y, highlight_color)

func draw_maple_leaf(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a maple leaf with lobes
	var center_x = 16
	var center_y = 16
	
	# Draw the basic shape first
	for y in range(4, 28):
		for x in range(4, 28):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			var angle = atan2(y - center_y, x - center_x)
			
			# Create a maple leaf shape with lobes
			var radius = 12
			
			# Add lobes based on angle
			var lobe_factor = 0.7 + 0.3 * sin(5 * angle)
			
			if dist_x*dist_x + dist_y*dist_y < radius*radius * lobe_factor:
				img.set_pixel(x, y, leaf_color)
	
	# Add veins
	for i in range(5):  # 5 main veins for maple leaf
		var angle = i * PI / 2.5
		var length = 10
		
		for j in range(length):
			var progress = float(j) / length
			var x = center_x + cos(angle) * j
			var y = center_y + sin(angle) * j
			
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				if img.get_pixel(int(x), int(y)).a > 0:
					img.set_pixel(int(x), int(y), vein_color)
	
	# Add some highlights
	for y in range(4, 28):
		for x in range(4, 28):
			if img.get_pixel(x, y).a > 0:
				if (x * y) % 13 == 0:
					img.set_pixel(x, y, highlight_color)

func draw_pine_needle(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a pine needle (thin and elongated)
	var center_x = 16
	var center_y = 16
	
	# Draw the needle shape
	for y in range(8, 24):
		for x in range(8, 24):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a thin needle shape
			if dist_x < 1 and dist_y < 8:
				img.set_pixel(x, y, leaf_color)
			
			# Add some width in the middle
			if dist_y < 4 and dist_y > 2 and dist_x < 2:
				img.set_pixel(x, y, leaf_color)
	
	# Add central vein
	for y in range(8, 24):
		if img.get_pixel(center_x, y).a > 0:
			img.set_pixel(center_x, y, vein_color)
	
	# Add some highlights
	for y in range(8, 24):
		for x in range(8, 24):
			if img.get_pixel(x, y).a > 0:
				if y % 5 == 0:
					img.set_pixel(x, y, highlight_color)

func draw_tropical_leaf(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a large tropical leaf with splits
	var center_x = 16
	var center_y = 16
	
	# Draw the basic shape first
	for y in range(4, 28):
		for x in range(4, 28):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a large oval shape
			if dist_x*dist_x/36 + dist_y*dist_y/144 < 1:
				# Add splits/cuts in the leaf
				var split_factor = sin(dist_x * 0.8) * 2
				if abs(dist_y - split_factor) > 1.5:
					img.set_pixel(x, y, leaf_color)
	
	# Add central vein
	for y in range(4, 28):
		if img.get_pixel(center_x, y).a > 0:
			img.set_pixel(center_x, y, vein_color)
	
	# Add side veins
	for y in range(8, 24, 3):
		for x in range(4, 28):
			if img.get_pixel(x, y).a > 0:
				if abs(x - center_x) < 10:
					img.set_pixel(x, y, vein_color)
	
	# Add some highlights
	for y in range(4, 28):
		for x in range(4, 28):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 9 == 0:
					img.set_pixel(x, y, highlight_color)

func draw_magical_leaf(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a glowing magical leaf
	var center_x = 16
	var center_y = 16
	
	# Adjust colors for magical appearance
	highlight_color = Color(0.7, 0.9, 1.0).lerp(highlight_color, 0.3)  # Add blue-ish glow
	
	# Draw the basic shape first
	for y in range(6, 26):
		for x in range(6, 26):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a leaf shape
			if dist_x*dist_x/25 + dist_y*dist_y/36 < 1:
				img.set_pixel(x, y, leaf_color)
	
	# Add glowing veins
	for y in range(6, 26):
		for x in range(6, 26):
			if img.get_pixel(x, y).a > 0:
				# Central vein
				if abs(x - center_x) < 1:
					img.set_pixel(x, y, highlight_color)
				
				# Side veins
				if (y - 6) % 4 == 0 and abs(x - center_x) < 8:
					img.set_pixel(x, y, highlight_color)
	
	# Add glowing aura
	for y in range(4, 28):
		for x in range(4, 28):
			if img.get_pixel(x, y).a == 0:  # Only add aura to transparent pixels
				var closest_leaf_pixel = false
				var min_dist = 100
				
				# Check nearby pixels for leaf
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var nx = x + dx
						var ny = y + dy
						
						if nx >= 0 and nx < 32 and ny >= 0 and ny < 32:
							if img.get_pixel(nx, ny).a > 0:
								var dist = sqrt(dx*dx + dy*dy)
								if dist < min_dist:
									min_dist = dist
									closest_leaf_pixel = true
				
				if closest_leaf_pixel and min_dist < 3:
					var intensity = 1.0 - (min_dist / 3.0)
					var aura_color = highlight_color
					aura_color.a = intensity * 0.5
					img.set_pixel(x, y, aura_color)
	
	# Add some magical sparkles
	var sparkle_count = 5
	if use_fixed_seed:
		sparkle_count = seeded_randi_range(3, 7)
	
	for i in range(sparkle_count):
		var sparkle_x
		var sparkle_y
		
		if use_fixed_seed:
			sparkle_x = seeded_randi_range(8, 24)
			sparkle_y = seeded_randi_range(8, 24)
		else:
			sparkle_x = randi_range(8, 24)
			sparkle_y = randi_range(8, 24)
		
		if img.get_pixel(sparkle_x, sparkle_y).a > 0:
			img.set_pixel(sparkle_x, sparkle_y, Color(1, 1, 1))
			
			# Add tiny cross shape for sparkle
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx = sparkle_x + offset.x
				var sy = sparkle_y + offset.y
				if sx >= 0 and sx < 32 and sy >= 0 and sy < 32:
					if img.get_pixel(sx, sy).a > 0:
						var sparkle_color = Color(1, 1, 1)
						sparkle_color.a = 0.7
						img.set_pixel(sx, sy, sparkle_color)

func draw_crystal_leaf(img: Image, leaf_color: Color, vein_color: Color, highlight_color: Color) -> void:
	# Draw a crystalline leaf
	var center_x = 16
	var center_y = 16
	
	# Adjust colors for crystal appearance
	leaf_color = Color(0.6, 0.8, 0.9).lerp(leaf_color, 0.3)  # Add blue-ish crystal tone
	vein_color = Color(0.4, 0.6, 0.8).lerp(vein_color, 0.3)
	highlight_color = Color(0.8, 0.9, 1.0).lerp(highlight_color, 0.3)
	
	# Draw the crystal leaf shape
	for y in range(6, 26):
		for x in range(6, 26):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			# Create a geometric crystal shape
			if dist_x + dist_y < 12:
				# Create faceted appearance with geometric patterns
				var pattern_value = (x * 3 + y * 5) % 7
				
				if pattern_value < 3:
					img.set_pixel(x, y, leaf_color)
				elif pattern_value < 5:
					img.set_pixel(x, y, vein_color)
				else:
					img.set_pixel(x, y, highlight_color)
	
	# Add crystal fracture lines
	for i in range(3):  # 3 main fracture lines
		var angle
		var length
		
		if use_fixed_seed:
			angle = seeded_randf() * PI
			length = seeded_randf_range(8, 12)
		else:
			angle = randf() * PI
			length = randf_range(8, 12)
		
		for j in range(int(length)):
			var x = center_x + cos(angle) * j
			var y = center_y + sin(angle) * j
			
			if x >= 0 and x < 32 and y >= 0 and y < 32:
				if img.get_pixel(int(x), int(y)).a > 0:
					img.set_pixel(int(x), int(y), highlight_color)
