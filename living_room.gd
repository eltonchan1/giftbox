extends Node2D

var outline_material = preload("res://outline_material.tres")
var hovered_areas = []
var dialogue_open = false
var is_typing = false
var full_text = ""
var current_char = 0
var type_speed = 0.03

var dialogue = {
	"carpetcol": "A carpet. \nThere's a cat on it.",
	"catcol": "A cat. \nSeems to be sleeping in today. \nThere's a carpet under it.",
	"treecol": "A Christmas tree. \nIt's pretty tall.",
	"giftcol": "A wrapped gift box. \nIt's perspective is a little weird, but it's a present nevertheless.",
	"lampcol": "A lamp. \nYou must be really tall to interact with this."
}

@onready var dialogue_label = $dialogue
@onready var dialogue_box = $ColorRect

func _ready():
	dialogue_box.visible = false
	dialogue_label.visible = false
	dialogue_label.text = ""
	
	for child in get_children():
		if child is Area2D:
			child.mouse_entered.connect(_on_mouse_entered.bind(child))
			child.mouse_exited.connect(_on_mouse_exited.bind(child))
			child.input_event.connect(_on_input_event.bind(child))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_open:
			if is_typing:
				# Skip to full text
				dialogue_label.text = full_text
				is_typing = false
			else:
				# Close dialogue
				dialogue_box.visible = false
				dialogue_label.visible = false
				dialogue_label.text = ""
				dialogue_open = false
			
			# Consume the event so it doesn't open a new dialogue
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
			dialogue_box.visible = true
			dialogue_label.visible = true
			dialogue_open = true
			full_text = dialogue[area.name]
			current_char = 0
			is_typing = true
			dialogue_label.text = ""
			type_text()

func type_text():
	while current_char < full_text.length() and is_typing:
		dialogue_label.text += full_text[current_char]
		current_char += 1
		await get_tree().create_timer(type_speed).timeout
	
	is_typing = false
