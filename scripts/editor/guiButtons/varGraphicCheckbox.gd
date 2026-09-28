class_name VarGraphicCheckbox
extends TextureButton

const CHECKBOX_CHECKED: Texture2D = preload("uid://c85u2d3vvjm3y")
const CHECKBOX_UNCHECKED: Texture2D = preload("uid://ge50dc08hxhq")

var variable: Variable

func _ready() -> void:
	texture_normal = CHECKBOX_UNCHECKED
	texture_pressed = CHECKBOX_CHECKED
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	toggle_mode = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size.x = 50.0
	button_pressed = variable.visible
	pressed.connect(onPress)

func onPress() -> void:
	variable.visible = button_pressed
