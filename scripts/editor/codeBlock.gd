class_name CodeBlock
extends MarginContainer

@export_group("for instance scene")
@export var content: HBoxContainer
@export var topDetection: Area2D
@export var bottomDetection: Area2D
@export var shapeNode: BlockShape
@export var bonusInputEvent: Control

## If true, the block acts as a preview in the block selector palette
var preview := false
var scriptView: SubViewport
var blockName: StringName
var mouseTouching := false
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

func _ready() -> void:
	if preview:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_entered.connect(mouseEntered)
		mouse_exited.connect(mouseExited)
		resized.connect(onResize)
	
	if BlockStructures.structures.has(blockName):
		blockStructure = BlockStructures.structures[blockName]
	
	# Build the block's labels and inputs
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
					if preview: input.mouse_filter = Control.MOUSE_FILTER_IGNORE
					content.add_child(input)
				&"options":
					var options: BlockOptions = BlockOptions.new()
					for j: int in range(3, blockStructure[i].size()):
						options.add_item(blockStructure[i][j])
					options.selected = blockStructure[i][2]
					options.block = self
					if preview: options.mouse_filter = Control.MOUSE_FILTER_IGNORE
					content.add_child(options)
	
	shapeNode.blockColor = BlockStructures.categoryColors[blockStructure[&"color"]]
	shapeNode.blockShape = blockStructure[&"shape"]
	custom_minimum_size.x = shapeNode.minimumSizes[blockStructure[&"shape"]]
	# Set snapping detectors enabled/disabled for block shape
	topDetection.monitoring = shapeNode.connectors[blockStructure[&"shape"]][0]
	topDetection.monitorable = shapeNode.connectors[blockStructure[&"shape"]][0]
	bottomDetection.monitoring = shapeNode.connectors[blockStructure[&"shape"]][1]
	bottomDetection.monitorable = shapeNode.connectors[blockStructure[&"shape"]][1]
	
	# Set bonus inputs for block shape
	bonusInputEvent.visible = blockStructure[&"shape"] == BlockShape.blockShapes.EVENT
	bonusInputEvent.mouse_default_cursor_shape = mouse_default_cursor_shape
	
	content.configureProperties()

func _process(_delta: float) -> void:
	if preview: return
	if Input.is_action_pressed(&"leftMouse"):
		if ((!mouseTouching) and (initialOffset == Vector2.ZERO)) or dragDisabled:
			dragDisabled = true
			return
		# Initial drag
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
			setToFront()
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
			global_position.y -= size.y
			childBlock = detectedBlock
			detectedBlock.parentBlock = self
		else:
			# Snapped as child, below other block
			global_position.y += detectedBlock.size.y
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
	global_position.y += parentBlock.size.y
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
	global_position.y -= size.y
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
	scriptView.move_child(self, -1)
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
		snapPreview.add_child(previewShape)
		# Add sibling for layering purposes
		detectedBlock.add_sibling(snapPreview)
	# Position preview
	snapPreview.global_position = detectedBlock.global_position
	if detectedSnapPos == 1:
		# On top of other block
		snapPreview.global_position.y -= snapPreview.size.y
	else:
		# Below other block
		snapPreview.global_position.y += detectedBlock.size.y
		# Shift blocks if placing in middle of another stack
		if detectedBlock.childBlock:
			detectedBlock.childBlock.offset_transform_position.y = snapPreview.size.y
			detectedBlock.getHighestInStack().processOffset(detectedBlock.childBlock)
func removePreview() -> void:
	if snapPreview:
		snapPreview.queue_free()
# Expected to be called from top-level block with one block offset
func processOffset(affected: CodeBlock) -> void:
	if parentBlock:
		if self != affected: offset_transform_position = parentBlock.offset_transform_position
	if childBlock: childBlock.processOffset(affected)

func mouseEntered() -> void:
	mouseTouching = true

func mouseExited() -> void:
	mouseTouching = false

func onResize() -> void:
	bottomDetection.position.y = size.y

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
