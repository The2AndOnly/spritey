class_name CodeBlock
extends MarginContainer

@export_group("for instance scene")
@export var content: HBoxContainer
@export var topDetection: Area2D
@export var bottomDetection: Area2D
@export var shapeNode: BlockShape
@export var grabArea: Area2D

## If true, the block acts as a preview in the block selector palette
var preview := false
var editor: Editor
var blockName: StringName
var mouseTouching := false
var focused := false
## The offset from the mouse when started dragging
var initialOffset: Vector2 = Vector2.ZERO
## Prevents dragging if the inital mouse click was outside the block
var dragDisabled := false
## Structure of the block
var blockStructure: Dictionary = {}
## Which side of another block it can be connected to while dragging | -1 = bottom, 0 = none, 1 = top
var detectedSnapPos: int = 0
## Which block it can be connected to while dragging
var detectedBlock: CodeBlock = null
## Block connected beneath this one
var childBlock: CodeBlock = null
## Block connected above this one
var parentBlock: CodeBlock = null
var snapPreview: MarginContainer = null
## For setting the color back when done hovering
var defaultColor: Color

signal clicked()

func _ready() -> void:
	grabArea.mouse_entered.connect(mouseEntered)
	grabArea.mouse_exited.connect(mouseExited)
	grabArea.input_event.connect(inputEvent)
	resized.connect(onResize)
	
	if BlockStructures.structures.has(blockName):
		blockStructure = BlockStructures.structures[blockName]
	
	# Read the structure to build the block's labels and inputs
	if blockStructure.size() == 0: return
	for i: Variant in blockStructure[&"structure"]:
		# Labels
		if i is String:
			var label: Label = Label.new()
			label.text = i
			content.add_child(label)
		# Data inputs
		if i is int:
			match blockStructure[i][0]:
				&"input":
					var input: BlockInputEdit = BlockInputEdit.new()
					input.type = blockStructure[i][1]
					input.text = blockStructure[i][2]
					input.block = self
					input.mouse_filter = Control.MOUSE_FILTER_PASS
					content.add_child(input)
				&"options":
					var options: BlockOptions = BlockOptions.new()
					var optionsList: Array = blockStructure[i][3].duplicate()
					match blockStructure[i][1]:
						2: optionsList.append_array(editor.signals)
						3: optionsList.append_array(BlockStructures.keyOptions)
					for j: String in optionsList:
						options.add_item(j)
					options.selected = blockStructure[i][2]
					options.block = self
					options.mouse_filter = Control.MOUSE_FILTER_PASS
					content.add_child(options)
	
	shapeNode.blockColor = BlockStructures.categoryColors[blockStructure[&"color"]]
	defaultColor = shapeNode.blockColor
	shapeNode.blockShape = blockStructure[&"shape"]
	custom_minimum_size.x = shapeNode.minimumSizes[blockStructure[&"shape"]]
	# Set snapping detectors enabled/disabled for block shape
	var connectors: Array = shapeNode.connectors[blockStructure[&"shape"]]
	topDetection.monitoring = connectors[0]
	topDetection.monitorable = connectors[0]
	bottomDetection.monitoring = connectors[1]
	bottomDetection.monitorable = connectors[1]
	
	content.configureProperties()

# Drag behavior
func _process(_delta: float) -> void:
	if preview: return
	# Don't allow drag while focused, so the user can do things like select text
	if focused: return
	if Input.is_action_pressed(&"leftMouse"):
		if ((!mouseTouching) and (initialOffset == Vector2.ZERO)) or dragDisabled:
			dragDisabled = true
			return
		# Initial drag
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
			setToFront()
		# Don't do anything until the mouse moves
		if (global_position - get_global_mouse_position()) == initialOffset:
			return
		# While dragging
		global_position = get_global_mouse_position() + initialOffset
		if childBlock: childBlock.moveWithParent(false)
		# Dragging will disconnect from parent
		if parentBlock:
			parentBlock.childBlock = null
			parentBlock = null
			setToFront()
		detectBlockSnap()
	else:
		if initialOffset != Vector2.ZERO:
			blockReleased(true)
		initialOffset = Vector2.ZERO
		dragDisabled = false

func blockReleased(topToBottom: bool) -> void:
	# Snap to detected block and set parent-child relationship
	if detectedBlock:
		global_position = detectedBlock.global_position
		if detectedSnapPos == 1:
			# Snapped as parent, on top of other block
			global_position.y -= size.y + 2.0
			childBlock = detectedBlock
			detectedBlock.parentBlock = self
		else:
			# Snapped as child, below other block
			global_position.y += detectedBlock.size.y + 2.0
			parentBlock = detectedBlock
			setStackToFront()
			# If that block already had a child, then re-order the stack to fit between
			if parentBlock.childBlock:
				var lowest: CodeBlock = getLowestInStack()
				var oldChild: CodeBlock = parentBlock.childBlock
				lowest.childBlock = oldChild
				oldChild.parentBlock = lowest
				oldChild.moveWithParent(false)
			parentBlock.childBlock = self
	# Fix any offset from previewif dropping in middle of stack
	if detectedBlock:
		detectedBlock.getHighestInStack().processOffset(null)
	detectedBlock = null
	detectedSnapPos = 0
	removePreview()
	# Child blocks follow with snap
	if topToBottom:
		if childBlock: childBlock.moveWithParent(true)
	# Parent blocks follow with snap
	else:
		if parentBlock: parentBlock.moveWithChild()

# If the block above this one moves, re-position
# Release is for the purpose of the bottom block detecting if the stack should connect on release
func moveWithParent(release: bool) -> void:
	global_position = parentBlock.global_position
	global_position.y += parentBlock.size.y + 2.0
	if childBlock:
		childBlock.moveWithParent(release)
	else:
		# If no child block, this block is in charge of detecting if the bottom of the stack can attach
		if release:
			if detectedSnapPos == 1:
				blockReleased(false)
		else:
			detectBlockSnap()
# If the block below this one moves, re-position
func moveWithChild() -> void:
	global_position = childBlock.global_position
	global_position.y -= size.y + 2.0
	if parentBlock: parentBlock.moveWithChild()

# Get the top block with no parent in the stack
func getHighestInStack() -> CodeBlock:
	if parentBlock:
		return parentBlock.getHighestInStack()
	else:
		return self
# Get the bottom block with no child in the stack
func getLowestInStack() -> CodeBlock:
	if childBlock:
		return childBlock.getLowestInStack()
	else:
		return self

# Blocks are layered by child order, not with z_index
func setToFront() -> void:
	move_to_front()
	if childBlock: childBlock.setToFront()
func setStackToFront() -> void:
	if parentBlock:
		parentBlock.setStackToFront()
	else:
		setToFront()

# Snap preview
func showPreview() -> void:
	if !detectedBlock: return
	if snapPreview == null:
		snapPreview = MarginContainer.new()
		snapPreview.custom_minimum_size = Vector2(size.x, size.y)
		snapPreview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var previewShape: BlockShape = BlockShape.new()
		previewShape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		previewShape.blockColor = Color("ffffff28")
		previewShape.blockShape = shapeNode.blockShape
		snapPreview.add_child(previewShape)
		# Add sibling for layering purposes
		detectedBlock.add_sibling(snapPreview)
	# Position preview
	snapPreview.global_position = detectedBlock.global_position
	if detectedSnapPos == 1:
		# On top of other block
		snapPreview.global_position.y -= snapPreview.size.y + 2.0
	else:
		# Below other block
		snapPreview.global_position.y += detectedBlock.size.y + 2.0
		# Shift blocks if placing in middle of another stack
		if detectedBlock.childBlock:
			detectedBlock.childBlock.offset_transform_position.y = snapPreview.size.y + 2.0
			detectedBlock.getHighestInStack().processOffset(detectedBlock.childBlock)
func removePreview() -> void:
	if snapPreview:
		snapPreview.queue_free()
# Expected to be called from top-level block with one block offset
func processOffset(affected: CodeBlock) -> void:
	if parentBlock:
		if self != affected: offset_transform_position = parentBlock.offset_transform_position
	if childBlock: childBlock.processOffset(affected)

func detectBlockSnap() -> void:
	# Don't snap to the top of a block if there is a block attached below this one
	if bottomDetection.monitoring and !childBlock:
		for i: Area2D in bottomDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapTop"):
				detectedBlock = i.get_parent()
				# Don't snap to the top of a block if it already has a parent
				if detectedBlock.parentBlock: break
				# Succeeded all checks
				detectedSnapPos = 1
				showPreview()
				return
	# Don't snap to the bottom of a block if there is a block attached above this one
	if topDetection.monitoring and !parentBlock:
		for i: Area2D in topDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapBottom"):
				detectedBlock = i.get_parent()
				# Succeeded all checks
				detectedSnapPos = -1
				showPreview()
				return
	# No possible snaps detected
	# Fix any affected stacks if dragging away from preview in middle of stack
	if detectedBlock:
		detectedBlock.getHighestInStack().processOffset(null)
	detectedBlock = null
	detectedSnapPos = 0
	removePreview()

func mouseEntered() -> void:
	# Don't allow interaction while focused on another block
	if (!preview) and get_viewport().gui_get_focus_owner():
		if get_viewport().gui_get_focus_owner().get_parent() != content: return
	mouseTouching = true
	if !focused:
		shapeNode.blockColor = shapeNode.blockColor.lightened(0.2)
	# Enable content interaction
	if !preview: content.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
func mouseExited() -> void:
	mouseTouching = false
	if !focused:
		shapeNode.blockColor = defaultColor
		# Disable content interaction
		content.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
func focusExit() -> void:
	focused = false
	if !mouseTouching: shapeNode.blockColor = defaultColor
func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int) -> void:
	if event.is_action_pressed(&"leftMouse"):
		if !mouseTouching: mouseEntered()
		clicked.emit()
func onResize() -> void:
	bottomDetection.position.y = size.y
