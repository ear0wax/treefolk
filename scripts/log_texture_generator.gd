extends Node

# Log texture generator for 16-bit style pixel art
# This script generates pixel art textures for logs that match the tree aesthetic

func _ready():
	generate_log_textures()

func generate_log_textures():
	# Create textures directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	if not dir.dir_exists("textures/gameplay"):
		dir.make_dir("textures/gameplay")
	
	# Generate and save log textures
	var log_texture = generate_log_texture()
	save_texture(log_texture, "res://textures/gameplay/log.png")
	
	# Generate variations
	var log_texture_moss = generate_log_texture(1)
	save_texture(log_texture_moss, "res://textures/gameplay/log_moss.png")
	
	var log_texture_old = generate_log_texture(2)
	save_texture(log_texture_old, "res://textures/gameplay/log_old.png")
	
	print("Log textures generated successfully")

func generate_log_texture(variation: int = 0) -> ImageTexture:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Get color palette from color manager if available
	var color_manager = get_color_manager()
	var palette = null
	
	if color_manager != null:
		palette = color_manager.get_color_palette(randi())
	else:
		# Fallback to default colors
		palette = {
			"wood": Color(0.45, 0.3, 0.15),  # Brown
			"bark": Color(0.35, 0.2, 0.1),   # Darker brown
			"leaf": Color(0.2, 0.5, 0.2),    # Green
			"highlight": Color(0.55, 0.4, 0.25)  # Lighter brown
		}
	
	# Base colors - match the tree trunk colors
	var log_color = palette.wood
	var bark_color = palette.bark
	var highlight_color = palette.highlight
	
	# Apply variations
	match variation:
		1:  # Mossy log
			log_color = log_color.darkened(0.1)  # Slightly darker
			bark_color = bark_color.darkened(0.1)  # Darker
			highlight_color = Color(0.3, 0.5, 0.2)  # Green moss
		2:  # Old log
			log_color = log_color.darkened(0.2)  # Grayer
			bark_color = bark_color.darkened(0.2)  # Darker gray
			highlight_color = highlight_color.darkened(0.1)  # Lighter gray
	
	# Draw the log body
	var center_x = 16
	var center_y = 16
	var log_width = 24
	var log_height = 10
	
	# Draw the main log body (horizontal)
	for y in range(center_y - log_height/2, center_y + log_height/2):
		for x in range(center_x - log_width/2, center_x + log_width/2):
			# Calculate distance from center for cylinder effect
			var rel_y = (y - center_y) / float(log_height/2)
			
			# Create cylindrical shape
			if abs(rel_y) < 1.0:
				# Determine pixel color based on position
				var color = log_color
				
				# Add wood grain pattern - similar to trunk texture
				if (x + y*3) % 7 == 0 or (x - y*2) % 5 == 0:
					color = bark_color
				
				# Add highlights to top
				if rel_y < -0.5 and (x + y) % 5 == 0:
					color = highlight_color
				
				img.set_pixel(x, y, color)
	
	# Draw the end caps (circular)
	var cap_radius = log_height / 2
	
	# Left cap
	var left_cap_x = center_x - log_width/2
	for y in range(center_y - cap_radius, center_y + cap_radius):
		for x in range(left_cap_x - 2, left_cap_x + 3):
			var dist = sqrt(pow(x - left_cap_x, 2) + pow(y - center_y, 2))
			if dist < cap_radius:
				var color = bark_color
				
				# Add wood rings
				if int(dist) % 2 == 0:
					color = log_color.darkened(0.1)
				
				# Add some variation
				if (x + y) % 3 == 0:
					color = color.lightened(0.1)
				
				img.set_pixel(x, y, color)
	
	# Right cap
	var right_cap_x = center_x + log_width/2
	for y in range(center_y - cap_radius, center_y + cap_radius):
		for x in range(right_cap_x - 2, right_cap_x + 3):
			var dist = sqrt(pow(x - right_cap_x, 2) + pow(y - center_y, 2))
			if dist < cap_radius:
				var color = bark_color
				
				# Add wood rings
				if int(dist) % 2 == 0:
					color = log_color.darkened(0.1)
				
				# Add some variation
				if (x + y) % 3 == 0:
					color = color.lightened(0.1)
				
				img.set_pixel(x, y, color)
	
	# Add knots in the wood (like in trunk texture)
	var knot_count = 2
	if variation == 2:  # Old logs have more knots
		knot_count = 3
	
	for i in range(knot_count):
		var knot_x = randi_range(center_x - log_width/2 + 4, center_x + log_width/2 - 4)
		var knot_y = randi_range(center_y - 2, center_y + 2)
		var knot_size = randi_range(1, 2)
		
		for y in range(knot_y - knot_size, knot_y + knot_size + 1):
			for x in range(knot_x - knot_size, knot_x + knot_size + 1):
				var dist = sqrt(pow(x - knot_x, 2) + pow(y - knot_y, 2))
				if dist <= knot_size and x >= 0 and x < 32 and y >= 0 and y < 32:
					if img.get_pixel(x, y).a > 0:  # Only if on log
						img.set_pixel(x, y, bark_color.darkened(0.3))
	
	# Add details based on variation
	match variation:
		1:  # Mossy log - add moss patches
			for i in range(5):
				var moss_x = randi_range(center_x - log_width/2 + 4, center_x + log_width/2 - 4)
				var moss_y = randi_range(center_y - log_height/2, center_y - 1)
				var moss_size = randi_range(1, 2)
				
				for y in range(moss_y - moss_size, moss_y + moss_size + 1):
					for x in range(moss_x - moss_size, moss_x + moss_size + 1):
						var dist = sqrt(pow(x - moss_x, 2) + pow(y - moss_y, 2))
						if dist <= moss_size and x >= 0 and x < 32 and y >= 0 and y < 32:
							if img.get_pixel(x, y).a > 0:  # Only if on log
								if randf() > 0.3:
									img.set_pixel(x, y, highlight_color)
								else:
									img.set_pixel(x, y, highlight_color.darkened(0.2))
		
		2:  # Old log - add cracks and damage
			for i in range(2):
				var crack_x = randi_range(center_x - log_width/2 + 5, center_x + log_width/2 - 5)
				var crack_length = randi_range(3, 6)
				
				for j in range(crack_length):
					var x = crack_x + j
					var y = center_y + (j % 3) - 1
					if x >= 0 and x < 32 and y >= 0 and y < 32:
						if img.get_pixel(x, y).a > 0:  # Only if on log
							img.set_pixel(x, y, bark_color.darkened(0.3))
	
	var texture = ImageTexture.create_from_image(img)
	return texture

# Get the color manager if it exists
func get_color_manager():
	if Engine.has_singleton("ColorManager"):
		return Engine.get_singleton("ColorManager")
	
	# Try to find it in the scene
	var root = get_tree().get_root()
	if root.has_node("ColorManager"):
		return root.get_node("ColorManager")
	
	# Try to get the instance
	if ClassDB.class_exists("ColorManager"):
		var ColorManagerClass = load("res://scripts/color_manager.gd")
		if ColorManagerClass:
			return ColorManagerClass.get_instance()
	
	return null

func save_texture(texture: ImageTexture, path: String) -> void:
	var img = texture.get_image()
	img.save_png(path)
	print("Saved texture to: " + path)
