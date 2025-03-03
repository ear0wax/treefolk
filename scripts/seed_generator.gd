extends PixelArtBase

func _ready():
	# Generate the texture when the scene is loaded with default seed 3146
	generate_texture(3146)

func generate_texture(seed_value: int = 3146) -> void:
	initialize(seed_value)
	
	var texture = generate_seed_texture()
	ensure_textures_dir()
	save_texture(texture, "res://textures/seed.png")
	
	# Update the sprite with the new texture
	var sprite = get_parent().get_node("Sprite3D")
	if sprite:
		sprite.texture = texture

func generate_seed_texture() -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Seed style variations
	var seed_styles = ["acorn", "maple", "pine", "magical", "fantasy"]
	var style_index = 0
	
	if use_fixed_seed:
		style_index = generation_seed % seed_styles.size()
	else:
		style_index = randi() % seed_styles.size()
	
	var style = seed_styles[style_index]
	
	# Base colors with high variation
	var seed_color = Color(0.6, 0.4, 0.2)  # Default brown
	var cap_color = Color(0.4, 0.25, 0.1)  # Default darker brown for cap
	var highlight_color = Color(0.7, 0.5, 0.3)  # Default highlight
	
	# Dramatically vary the colors based on the seed
	if use_fixed_seed:
		# Use the seed to create very different color palettes
		var hue_shift = fmod(float(generation_seed) / 1000.0, 1.0)
		var saturation = fmod(float(generation_seed) / 500.0, 0.5) + 0.5
		var value = fmod(float(generation_seed) / 250.0, 0.3) + 0.7
		
		seed_color = Color.from_hsv(hue_shift, saturation, value)
		cap_color = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation, value * 0.8)
		highlight_color = Color.from_hsv(fmod(hue_shift - 0.05, 1.0), saturation * 0.8, value * 1.2)
	
	# Draw the seed based on style
	match style:
		"acorn":
			draw_acorn_seed(img, seed_color, cap_color, highlight_color)
		"maple":
			draw_maple_seed(img, seed_color, highlight_color)
		"pine":
			draw_pine_seed(img, seed_color, highlight_color)
		"magical":
			draw_magical_seed(img, seed_color, highlight_color)
		"fantasy":
			draw_fantasy_seed(img, seed_color, cap_color, highlight_color)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_acorn_seed(img: Image, seed_color: Color, cap_color: Color, highlight_color: Color) -> void:
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
				img.set_pixel(x, y, highlight_color)
	
	# Add some seed-specific details
	if use_fixed_seed:
		var detail_count = seeded_randi_range(2, 5)
		for i in range(detail_count):
			var detail_x = seeded_randi_range(13, 19)
			var detail_y = seeded_randi_range(15, 25)
			if img.get_pixel(detail_x, detail_y).a > 0:
				img.set_pixel(detail_x, detail_y, seed_color.darkened(0.3))

func draw_maple_seed(img: Image, seed_color: Color, highlight_color: Color) -> void:
	# Draw maple seed (samara) with wing
	var center_x = 16
	var center_y = 20
	
	# Draw the seed pod
	for y in range(18, 24):
		for x in range(14, 19):
			var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if dist < 3:
				img.set_pixel(x, y, seed_color)
	
	# Draw the wing
	for y in range(10, 26):
		for x in range(16, 26):
			var rel_y = y - center_y
			var rel_x = x - center_x
			
			# Create a curved wing shape
			if rel_x > 0 and rel_x < 10 and abs(rel_y) < 8 - rel_x/2:
				if rel_x + abs(rel_y) < 10:
					img.set_pixel(x, y, seed_color.lightened(0.1))
	
	# Add veins to the wing
	for y in range(10, 26):
		for x in range(16, 26):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 3 == 0:
					img.set_pixel(x, y, highlight_color)

func draw_pine_seed(img: Image, seed_color: Color, highlight_color: Color) -> void:
	# Draw pine seed (pinecone-like)
	var center_x = 16
	var center_y = 16
	
	# Draw the main seed body
	for y in range(12, 22):
		for x in range(12, 21):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			if dist_x + dist_y < 8 and dist_x*dist_x + dist_y*dist_y < 25:
				img.set_pixel(x, y, seed_color)
	
	# Add scale-like texture
	for y in range(12, 22):
		for x in range(12, 21):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 3 == 0 or (x - y) % 3 == 0:
					img.set_pixel(x, y, seed_color.darkened(0.2))
	
	# Add highlights
	for y in range(12, 22):
		for x in range(12, 21):
			if img.get_pixel(x, y).a > 0 and (x + y) % 5 == 0:
				img.set_pixel(x, y, highlight_color)

func draw_magical_seed(img: Image, seed_color: Color, highlight_color: Color) -> void:
	# Draw a glowing magical seed
	var center_x = 16
	var center_y = 16
	
	# Create a base circular seed
	for y in range(10, 23):
		for x in range(10, 23):
			var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if dist < 6:
				var intensity = 1.0 - (dist / 6.0)
				var pixel_color = seed_color.lightened(intensity * 0.5)
				img.set_pixel(x, y, pixel_color)
	
	# Add glowing aura
	for y in range(8, 25):
		for x in range(8, 25):
			var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
			if dist >= 6 and dist < 8:
				var intensity = 1.0 - ((dist - 6) / 2.0)
				var pixel_color = highlight_color
				pixel_color.a = intensity * 0.7
				
				# Only set if empty or blend with existing
				if img.get_pixel(x, y).a == 0:
					img.set_pixel(x, y, pixel_color)
	
	# Add some magical sparkles
	for i in range(8):
		var angle
		var distance
		
		if use_fixed_seed:
			angle = seeded_randf() * 2 * PI
			distance = seeded_randf_range(7, 10)
		else:
			angle = randf() * 2 * PI
			distance = randf_range(7, 10)
		
		var sparkle_x = int(center_x + cos(angle) * distance)
		var sparkle_y = int(center_y + sin(angle) * distance)
		
		if sparkle_x >= 0 and sparkle_x < 32 and sparkle_y >= 0 and sparkle_y < 32:
			img.set_pixel(sparkle_x, sparkle_y, highlight_color)
			
			# Add tiny cross shape for sparkle
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx = sparkle_x + offset.x
				var sy = sparkle_y + offset.y
				if sx >= 0 and sx < 32 and sy >= 0 and sy < 32:
					var sparkle_color = highlight_color
					sparkle_color.a = 0.7
					img.set_pixel(sx, sy, sparkle_color)

func draw_fantasy_seed(img: Image, seed_color: Color, cap_color: Color, highlight_color: Color) -> void:
	# Draw a fantasy-styled seed with crystalline elements
	var center_x = 16
	var center_y = 16
	
	# Draw crystal-like seed base
	for y in range(12, 24):
		for x in range(12, 21):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y) 
			
			# Create a crystal shape
			if dist_x < 4 and dist_y < 6 - dist_x/2:
				img.set_pixel(x, y, seed_color)
	
	# Add facets to the crystal
	for y in range(12, 24):
		for x in range(12, 21):
			if img.get_pixel(x, y).a > 0:
				if (x + y) % 4 == 0:
					img.set_pixel(x, y, highlight_color)
				elif (x - y) % 3 == 0:
					img.set_pixel(x, y, cap_color)
	
	# Add some small floating particles around the seed
	for i in range(10):
		var angle
		var distance
		
		if use_fixed_seed:
			angle = seeded_randf() * 2 * PI
			distance = seeded_randf_range(5, 8)
		else:
			angle = randf() * 2 * PI
			distance = randf_range(5, 8)
		
		var particle_x = int(center_x + cos(angle) * distance)
		var particle_y = int(center_y + sin(angle) * distance)
		
		if particle_x >= 0 and particle_x < 32 and particle_y >= 0 and particle_y < 32:
			var particle_color = highlight_color
			particle_color.a = 0.8
			img.set_pixel(particle_x, particle_y, particle_color)
