extends PixelArtBase

# Trunk types
enum TrunkType {
	PLAIN,
	SINGLE_BRANCH_LEFT,
	SINGLE_BRANCH_RIGHT,
	DOUBLE_BRANCH,
	MULTI_BRANCH
}

var trunk_type: TrunkType = TrunkType.PLAIN
var branch_positions = []

func _ready():
	# Generate the texture when the scene is loaded with default seed 3146
	generate_texture(3146)

func generate_texture(seed_value: int = 3146, type: TrunkType = TrunkType.PLAIN) -> void:
	initialize(seed_value)
	trunk_type = type
	
	var texture = generate_trunk_texture()
	ensure_textures_dir()
	save_texture(texture, "res://textures/trunk.png")
	
	# Update the sprite with the new texture
	var sprite = get_parent().get_node("Sprite3D")
	if sprite:
		sprite.texture = texture
		
	# Store branch positions for later use
	get_parent().set_meta("branch_positions", branch_positions)
	get_parent().set_meta("trunk_type", trunk_type)

func generate_trunk_texture() -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Trunk style variations
	var trunk_styles = ["standard", "birch", "pine", "ancient", "magical", "crystal"]
	var style_index = 0
	
	if use_fixed_seed:
		style_index = generation_seed % trunk_styles.size()
	else:
		style_index = randi() % trunk_styles.size()
	
	var style = trunk_styles[style_index]
	
	# Base colors with high variation
	var trunk_color = Color(0.45, 0.3, 0.15)  # Default brown
	var bark_color = Color(0.35, 0.2, 0.1)  # Default darker brown for bark
	var highlight_color = Color(0.55, 0.4, 0.25)  # Default lighter for highlights
	
	# Dramatically vary the colors based on the seed
	if use_fixed_seed:
		# Use the seed to create very different color palettes
		var hue_shift = fmod(float(generation_seed) / 1000.0, 1.0)
		var saturation = fmod(float(generation_seed) / 500.0, 0.5) + 0.5
		var value = fmod(float(generation_seed) / 250.0, 0.3) + 0.7
		
		trunk_color = Color.from_hsv(hue_shift, saturation, value)
		bark_color = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation, value * 0.8)
		highlight_color = Color.from_hsv(fmod(hue_shift - 0.05, 1.0), saturation * 0.8, value * 1.2)
	
	# Draw the trunk based on style
	match style:
		"standard":
			draw_standard_trunk(img, trunk_color, bark_color, highlight_color)
		"birch":
			draw_birch_trunk(img, trunk_color, bark_color, highlight_color)
		"pine":
			draw_pine_trunk(img, trunk_color, bark_color, highlight_color)
		"ancient":
			draw_ancient_trunk(img, trunk_color, bark_color, highlight_color)
		"magical":
			draw_magical_trunk(img, trunk_color, bark_color, highlight_color)
		"crystal":
			draw_crystal_trunk(img, trunk_color, bark_color, highlight_color)
	
	# Add branch connection points based on trunk type
	branch_positions.clear()
	add_branch_connections(img, trunk_color, bark_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_standard_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw the trunk
	for y in range(4, 60):
		for x in range(24, 40):
			var center_x = 32
			var width_variation
			if use_fixed_seed:
				width_variation = sin(y * 0.1 + generation_seed * 0.01) * 2
			else:
				width_variation = sin(y * 0.1) * 2
				
			var width = 7 + width_variation
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add bark texture
	for y in range(4, 60):
		for x in range(24, 40):
			if img.get_pixel(x, y).a > 0:
				# Create vertical bark lines with seed-based patterns
				var pattern1
				var pattern2
				if use_fixed_seed:
					pattern1 = (x + y*3 + generation_seed % 5) % 7
					pattern2 = (x - y*2 + generation_seed % 3) % 5
				else:
					pattern1 = (x + y*3) % 7
					pattern2 = (x - y*2) % 5
				
				if pattern1 == 0 or pattern2 == 0:
					img.set_pixel(x, y, bark_color)
				
				# Add some random highlights
				var rand_check
				if use_fixed_seed:
					rand_check = seeded_randf() > 0.9
				else:
					rand_check = randf() > 0.9
					
				if rand_check:
					img.set_pixel(x, y, highlight_color)
	
	# Add some knots in the wood
	var knot_count = 2
	if use_fixed_seed:
		knot_count = seeded_randi_range(1, 3)
		
	for i in range(knot_count):
		var knot_x
		var knot_y
		var knot_size
		
		if use_fixed_seed:
			knot_x = seeded_randf_range(26, 38)
			knot_y = seeded_randf_range(15, 50)
			knot_size = seeded_randf_range(1.5, 3)
		else:
			knot_x = randf_range(26, 38)
			knot_y = randf_range(15, 50)
			knot_size = randf_range(1.5, 3)
		
		for y in range(int(knot_y - knot_size), int(knot_y + knot_size) + 1):
			for x in range(int(knot_x - knot_size), int(knot_x + knot_size) + 1):
				var dist = sqrt(pow(x - knot_x, 2) + pow(y - knot_y, 2))
				if dist <= knot_size and x >= 0 and x < 64 and y >= 0 and y < 64:
					if img.get_pixel(x, y).a > 0:
						img.set_pixel(x, y, bark_color.darkened(0.3))

func draw_birch_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw a birch-like trunk with horizontal stripes
	var center_x = 32
	
	# Make the trunk color lighter for birch
	trunk_color = trunk_color.lightened(0.3)
	
	# Draw the main trunk
	for y in range(4, 60):
		for x in range(24, 40):
			var width_variation = sin(y * 0.08) * 1.5
			var width = 7 + width_variation
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add characteristic birch horizontal stripes
	for y in range(4, 60):
		if (y % 5 == 0) or (y % 7 == 0):
			var stripe_length
			var stripe_x
			
			if use_fixed_seed:
				stripe_length = seeded_randi_range(3, 8)
				stripe_x = seeded_randi_range(25, 35)
			else:
				stripe_length = randi_range(3, 8)
				stripe_x = randi_range(25, 35)
			
			for x in range(stripe_x, stripe_x + stripe_length):
				if x < 64 and img.get_pixel(x, y).a > 0:
					img.set_pixel(x, y, bark_color)
					
					# Add stripe above and below
					if y > 4 and img.get_pixel(x, y-1).a > 0:
						img.set_pixel(x, y-1, bark_color.lightened(0.2))
					if y < 59 and img.get_pixel(x, y+1).a > 0:
						img.set_pixel(x, y+1, bark_color.lightened(0.2))
	
	# Add some small dark spots
	var spot_count = 15
	if use_fixed_seed:
		spot_count = seeded_randi_range(10, 20)
	
	for i in range(spot_count):
		var spot_x
		var spot_y
		
		if use_fixed_seed:
			spot_x = seeded_randi_range(25, 39)
			spot_y = seeded_randi_range(5, 59)
		else:
			spot_x = randi_range(25, 39)
			spot_y = randi_range(5, 59)
		
		if img.get_pixel(spot_x, spot_y).a > 0:
			img.set_pixel(spot_x, spot_y, bark_color.darkened(0.1))

func draw_pine_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw a pine-like trunk with rough bark
	var center_x = 32
	
	# Adjust colors for pine
	trunk_color = trunk_color.darkened(0.1)
	bark_color = bark_color.darkened(0.2)
	
	# Draw the main trunk with slight taper
	for y in range(4, 60):
		for x in range(24, 40):
			var progress = float(y - 4) / 56.0
			var width = 8 - progress * 2  # Taper toward the top
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add deep vertical furrows characteristic of pine
	for y in range(4, 60):
		for x in range(24, 40):
			if img.get_pixel(x, y).a > 0:
				var furrow_pattern
				
				if use_fixed_seed:
					furrow_pattern = (x + generation_seed) % 4
				else:
					furrow_pattern = x % 4
				
				if furrow_pattern == 0:
					img.set_pixel(x, y, bark_color)
					
					# Make furrows continuous
					if y > 4 and img.get_pixel(x, y-1).a > 0:
						img.set_pixel(x, y-1, bark_color)
	
	# Add some resin/sap highlights
	var resin_count = 5
	if use_fixed_seed:
		resin_count = seeded_randi_range(3, 7)
	
	for i in range(resin_count):
		var resin_x
		var resin_y
		var resin_length
		
		if use_fixed_seed:
			resin_x = seeded_randi_range(26, 38)
			resin_y = seeded_randi_range(10, 40)
			resin_length = seeded_randi_range(3, 8)
		else:
			resin_x = randi_range(26, 38)
			resin_y = randi_range(10, 40)
			resin_length = randi_range(3, 8)
		
		for j in range(resin_length):
			var y = resin_y + j
			if y < 60 and img.get_pixel(resin_x, y).a > 0:
				img.set_pixel(resin_x, y, highlight_color)
				
				# Add some width to the resin streak
				if img.get_pixel(resin_x+1, y).a > 0 and randf() > 0.5:
					img.set_pixel(resin_x+1, y, highlight_color.darkened(0.1))

func draw_ancient_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw an ancient, gnarled trunk with deep texture
	var center_x = 32
	
	# Adjust colors for ancient look
	trunk_color = trunk_color.darkened(0.15)
	bark_color = bark_color.darkened(0.25)
	
	# Draw the main trunk with irregular shape
	for y in range(4, 60):
		for x in range(24, 40):
			var noise_factor
			
			if use_fixed_seed:
				noise_factor = sin(y * 0.2 + x * 0.3 + generation_seed * 0.01) * 3
			else:
				noise_factor = sin(y * 0.2 + x * 0.3) * 3
				
			var width = 7 + noise_factor
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add deep, irregular bark texture
	for y in range(4, 60):
		for x in range(24, 40):
			if img.get_pixel(x, y).a > 0:
				var bark_pattern
				
				if use_fixed_seed:
					bark_pattern = int(sin(x * 0.8 + y * 0.7 + generation_seed * 0.05) * 10)
				else:
					bark_pattern = int(sin(x * 0.8 + y * 0.7) * 10)
				
				if bark_pattern % 3 == 0 or bark_pattern % 7 == 0:
					img.set_pixel(x, y, bark_color)
	
	# Add gnarled knots and burls
	var knot_count = 4
	if use_fixed_seed:
		knot_count = seeded_randi_range(3, 6)
	
	for i in range(knot_count):
		var knot_x
		var knot_y
		var knot_size
		
		if use_fixed_seed:
			knot_x = seeded_randf_range(26, 38)
			knot_y = seeded_randf_range(10, 50)
			knot_size = seeded_randf_range(2, 4)
		else:
			knot_x = randf_range(26, 38)
			knot_y = randf_range(10, 50)
			knot_size = randf_range(2, 4)
		
		# Draw concentric rings for the knot
		for radius in range(int(knot_size), 0, -1):
			for y in range(int(knot_y - radius), int(knot_y + radius) + 1):
				for x in range(int(knot_x - radius), int(knot_x + radius) + 1):
					var dist = sqrt(pow(x - knot_x, 2) + pow(y - knot_y, 2))
					if dist <= radius and dist > radius - 1 and x >= 0 and x < 64 and y >= 0 and y < 64:
						if img.get_pixel(x, y).a > 0:
							var ring_color
							if radius % 2 == 0:
								ring_color = bark_color.darkened(0.3)
							else:
								ring_color = bark_color
							img.set_pixel(x, y, ring_color)
	
	# Add moss/lichen highlights
	var moss_count = 7
	if use_fixed_seed:
		moss_count = seeded_randi_range(5, 10)
	
	for i in range(moss_count):
		var moss_x
		var moss_y
		var moss_size
		
		if use_fixed_seed:
			moss_x = seeded_randf_range(25, 39)
			moss_y = seeded_randf_range(5, 55)
			moss_size = seeded_randf_range(1, 2.5)
		else:
			moss_x = randf_range(25, 39)
			moss_y = randf_range(5, 55)
			moss_size = randf_range(1, 2.5)
		
		# Create a small patch of moss/lichen
		for y in range(int(moss_y - moss_size), int(moss_y + moss_size) + 1):
			for x in range(int(moss_x - moss_size), int(moss_x + moss_size) + 1):
				var dist = sqrt(pow(x - moss_x, 2) + pow(y - moss_y, 2))
				if dist <= moss_size and x >= 0 and x < 64 and y >= 0 and y < 64:
					if img.get_pixel(x, y).a > 0:
						# Create a greenish highlight for moss
						var moss_color = Color(0.3, 0.5, 0.2).lerp(highlight_color, 0.3)
						img.set_pixel(x, y, moss_color)

func draw_magical_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw a magical glowing trunk
	var center_x = 32
	
	# Adjust colors for magical appearance
	highlight_color = Color(0.7, 0.7, 1.0).lerp(highlight_color, 0.3)  # Add blue-ish glow
	
	# Draw the main trunk
	for y in range(4, 60):
		for x in range(24, 40):
			var width_variation = sin(y * 0.1) * 2
			var width = 7 + width_variation
			
			if abs(x - center_x) < width:
				img.set_pixel(x, y, trunk_color)
	
	# Add magical runes/symbols
	var rune_count = 6
	if use_fixed_seed:
		rune_count = seeded_randi_range(4, 8)
	
	for i in range(rune_count):
		var rune_y
		var rune_width
		var rune_height
		
		if use_fixed_seed:
			rune_y = seeded_randi_range(8, 55)
			rune_width = seeded_randi_range(3, 6)
			rune_height = seeded_randi_range(3, 6)
		else:
			rune_y = randi_range(8, 55)
			rune_width = randi_range(3, 6)
			rune_height = randi_range(3, 6)
		
		# Choose a rune pattern based on seed
		var rune_type
		if use_fixed_seed:
			rune_type = (generation_seed + i) % 5
		else:
			rune_type = i % 5
		
		match rune_type:
			0:  # Circle
				draw_circle_rune(img, center_x, rune_y, rune_width, highlight_color)
			1:  # Triangle
				draw_triangle_rune(img, center_x, rune_y, rune_width, highlight_color)
			2:  # Square
				draw_square_rune(img, center_x, rune_y, rune_width, highlight_color)
			3:  # X shape
				draw_x_rune(img, center_x, rune_y, rune_width, highlight_color)
			4:  # Spiral
				draw_spiral_rune(img, center_x, rune_y, rune_width, highlight_color)
	
	# Add glowing aura
	for y in range(4, 60):
		for x in range(20, 44):
			if img.get_pixel(x, y).a == 0:  # Only add aura to transparent pixels
				var closest_trunk_x = -1
				var min_dist = 100
				
				# Find the closest trunk pixel
				for tx in range(24, 40):
					if img.get_pixel(tx, y).a > 0:
						var dist = abs(x - tx)
						if dist < min_dist:
							min_dist = dist
							closest_trunk_x = tx
				
				if closest_trunk_x != -1 and min_dist < 5:
					var intensity = 1.0 - (min_dist / 5.0)
					var aura_color = highlight_color
					aura_color.a = intensity * 0.5
					img.set_pixel(x, y, aura_color)

func draw_crystal_trunk(img: Image, trunk_color: Color, bark_color: Color, highlight_color: Color) -> void:
	# Draw a crystalline trunk
	var center_x = 32
	
	# Adjust colors for crystal appearance
	trunk_color = Color(0.6, 0.8, 0.9).lerp(trunk_color, 0.3)  # Add blue-ish crystal tone
	bark_color = Color(0.4, 0.6, 0.8).lerp(bark_color, 0.3)
	highlight_color = Color(0.8, 0.9, 1.0).lerp(highlight_color, 0.3)
	
	# Draw the main crystal trunk with facets
	for y in range(4, 60):
		for x in range(24, 40):
			var width = 7 + sin(y * 0.1) * 2
			
			if abs(x - center_x) < width:
				# Create faceted appearance with geometric patterns
				var pattern_value = (x * 3 + y * 5) % 7
				
				if pattern_value < 3:
					img.set_pixel(x, y, trunk_color)
				elif pattern_value < 5:
					img.set_pixel(x, y, bark_color)
				else:
					img.set_pixel(x, y, highlight_color)
	
	# Add crystal formations jutting out
	var crystal_count = 5
	if use_fixed_seed:
		crystal_count = seeded_randi_range(3, 7)
	
	for i in range(crystal_count):
		var crystal_y
		var crystal_size
		var crystal_dir
		
		if use_fixed_seed:
			crystal_y = seeded_randi_range(10, 50)
			crystal_size = seeded_randi_range(3, 6)
			crystal_dir = -1
			if seeded_randf() > 0.5:
				crystal_dir = 1
		else:
			crystal_y = randi_range(10, 50)
			crystal_size = randi_range(3, 6)
			crystal_dir = -1
			if randf() > 0.5:
				crystal_dir = 1
		
		var crystal_x = center_x + (7 * crystal_dir)
		
		# Draw a crystal formation
		for j in range(crystal_size):
			for k in range(crystal_size - j):
				var x = crystal_x + (j * crystal_dir)
				var y = crystal_y + k - crystal_size/2
				
				if x >= 0 and x < 64 and y >= 0 and y < 64:
					var color_choice = (j + k) % 3
					
					if color_choice == 0:
						img.set_pixel(x, y, trunk_color)
					elif color_choice == 1:
						img.set_pixel(x, y, bark_color)
					else:
						img.set_pixel(x, y, highlight_color)
	
	# Add some internal fracture lines
	var fracture_count = 7
	if use_fixed_seed:
		fracture_count = seeded_randi_range(5, 10)
	
	for i in range(fracture_count):
		var start_y
		var length
		var angle
		
		if use_fixed_seed:
			start_y = seeded_randi_range(8, 55)
			length = seeded_randi_range(5, 15)
			angle = seeded_randf_range(-0.3, 0.3)
		else:
			start_y = randi_range(8, 55)
			length = randi_range(5, 15)
			angle = randf_range(-0.3, 0.3)
		
		var start_x
		if use_fixed_seed:
			start_x = center_x + seeded_randi_range(-5, 5)
		else:
			start_x = center_x + randi_range(-5, 5)
		
		for j in range(length):
			var x = start_x + j * cos(angle)
			var y = start_y + j * sin(angle)
			
			if x >= 0 and x < 64 and y >= 0 and y < 64:
				if img.get_pixel(int(x), int(y)).a > 0:
					img.set_pixel(int(x), int(y), highlight_color)

# Helper functions for drawing magical runes
func draw_circle_rune(img: Image, center_x: int, center_y: int, size: int, color: Color) -> void:
	for y in range(center_y - size, center_y + size + 1):
		for x in range(center_x - size, center_x + size + 1):
			var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if dist <= size and dist >= size - 1 and x >= 0 and x < 64 and y >= 0 and y < 64:
				if img.get_pixel(x, y).a > 0:  # Only draw on trunk
					img.set_pixel(x, y, color)

func draw_triangle_rune(img: Image, center_x: int, center_y: int, size: int, color: Color) -> void:
	var points = [
		Vector2(center_x, center_y - size),
		Vector2(center_x - size, center_y + size),
		Vector2(center_x + size, center_y + size)
	]
	
	# Draw lines between points
	draw_line(img, points[0], points[1], color)
	draw_line(img, points[1], points[2], color)
	draw_line(img, points[2], points[0], color)

func draw_square_rune(img: Image, center_x: int, center_y: int, size: int, color: Color) -> void:
	var half_size = size / 2
	var points = [
		Vector2(center_x - half_size, center_y - half_size),
		Vector2(center_x + half_size, center_y - half_size),
		Vector2(center_x + half_size, center_y + half_size),
		Vector2(center_x - half_size, center_y + half_size)
	]
	
	# Draw lines between points
	draw_line(img, points[0], points[1], color)
	draw_line(img, points[1], points[2], color)
	draw_line(img, points[2], points[3], color)
	draw_line(img, points[3], points[0], color)

func draw_x_rune(img: Image, center_x: int, center_y: int, size: int, color: Color) -> void:
	var points = [
		Vector2(center_x - size, center_y - size),
		Vector2(center_x + size, center_y + size),
		Vector2(center_x - size, center_y + size),
		Vector2(center_x + size, center_y - size)
	]
	
	# Draw lines between points
	draw_line(img, points[0], points[1], color)
	draw_line(img, points[2], points[3], color)

func draw_spiral_rune(img: Image, center_x: int, center_y: int, size: int, color: Color) -> void:
	var max_radius = size
	var turns = 2
	var points_per_turn = 8
	var total_points = turns * points_per_turn
	
	var last_point = Vector2(center_x, center_y)
	
	for i in range(1, total_points + 1):
		var angle = (i / float(points_per_turn)) * 2 * PI
		var radius = (i / float(total_points)) * max_radius
		var x = center_x + cos(angle) * radius
		var y = center_y + sin(angle) * radius
		var point = Vector2(x, y)
		
		draw_line(img, last_point, point, color)
		last_point = point

func draw_line(img: Image, start: Vector2, end: Vector2, color: Color) -> void:
	var dx = end.x - start.x
	var dy = end.y - start.y
	var steps = max(abs(dx), abs(dy))
	
	if steps == 0:
		return
	
	var x_increment = dx / steps
	var y_increment = dy / steps
	
	var x = start.x
	var y = start.y
	
	for i in range(steps + 1):
		if x >= 0 and x < 64 and y >= 0 and y < 64:
			if img.get_pixel(int(x), int(y)).a > 0:  # Only draw on trunk
				img.set_pixel(int(x), int(y), color)
		
		x += x_increment
		y += y_increment

func add_branch_connections(img: Image, trunk_color: Color, bark_color: Color) -> void:
	# Add branch connection points based on trunk type
	branch_positions.clear()
	
	match trunk_type:
		TrunkType.PLAIN:
			# No branches
			pass
			
		TrunkType.SINGLE_BRANCH_LEFT:
			# Add a single branch on the left
			var branch_y
			if use_fixed_seed:
				branch_y = seeded_randi_range(20, 40)
			else:
				branch_y = randi_range(20, 40)
				
			draw_branch_connection(img, 24, branch_y, -1, trunk_color, bark_color)
			branch_positions.append({"y": branch_y, "side": -1})
			
		TrunkType.SINGLE_BRANCH_RIGHT:
			# Add a single branch on the right
			var branch_y
			if use_fixed_seed:
				branch_y = seeded_randi_range(20, 40)
			else:
				branch_y = randi_range(20, 40)
				
			draw_branch_connection(img, 40, branch_y, 1, trunk_color, bark_color)
			branch_positions.append({"y": branch_y, "side": 1})
			
		TrunkType.DOUBLE_BRANCH:
			# Add branches on both sides
			var branch_y1
			var branch_y2
			if use_fixed_seed:
				branch_y1 = seeded_randi_range(15, 30)
				branch_y2 = seeded_randi_range(35, 50)
			else:
				branch_y1 = randi_range(15, 30)
				branch_y2 = randi_range(35, 50)
				
			draw_branch_connection(img, 24, branch_y1, -1, trunk_color, bark_color)
			draw_branch_connection(img, 40, branch_y2, 1, trunk_color, bark_color)
			branch_positions.append({"y": branch_y1, "side": -1})
			branch_positions.append({"y": branch_y2, "side": 1})
			
		TrunkType.MULTI_BRANCH:
			# Add multiple branches on both sides
			var num_branches
			if use_fixed_seed:
				num_branches = seeded_randi_range(3, 5)
			else:
				num_branches = randi_range(3, 5)
				
			for i in range(num_branches):
				var branch_y
				var side
				if use_fixed_seed:
					branch_y = seeded_randi_range(10, 55)
					side = -1
					if seeded_randf() > 0.5:
						side = 1
				else:
					branch_y = randi_range(10, 55)
					side = -1
					if randf() > 0.5:
						side = 1
					
				var x_pos = 40 if side > 0 else 24
				draw_branch_connection(img, x_pos, branch_y, side, trunk_color, bark_color)
				branch_positions.append({"y": branch_y, "side": side})

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
