class_name BlockOptions
extends OptionButton

var block: CodeBlock
var detectionShape: CollisionShape2D
var id: int
# Custom item to select since the options may get cleared and updated
var itemSelected: int = 0
# IDs are for addon options that reference things eg. sprites
# Created alongside the option button's items, if -1 then no ID
var itemIDs: Array[int] = []
var selectedID: int = -1

func _ready() -> void:
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	get_popup().popup_hide.connect(popupHide)
	item_selected.connect(onItemSelect)

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int):
	if event.is_action_pressed(&"leftMouse"):
		block.editor.uiFocused = self
		block.getHighestInStack().setToFront()
		show_popup()

func setDetectionRect() -> void:
	detectionShape.shape.size = size
	detectionShape.position = size / Vector2(2.0, 2.0)

func onItemSelect(new: int) -> void:
	itemSelected = new
	selectedID = itemIDs[itemSelected]
	block.fixMinimumSize()
	block.size.x = 0.0
	block.getHighestInStack().updateSpriteScript()
	await get_tree().process_frame
	setDetectionRect()

func popupHide() -> void:
	if block.editor.uiFocused == self: block.editor.uiFocused = null
