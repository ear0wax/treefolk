extends Control

func _ready():
	# Create UI elements
	create_tree_resource_bars()
	create_color_mode_toggle()
	create_fungus_panel()
	create_season_display()
	create_event_panel()
	create_trauma_test_buttons()
	
	# Connect button signals
	$RegrowTreeButton.pressed.connect(_on_regrow_tree_pressed)
	$ReRollArtButton.pressed.connect(_on_reroll_art_pressed)

# ... [keep all existing functions] ...

func create_trauma_test_buttons():
	# Create a panel for trauma test buttons
	var test_panel = Panel.new()
	test_panel.name = "TraumaTestPanel"
	test_panel.size_flags_horizontal = Control.SIZE_FILL
	test_panel.size_flags_vertical = Control.SIZE_FILL
	test_panel.position = Vector2(230, 630)
	test_panel.size = Vector2(200, 150)
	add_child(test_panel)
	
	# Add a title label
	var title_label = Label.new()
	title_label.text = "Test Trauma Events"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(180, 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_panel.add_child(title_label)
	
	# Add buttons for different trauma types
	var trauma_types = ["Lightning", "Disease", "Pest", "Drought"]
	var y_offset = 40
	
	for i in range(trauma_types.size()):
		var button = Button.new()
		button.name = trauma_types[i] + "Button"
		button.text = trauma_types[i]
		button.position = Vector2(10, y_offset)
		button.size = Vector2(180, 25)
		test_panel.add_child(button)
		
		# Connect button signals
		button.pressed.connect(func(): _on_trauma_test_button_pressed(i))
		
		y_offset += 30
	
	# Add a severity slider
	var severity_label = Label.new()
	severity_label.text = "Severity: 1.0"
	severity_label.name = "SeverityLabel"
	severity_label.position = Vector2(10, y_offset)
	severity_label.size = Vector2(180, 20)
	test_panel.add_child(severity_label)
	
	var severity_slider = HSlider.new()
	severity_slider.name = "SeveritySlider"
	severity_slider.min_value = 0.1
	severity_slider.max_value = 2.0
	severity_slider.step = 0.1
	severity_slider.value = 1.0
	severity_slider.position = Vector2(10, y_offset + 20)
	severity_slider.size = Vector2(180, 20)
	test_panel.add_child(severity_slider)
	
	# Connect slider value changed signal
	severity_slider.value_changed.connect(_on_severity_slider_changed)

func _on_trauma_test_button_pressed(trauma_type):
	# Trigger a trauma event of the selected type
	var main_node = get_node("/root/Main")
	if main_node and main_node.trauma_system:
		var severity = 1.0
		
		# Get severity from slider if available
		if has_node("TraumaTestPanel/SeveritySlider"):
			severity = get_node("TraumaTestPanel/SeveritySlider").value
		
		main_node.trauma_system.trigger_trauma_event(trauma_type, severity)

func _on_severity_slider_changed(value):
	# Update severity label
	if has_node("TraumaTestPanel/SeverityLabel"):
		get_node("TraumaTestPanel/SeverityLabel").text = "Severity: " + str(value)
