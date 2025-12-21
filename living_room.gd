extends Node2D

var outline_material = preload("res://outline_material.tres")
var hovered_areas = []
var dialogue_open = false
var is_typing = false
var full_text = ""
var current_char = 0
var type_speed = 0.05

var current_dialogue_chain = []
var current_dialogue_index = 0

# Game state variables
var game_vars = {
	"has_catnip": false,
	"has_keys": false,
	"in_room": false
}

var dialogue = {
	"carpetcol": [
		{"text": "A carpet. \nThere's a cat on it.", "type": "text"},
	],
	"catcol": [
		{"text": "A cat. \nThere's a carpet under it.", "type": "text"},
		{"text": "Pet the cat?", "type": "choice_conditional", 
		 "condition": "has_catnip",  # Check if player has catnip
		 "if_true": {  # Show this if has_catnip = true
			"choices": ["Pet", "Give catnip", "Leave"], 
			"responses": [
				[{"text": "The cat purrs.", "type": "text"}],
				[
					{"text": "dayum that stuff good", "type": "text"},
					{"text": "The cat is very happy now.", "type": "text", "set_var": {"has_catnip": false}}
				],
				[{"text": "The cat probably needs to rest, better not disturb it.", "type": "text"}]
			]
		 },
		 "if_false": {  # Show this if has_catnip = false
			"choices": ["Pet", "Leave"], 
			"responses": [
				[{"text": "The cat purrs.", "type": "text"}],
				[{"text": "The cat probably needs to rest, better not disturb it.", "type": "text"}]
			]
		 }
		}
	],
	"treecol": [
		{"text": "A decorated Christmas tree.", "type": "text"}
	],
	"giftcol": [
		{"text": "A present.", "type": "text"},
		{"text": "Open the present?", "type": "choice", "choices": ["Yes", "No"], "responses": [
			[
				{"text": "You got... catnip? \n(was this supposed to be for the cat?)", "type": "text", "set_var": {"has_catnip": true}},
			],
			[{"text": "Might not be your present, better leave it for the recipient.", "type": "text"}]
		]}
	],
	"lampcol": [
		{"text": "A lamp. \nYou must be really tall to interact with this.", "type": "text"}
	],
	"doorsidecol": [
		{"text": "A door to your room.", "type": "text"},
		{"text": "Enter your room?", "type": "choice", "choices": ["Yes", "No"], "responses": [
			[{"text": "You entered your room.", "type": "text", "set_var": {"in_room": true}}],
			[{"text": "Maybe not the best time right now.", "type": "text"}]
		]}
	]
}

@onready var dialogue_label = $dialogue
@onready var dialogue_box = $ColorRect
@onready var choice_container = $ChoiceContainer

func _ready():
	dialogue_box.visible = false
	dialogue_label.visible = false
	choice_container.visible = false
	
	for child in get_children():
		if child is Area2D:
			child.mouse_entered.connect(_on_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_mouse_exited.bind(child))
			child.input_event.connect(_on_input_event.bind(child))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_open and choice_container.visible == false:
			if is_typing:
				dialogue_label.text = full_text
				is_typing = false
			else:
				advance_dialogue()
			
			get_viewport().set_input_as_handled()

func _on_mouse_entered(area):
	if area not in hovered_areas:
		hovered_areas.append(area)
	update_outline()

func _on_mouse_exited(area):
	hovered_areas.erase(area)
	update_outline()

func update_outline():
	for child in get_children():
		if child is Sprite2D:
			child.material = null
	
	if hovered_areas.size() > 0:
		var top_area = get_topmost_area()
		var sprite_name = top_area.name.replace("col", "")
		var sprite = get_node(sprite_name)
		sprite.material = outline_material

func get_topmost_area():
	var top_area = hovered_areas[0]
	var highest_z = get_sprite_z(top_area)
	
	for area in hovered_areas:
		var z = get_sprite_z(area)
		if z > highest_z:
			highest_z = z
			top_area = area
	
	return top_area

func get_sprite_z(area):
	var sprite_name = area.name.replace("col", "")
	var sprite = get_node(sprite_name)
	return sprite.z_index

func _on_input_event(_viewport, event, _shape_idx, area):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not dialogue_open and area == get_topmost_area():
			start_dialogue(dialogue[area.name])

func start_dialogue(dialogue_chain):
	current_dialogue_chain = dialogue_chain
	current_dialogue_index = 0
	dialogue_open = true
	show_current_dialogue()

func show_current_dialogue():
	var dialogue_data = current_dialogue_chain[current_dialogue_index]
	
	# Check if this dialogue sets any variables
	if dialogue_data.has("set_var"):
		for key in dialogue_data.set_var.keys():
			game_vars[key] = dialogue_data.set_var[key]
	
	if dialogue_data.type == "text":
		choice_container.visible = false
		dialogue_box.visible = true
		dialogue_label.visible = true
		full_text = dialogue_data.text
		current_char = 0
		is_typing = true
		dialogue_label.text = ""
		type_text()
	
	elif dialogue_data.type == "choice":
		dialogue_box.visible = true
		dialogue_label.visible = true
		dialogue_label.text = dialogue_data.text
		show_choices(dialogue_data.choices, dialogue_data.responses)
	
	elif dialogue_data.type == "choice_conditional":
		# Check the condition and show appropriate choices
		var condition_met = game_vars.get(dialogue_data.condition, false)
		var choice_data = dialogue_data.if_true if condition_met else dialogue_data.if_false
		
		dialogue_box.visible = true
		dialogue_label.visible = true
		dialogue_label.text = dialogue_data.text
		show_choices(choice_data.choices, choice_data.responses)

func show_choices(choices, responses):
	# Clear old buttons
	for child in choice_container.get_children():
		child.queue_free()
	
	choice_container.visible = true
	
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]
		button.custom_minimum_size = Vector2(200, 100)
		button.add_theme_font_size_override("font_size", 48)
		
		# Create custom style
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)
		button.add_theme_stylebox_override("focus", style_pressed)
		button.add_theme_stylebox_override("disabled", style_pressed)
		
		button.add_theme_color_override("font_color", Color(0.216, 0.169, 0.145, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.373, 0.301, 0.265, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.466, 0.38, 0.338, 1.0))
		
		button.pressed.connect(_on_choice_selected.bind(responses[i]))
		choice_container.add_child(button)

func _on_choice_selected(response_chain):
	choice_container.visible = false
	start_dialogue(response_chain)

func advance_dialogue():
	current_dialogue_index += 1
	
	if current_dialogue_index < current_dialogue_chain.size():
		show_current_dialogue()
	else:
		close_dialogue()

func close_dialogue():
	dialogue_box.visible = false
	dialogue_label.visible = false
	choice_container.visible = false
	dialogue_label.text = ""
	dialogue_open = false

func type_text():
	while current_char < full_text.length() and is_typing:
		dialogue_label.text += full_text[current_char]
		current_char += 1
		await get_tree().create_timer(type_speed).timeout
	
	is_typing = false
