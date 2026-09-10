extends Node

const GRAB: Texture2D = preload("uid://cyhafdxhi27q5")
const GRABBING: Texture2D = preload("uid://yfkjq1icqgh")

func _ready() -> void:
	Input.set_custom_mouse_cursor(GRAB, Input.CURSOR_HELP, Vector2(16.0, 16.0))

func _input(event: InputEvent) -> void:
	# Debug toggle fullscreen
	if event is InputEventKey:
		if event.is_action_pressed(&"toggleFullscreen"):
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_max_size(Vector2i(1152, 648))
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_max_size(Vector2i(1920, 1080))
				DisplayServer.window_set_position(Vector2i(int((DisplayServer.screen_get_size().x/2.0)-(DisplayServer.window_get_size().x/2.0)),int((DisplayServer.screen_get_size().y/2.0)-(DisplayServer.window_get_size().y/2.0))))
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# Grab blocks
	if Input.is_action_just_pressed(&"leftMouse") and Input.get_current_cursor_shape() == Input.CURSOR_HELP:
		Input.set_custom_mouse_cursor(GRABBING, Input.CURSOR_HELP, Vector2(16.0, 16.0))
	if Input.is_action_just_released(&"leftMouse"):
		Input.set_custom_mouse_cursor(GRAB, Input.CURSOR_HELP, Vector2(16.0, 16.0))
