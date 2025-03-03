extends Node

# Treefolk texture generator for 16-bit style pixel art
# This script generates pixel art textures for treefolk characters

func _ready():
	generate_treefolk_textures()

func generate_treefolk_textures():
	# Create textures directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	if not dir.dir_exists("textures/gameplay"):
		dir.make_dir("textures/gameplay")
	
	# Generate and save treefolk textures
	var treefolk_texture = generate_treefolk_spritesheet()
	save_texture(treefolk_texture, "res://textures/gameplay/treefolk_sprite.png")
	
	# Generate variations
	var treefolk_elder = generate_treefolk_spritesheet(1)
	save_texture(treefolk_elder, "res://textures/gameplay/treefolk_elder.png")
	
	var treefolk_sapling = generate_treefolk_spritesheet(2)
	save_texture(treefolk_sapling, "res://textures/gameplay/treefolk_sapling.png")
	
	print("Treefolk textures generated successfully")

func generate_treefolk_spritesheet(variation: int = 0) -> ImageTexture:
	var img = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Start with transparent
	
	# Base colors
	var body_color = Color(0.4, 0.6, 0.3)  # Green-brown
	var detail_color = Color(0.3, 0.5, 0.2)  # Darker green-brown
	var highlight_color = Color(0.5, 0.7, 0.4)  # Lighter green
	var eye_color = Color(1, 1, 1)  # White
	
	# Apply variations
	match variation:
		1:  # Elder treefolk
			body_color = Color(0.5, 0.4, 0.3)  # More brown
			detail_color = Color(0.4, 0.3, 0.2)
			highlight_color = Color(0.6, 0.5, 0.4)
			# Add white "beard" later
		2:  # Sapling treefolk
			body_color = Color(0.3, 0.7, 0.4)  # More green
			detail_color = Color(0.2, 0.5, 0.3)
			highlight_color = Color(0.4, 0.8, 0.5)
	
	# Draw four frames of animation
	# Frame 1: Idle (32x32 area starting at 0,0)
	draw_treefolk_frame(img, 16, 16, body_color, detail_color, highlight_color, eye_color, 0, variation)
	
	# Frame 2: Walk 1 (32x32 area starting at 32,0)
	draw_treefolk_frame(img, 48, 16, body_color, detail_color, highlight_color, eye_color, 1, variation)
	
	# Frame 3: Walk 2 (32x32 area starting at 64,0)
	draw_treefolk_frame(img, 80, 16, body_color, detail_color, highlight_color, eye_color, 2, variation)
	
	# Frame 4: Walk 3 (32x32 area starting at 96,0)
	draw_treefolk_frame(img, 112, 16, body_color, detail_color, highlight_color, eye_color, 3, variation)
	
	# Frame 5: Action (32x32 area starting at 0,32)
	draw_treefolk_frame(img, 16, 48, body_color, detail_color, highlight_color, eye_color, 4, variation)
	
	# Frame 6: Rest (32x32 area starting at 32,32)
	draw_treefolk_frame(img, 48, 48, body_color, detail_color, highlight_color, eye_color, 5, variation)
	
	var texture = ImageTexture.create_from_image(img)
	return texture

func draw_treefolk_frame(img: Image, center_x: int, center_y: int, body_color: Color, 
						detail_color: Color, highlight_color: Color, eye_color: Color, 
						frame: int, variation: int):
	# Body dimensions
	var body_width = 10
	var body_height = 16
	var head_size = 6
	
	# Adjust size based on variation
	if variation == 1:  # Elder - slightly wider
		body_width += 2
	elif variation == 2:  # Sapling - slightly smaller
		body_width -= 2
		body_height -= 2
		head_size -= 1
	
	# Draw the body based on frame
	match frame:
		0:  # Idle
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 0)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 0, variation)
		
		1:  # Walk 1
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 0)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 1, variation)
		
		2:  # Walk 2
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 0)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 2, variation)
		
		3:  # Walk 3
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 0)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 3, variation)
		
		4:  # Action (working)
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 1)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 4, variation)
		
		5:  # Rest
			draw_treefolk_body(img, center_x, center_y, body_width, body_height, body_color, detail_color, highlight_color, 2)
			draw_treefolk_head(img, center_x, center_y - body_height/2 - head_size/2, head_size, body_color, detail_color, highlight_color, eye_color, variation)
			draw_treefolk_limbs(img, center_x, center_y, body_width, body_height, body_color, detail_color, 5, variation)

func draw_treefolk_body(img: Image, center_x: int, center_y: int, width: int, height: int, 
					   body_color: Color, detail_color: Color, highlight_color: Color, pose: int):
	# Body poses: 0=standing, 1=working, 2=resting
	var y_offset = 0
	if pose == 1:
		y_offset = 1  # Slightly lower for working
	elif pose == 2:
		y_offset = 2  # Lower for resting
	
	# Draw the main body trunk
	for y in range(center_y - height/2 + y_offset, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			# Calculate relative position
			var rel_x = (x - center_x) / float(width/2)
			var rel_y = (y - center_y) / float(height/2)
			
			# Create a trunk-like shape
			if abs(rel_x) < 0.8 - 0.2 * abs(rel_y):
				var color = body_color
				
				# Add bark texture
				if (x + y*3) % 7 == 0 or (x - y*2) % 5 == 0:
					color = detail_color
				
				# Add highlights
				if (x + y) % 9 == 0:
					color = highlight_color
				
				img.set_pixel(x, y, color)

func draw_treefolk_head(img: Image, center_x: int, center_y: int, size: int, 
					   body_color: Color, detail_color: Color, highlight_color: Color, 
					   eye_color: Color, variation: int):
	# Draw the head (slightly oval)
	for y in range(center_y - size, center_y + size):
		for x in range(center_x - size, center_x + size):
			var rel_x = (x - center_x) / float(size)
			var rel_y = (y - center_y) / float(size)
			
			# Create oval shape
			if rel_x * rel_x + rel_y * rel_y * 1.2 < 1.0:
				var color = body_color
				
				# Add texture
				if (x + y) % 5 == 0:
					color = detail_color
				
				# Add highlights at top
				if rel_y < -0.5 and (x + y) % 7 == 0:
					color = highlight_color
				
				img.set_pixel(x, y, color)
	
	# Draw eyes
	var eye_spacing = size / 2
	var eye_y = center_y - size/4
	
	# Left eye
	for y in range(eye_y - 1, eye_y + 2):
		for x in range(center_x - eye_spacing - 1, center_x - eye_spacing + 2):
			if abs(x - (center_x - eye_spacing)) <= 1 and abs(y - eye_y) <= 1:
				img.set_pixel(x, y, eye_color)
	
	# Right eye
	for y in range(eye_y - 1, eye_y + 2):
		for x in range(center_x + eye_spacing - 1, center_x + eye_spacing + 2):
			if abs(x - (center_x + eye_spacing)) <= 1 and abs(y - eye_y) <= 1:
				img.set_pixel(x, y, eye_color)
	
	# Add variation-specific details
	if variation == 1:  # Elder - add "beard" of roots
		for i in range(5):
			var start_x = center_x - 3 + i * 1.5
			var start_y = center_y + size - 1
			var length = 3 + (i % 3)
			
			for j in range(length):
				var x = int(start_x)
				var y = start_y + j
				
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, detail_color)
	
	elif variation == 2:  # Sapling - add leaf sprout on top
		for i in range(3):
			var x = center_x
			var y = center_y - size - i
			
			if y >= 0:
				img.set_pixel(x, y, highlight_color)
				
				if i > 0:
					img.set_pixel(x-1, y, highlight_color)
					img.set_pixel(x+1, y, highlight_color)

func draw_treefolk_limbs(img: Image, center_x: int, center_y: int, body_width: int, body_height: int, 
						body_color: Color, _detail_color: Color, pose: int, variation: int):
	# Limb poses: 0=idle, 1-3=walking, 4=working, 5=resting
	
	# Arm positions based on pose
	var left_arm_angle = 0
	var right_arm_angle = 0
	var left_arm_length = 5
	var right_arm_length = 5
	
	# Leg positions based on pose
	var left_leg_angle = PI/2  # Straight down
	var right_leg_angle = PI/2  # Straight down
	var left_leg_length = 6
	var right_leg_length = 6
	
	# Adjust limb parameters based on pose
	match pose:
		0:  # Idle
			left_arm_angle = PI * 0.6  # Slightly down
			right_arm_angle = PI * 0.4  # Slightly down
		
		1:  # Walk 1
			left_arm_angle = PI * 0.7  # More down
			right_arm_angle = PI * 0.3  # More up
			left_leg_angle = PI * 0.6  # Forward
			right_leg_angle = PI * 0.4  # Back
		
		2:  # Walk 2
			left_arm_angle = PI * 0.5  # Middle
			right_arm_angle = PI * 0.5  # Middle
			left_leg_angle = PI * 0.4  # Back
			right_leg_angle = PI * 0.6  # Forward
		
		3:  # Walk 3
			left_arm_angle = PI * 0.3  # More up
			right_arm_angle = PI * 0.7  # More down
			left_leg_angle = PI * 0.5  # Middle
			right_leg_angle = PI * 0.5  # Middle
		
		4:  # Working
			left_arm_angle = PI * 0.2  # Up
			right_arm_angle = PI * 0.2  # Up
			left_arm_length = 6  # Extended
			right_arm_length = 6  # Extended
		
		5:  # Resting
			left_arm_angle = PI * 0.5  # Out to side
			right_arm_angle = PI * 0.5  # Out to side
			left_leg_angle = PI * 0.4  # Relaxed
			right_leg_angle = PI * 0.6  # Relaxed
	
	# Adjust for variation
	if variation == 1:  # Elder - longer arms
		left_arm_length += 1
		right_arm_length += 1
	elif variation == 2:  # Sapling - shorter limbs
		left_arm_length -= 1
		right_arm_length -= 1
		left_leg_length -= 1
		right_leg_length -= 1
	
	# Draw arms
	# Left arm
	var left_arm_start_x = center_x - body_width/2
	var left_arm_start_y = center_y - body_height/4
	
	for i in range(left_arm_length):
		var x = left_arm_start_x - i * cos(left_arm_angle)
		var y = left_arm_start_y + i * sin(left_arm_angle)
		
		if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(int(x), int(y), body_color)
			
			# Add some width to the arm
			if i > 0:
				var y_offset = 1
				if y + y_offset < img.get_height():
					img.set_pixel(int(x), int(y) + y_offset, body_color)
	
	# Right arm
	var right_arm_start_x = center_x + body_width/2
	var right_arm_start_y = center_y - body_height/4
	
	for i in range(right_arm_length):
		var x = right_arm_start_x + i * cos(right_arm_angle)
		var y = right_arm_start_y + i * sin(right_arm_angle)
		
		if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(int(x), int(y), body_color)
			
			# Add some width to the arm
			if i > 0:
				var y_offset = 1
				if y + y_offset < img.get_height():
					img.set_pixel(int(x), int(y) + y_offset, body_color)
	
	# Draw legs
	# Left leg
	var left_leg_start_x = center_x - body_width/4
	var left_leg_start_y = center_y + body_height/2
	
	for i in range(left_leg_length):
		var x = left_leg_start_x - i * cos(left_leg_angle)
		var y = left_leg_start_y + i * sin(left_leg_angle)
		
		if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(int(x), int(y), body_color)
			
			# Add some width to the leg
			var x_offset = 1
			if x + x_offset < img.get_width():
				img.set_pixel(int(x) + x_offset, int(y), body_color)
	
	# Right leg
	var right_leg_start_x = center_x + body_width/4
	var right_leg_start_y = center_y + body_height/2
	
	for i in range(right_leg_length):
		var x = right_leg_start_x + i * cos(right_leg_angle)
		var y = right_leg_start_y + i * sin(right_leg_angle)
		
		if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(int(x), int(y), body_color)
			
			# Add some width to the leg
			var x_offset = 1
			if x + x_offset < img.get_width():
				img.set_pixel(int(x) + x_offset, int(y), body_color)

func save_texture(texture: ImageTexture, path: String) -> void:
	var img = texture.get_image()
	img.save_png(path)
	print("Saved texture to: " + path)
