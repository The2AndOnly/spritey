extends Area2D

# This is for detecting when the mouse is over a block to show the grabbing hand

const GRAB: Texture2D = preload("uid://cyhafdxhi27q5")
const GRABBING: Texture2D = preload("uid://yfkjq1icqgh")

var handEnabled := true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Filter out events that aren't a left click
		if Input.is_action_just_released(&"leftMouse"): handEnabled = true
		if !Input.is_action_pressed(&"leftMouse"): return
		# If initial click was outside block, disable the hand
		if get_overlapping_areas().size() == 0:
			handEnabled = false
	
	if event is InputEventMouse:
		global_position = get_global_mouse_position()
		if (get_overlapping_areas().size() > 0) and handEnabled:
			Input.set_custom_mouse_cursor(
				GRABBING if Input.is_action_pressed(&"leftMouse") else GRAB,
				Input.CURSOR_ARROW, Vector2(16.0, 16.0)
			)
		else:
			Input.set_custom_mouse_cursor(Global.ARROW, Input.CURSOR_ARROW)
