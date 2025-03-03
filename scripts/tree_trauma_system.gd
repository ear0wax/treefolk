extends Node

# Tree Trauma System
# Handles various traumatic events that can affect the tree's growth and health

class_name TreeTraumaSystem

# Types of trauma events
enum TraumaType {
	LIGHTNING,      # Lightning strike
	DISEASE,        # Disease outbreak
	PEST,           # Pest infestation
	DROUGHT,        # Drought period
	FLOOD,          # Flooding
	FIRE,           # Fire damage
	FROST,          # Frost damage
	PHYSICAL        # Physical damage (e.g., animal, human)
}

# Reference to the tree manager
var tree_manager = null

# Trauma event history
var trauma_history = []

# Signals
signal trauma_event_occurred(event_type, severity, affected_components)
signal disease_spread(from_component, to_component, disease_type)
signal pest_spread(from_component, to_component, pest_type)

func _ready():
	# Find the tree manager
	await get_tree().process_frame
	var main_node = get_node("/root/Main")
	if main_node and main_node.tree_manager:
		tree_manager = main_node.tree_manager

func trigger_trauma_event(event_type: TraumaType, severity: float = 1.0, target_component = null):
	# Trigger a specific trauma event
	print("Trauma event triggered: " + TraumaType.keys()[event_type] + " with severity " + str(severity))
	
	# Record the event
	var event_data = {
		"type": event_type,
		"severity": severity,
		"time": Time.get_unix_time_from_system(),
		"affected_components": []
	}
	
	# Apply the trauma effects
	match event_type:
		TraumaType.LIGHTNING:
			apply_lightning_strike(severity, target_component, event_data)
		TraumaType.DISEASE:
			apply_disease(severity, target_component, event_data)
		TraumaType.PEST:
			apply_pest_infestation(severity, target_component, event_data)
		TraumaType.DROUGHT:
			apply_drought(severity, event_data)
		TraumaType.FLOOD:
			apply_flood(severity, event_data)
		TraumaType.FIRE:
			apply_fire(severity, target_component, event_data)
		TraumaType.FROST:
			apply_frost(severity, event_data)
		TraumaType.PHYSICAL:
			apply_physical_damage(severity, target_component, event_data)
	
	# Add to history
	trauma_history.append(event_data)
	
	# Emit signal
	emit_signal("trauma_event_occurred", event_type, severity, event_data.affected_components)

func apply_lightning_strike(severity: float, target_component, event_data: Dictionary):
	# Lightning typically hits the top of the tree
	var affected_components = []
	
	if target_component == null and tree_manager != null:
		# Target the highest trunk section if no specific target
		if tree_manager.trunk_sections.size() > 0:
			target_component = tree_manager.trunk_sections[tree_manager.trunk_sections.size() - 1]
	
	if target_component != null:
		# Apply direct damage to the target component
		if target_component.has_node("TrunkComponent"):
			var component = target_component.get_node("TrunkComponent")
			component.add_damage(50.0 * severity)
			component.add_trauma(70.0 * severity)
			affected_components.append(target_component)
			
			# Lightning can cause fire
			if randf() < 0.3 * severity:
				component.add_rot(20.0 * severity)  # Charring/burning
			
			# Lightning can travel down the trunk
			var current = target_component
			var index = tree_manager.trunk_sections.find(current)
			
			while index > 0:
				index -= 1
				current = tree_manager.trunk_sections[index]
				
				if current.has_node("TrunkComponent"):
					var trunk_comp = current.get_node("TrunkComponent")
					trunk_comp.add_damage(30.0 * severity * (index + 1) / tree_manager.trunk_sections.size())
					trunk_comp.add_trauma(50.0 * severity * (index + 1) / tree_manager.trunk_sections.size())
					affected_components.append(current)
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_disease(severity: float, target_component, event_data: Dictionary):
	# Disease affects a component and can spread to connected components
	var affected_components = []
	
	if target_component == null and tree_manager != null:
		# Choose a random component if no specific target
		var all_components = tree_manager.all_components
		if all_components.size() > 0:
			target_component = all_components[randi() % all_components.size()]
	
	if target_component != null:
		# Apply disease effects to the target component
		var component = null
		
		if target_component.has_node("TrunkComponent"):
			component = target_component.get_node("TrunkComponent")
		elif target_component.has_node("BranchComponent"):
			component = target_component.get_node("BranchComponent")
		elif target_component.has_node("RootComponent"):
			component = target_component.get_node("RootComponent")
		
		if component != null:
			component.add_rot(30.0 * severity)  # Disease causes rot
			component.add_trauma(20.0 * severity)
			affected_components.append(target_component)
			
			# Disease can spread to connected components
			for child in component.child_components:
				if randf() < 0.4 * severity:
					child.add_rot(20.0 * severity)
					child.add_trauma(15.0 * severity)
					affected_components.append(child.get_parent())
					emit_signal("disease_spread", target_component, child.get_parent(), "fungal_rot")
			
			if component.parent_component != null:
				if randf() < 0.3 * severity:
					component.parent_component.add_rot(15.0 * severity)
					component.parent_component.add_trauma(10.0 * severity)
					affected_components.append(component.parent_component.get_parent())
					emit_signal("disease_spread", target_component, component.parent_component.get_parent(), "fungal_rot")
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_pest_infestation(severity: float, target_component, event_data: Dictionary):
	# Pests typically affect branches and leaves
	var affected_components = []
	
	if target_component == null and tree_manager != null:
		# Target a random branch if no specific target
		if tree_manager.branches.size() > 0:
			target_component = tree_manager.branches[randi() % tree_manager.branches.size()]
	
	if target_component != null:
		# Apply pest effects to the target component
		if target_component.has_node("BranchComponent"):
			var component = target_component.get_node("BranchComponent")
			component.add_damage(15.0 * severity)
			component.add_trauma(25.0 * severity)
			
			# Pests primarily affect leaves
			if component.has_leaves:
				component.leaf_health = max(0.0, component.leaf_health - 0.5 * severity)
			
			affected_components.append(target_component)
			
			# Pests can spread to nearby branches
			for branch in tree_manager.branches:
				if branch != target_component:
					var distance = branch.global_position.distance_to(target_component.global_position)
					if distance < 2.0:
						if branch.has_node("BranchComponent"):
							var branch_comp = branch.get_node("BranchComponent")
							branch_comp.add_damage(10.0 * severity)
							branch_comp.add_trauma(15.0 * severity)
							
							if branch_comp.has_leaves:
								branch_comp.leaf_health = max(0.0, branch_comp.leaf_health - 0.3 * severity)
							
							affected_components.append(branch)
							emit_signal("pest_spread", target_component, branch, "bark_beetle")
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_drought(severity: float, event_data: Dictionary):
	# Drought affects the entire tree, especially leaves and smaller branches
	var affected_components = []
	
	if tree_manager != null:
		# Reduce water resources
		tree_manager.water = max(0, tree_manager.water - 30.0 * severity)
		
		# Affect branches and leaves
		for branch in tree_manager.branches:
			if branch.has_node("BranchComponent"):
				var component = branch.get_node("BranchComponent")
				component.add_trauma(10.0 * severity)
				
				# Drought primarily affects leaves
				if component.has_leaves:
					component.leaf_health = max(0.0, component.leaf_health - 0.4 * severity)
				
				affected_components.append(branch)
		
		# Affect roots
		for root in tree_manager.roots:
			if root.has_node("RootComponent"):
				var component = root.get_node("RootComponent")
				component.add_trauma(15.0 * severity)
				component.water_gathering *= (1.0 - 0.3 * severity)  # Reduce water gathering ability
				affected_components.append(root)
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_flood(severity: float, event_data: Dictionary):
	# Flooding primarily affects roots and lower trunk
	var affected_components = []
	
	if tree_manager != null:
		# Increase water resources (temporarily)
		tree_manager.water = min(tree_manager.max_resources, tree_manager.water + 20.0 * severity)
		
		# Affect roots
		for root in tree_manager.roots:
			if root.has_node("RootComponent"):
				var component = root.get_node("RootComponent")
				component.add_trauma(20.0 * severity)
				component.add_rot(15.0 * severity)  # Waterlogging can cause rot
				affected_components.append(root)
		
		# Affect lower trunk sections
		var lower_trunk_count = min(2, tree_manager.trunk_sections.size())
		for i in range(lower_trunk_count):
			var trunk = tree_manager.trunk_sections[i]
			if trunk.has_node("TrunkComponent"):
				var component = trunk.get_node("TrunkComponent")
				component.add_trauma(10.0 * severity)
				component.add_rot(10.0 * severity)
				affected_components.append(trunk)
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_fire(severity: float, target_component, event_data: Dictionary):
	# Fire typically affects a specific area and can spread
	var affected_components = []
	
	if target_component == null and tree_manager != null:
		# Start fire at a random trunk or branch
		var potential_targets = []
		potential_targets.append_array(tree_manager.trunk_sections)
		potential_targets.append_array(tree_manager.branches)
		
		if potential_targets.size() > 0:
			target_component = potential_targets[randi() % potential_targets.size()]
	
	if target_component != null:
		# Apply fire damage to the target component
		var component = null
		
		if target_component.has_node("TrunkComponent"):
			component = target_component.get_node("TrunkComponent")
		elif target_component.has_node("BranchComponent"):
			component = target_component.get_node("BranchComponent")
		
		if component != null:
			component.add_damage(40.0 * severity)
			component.add_trauma(30.0 * severity)
			affected_components.append(target_component)
			
			# Fire can spread to nearby components
			var nearby_components = []
			
			# Find components within a certain distance
			for comp in tree_manager.all_components:
				if comp != target_component:
					var distance = comp.global_position.distance_to(target_component.global_position)
					if distance < 1.5:
						nearby_components.append(comp)
			
			# Fire spreads based on severity
			for comp in nearby_components:
				if randf() < 0.6 * severity:
					var child_comp = null
					
					if comp.has_node("TrunkComponent"):
						child_comp = comp.get_node("TrunkComponent")
					elif comp.has_node("BranchComponent"):
						child_comp = comp.get_node("BranchComponent")
					elif comp.has_node("RootComponent"):
						child_comp = comp.get_node("RootComponent")
					
					if child_comp != null:
						child_comp.add_damage(30.0 * severity)
						child_comp.add_trauma(20.0 * severity)
						affected_components.append(comp)
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_frost(severity: float, event_data: Dictionary):
	# Frost affects the entire tree, especially new growth and leaves
	var affected_components = []
	
	if tree_manager != null:
		# Affect branches and leaves
		for branch in tree_manager.branches:
			if branch.has_node("BranchComponent"):
				var component = branch.get_node("BranchComponent")
				
				# New growth is more susceptible to frost
				var damage_factor = 1.0
				if component.growth_stage < 2:
					damage_factor = 2.0
				
				component.add_damage(10.0 * severity * damage_factor)
				component.add_trauma(15.0 * severity * damage_factor)
				
				# Frost kills leaves
				if component.has_leaves:
					component.leaf_health = max(0.0, component.leaf_health - 0.7 * severity)
				
				affected_components.append(branch)
		
		# Affect trunk sections, especially newer ones
		for i in range(tree_manager.trunk_sections.size()):
			var trunk = tree_manager.trunk_sections[i]
			if trunk.has_node("TrunkComponent"):
				var component = trunk.get_node("TrunkComponent")
				
				# Newer trunk sections (higher up) are more susceptible
				var damage_factor = float(i) / max(1, tree_manager.trunk_sections.size() - 1)
				
				component.add_damage(5.0 * severity * damage_factor)
				component.add_trauma(10.0 * severity * damage_factor)
				affected_components.append(trunk)
	
	# Record affected components
	event_data.affected_components = affected_components

func apply_physical_damage(severity: float, target_component, event_data: Dictionary):
	# Physical damage affects a specific component
	var affected_components = []
	
	if target_component == null and tree_manager != null:
		# Choose a random component if no specific target
		var all_components = tree_manager.all_components
		if all_components.size() > 0:
			target_component = all_components[randi() % all_components.size()]
	
	if target_component != null:
		# Apply physical damage to the target component
		var component = null
		
		if target_component.has_node("TrunkComponent"):
			component = target_component.get_node("TrunkComponent")
		elif target_component.has_node("BranchComponent"):
			component = target_component.get_node("BranchComponent")
		elif target_component.has_node("RootComponent"):
			component = target_component.get_node("RootComponent")
		
		if component != null:
			component.add_damage(30.0 * severity)
			component.add_trauma(40.0 * severity)
			affected_components.append(target_component)
			
			# Physical damage can create entry points for disease
			if randf() < 0.3 * severity:
				component.add_rot(10.0 * severity)
	
	# Record affected components
	event_data.affected_components = affected_components

func get_trauma_history():
	return trauma_history

func get_recent_trauma_events(count: int = 5):
	# Return the most recent trauma events
	var sorted_events = trauma_history.duplicate()
	sorted_events.sort_custom(func(a, b): return a.time > b.time)
	
	var recent_events = []
	for i in range(min(count, sorted_events.size())):
		recent_events.append(sorted_events[i])
	
	return recent_events
