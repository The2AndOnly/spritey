class_name BlockInputEdit
extends LineEdit

# 0 = integer
# 1 = float
# 2 = string
# 3 = positive integer
# 4 = positive float
var type: int = 0
var block: CodeBlock
var detectedBlock: CodeBlock
var highlight: Panel
var detectionShape: CollisionShape2D
var touchingMouse := false

func _ready() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	text_changed.connect(onType)
	focus_entered.connect(onFocus)
	focus_exited.connect(onFocusExit)
	text_submitted.connect(onSubmit)

func mouseEntered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_IBEAM)
	touchingMouse = true

func mouseExited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	touchingMouse = false

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int):
	if event.is_action_pressed(&"leftMouse"):
		grab_focus()
		select_all()
		caret_column = text.length()

func onType(_newText: String) -> void:
	block.size.x = 0.0
	setDetectionRect()

func setDetectionRect() -> void:
	detectionShape.shape.size = size
	detectionShape.position = size / Vector2(2.0, 2.0)

func onFocus() -> void:
	block.focused = true
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	block.getHighestInStack().setToFront()
func onFocusExit() -> void:
	onSubmit(text)
func onSubmit(_newText: String) -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	setDetectionRect()
	release_focus()
	block.focusExit()
