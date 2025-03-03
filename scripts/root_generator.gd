extends PixelArtBase

func _ready():
	# Generate the texture when the scene is loaded with default seed 3146
	generate_texture(3146)

func generate_texture(seed_value: int = 3146) -> void:
	initialize(seed_value)
	
	var texture = generate_root_texture()
	ensure_textures_dir()
	save_texture(texture, "res://textures/root.png")
	
	# Update the sprite with the new texture
	var sprite = get_parent().get_node("Sprite3D")
	if sprite:
		sprite.texture = texture

func generate_root_texture() -> ImageTexture:
	var img = Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Root style variations
	var root_styles = ["standard", "fibrous", "taproot", "aerial", "magical", "crystal"]
	var style_index = 0
	
	if use_fixed_seed:
		style_index = generation_seed % root_styles.size()
	else:
		style_index = randi() % root_styles.size()
	
	var style = root_styles[style_index]
	
	# Base colors with high variation
	var root_color = Color(0.5, 0.35, 0.2)  # Default brown
	var detail_color = Color(0.4, 0.25, 0.1)  # Default darker brown
	var highlight_color = Color(0.6, 0.45, 0.3)  # Default highlight
	
	# Dramatically vary the colors based on the seed
	if use_fixed_seed:
		# Use the seed to create very different color palettes
		var hue_shift = fmod(float(generation_seed) / 1000.0, 1.0)
		var saturation = fmod(float(generation_seed) / 500.0, 0.5) + 0.5
		var value = fmod(float(generation_seed) / 250.0, 0.3) + 0.7
		
		root_color = Color.from_hsv(hue_shift, saturation, value)
		detail_color = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation, value * 0.8)
		highlight_color = Color.from_hsv(fmod(hue_shift - 0.05, 1.0), saturation * 0.8, value * 1.2)
	
	# Draw the root based on style
	match style:
		"standard":
			draw_standard_root(img, root_color, detail_color)
		"fibrous":
			draw_fibrous_root(img, root_color, detail_color)
		"taproot":
			draw_taproot(img, root_color, detail_color)
		"aerial":
			draw_aerial_root(img, root_color, detail_color, highlight_color)
		"magical":
			draw_magical_root(img, root_color, highlight_color)
		"crystal":
			draw_crystal_root(img, root_color, detail_color, highlight_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_standard_root(img: Image, root_color: Color, detail_color: Color) -> void:
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
	var branch_count = 3
	if use_fixed_seed:
		branch_count = seeded_randi_range(2, 4)
		
	for i in range(branch_count):
		var angle
		var length
		if use_fixed_seed:
			angle = seeded_randf() * PI
			length = seeded_randf_range(10, 20)
		else:
			angle = randf() * PI
			length = randf_range(10, 20)
			
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
							var rand_check
							if use_fixed_seed:
								rand_check = seeded_randf() > 0.5
							else:
								rand_check = randf() > 0.5
								
							if rand_check:
								img.set_pixel(nx, ny, root_color.darkened(0.2))
	
	# Add some texture details
	for y in range(8, 40):
		for x in range(24, 40):
			var rand_check
			if use_fixed_seed:
				rand_check = seeded_randf() > 0.8
			else:
				rand_check = randf() > 0.8
				
			if img.get_pixel(x, y).a > 0 and rand_check:
				img.set_pixel(x, y, detail_color)

func draw_fibrous_root(img: Image, root_color: Color, detail_color: Color) -> void:
	# Fibrous root system with many small roots
	var center_x = 32
	var center_y = 20
	
	# Draw the main root mass
	for y in range(15, 35):
		for x in range(25, 40):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			if dist_x < 7 - dist_y/10 and dist_y < 10:
				img.set_pixel(x, y, root_color)
	
	# Add many small fibrous roots
	var root_count = 20
	if use_fixed_seed:
		root_count = seeded_randi_range(15, 25)
	
	for i in range(root_count):
		var angle
		var length
		
		if use_fixed_seed:
			angle = seeded_randf() * PI * 1.2 - PI * 0.1  # Mostly downward
			length = seeded_randf_range(5, 15)
		else:
			angle = randf() * PI * 1.2 - PI * 0.1
			length = randf_range(5, 15)
		
		var start_x
		var start_y
		
		if use_fixed_seed:
			start_x = center_x + seeded_randf_range(-6, 6)
			start_y = center_y + seeded_randf_range(-5, 10)
		else:
			start_x = center_x + randf_range(-6, 6)
			start_y = center_y + randf_range(-5, 10)
		
		for j in range(int(length)):
			var x = start_x + cos(angle) * j
			var y = start_y + sin(angle) * j
			
			if x >= 0 and x < 64 and y >= 0 and y < 48:
				img.set_pixel(int(x), int(y), root_color)
	
	# Add texture details
	for y in range(8, 40):
		for x in range(20, 45):
			if img.get_pixel(x, y).a > 0 and (x + y) % 5 == 0:
				img.set_pixel(x, y, detail_color)

func draw_taproot(img: Image, root_color: Color, detail_color: Color) -> void:
	# Taproot system with one dominant vertical root
	var center_x = 32
	
	# Draw the main taproot
	var root_width = 5
	for y in range(15, 40):
		var progress = float(y - 15) / 25.0
		var width = root_width * (1.0 - progress * 0.5)
		
		for x in range(center_x - int(width), center_x + int(width) + 1):
			if x >= 0 and x < 64:
				img.set_pixel(x, y, root_color)
	
	# Add some lateral roots
	var lateral_count = 6
	if use_fixed_seed:
		lateral_count = seeded_randi_range(4, 8)
	
	for i in range(lateral_count):
		var y_pos
		var length
		var direction
		
		if use_fixed_seed:
			y_pos = seeded_randi_range(20, 35)
			length = seeded_randf_range(5, 12)
			direction = -1
			if seeded_randf() > 0.5:
				direction = 1
		else:
			y_pos = randi_range(20, 35)
			length = randf_range(5, 12)
			direction = -1
			if randf() > 0.5:
				direction = 1
		
		for j in range(int(length)):
			var x = center_x + j * direction
			var y = y_pos + (j * 0.2)  # Slight downward angle
			
			if x >= 0 and x < 64 and y >= 0 and y < 48:
				img.set_pixel(int(x), int(y), root_color)
				
				# Add some width to lateral roots
				if j < length * 0.3:  # Thicker near the base
					for k in [-1, 1]:
						var ny = int(y) + k
						if ny >= 0 and ny < 48:
							img.set_pixel(int(x), ny, root_color.darkened(0.1))
	
	# Add texture details
	for y in range(15, 40):
		for x in range(center_x - root_width, center_x + root_width + 1):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 4 == 0 or (x - y) % 5 == 0:
					img.set_pixel(x, y, detail_color)

func draw_aerial_root(img: Image, root_color: Color, detail_color: Color, highlight_color: Color) -> void:
	# Aerial roots that hang down
	var center_x = 32
	var top_y = 10
	
	# Draw several hanging aerial roots
	var root_count = 5
	if use_fixed_seed:
		root_count = seeded_randi_range(3, 7)
	
	for i in range(root_count):
		var start_x
		var length
		var curve_factor
		
		if use_fixed_seed:
			start_x = center_x + seeded_randf_range(-10, 10)
			length = seeded_randf_range(15, 30)
			curve_factor = seeded_randf_range(-0.1, 0.1)
		else:
			start_x = center_x + randf_range(-10, 10)
			length = randf_range(15, 30)
			curve_factor = randf_range(-0.1, 0.1)
		
		for j in range(int(length)):
			var curve = curve_factor * j
			var x = start_x + curve
			var y = top_y + j
			
			if x >= 0 and x < 64 and y >= 0 and y < 48:
				img.set_pixel(int(x), int(y), root_color)
				
				# Add some width
				for k in [-1, 0, 1]:
					var nx = int(x) + k
					if nx >= 0 and nx < 64:
						if k != 0 and randf() > 0.7:
							img.set_pixel(nx, int(y), root_color.darkened(0.2))
		
		# Add some small offshoots
		var offshoot_count = 2
		if use_fixed_seed:
			offshoot_count = seeded_randi_range(1, 3)
		
		for j in range(offshoot_count):
			var offshoot_y
			var offshoot_length
			var offshoot_dir
			
			if use_fixed_seed:
				offshoot_y = top_y + seeded_randi_range(5, int(length) - 5)
				offshoot_length = seeded_randf_range(3, 7)
				offshoot_dir = -1
				if seeded_randf() > 0.5:
					offshoot_dir = 1
			else:
				offshoot_y = top_y + randi_range(5, int(length) - 5)
				offshoot_length = randf_range(3, 7)
				offshoot_dir = -1
				if randf() > 0.5:
					offshoot_dir = 1
			
			var offshoot_x = start_x + curve_factor * (offshoot_y - top_y)
			
			for k in range(int(offshoot_length)):
				var x = offshoot_x + k * offshoot_dir
				var y = offshoot_y + k * 0.5  # Slight downward angle
				
				if x >= 0 and x < 64 and y >= 0 and y < 48:
					img.set_pixel(int(x), int(y), root_color)
	
	# Add some highlights to make them look moist
	for y in range(10, 40):
		for x in range(20, 45):
			if img.get_pixel(x, y).a > 0 and randf() > 0.9:
				img.set_pixel(x, y, highlight_color)

func draw_magical_root(img: Image, root_color: Color, highlight_color: Color) -> void:
	# Magical glowing roots
	var center_x = 32
	var center_y = 24
	
	# Draw the main root structure
	for y in range(15, 35):
		for x in range(25, 40):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			if dist_x < 6 - dist_y/10 and dist_y < 10:
				img.set_pixel(x, y, root_color)
	
	# Add glowing tendrils
	var tendril_count = 7
	if use_fixed_seed:
		tendril_count = seeded_randi_range(5, 10)
	
	for i in range(tendril_count):
		var angle
		var length
		
		if use_fixed_seed:
			angle = seeded_randf() * PI * 1.5 - PI * 0.25  # Wide spread
			length = seeded_randf_range(10, 20)
		else:
			angle = randf() * PI * 1.5 - PI * 0.25
			length = randf_range(10, 20)
		
		for j in range(int(length)):
			var intensity = 1.0 - (float(j) / length)
			var x = center_x + cos(angle) * j
			var y = center_y + sin(angle) * j
			
			if x >= 0 and x < 64 and y >= 0 and y < 48:
				var glow_color = root_color.lerp(highlight_color, intensity)
				img.set_pixel(int(x), int(y), glow_color)
				
				# Add glow effect
				for k in range(-1, 2):
					for l in range(-1, 2):
						if k == 0 and l == 0:
							continue
							
						var nx = int(x) + k
						var ny = int(y) + l
						
						if nx >= 0 and nx < 64 and ny >= 0 and ny < 48:
							if img.get_pixel(nx, ny).a == 0:  # Only if pixel is empty
								var aura_color = highlight_color
								aura_color.a = intensity * 0.5
								img.set_pixel(nx, ny, aura_color)
	
	# Add some pulsing nodes
	var node_count = 4
	if use_fixed_seed:
		node_count = seeded_randi_range(3, 6)
	
	for i in range(node_count):
		var node_x
		var node_y
		
		if use_fixed_seed:
			node_x = center_x + seeded_randf_range(-8, 8)
			node_y = center_y + seeded_randf_range(-8, 8)
		else:
			node_x = center_x + randf_range(-8, 8)
			node_y = center_y + randf_range(-8, 8)
		
		if node_x >= 0 and node_x < 64 and node_y >= 0 and node_y < 48:
			img.set_pixel(int(node_x), int(node_y), highlight_color)
			
			# Add glow around node
			for k in range(-2, 3):
				for l in range(-2, 3):
					if k == 0 and l == 0:
						continue
						
					var nx = int(node_x) + k
					var ny = int(node_y) + l
					
					if nx >= 0 and nx < 64 and ny >= 0 and ny < 48:
						var dist = sqrt(k*k + l*l)
						if dist < 2.5:
							var glow_intensity = 1.0 - (dist / 2.5)
							var glow_color = highlight_color
							glow_color.a = glow_intensity * 0.7
							
							if img.get_pixel(nx, ny).a < glow_color.a:
								img.set_pixel(nx, ny, glow_color)

func draw_crystal_root(img: Image, root_color: Color, detail_color: Color, highlight_color: Color) -> void:
	# Crystal-like roots with facets
	var center_x = 32
	var center_y = 24
	
	# Draw the main crystalline structure
	for y in range(15, 35):
		for x in range(25, 40):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			if dist_x < 7 - dist_y/8 and dist_y < 12:
				# Create faceted appearance with geometric patterns
				var pattern_value = (x * 3 + y * 5) % 7
				
				if pattern_value < 3:
					img.set_pixel(x, y, root_color)
				elif pattern_value < 5:
					img.set_pixel(x, y, detail_color)
				else:
					img.set_pixel(x, y, highlight_color)
	
	# Add crystal spikes
	var spike_count = 6
	if use_fixed_seed:
		spike_count = seeded_randi_range(4, 8)
	
	for i in range(spike_count):
		var angle
		var length
		
		if use_fixed_seed:
			angle = seeded_randf() * PI * 1.5 - PI * 0.25
			length = seeded_randf_range(8, 15)
		else:
			angle = randf() * PI * 1.5 - PI * 0.25
			length = randf_range(8, 15)
		
		var start_x = center_x + cos(angle) * 5
		var start_y = center_y + sin(angle) * 5
		
		for j in range(int(length)):
			var progress = float(j) / length
			var width = max(1, int(3 * (1.0 - progress)))
			
			var x = start_x + cos(angle) * j
			var y = start_y + sin(angle) * j
			
			for w in range(-width, width + 1):
				var nx = int(x) + int(w * sin(angle))
				var ny = int(y) - int(w * cos(angle))
				
				if nx >= 0 and nx < 64 and ny >= 0 and ny < 48:
					var color_choice = (j + i) % 3
					
					if color_choice == 0:
						img.set_pixel(nx, ny, root_color)
					elif color_choice == 1:
						img.set_pixel(nx, ny, detail_color)
					else:
						img.set_pixel(nx, ny, highlight_color)
