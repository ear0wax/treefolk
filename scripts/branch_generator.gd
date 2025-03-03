extends PixelArtBase

func _ready():
	# Generate the texture when the scene is loaded with default seed 3146
	generate_texture(3146)

func generate_texture(seed_value: int = 3146) -> void:
	initialize(seed_value)
	
	var texture = generate_branch_texture()
	ensure_textures_dir()
	save_texture(texture, "res://textures/branch.png")
	
	# Update the sprite with the new texture
	var sprite = get_parent().get_node("Sprite3D")
	if sprite:
		sprite.texture = texture

func generate_branch_texture() -> ImageTexture:
	var img = Image.create(96, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Branch style variations
	var branch_styles = ["standard", "leafy", "pine", "flowering", "magical", "crystal"]
	var style_index = 0
	
	if use_fixed_seed:
		style_index = generation_seed % branch_styles.size()
	else:
		style_index = randi() % branch_styles.size()
	
	var style = branch_styles[style_index]
	
	# Base colors with high variation
	var branch_color = Color(0.4, 0.25, 0.1)  # Default brown
	var detail_color = Color(0.3, 0.2, 0.1)  # Default darker brown
	var leaf_color = Color(0.2, 0.5, 0.2)  # Default green
	var leaf_highlight = Color(0.3, 0.6, 0.3)  # Default lighter green
	
	# Dramatically vary the colors based on the seed
	if use_fixed_seed:
		# Use the seed to create very different color palettes
		var hue_shift = fmod(float(generation_seed) / 1000.0, 1.0)
		var saturation = fmod(float(generation_seed) / 500.0, 0.5) + 0.5
		var value = fmod(float(generation_seed) / 250.0, 0.3) + 0.7
		
		branch_color = Color.from_hsv(hue_shift, saturation, value)
		detail_color = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation, value * 0.8)
		
		# Leaf colors can be completely different
		var leaf_hue = fmod(float(generation_seed) / 700.0, 1.0)
		leaf_color = Color.from_hsv(leaf_hue, saturation, value)
		leaf_highlight = Color.from_hsv(fmod(leaf_hue + 0.05, 1.0), saturation * 0.8, value * 1.2)
		
		# Seasonal variations
		var season = generation_seed % 4
		match season:
			0:  # Spring - fresh green
				leaf_color = Color(0.2, 0.6, 0.2).lerp(leaf_color, 0.3)
				leaf_highlight = Color(0.3, 0.7, 0.3).lerp(leaf_highlight, 0.3)
			1:  # Summer - deep green
				leaf_color = Color(0.1, 0.4, 0.1).lerp(leaf_color, 0.3)
				leaf_highlight = Color(0.2, 0.5, 0.2).lerp(leaf_highlight, 0.3)
			2:  # Fall - orange/red
				leaf_color = Color(0.7, 0.3, 0.1).lerp(leaf_color, 0.3)
				leaf_highlight = Color(0.8, 0.4, 0.1).lerp(leaf_highlight, 0.3)
			3:  # Winter - brown/sparse
				leaf_color = Color(0.5, 0.4, 0.2).lerp(leaf_color, 0.3)
				leaf_highlight = Color(0.6, 0.5, 0.3).lerp(leaf_highlight, 0.3)
	
	# Draw the branch based on style
	match style:
		"standard":
			draw_standard_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
		"leafy":
			draw_leafy_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
		"pine":
			draw_pine_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
		"flowering":
			draw_flowering_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
		"magical":
			draw_magical_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
		"crystal":
			draw_crystal_branch(img, branch_color, detail_color, leaf_color, leaf_highlight)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_standard_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw the main branch - starting from the left edge (trunk connection point)
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
			if img.get_pixel(x, y).a > 0:
				var pattern
				if use_fixed_seed:
					pattern = (x + generation_seed) % 5
				else:
					pattern = x % 5
					
				if pattern == 0:
					img.set_pixel(x, y, detail_color)
	
	# Add some leaves
	var leaf_count
	if use_fixed_seed:
		leaf_count = seeded_randi_range(10, 20)
	else:
		leaf_count = 15
		
	for i in range(leaf_count):
		var leaf_x
		var leaf_y
		var leaf_size
		
		if use_fixed_seed:
			leaf_x = seeded_randf_range(30, 90)
			leaf_y = seeded_randf_range(8, 24)
			leaf_size = seeded_randf_range(1, 3)
		else:
			leaf_x = randf_range(30, 90)
			leaf_y = randf_range(8, 24)
			leaf_size = randf_range(1, 3)
		
		# Only place leaves near the branch
		if abs(leaf_y - 16) > 4 and abs(leaf_y - 16) < 8:
			for y in range(int(leaf_y - leaf_size), int(leaf_y + leaf_size) + 1):
				for x in range(int(leaf_x - leaf_size), int(leaf_x + leaf_size) + 1):
					var dist = sqrt(pow(x - leaf_x, 2) + pow(y - leaf_y, 2))
					if dist <= leaf_size and x >= 0 and x < 96 and y >= 0 and y < 32:
						var rand_check
						if use_fixed_seed:
							rand_check = seeded_randf() > 0.3
						else:
							rand_check = randf() > 0.3
							
						if rand_check:
							img.set_pixel(x, y, leaf_color)
						else:
							img.set_pixel(x, y, leaf_highlight)

func draw_leafy_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw a branch with dense foliage
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 85
	var branch_end_y = 16
	
	# Draw the main branch
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 2.5 * (1.0 - progress * 0.6)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					img.set_pixel(x, py, branch_color)
	
	# Add bark texture
	for y in range(0, 32):
		for x in range(0, branch_end_x):
			if img.get_pixel(x, y).a > 0 and (x + y) % 4 == 0:
				img.set_pixel(x, y, detail_color)
	
	# Add small branches
	var branch_count = 4
	if use_fixed_seed:
		branch_count = seeded_randi_range(3, 6)
	
	for i in range(branch_count):
		var start_x
		var start_y
		var length
		var angle
		
		if use_fixed_seed:
			start_x = seeded_randf_range(20, 70)
			start_y = 16
			length = seeded_randf_range(10, 20)
			angle = seeded_randf_range(-0.5, 0.5)
		else:
			start_x = randf_range(20, 70)
			start_y = 16
			length = randf_range(10, 20)
			angle = randf_range(-0.5, 0.5)
		
		for j in range(int(length)):
			var x = start_x + j * cos(angle)
			var y = start_y + j * sin(angle)
			
			if x >= 0 and x < 96 and y >= 0 and y < 32:
				img.set_pixel(int(x), int(y), branch_color)
	
	# Add dense leaf clusters
	var cluster_count = 6
	if use_fixed_seed:
		cluster_count = seeded_randi_range(4, 8)
	
	for i in range(cluster_count):
		var cluster_x
		var cluster_y
		var cluster_size
		
		if use_fixed_seed:
			cluster_x = seeded_randf_range(30, 90)
			cluster_y = seeded_randf_range(8, 24)
			cluster_size = seeded_randf_range(4, 8)
		else:
			cluster_x = randf_range(30, 90)
			cluster_y = randf_range(8, 24)
			cluster_size = randf_range(4, 8)
		
		for j in range(int(cluster_size * 2)):
			var leaf_x
			var leaf_y
			var leaf_size
			
			if use_fixed_seed:
				leaf_x = cluster_x + seeded_randf_range(-cluster_size/2, cluster_size/2)
				leaf_y = cluster_y + seeded_randf_range(-cluster_size/2, cluster_size/2)
				leaf_size = seeded_randf_range(1, 2.5)
			else:
				leaf_x = cluster_x + randf_range(-cluster_size/2, cluster_size/2)
				leaf_y = cluster_y + randf_range(-cluster_size/2, cluster_size/2)
				leaf_size = randf_range(1, 2.5)
			
			for y in range(int(leaf_y - leaf_size), int(leaf_y + leaf_size) + 1):
				for x in range(int(leaf_x - leaf_size), int(leaf_x + leaf_size) + 1):
					var dist = sqrt(pow(x - leaf_x, 2) + pow(y - leaf_y, 2))
					if dist <= leaf_size and x >= 0 and x < 96 and y >= 0 and y < 32:
						var rand_check
						if use_fixed_seed:
							rand_check = seeded_randf() > 0.3
						else:
							rand_check = randf() > 0.3
						
						if rand_check:
							img.set_pixel(x, y, leaf_color)
						else:
							img.set_pixel(x, y, leaf_highlight)

func draw_pine_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw a pine branch with needles
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 90
	var branch_end_y = 16
	
	# Draw the main branch
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 2.0 * (1.0 - progress * 0.5)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					img.set_pixel(x, py, branch_color)
	
	# Add bark texture
	for y in range(0, 32):
		for x in range(0, branch_end_x):
			if img.get_pixel(x, y).a > 0 and x % 3 == 0:
				img.set_pixel(x, y, detail_color)
	
	# Add pine needles
	var needle_count = 55
	if use_fixed_seed:
		needle_count = seeded_randi_range(40, 70)
	
	for i in range(needle_count):
		var needle_x
		var needle_y
		var needle_length
		var needle_angle
		var needle_side
		
		if use_fixed_seed:
			needle_x = seeded_randf_range(10, 85)
			needle_y = 16 + seeded_randf_range(-1, 1)
			needle_length = seeded_randf_range(3, 7)
			needle_side = -1
			if seeded_randf() > 0.5:
				needle_side = 1
			needle_angle = seeded_randf_range(-0.3, 0.3) + (PI/2 if needle_side > 0 else -PI/2)
		else:
			needle_x = randf_range(10, 85)
			needle_y = 16 + randf_range(-1, 1)
			needle_length = randf_range(3, 7)
			needle_side = -1
			if randf() > 0.5:
				needle_side = 1
			needle_angle = randf_range(-0.3, 0.3) + (PI/2 if needle_side > 0 else -PI/2)
		
		# Only place needles if there's a branch at this position
		if img.get_pixel(int(needle_x), int(needle_y)).a > 0:
			for j in range(int(needle_length)):
				var x = needle_x + j * cos(needle_angle)
				var y = needle_y + j * sin(needle_angle)
				
				if x >= 0 and x < 96 and y >= 0 and y < 32:
					var needle_color
					if j < needle_length * 0.7:
						needle_color = leaf_color
					else:
						needle_color = leaf_highlight
					img.set_pixel(int(x), int(y), needle_color)

func draw_flowering_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw a branch with flowers
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 85
	var branch_end_y = 16
	
	# Draw the main branch
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 2.5 * (1.0 - progress * 0.6)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					img.set_pixel(x, py, branch_color)
	
	# Add bark texture
	for y in range(0, 32):
		for x in range(0, branch_end_x):
			if img.get_pixel(x, y).a > 0 and (x + y) % 4 == 0:
				img.set_pixel(x, y, detail_color)
	
	# Add small branches
	var branch_count = 4
	if use_fixed_seed:
		branch_count = seeded_randi_range(3, 6)
	
	for i in range(branch_count):
		var start_x
		var start_y
		var length
		var angle
		
		if use_fixed_seed:
			start_x = seeded_randf_range(20, 70)
			start_y = 16
			length = seeded_randf_range(8, 15)
			angle = seeded_randf_range(-0.7, 0.7)
		else:
			start_x = randf_range(20, 70)
			start_y = 16
			length = randf_range(8, 15)
			angle = randf_range(-0.7, 0.7)
		
		for j in range(int(length)):
			var x = start_x + j * cos(angle)
			var y = start_y + j * sin(angle)
			
			if x >= 0 and x < 96 and y >= 0 and y < 32:
				img.set_pixel(int(x), int(y), branch_color)
	
	# Add some leaves
	var leaf_count = 15
	if use_fixed_seed:
		leaf_count = seeded_randi_range(10, 20)
	
	for i in range(leaf_count):
		var leaf_x
		var leaf_y
		var leaf_size
		
		if use_fixed_seed:
			leaf_x = seeded_randf_range(20, 85)
			leaf_y = seeded_randf_range(8, 24)
			leaf_size = seeded_randf_range(1, 2)
		else:
			leaf_x = randf_range(20, 85)
			leaf_y = randf_range(8, 24)
			leaf_size = randf_range(1, 2)
		
		for y in range(int(leaf_y - leaf_size), int(leaf_y + leaf_size) + 1):
			for x in range(int(leaf_x - leaf_size), int(leaf_x + leaf_size) + 1):
				var dist = sqrt(pow(x - leaf_x, 2) + pow(y - leaf_y, 2))
				if dist <= leaf_size and x >= 0 and x < 96 and y >= 0 and y < 32:
					var rand_check
					if use_fixed_seed:
						rand_check = seeded_randf() > 0.3
					else:
						rand_check = randf() > 0.3
					
					if rand_check:
						img.set_pixel(x, y, leaf_color)
					else:
						img.set_pixel(x, y, leaf_highlight)
	
	# Add flowers
	var flower_count = 8
	if use_fixed_seed:
		flower_count = seeded_randi_range(5, 12)
	
	var flower_colors = [
		Color(1.0, 0.5, 0.5),  # Pink
		Color(1.0, 0.8, 0.8),  # Light pink
		Color(1.0, 1.0, 0.5),  # Yellow
		Color(0.8, 0.6, 1.0),  # Purple
		Color(1.0, 1.0, 1.0)   # White
	]
	
	var flower_color_index
	if use_fixed_seed:
		flower_color_index = generation_seed % flower_colors.size()
	else:
		flower_color_index = randi() % flower_colors.size()
	
	var flower_color = flower_colors[flower_color_index]
	var flower_center_color = flower_color.darkened(0.3)
	
	for i in range(flower_count):
		var flower_x
		var flower_y
		var flower_size
		
		if use_fixed_seed:
			flower_x = seeded_randf_range(30, 90)
			flower_y = seeded_randf_range(6, 26)
			flower_size = seeded_randf_range(1.5, 3)
		else:
			flower_x = randf_range(30, 90)
			flower_y = randf_range(6, 26)
			flower_size = randf_range(1.5, 3)
		
		# Draw flower petals
		for angle in range(0, 360, 60):
			var rad_angle = deg_to_rad(angle)
			var petal_x = flower_x + cos(rad_angle) * flower_size
			var petal_y = flower_y + sin(rad_angle) * flower_size
			
			for y in range(int(petal_y - 1), int(petal_y + 2)):
				for x in range(int(petal_x - 1), int(petal_x + 2)):
					var dist = sqrt(pow(x - petal_x, 2) + pow(y - petal_y, 2))
					if dist <= 1 and x >= 0 and x < 96 and y >= 0 and y < 32:
						img.set_pixel(x, y, flower_color)
		
		# Draw flower center
		img.set_pixel(int(flower_x), int(flower_y), flower_center_color)
		
		# Add some randomness to petals
		for j in range(3):
			var rand_angle
			if use_fixed_seed:
				rand_angle = seeded_randf() * 2 * PI
			else:
				rand_angle = randf() * 2 * PI
				
			var rand_x = int(flower_x + cos(rand_angle) * flower_size * 0.7)
			var rand_y = int(flower_y + sin(rand_angle) * flower_size * 0.7)
			
			if rand_x >= 0 and rand_x < 96 and rand_y >= 0 and rand_y < 32:
				img.set_pixel(rand_x, rand_y, flower_color)

func draw_magical_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw a magical glowing branch
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 85
	var branch_end_y = 16
	
	# Adjust colors for magical appearance
	leaf_highlight = Color(0.7, 0.9, 1.0).lerp(leaf_highlight, 0.3)  # Add blue-ish glow
	
	# Draw the main branch
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 2.5 * (1.0 - progress * 0.6)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					img.set_pixel(x, py, branch_color)
	
	# Add magical runes/symbols along the branch
	var rune_count = 4
	if use_fixed_seed:
		rune_count = seeded_randi_range(3, 6)
	
	for i in range(rune_count):
		var rune_x
		var rune_size
		
		if use_fixed_seed:
			rune_x = seeded_randi_range(15, 75)
			rune_size = seeded_randf_range(1, 2)
		else:
			rune_x = randi_range(15, 75)
			rune_size = randf_range(1, 2)
		
		# Draw a small glowing rune
		for y in range(int(branch_start_y - rune_size), int(branch_start_y + rune_size) + 1):
			for x in range(int(rune_x - rune_size), int(rune_x + rune_size) + 1):
				var dist = sqrt(pow(x - rune_x, 2) + pow(y - branch_start_y, 2))
				if dist <= rune_size and x >= 0 and x < 96 and y >= 0 and y < 32:
					if img.get_pixel(x, y).a > 0:  # Only draw on branch
						img.set_pixel(x, y, leaf_highlight)
	
	# Add glowing aura around the branch
	for y in range(0, 32):
		for x in range(0, branch_end_x):
			if img.get_pixel(x, y).a == 0:  # Only add aura to transparent pixels
				var closest_branch_pixel = false
				var min_dist = 100
				
				# Check nearby pixels for branch
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var nx = x + dx
						var ny = y + dy
						
						if nx >= 0 and nx < 96 and ny >= 0 and ny < 32:
							if img.get_pixel(nx, ny).a > 0:
								var dist = sqrt(dx*dx + dy*dy)
								if dist < min_dist:
									min_dist = dist
									closest_branch_pixel = true
				
				if closest_branch_pixel and min_dist < 3:
					var intensity = 1.0 - (min_dist / 3.0)
					var aura_color = leaf_highlight
					aura_color.a = intensity * 0.5
					img.set_pixel(x, y, aura_color)
	
	# Add magical particles/sparkles
	var particle_count = 20
	if use_fixed_seed:
		particle_count = seeded_randi_range(15, 30)
	
	for i in range(particle_count):
		var particle_x
		var particle_y
		
		if use_fixed_seed:
			particle_x = seeded_randf_range(10, 90)
			particle_y = seeded_randf_range(8, 24)
		else:
			particle_x = randf_range(10, 90)
			particle_y = randf_range(8, 24)
		
		# Only place particles near the branch
		var near_branch = false
		for dy in range(-5, 6):
			for dx in range(-5, 6):
				var nx = int(particle_x) + dx
				var ny = int(particle_y) + dy
				
				if nx >= 0 and nx < 96 and ny >= 0 and ny < 32:
					if img.get_pixel(nx, ny).a > 0:
						near_branch = true
						break
			if near_branch:
				break
		
		if near_branch:
			img.set_pixel(int(particle_x), int(particle_y), leaf_highlight)
			
			# Add tiny cross shape for sparkle
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx = int(particle_x) + offset.x
				var sy = int(particle_y) + offset.y
				if sx >= 0 and sx < 96 and sy >= 0 and sy < 32:
					var sparkle_color = leaf_highlight
					sparkle_color.a = 0.7
					img.set_pixel(sx, sy, sparkle_color)

func draw_crystal_branch(img: Image, branch_color: Color, detail_color: Color, leaf_color: Color, leaf_highlight: Color) -> void:
	# Draw a crystalline branch
	var branch_start_x = 0
	var branch_start_y = 16
	var branch_end_x = 85
	var branch_end_y = 16
	
	# Adjust colors for crystal appearance
	branch_color = Color(0.6, 0.8, 0.9).lerp(branch_color, 0.3)  # Add blue-ish crystal tone
	detail_color = Color(0.4, 0.6, 0.8).lerp(detail_color, 0.3)
	leaf_color = Color(0.5, 0.7, 0.9).lerp(leaf_color, 0.3)
	leaf_highlight = Color(0.8, 0.9, 1.0).lerp(leaf_highlight, 0.3)
	
	# Draw the main crystal branch with facets
	for x in range(branch_start_x, branch_end_x):
		var progress = float(x - branch_start_x) / (branch_end_x - branch_start_x)
		var y = branch_start_y + (branch_end_y - branch_start_y) * progress
		
		# Calculate thickness that tapers toward the end
		var thickness = 2.5 * (1.0 - progress * 0.6)
		
		for dy in range(-ceil(thickness), ceil(thickness) + 1):
			var py = int(y + dy)
			if py >= 0 and py < 32:
				if abs(dy) < thickness:
					# Create faceted appearance with geometric patterns
					var pattern_value = (x * 3 + py * 5) % 7
					
					if pattern_value < 3:
						img.set_pixel(x, py, branch_color)
					elif pattern_value < 5:
						img.set_pixel(x, py, detail_color)
					else:
						img.set_pixel(x, py, leaf_highlight)
	
	# Add crystal formations jutting out
	var crystal_count = 7
	if use_fixed_seed:
		crystal_count = seeded_randi_range(5, 10)
	
	for i in range(crystal_count):
		var crystal_x
		var crystal_y
		var crystal_size
		var crystal_angle
		
		if use_fixed_seed:
			crystal_x = seeded_randf_range(20, 80)
			crystal_y = 16
			crystal_size = seeded_randf_range(3, 6)
			crystal_angle = seeded_randf_range(-0.7, 0.7)
		else:
			crystal_x = randf_range(20, 80)
			crystal_y = 16
			crystal_size = randf_range(3, 6)
			crystal_angle = randf_range(-0.7, 0.7)
		
		# Only place crystals if there's a branch at this position
		if img.get_pixel(int(crystal_x), int(crystal_y)).a > 0:
			for j in range(int(crystal_size)):
				var x = crystal_x + j * cos(crystal_angle)
				var y = crystal_y + j * sin(crystal_angle)
				
				if x >= 0 and x < 96 and y >= 0 and y < 32:
					var color_choice = (j + i) % 3
					
					if color_choice == 0:
						img.set_pixel(int(x), int(y), branch_color)
					elif color_choice == 1:
						img.set_pixel(int(x), int(y), detail_color)
					else:
						img.set_pixel(int(x), int(y), leaf_highlight)
	
	# Add some internal fracture lines
	var fracture_count = 5
	if use_fixed_seed:
		fracture_count = seeded_randi_range(3, 7)
	
	for i in range(fracture_count):
		var start_x
		var length
		var angle
		
		if use_fixed_seed:
			start_x = seeded_randf_range(10, 75)
			length = seeded_randf_range(5, 15)
			angle = seeded_randf_range(-0.3, 0.3)
		else:
			start_x = randf_range(10, 75)
			length = randf_range(5, 15)
			angle = randf_range(-0.3, 0.3)
		
		for j in range(int(length)):
			var x = start_x + j * cos(angle)
			var y = branch_start_y + j * sin(angle)
			
			if x >= 0 and x < 96 and y >= 0 and y < 32:
				if img.get_pixel(int(x), int(y)).a > 0:
					img.set_pixel(int(x), int(y), leaf_highlight)
