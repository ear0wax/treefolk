extends Node

# Fungus Manager for Norse Tree Builder
# Handles fungus growth, collection, and effects

class_name FungusManager

# Fungus properties
var fungus_types = {
	0: {
		"name": "Normal",
		"color": Color(1.0, 0.9, 0.8),
		"growth_rate": 1.0,
		"nutrient_value": 5,
		"rarity": 0.5
	},
	1: {
		"name": "Red",
		"color": Color(1.0, 0.5, 0.4),
		"growth_rate": 1.2,
		"nutrient_value": 8,
		"rarity": 0.3
	},
	2: {
		"name": "Blue",
		"color": Color(0.6, 0.7, 1.0),
		"growth_rate": 0.8,
		"nutrient_value": 12,
		"rarity": 0.15
	},
	3: {
		"name": "Glowing",
		"color": Color(0.8, 0.9, 0.6),
		"growth_rate": 0.6,
		"nutrient_value": 20,
		"rarity": 0.05
	}
}

# Fungus collection
var total_fungus_collected = 0
var fungus_by_type = [0, 0, 0, 0]  # Count of each type collected

# Fungus effects
var active_effects = []

# Signals
signal fungus_collected(type, amount)
signal fungus_effect_activated(effect_type, duration)
signal fungus_effect_ended(effect_type)

func _ready():
	# Initialize fungus manager
	pass

func _process(delta):
	# Process active effects
	process_effects(delta)

func collect_fungus(type: int, amount: int = 1):
	# Add to collection
	total_fungus_collected += amount
	fungus_by_type[type] += amount
	
	# Apply immediate effects based on fungus type
	apply_fungus_effects(type, amount)
	
	# Emit signal
	emit_signal("fungus_collected", type, amount)
	
	print("Collected " + str(amount) + " " + fungus_types[type].name + " fungus")
	return fungus_types[type].nutrient_value * amount

func apply_fungus_effects(type: int, amount: int):
	# Different fungus types have different effects
	match type:
		0:  # Normal - small nutrient boost
			add_nutrients(fungus_types[type].nutrient_value * amount)
		
		1:  # Red - growth speed boost
			activate_effect("growth_boost", 30.0, 1.5)
		
		2:  # Blue - water retention
			activate_effect("water_retention", 60.0, 0.5)
		
		3:  # Glowing - special effect (tree glow + attract treefolk)
			activate_effect("tree_glow", 120.0, 2.0)
			add_nutrients(fungus_types[type].nutrient_value * amount * 2)

func activate_effect(effect_type: String, duration: float, magnitude: float):
	# Check if effect already active
	for effect in active_effects:
		if effect.type == effect_type:
			# Extend duration
			effect.remaining_time = max(effect.remaining_time, duration)
			effect.magnitude = max(effect.magnitude, magnitude)
			print("Extended " + effect_type + " effect duration to " + str(effect.remaining_time))
			return
	
	# Add new effect
	var effect = {
		"type": effect_type,
		"remaining_time": duration,
		"magnitude": magnitude
	}
	
	active_effects.append(effect)
	
	# Apply initial effect
	apply_effect_start(effect_type, magnitude)
	
	# Emit signal
	emit_signal("fungus_effect_activated", effect_type, duration)
	
	print("Activated " + effect_type + " effect for " + str(duration) + " seconds")

func process_effects(delta):
	var effects_to_remove = []
	
	# Update all active effects
	for effect in active_effects:
		effect.remaining_time -= delta
		
		# Check if effect has expired
		if effect.remaining_time <= 0:
			effects_to_remove.append(effect)
		else:
			# Apply ongoing effect
			apply_effect_tick(effect.type, effect.magnitude, delta)
	
	# Remove expired effects
	for effect in effects_to_remove:
		active_effects.erase(effect)
		apply_effect_end(effect.type)
		emit_signal("fungus_effect_ended", effect.type)
		print(effect.type + " effect has ended")

func apply_effect_start(effect_type: String, magnitude: float):
	# Apply initial effect when activated
	var main_node = get_tree().get_root().get_node("Main")
	
	match effect_type:
		"growth_boost":
			if main_node and main_node.has_node("TreePivot"):
				# Visual indication of growth boost
				var tree_pivot = main_node.get_node("TreePivot")
				tree_pivot.modulate = Color(1.0, 1.2, 1.0)
		
		"water_retention":
			# No immediate visual effect
			pass
		
		"tree_glow":
			if main_node and main_node.has_node("TreePivot"):
				# Make tree glow
				var tree_pivot = main_node.get_node("TreePivot")
				
				# Add glow to all tree parts
				for part in main_node.current_tree_parts:
					if part.has_node("Sprite3D"):
						var sprite = part.get_node("Sprite3D")
						sprite.modulate = Color(1.0, 1.0, 1.0) * 1.5

func apply_effect_tick(effect_type: String, magnitude: float, delta: float):
	# Apply ongoing effect each frame
	var main_node = get_tree().get_root().get_node("Main")
	
	match effect_type:
		"growth_boost":
			if main_node:
				# Increase growth timer
				main_node.growth_timer += delta * (magnitude - 1.0)
		
		"water_retention":
			if main_node and main_node.tree_manager:
				# Reduce water consumption
				main_node.tree_manager.water_consumption_rate = 1.0 - (magnitude * 0.5)
		
		"tree_glow":
			if main_node and main_node.has_node("TreePivot"):
				# Pulsing glow effect
				var tree_pivot = main_node.get_node("TreePivot")
				var pulse = (sin(Time.get_ticks_msec() * 0.001) + 1.0) * 0.2 + 1.0
				
				# Apply to all tree parts
				for part in main_node.current_tree_parts:
					if part.has_node("Sprite3D"):
						var sprite = part.get_node("Sprite3D")
						sprite.modulate = Color(1.0, 1.0, 0.8) * pulse

func apply_effect_end(effect_type: String):
	# Apply cleanup when effect ends
	var main_node = get_tree().get_root().get_node("Main")
	
	match effect_type:
		"growth_boost":
			if main_node and main_node.has_node("TreePivot"):
				# Reset visual indication
				var tree_pivot = main_node.get_node("TreePivot")
				tree_pivot.modulate = Color(1.0, 1.0, 1.0)
		
		"water_retention":
			if main_node and main_node.tree_manager:
				# Reset water consumption
				main_node.tree_manager.water_consumption_rate = 1.0
		
		"tree_glow":
			if main_node and main_node.has_node("TreePivot"):
				# Reset glow
				for part in main_node.current_tree_parts:
					if part.has_node("Sprite3D"):
						var sprite = part.get_node("Sprite3D")
						sprite.modulate = Color(1.0, 1.0, 1.0)

func add_nutrients(amount: float):
	# Add nutrients to the tree
	var main_node = get_tree().get_root().get_node("Main")
	if main_node and main_node.tree_manager:
		main_node.tree_manager.nutrients += amount
		main_node.tree_manager.emit_signal("resources_updated", 
			main_node.tree_manager.nutrients, 
			main_node.tree_manager.water)
