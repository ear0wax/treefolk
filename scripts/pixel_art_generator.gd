extends Node

# This script generates placeholder pixel art textures for tree components
# You can use these as references to create more detailed sprites later

func _ready():
	# Generate gameplay textures
	generate_gameplay_textures()

func generate_gameplay_textures():
	# Create textures directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	if not dir.dir_exists("textures/gameplay"):
		dir.make_dir("textures/gameplay")
	
	# Generate and save gameplay textures
	generate_and_save_crow_texture()
	generate_and_save_treefolk_texture()
	generate_and_save_ui_textures()
	generate_and_save_task_icons()

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

func generate_trunk_texture() -> ImageTexture:
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

func generate_branch_texture() -> ImageTexture:
	var img = Image.create(96, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var branch_color = Color(0.4, 0.25, 0.1)  # Brown
	var detail_color = Color(0.3, 0.2, 0.1)  # Darker brown
	var leaf_color = Color(0.2, 0.5, 0.2)  # Green
	var leaf_highlight = Color(0.3, 0.6, 0.3)  # Lighter green
	
	# Draw the main branch
	for y in range(14, 18):
		for x in range(8, 88):
			var thickness = 2 - abs(x - 48) / 40.0
			if abs(y - 16) < thickness:
				img.set_pixel(x, y, branch_color)
	
	# Add some bark texture
	for y in range(14, 18):
		for x in range(8, 88):
			if img.get_pixel(x, y).a > 0 and x % 5 == 0:
				img.set_pixel(x, y, detail_color)
	
	# Add some leaves
	for i in range(15):
		var leaf_x = randf_range(20, 80)
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

func generate_and_save_crow_texture():
	var img = Image.create(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var crow_color = Color(0.1, 0.1, 0.1)  # Black
	var highlight_color = Color(0.3, 0.3, 0.3)  # Dark gray for highlights
	
	# Draw two frames of crow animation
	# Frame 1 - Wings up
	for y in range(8, 24):
		for x in range(4, 28):
			# Body
			var body_center_x = 16
			var body_center_y =  16
			var dist_x = abs(x - body_center_x)
			var dist_y = abs(y - body_center_y)
			
			if dist_x*dist_x/36 + dist_y*dist_y/16 < 1:
				img.set_pixel(x, y, crow_color)
			
			# Wings up
			if (y < 12 and x > 8 and x < 24 and 
				(abs(x - 16) < 8 - abs(y - 8))):
				img.set_pixel(x, y, crow_color)
	
	# Head and beak
	for y in range(12, 18):
		for x in range(2, 8):
			var head_center_x = 5
			var head_center_y = 15
			var dist = sqrt(pow(x - head_center_x, 2) + pow(y - head_center_y, 2))
			
			if dist < 3:
				img.set_pixel(x, y, crow_color)
	
	# Beak
	for y in range(14, 16):
		for x in range(0, 2):
			img.set_pixel(x, y, Color(0.8, 0.7, 0.1))  # Yellow beak
	
	# Eye
	img.set_pixel(3, 14, Color(1, 1, 1))
	
	# Frame 2 - Wings down
	for y in range(8, 24):
		for x in range(36, 60):
			# Body
			var body_center_x = 48
			var body_center_y = 16
			var dist_x = abs(x - body_center_x)
			var dist_y = abs(y - body_center_y)
			
			if dist_x*dist_x/36 + dist_y*dist_y/16 < 1:
				img.set_pixel(x, y, crow_color)
			
			# Wings down
			if (y > 16 and x > 40 and x < 56 and 
				(abs(x - 48) < 8 - abs(y - 24))):
				img.set_pixel(x, y, crow_color)
	
	# Head and beak
	for y in range(12, 18):
		for x in range(34, 40):
			var head_center_x = 37
			var head_center_y = 15
			var dist = sqrt(pow(x - head_center_x, 2) + pow(y - head_center_y, 2))
			
			if dist < 3:
				img.set_pixel(x, y, crow_color)
	
	# Beak
	for y in range(14, 16):
		for x in range(32, 34):
			img.set_pixel(x, y, Color(0.8, 0.7, 0.1))  # Yellow beak
	
	# Eye
	img.set_pixel(35, 14, Color(1, 1, 1))
	
	# Add some highlights
	for y in range(8, 24):
		for x in range(4, 60):
			if img.get_pixel(x, y) == crow_color and (x + y) % 7 == 0:
				img.set_pixel(x, y, highlight_color)
	
	# Save the texture
	img.save_png("res://textures/gameplay/crow_sprite.png")
	print("Saved crow texture")

func generate_and_save_treefolk_texture():
	var img = Image.create(96, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	var body_color = Color(0.4, 0.6, 0.3)  # Green-brown
	var detail_color = Color(0.3, 0.5, 0.2)  # Darker green-brown
	var highlight_color = Color(0.5, 0.7, 0.4)  # Lighter green
	
	# Draw four frames of treefolk animation (idle + 3 walking frames)
	
	# Frame 1 - Idle
	draw_treefolk_frame(img, 16, 16, body_color, detail_color, highlight_color, 0)
	
	# Frame 2 - Walk 1
	draw_treefolk_frame(img, 48, 16, body_color, detail_color, highlight_color, 1)
	
	# Frame 3 - Walk 2
	draw_treefolk_frame(img, 80, 16, body_color, detail_color, highlight_color, 2)
	
	# Frame 4 - Walk 3
	draw_treefolk_frame(img, 16, 48, body_color, detail_color, highlight_color, 3)
	
	# Save the texture
	img.save_png("res://textures/gameplay/treefolk_sprite.png")
	print("Saved treefolk texture")

func draw_treefolk_frame(img: Image, center_x: int, center_y: int, body_color: Color, detail_color: Color, highlight_color: Color, frame: int):
	# Body
	for y in range(center_y - 10, center_y + 10):
		for x in range(center_x - 6, center_x + 6):
			var dist_x = abs(x - center_x)
			var dist_y = abs(y - center_y)
			
			if dist_x*dist_x/16 + dist_y*dist_y/100 < 1:
				img.set_pixel(x, y, body_color)
	
	# Head
	for y in range(center_y - 16, center_y - 10):
		for x in range(center_x - 4, center_x + 4):
			var dist = sqrt(pow(x - center_x, 2) + pow(y - (center_y - 13), 2))
			
			if dist < 4:
				img.set_pixel(x, y, body_color)
	
	# Eyes
	img.set_pixel(center_x - 2, center_y - 14, Color(1, 1, 1))
	img.set_pixel(center_x + 2, center_y - 14, Color(1, 1, 1))
	
	# Arms and legs based on frame
	match frame:
		0:  # Idle
			# Arms
			for i in range(5):
				img.set_pixel(center_x - 6 - i, center_y - 5 + i, body_color)
				img.set_pixel(center_x + 6 + i, center_y - 5 + i, body_color)
			
			# Legs
			for i in range(6):
				img.set_pixel(center_x - 3, center_y + 10 + i, body_color)
				img.set_pixel(center_x + 3, center_y + 10 + i, body_color)
		
		1:  # Walk 1
			# Arms
			for i in range(5):
				img.set_pixel(center_x - 6 - i, center_y - 5 + i, body_color)
				img.set_pixel(center_x + 6 + i, center_y - 5 + i, body_color)
			
			# Legs
			for i in range(6):
				img.set_pixel(center_x - 4, center_y + 10 + i, body_color)
				img.set_pixel(center_x + 2, center_y + 10 + i, body_color)
		
		2:  # Walk 2
			# Arms
			for i in range(5):
				img.set_pixel(center_x - 6 - i, center_y - 3 + i, body_color)
				img.set_pixel(center_x + 6 + i, center_y - 3 + i, body_color)
			
			# Legs
			for i in range(6):
				img.set_pixel(center_x - 2, center_y + 10 + i, body_color)
				img.set_pixel(center_x + 4, center_y + 10 + i, body_color)
		
		3:  # Walk 3
			# Arms
			for i in range(5):
				img.set_pixel(center_x - 6 - i, center_y - 5 + i, body_color)
				img.set_pixel(center_x + 6 + i, center_y - 5 + i, body_color)
			
			# Legs
			for i in range(6):
				img.set_pixel(center_x - 4, center_y + 10 + i, body_color)
				img.set_pixel(center_x + 2, center_y + 10 + i, body_color)
	
	# Add some leaf/branch details
	for y in range(center_y - 16, center_y + 16):
		for x in range(center_x - 10, center_x + 10):
			if img.get_pixel(x, y) == body_color:
				if (x + y) % 7 == 0:
					img.set_pixel(x, y, highlight_color)
				elif (x - y) % 5 == 0:
					img.set_pixel(x, y, detail_color)

func generate_and_save_ui_textures():
	# Generate log icon
	var log_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	log_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a log icon
	for y in range(12, 20):
		for x in range(6, 26):
			var dist_y = abs(y - 16)
			if dist_y < 4:
				log_img.fill_rect(Rect2i(x, y, 1, 1), Color(0.6, 0.4, 0.2))
				
				# Add some wood grain
				if (x + y) % 5 == 0:
					log_img.fill_rect(Rect2i(x, y, 1, 1), Color(0.5, 0.3, 0.1))
	
	# Add end circles
	for y in range(10, 22):
		for x in range(4, 8):
			var dist = sqrt(pow(x - 6, 2) + pow(y - 16, 2))
			if dist < 4:
				log_img.fill_rect(Rect2i(x, y, 1, 1), Color(0.7, 0.5, 0.3))
	
	for y in range(10, 22):
		for x in range(24, 28):
			var dist = sqrt(pow(x - 26, 2) + pow(y - 16, 2))
			if dist < 4:
				log_img.fill_rect(Rect2i(x, y, 1, 1), Color(0.7, 0.5, 0.3))
	
	# Save log icon
	log_img.save_png("res://textures/gameplay/log_icon.png")
	
	# Generate treefolk icon
	var treefolk_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	treefolk_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a simple treefolk icon
	var body_color = Color(0.4, 0.6, 0.3)  # Green-brown
	
	# Body
	for y in range(12, 24):
		for x in range(13, 19):
			treefolk_img.fill_rect(Rect2i(x, y, 1, 1), body_color)
	
	# Head
	for y in range(6, 12):
		for x in range(12, 20):
			var dist = sqrt(pow(x - 16, 2) + pow(y - 9, 2))
			if dist < 4:
				treefolk_img.fill_rect(Rect2i(x, y, 1, 1), body_color)
	
	# Arms
	for i in range(5):
		treefolk_img.fill_rect(Rect2i(8 + i, 14 + i, 1, 1), body_color)
		treefolk_img.fill_rect(Rect2i(23 - i, 14 + i, 1, 1), body_color)
	
	# Legs
	for i in range(6):
		treefolk_img.fill_rect(Rect2i(14, 24 + i, 1, 1), body_color)
		treefolk_img.fill_rect(Rect2i(18, 24 + i, 1, 1), body_color)
	
	# Save treefolk icon
	treefolk_img.save_png("res://textures/gameplay/treefolk_icon.png")

func generate_and_save_task_icons():
	# Generate task icons (32x32 each)
	
	# Idle icon
	var idle_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	idle_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a simple Z Z Z for sleeping/idle
	var z_color = Color(0.7, 0.7, 1.0)
	
	# First Z
	for x in range(12, 20):
		idle_img.fill_rect(Rect2i(x, 8, 1, 1), z_color)
	for y in range(8, 16):
		idle_img.fill_rect(Rect2i(20 - y + 8, y, 1, 1), z_color)
	for x in range(12, 20):
		idle_img.fill_rect(Rect2i(x, 16, 1, 1), z_color)
	
	# Second Z (smaller)
	for x in range(16, 22):
		idle_img.fill_rect(Rect2i(x, 12, 1, 1), z_color)
	for y in range(12, 18):
		idle_img.fill_rect(Rect2i(22 - y + 12, y, 1, 1), z_color)
	for x in range(16, 22):
		idle_img.fill_rect(Rect2i(x, 18, 1, 1), z_color)
	
	# Third Z (smallest)
	for x in range(20, 24):
		idle_img.fill_rect(Rect2i(x, 16, 1, 1), z_color)
	for y in range(16, 20):
		idle_img.fill_rect(Rect2i(24 - y + 16, y, 1, 1), z_color)
	for x in range(20, 24):
		idle_img.fill_rect(Rect2i(x, 20, 1, 1), z_color)
	
	# Save idle icon
	idle_img.save_png("res://textures/gameplay/idle_icon.png")
	
	# Log collection icon
	var log_collection_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	log_collection_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a log with an arrow
	var log_color = Color(0.6, 0.4, 0.2)
	var arrow_color = Color(0.2, 0.8, 0.2)
	
	# Log
	for y in range(16, 22):
		for x in range(8, 20):
			log_collection_img.fill_rect(Rect2i(x, y, 1, 1), log_color)
			
			# Add some wood grain
			if (x + y) % 4 == 0:
				log_collection_img.fill_rect(Rect2i(x, y, 1, 1), log_color.darkened(0.2))
	
	# Arrow
	for i in range(8):
		log_collection_img.fill_rect(Rect2i(20 + i, 18, 1, 1), arrow_color)
	
	# Arrow head
	for i in range(4):
		log_collection_img.fill_rect(Rect2i(24 + i, 18 - i, 1, 1), arrow_color)
		log_collection_img.fill_rect(Rect2i(24 + i, 18 + i, 1, 1), arrow_color)
	
	# Save log collection icon
	log_collection_img.save_png("res://textures/gameplay/log_collection_icon.png")
	
	# Shelter building icon
	var shelter_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	shelter_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a simple house/shelter
	var shelter_color = Color(0.7, 0.5, 0.3)
	var roof_color = Color(0.5, 0.3, 0.1)
	
	# House body
	for y in range(16, 24):
		for x in range(8, 24):
			shelter_img.fill_rect(Rect2i(x, y, 1, 1), shelter_color)
	
	# Roof
	for y in range(8, 16):
		for x in range(8 - (y - 8), 24 + (y - 8)):
			if x >= 0 and x < 32:
				shelter_img.fill_rect(Rect2i(x, y, 1, 1), roof_color)
	
	# Door
	for y in range(18, 24):
		for x in range(14, 18):
			shelter_img.fill_rect(Rect2i(x, y, 1, 1), roof_color.darkened(0.3))
	
	# Window
	for y in range(18, 21):
		for x in range(20, 23):
			shelter_img.fill_rect(Rect2i(x, y, 1, 1), Color(0.8, 0.9, 1.0))
	
	# Save shelter icon
	shelter_img.save_png("res://textures/gameplay/shelter_icon.png")
	
	# Ladder building icon
	var ladder_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	ladder_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a simple ladder
	var ladder_color = Color(0.7, 0.5, 0.3)
	
	# Vertical sides
	for y in range(8, 24):
		ladder_img.fill_rect(Rect2i(12, y, 1, 1), ladder_color)
		ladder_img.fill_rect(Rect2i(20, y, 1, 1), ladder_color)
	
	# Horizontal rungs
	for i in range(5):
		for x in range(12, 21):
			ladder_img.fill_rect(Rect2i(x, 10 + i * 3, 1, 1), ladder_color)
	
	# Save ladder icon
	ladder_img.save_png("res://textures/gameplay/ladder_icon.png")
	
	# Tree maintenance icon
	var maintain_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	maintain_img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Draw a tree with a wrench
	var tree_color = Color(0.3, 0.5, 0.2)
	var trunk_color = Color(0.5, 0.3, 0.1)
	var tool_color = Color(0.7, 0.7, 0.7)
	
	# Tree trunk
	for y in range(16, 24):
		for x in range(14, 18):
			maintain_img.fill_rect(Rect2i(x, y, 1, 1), trunk_color)
	
	# Tree foliage
	for y in range(8, 16):
		for x in range(8, 24):
			var dist_x = abs(x - 16)
			var dist_y = abs(y - 12)
			if dist_x*dist_x/36 + dist_y*dist_y/16 < 1:
				maintain_img.fill_rect(Rect2i(x, y, 1, 1), tree_color)
	
	# Wrench
	for i in range(6):
		maintain_img.fill_rect(Rect2i(20 + i, 20 + i, 1, 1), tool_color)
		maintain_img.fill_rect(Rect2i(20 + i, 20 + i + 1, 1, 1), tool_color)
	
	for i in range(3):
		maintain_img.fill_rect(Rect2i(20 + i, 20 - i, 1, 1), tool_color)
		maintain_img.fill_rect(Rect2i(20 + i, 20 - i - 1, 1, 1), tool_color)
	
	# Save maintenance icon
	maintain_img.save_png("res://textures/gameplay/maintain_icon.png")

func save_textures():
	# Create directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	
	# Generate and save each texture
	var seed_texture = generate_seed_texture()
	var root_texture = generate_root_texture()
	var trunk_texture = generate_trunk_texture()
	var branch_texture = generate_branch_texture()
	var leaf_texture = generate_leaf_texture()
	
	# Save the textures
	var seed_img = seed_texture.get_image()
	seed_img.save_png("res://textures/seed.png")
	
	var root_img = root_texture.get_image()
	root_img.save_png("res://textures/root.png")
	
	var trunk_img = trunk_texture.get_image()
	trunk_img.save_png("res://textures/trunk.png")
	
	var branch_img = branch_texture.get_image()
	branch_img.save_png("res://textures/branch.png")
	
	var leaf_img = leaf_texture.get_image()
	leaf_img.save_png("res://textures/leaf.png")
	
	print("All textures generated and saved to the textures folder")
