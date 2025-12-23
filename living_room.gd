extends Node2D

#change dialogue and also git the gift open image, maybe simple music???

var outline_material = preload("res://outline_material.tres")
var hovered_areas = []
var dialogue_open = false
var is_typing = false
var full_text = ""
var current_char = 0
var type_speed = 0.02

var current_dialogue_chain = []
var current_dialogue_index = 0

var game_vars = {
	"has_catnip": false,
	"gave_catnip": false,
	"has_keys": false,
	"gift_opened": false,
	"outside": false,
	"got_keys_from_cat": false
}


var meow = preload("res://assets/meow.wav")
@onready var audio_player = $AudioStreamPlayer

var dialogue = {
	"carpetcol": [
		{"text": "A carpet. \nThere's a cat on it.", "type": "text"},
	],
		"catcol": [
		{"text": "A cat. \nThere's a carpet under it.", "type": "text"},
		{"text": "Pet the cat?", "type": "choice_conditional", 
		 "condition": "gave_catnip",
		 "if_true": {
			"choices": ["Pet", "Leave"], 
			"responses": [
				[{"text": "purrrrrrrrrrrrrrrrrr", "type": "text", "sound": true}],
				[{"text": "The cat looks really high...", "type": "text"}]
			]
		 },
		 "if_false": {
			"text": "Pet the cat?",
			"type": "choice_conditional",
			"condition": "has_catnip",
			"if_true": {
				"choices": ["Pet", "Give catnip", "Leave"], 
				"responses": [
					[{"text": "The cat purrs.", "type": "text"}],
					[
						{"text": "damn that shit gas", "type": "text", "sound": true, "trigger": "catniwp"},
						{"text": "oh yea btw heres ur keys i had them", "type": "text", "sound": true},
						{"text": "(...? You got your keys!)", "type": "text", "set_var": {"has_catnip": false, "gave_catnip": true, "has_keys": true, "got_keys_from_cat": true}}
					],
					[{"text": "The cat probably needs to rest, better not disturb it.", "type": "text"}]
				]
			},
			"if_false": {
				"choices": ["Pet", "Leave"], 
				"responses": [
					[{"text": "The cat purrs.", "type": "text"}],
					[{"text": "The cat probably needs to rest, better not disturb it.", "type": "text"}]
				]
			}
		 }
		}
	],
	"treecol": [
		{"text": "A decorated Christmas tree.", "type": "text"}
	],
	"giftcol": [
		{"text": "A present.", "type": "text"},
		{"text": "Open the present?", "type": "choice_conditional",
		 "condition": "gift_opened",
		 "if_true": {
			"choices": ["Yes", "No"],
			"responses": [
				[{"text": "You couldn't open the gift while it was open, so you closed it and opened it.", "type": "text"}, {"text": "It was empty. \nOf course.", "type": "text"}],
				[{"text": "Is it even possible to open a present after you've opened it?", "type": "text"}]
			]
		 },
		 "if_false": {
			"choices": ["Yes", "No"],
			"responses": [
				[
					{"text": "You got... catnip? \n(was this supposed to be for the cat?)", "type": "text", "set_var": {"has_catnip": true, "gift_opened": true}, "trigger": "gift_open"}
				],
				[{"text": "Might not be your present, better leave it for the recipient.", "type": "text"}]
			]
		 }
		}
	],
	"lampcol": [
		{"text": "A lamp. \nYou must be really tall to interact with this.", "type": "text"}
	],
	"doorexitcol": [
		{"text": "The door to go outside.", "type": "text"},
		{"text": "Go outside?", "type": "choice_conditional",
		 "condition": "has_keys",
		 "if_true": {
			"choices": ["Yes", "No"],
			"responses": [
				[{"text": "You went outside.", "type": "text", "set_var": {"outside": true}}],
				[{"text": "Maybe stay a bit longer.", "type": "text"}]
			]
		 },
		 "if_false": {
			"choices": ["Yes", "No"],
			"responses": [
				[{"text": "It's locked. You need keys.", "type": "text"}],
				[{"text": "Maybe stay a bit longer.", "type": "text"}]
			]
		 }
		}
	],
	"doorsidecol": [
		{"text": "yea i didnt have the time to make and code a whole other room sorry :heavysob: \n-the person who made this house (definitely not elslie)", "type": "text"}
	]
}

@onready var dialogue_label = $dialogue
@onready var dialogue_box = $ColorRect
@onready var choice_container = $ChoiceContainer

@onready var cat_sprite = $cat
@onready var gift_sprite = $gift

func _ready():
	dialogue_box.visible = false
	dialogue_label.visible = false
	choice_container.visible = false
	
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
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
		if has_node(sprite_name):
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
	if has_node(sprite_name):
		var sprite = get_node(sprite_name)
		return sprite.z_index
	return 0

func _on_input_event(_viewport, event, _shape_idx, area):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not dialogue_open and area == get_topmost_area():
			start_dialogue(dialogue[area.name])

func start_dialogue(dialogue_chain):
	current_dialogue_chain = process_dialogue_chain(dialogue_chain)
	current_dialogue_index = 0
	dialogue_open = true
	show_current_dialogue()

func process_dialogue_chain(chain):
	var processed = []
	for item in chain:
		if item.type == "choice_conditional":
			var resolved = resolve_conditional(item)
			processed.append(resolved)
		else:
			processed.append(item)
	return processed

func resolve_conditional(item):
	var condition_met = game_vars.get(item.condition, false)
	
	if condition_met:
		if item.if_true.has("condition"):
			return resolve_conditional(item.if_true)
		else:
			return {
				"text": item.text,
				"type": "choice",
				"choices": item.if_true.choices,
				"responses": item.if_true.responses
			}
	else:
		if item.if_false.has("condition"):
			return resolve_conditional(item.if_false)
		else:
			return {
				"text": item.text,
				"type": "choice",
				"choices": item.if_false.choices,
				"responses": item.if_false.responses
			}

func show_current_dialogue():
	var dialogue_data = current_dialogue_chain[current_dialogue_index]
	
	if dialogue_data.has("set_var"):
		for key in dialogue_data.set_var.keys():
			game_vars[key] = dialogue_data.set_var[key]
	
	if dialogue_data.has("trigger"):
		trigger_event(dialogue_data.trigger)
	
	var play_sound = dialogue_data.get("sound", false)
	
	if dialogue_data.type == "text":
		choice_container.visible = false
		dialogue_box.visible = true
		dialogue_label.visible = true
		full_text = dialogue_data.text
		current_char = 0
		is_typing = true
		dialogue_label.text = ""
		type_text(play_sound)
	
	elif dialogue_data.type == "choice":
		dialogue_box.visible = true
		dialogue_label.visible = true
		dialogue_label.text = dialogue_data.text
		show_choices(dialogue_data.choices, dialogue_data.responses)

func trigger_event(event_name):
	match event_name:
		"catniwp":
			cat_sprite.texture = preload("res://assets/catniwp.png")
		"gift_open":
			gift_sprite.texture = preload("res://assets/giftopen.png")

func show_choices(choices, responses):
	for child in choice_container.get_children():
		child.queue_free()
	
	choice_container.visible = true
	
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]
		button.custom_minimum_size = Vector2(200, 100)
		button.add_theme_font_size_override("font_size", 48)
		
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

func type_text(play_sound = false):
	while current_char < full_text.length() and is_typing:
		dialogue_label.text += full_text[current_char]
		current_char += 1
		
		if play_sound and meow and current_char % 2 == 0:
			audio_player.stream = meow
			audio_player.pitch_scale = randf_range(0.95, 1.05)
			audio_player.play()
		
		await get_tree().create_timer(type_speed).timeout
	
	is_typing = false
