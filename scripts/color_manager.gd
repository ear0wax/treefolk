extends Node

# Color Manager for Norse Tree Builder
# Handles color scheme toggling between natural and wild colors

# Color mode
enum ColorMode {NATURAL, WILD}
var current_mode = ColorMode.NATURAL

# Signal when color mode changes
signal color_mode_changed(mode)

# Singleton pattern
static var instance = null

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	# Set initial color mode
	set_color_mode(ColorMode.NATURAL)

# Get the singleton instance
static func get_instance():
	if instance == null:
		instance = load("res://scripts/color_manager.gd").new()
	return instance

# Set the color mode
func set_color_mode(mode):
	current_mode = mode
	emit_signal("color_mode_changed", mode)
	print("Color mode set to: " + ("Natural" if mode == ColorMode.NATURAL else "Wild"))

# Toggle between color modes
func toggle_color_mode():
	if current_mode == ColorMode.NATURAL:
		set_color_mode(ColorMode.WILD)
	else:
		set_color_mode(ColorMode.NATURAL)

# Get current color mode
func get_color_mode():
	return current_mode

# Get a color palette based on the current mode
func get_color_palette(seed_value: int = 0):
	if current_mode == ColorMode.NATURAL:
		return get_natural_palette(seed_value)
	else:
		return get_wild_palette(seed_value)

# Natural color palette - more realistic, less variation
func get_natural_palette(seed_value: int = 0):
	var palette = {
		"wood": Color(0.45, 0.3, 0.15),  # Brown
		"bark": Color(0.35, 0.2, 0.1),   # Darker brown
		"leaf": Color(0.2, 0.5, 0.2),    # Green
		"highlight": Color(0.55, 0.4, 0.25)  # Lighter brown
	}
	
	# Add slight variation based on seed
	if seed_value > 0:
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_value
		
		# Small variations (±10%)
		for key in palette:
			palette[key] = Color(
				clamp(palette[key].r + (rng.randf() - 0.5) * 0.2, 0, 1),
				clamp(palette[key].g + (rng.randf() - 0.5) * 0.2, 0, 1),
				clamp(palette[key].b + (rng.randf() - 0.5) * 0.2, 0, 1)
			)
	
	return palette

# Wild color palette - fantasy colors with high variation
func get_wild_palette(seed_value: int = 0):
	var base_palette = {
		"wood": Color(0.45, 0.3, 0.15),  # Default brown
		"bark": Color(0.35, 0.2, 0.1),   # Default darker brown
		"leaf": Color(0.2, 0.5, 0.2),    # Default green
		"highlight": Color(0.55, 0.4, 0.25)  # Default highlight
	}
	
	# If no seed, return a random wild palette
	if seed_value <= 0:
		var hue = randf()
		base_palette.wood = Color.from_hsv(hue, 0.7, 0.5)
		base_palette.bark = Color.from_hsv(fmod(hue + 0.05, 1.0), 0.8, 0.3)
		base_palette.leaf = Color.from_hsv(fmod(hue + 0.3, 1.0), 0.8, 0.6)
		base_palette.highlight = Color.from_hsv(fmod(hue + 0.1, 1.0), 0.6, 0.7)
		return base_palette
	
	# Use the seed to create very different color palettes
	var hue_shift = fmod(float(seed_value) / 1000.0, 1.0)
	var saturation = fmod(float(seed_value) / 500.0, 0.5) + 0.5
	var value = fmod(float(seed_value) / 250.0, 0.3) + 0.7
	
	var palette = {}
	palette.wood = Color.from_hsv(hue_shift, saturation, value)
	palette.bark = Color.from_hsv(fmod(hue_shift + 0.05, 1.0), saturation, value * 0.8)
	
	# Leaf colors can be completely different
	var leaf_hue = fmod(float(seed_value) / 700.0, 1.0)
	palette.leaf = Color.from_hsv(leaf_hue, saturation, value)
	palette.highlight = Color.from_hsv(fmod(leaf_hue + 0.05, 1.0), saturation * 0.8, value * 1.2)
	
	# Seasonal variations
	var season = seed_value % 4
	match season:
		0:  # Spring - fresh green
			palette.leaf = Color(0.2, 0.6, 0.2).lerp(palette.leaf, 0.3)
			palette.highlight = Color(0.3, 0.7, 0.3).lerp(palette.highlight, 0.3)
		1:  # Summer - deep green
			palette.leaf = Color(0.1, 0.4, 0.1).lerp(palette.leaf, 0.3)
			palette.highlight = Color(0.2, 0.5, 0.2).lerp(palette.highlight, 0.3)
		2:  # Fall - orange/red
			palette.leaf = Color(0.7, 0.3, 0.1).lerp(palette.leaf, 0.3)
			palette.highlight = Color(0.8, 0.4, 0.1).lerp(palette.highlight, 0.3)
		3:  # Winter - brown/sparse
			palette.leaf = Color(0.5, 0.4, 0.2).lerp(palette.leaf, 0.3)
			palette.highlight = Color(0.6, 0.5, 0.3).lerp(palette.highlight, 0.3)
	
	return palette
