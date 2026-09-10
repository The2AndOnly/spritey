class_name CodeBlock
extends MarginContainer

var mouseTouching := false
var initialOffset: Vector2 = Vector2.ZERO
var dragDisabled := false

func _ready() -> void:
	mouse_entered.connect(mouseEntered)
	mouse_exited.connect(mouseExited)

func _process(_delta: float) -> void:
	if Input.is_action_pressed(&"leftMouse"):
		if ((!mouseTouching) and (initialOffset == Vector2.ZERO)) or dragDisabled:
			dragDisabled = true
			return
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
		global_position = get_global_mouse_position() + initialOffset
	else:
		initialOffset = Vector2.ZERO
		dragDisabled = false

func mouseEntered() -> void:
	mouseTouching = true

func mouseExited() -> void:
	mouseTouching = false
