class_name BlockInputEdit
extends LineEdit

# 0 = integer
# 1 = float
# 2 = string
# 3 = positive integer
# 4 = positive float
var type: int = 0
var block: CodeBlock
var highlight: Panel
var detectionShape: CollisionShape2D

func _ready() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	text_changed.connect(onType)
	focus_entered.connect(onFocus)
	focus_exited.connect(onFocusExit)
	if !block.preview: block.editor.changedFocus.connect(changedFocus)

func mouseEntered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_IBEAM)

func mouseExited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int):
	if event.is_action_pressed(&"leftMouse"):
		block.editor.uiFocused = self
		grab_focus()
		select_all()
		caret_column = text.length()

func onType(_newText: String) -> void:
	block.fixMinimumSize()
	block.size.x = 0.0

func setDetectionRect() -> void:
	detectionShape.shape.size = size
	detectionShape.position = size / Vector2(2.0, 2.0)

func onFocus() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	block.getHighestInStack().setToFront()
func onFocusExit() -> void:
	# For some reason, focus exit gets emitted when clicking on a LineEdit you're editing
	# So defer the call, and in the submit function check if it has focus
	onSubmit.call_deferred(text)
func changedFocus(newFocus: Control) -> void:
	# Disable detectionShape if this was the input focused because it doesn't resize while typing
	detectionShape.get_parent().visible = newFocus != self

func onSubmit(_newText: String) -> void:
	if has_focus(): return
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	setDetectionRect()
	release_focus()
	block.getHighestInStack().updateSpriteScript()
	if block.editor.uiFocused == self: block.editor.uiFocused = null
