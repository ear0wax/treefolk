extends Node

# Base class for pixel art generation with seed support
class_name PixelArtBase

# Seed value for random generation
var generation_seed: int = 0
var use_fixed_seed: bool = false

# Color palette variations
var color_palettes = {
	"standard": {
		"wood": Color(0.45, 0.3, 0.15),
		"bark": Color(0.35, 0.2, 0.1),
		"leaf": Color(0.2, 0.5, 0.2),
		"highlight": Color(0.55, 0.4, 0.25)
	},
	"autumn": {
		"wood": Color(0.5, 0.35, 0.2),
		"bark": Color(0.4, 0.25, 0.15),
		"leaf": Color(0.7, 0.3, 0.1),
		"highlight": Color(0.8, 0.5, 0.2)
	},
	"winter": {
		"wood": Color(0.4, 0.3, 0.2),
		"bark": Color(0.3, 0.2, 0.15),
		"leaf": Color(0.5, 0.5, 0.5),
		"highlight": Color(0.7, 0.7, 0.8)
	},
	"spring": {
		"wood": Color(0.5, 0.35, 0.2),
		"bark": Color(0.4, 0.25, 0.15),
		"leaf": Color(0.3, 0.6, 0.3),
		"highlight": Color(0.5, 0.7, 0.3)
	},
	"magical": {
		"wood": Color(0.4, 0.3, 0.5),
		"bark": Color(0.3, 0.2, 0.4),
		"leaf": Color(0.4, 0.6, 0.8),
		"highlight": Color(0.6, 0.8, 1.0)
	},
	"crystal": {
		"wood": Color(0.6, 0.7, 0.8),
		"bark": Color(0.4, 0.5, 0.7),
		"leaf": Color(0.7, 0.8, 0.9),
		"highlight": Color(0.9, 0.95, 1.0)
	},
	"desert": {
		"wood": Color(0.6, 0.5, 0.3),
		"bark": Color(0.5, 0.4, 0.2),
		"leaf": Color(0.7, 0.7, 0.4),
		"highlight": Color(0.8, 0.8, 0.5)
	},
	"tropical": {
		"wood": Color(0.5, 0.4, 0.3),
		"bark": Color(0.4, 0.3, 0.2),
		"leaf": Color(0.1, 0.6, 0.3),
		"highlight": Color(0.3, 0.7, 0.4)
	},
	"volcanic": {
		"wood": Color(0.3, 0.2, 0.2),
		"bark": Color(0.2, 0.1, 0.1),
		"leaf": Color(0.6, 0.2, 0.1),
		"highlight": Color(0.8, 0.4, 0.1)
	}
}

# Initialize with optional seed
func initialize(seed_value: int = -1):
	if seed_value >= 0:
		generation_seed = seed_value
		use_fixed_seed = true
	else:
		generation_seed = randi()
		use_fixed_seed = false

# Get a seeded random float between 0 and 1
func seeded_randf() -> float:
	if use_fixed_seed:
		# Use a simple but deterministic algorithm based on the seed
		generation_seed = (generation_seed * 1103515245 + 12345) & 0x7FFFFFFF
		return float(generation_seed) / 2147483647.0
	else:
		return randf()

# Get a seeded random float in a range
func seeded_randf_range(from: float, to: float) -> float:
	return from + seeded_randf() * (to - from)

# Get a seeded random int in a range
func seeded_randi_range(from: int, to: int) -> int:
	return int(round(seeded_randf_range(from, to)))

# Get a color palette based on seed
func get_palette_for_seed() -> Dictionary:
	# Check if we should use the color manager
	var color_manager = get_color_manager()
	if color_manager != null:
		return color_manager.get_color_palette(generation_seed)
	
	# Fallback to original method if color manager not available
	var palette_keys = color_palettes.keys()
	var palette_index = generation_seed % palette_keys.size()
	var base_palette = color_palettes[palette_keys[palette_index]]
	
	# Create a new palette with slight variations
	var palette = {}
	for key in base_palette:
		var color = base_palette[key]
		
		# Add some variation based on the seed
		var hue_shift = fmod(float(generation_seed) / 10000.0, 0.1) - 0.05
		var saturation_shift = fmod(float(generation_seed) / 5000.0, 0.2) - 0.1
		var value_shift = fmod(float(generation_seed) / 2500.0, 0.2) - 0.1
		
		var hsv = color.to_hsv()
		hsv.x = fmod(hsv.x + hue_shift, 1.0)
		hsv.y = clamp(hsv.y + saturation_shift, 0.0, 1.0)
		hsv.z = clamp(hsv.z + value_shift, 0.0, 1.0)
		
		palette[key] = Color.from_hsv(hsv.x, hsv.y, hsv.z)
	
	return palette

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

# Save a texture to a file
func save_texture(texture: ImageTexture, path: String) -> void:
	var img = texture.get_image()
	img.save_png(path)
	print("Saved texture to: " + path)

# Ensure the textures directory exists
func ensure_textures_dir() -> void:
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
