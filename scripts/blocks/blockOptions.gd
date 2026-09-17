class_name BlockOptions
extends OptionButton

var block: CodeBlock
var detectionShape: CollisionShape2D

func _ready() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	focus_entered.connect(popupHide)

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int):
	if event.is_action_pressed(&"leftMouse"):
		block.editor.uiFocused = self
		block.getHighestInStack().setToFront()
		show_popup()
		get_popup().popup_hide.connect(func() -> void:
			popupHide.call_deferred()
		)

func setDetectionRect() -> void:
	detectionShape.shape.size = size
	detectionShape.position = size / Vector2(2.0, 2.0)

func popupHide() -> void:
	block.fixMinimumSize()
	block.size.x = 0.0
	block.getHighestInStack().updateSpriteScript()
	if block.editor.uiFocused == self: block.editor.uiFocused = null
	await get_tree().process_frame
	setDetectionRect()
