class_name CodeBlock
extends MarginContainer

@export_group("for instance scene")
@export var content: HBoxContainer
@export var topDetection: Area2D
@export var bottomDetection: Area2D
@export var valueDrop: Area2D
@export var shapeNode: BlockShape
@export var grabArea: Area2D

## If true, the block acts as a preview in the block selector palette
var preview := false
var editor: Editor
## Which sprite's script this block is a part of
var sprite: Sprite
## The ID of the block in a spriteScript
var blockID: int
var blockName: StringName
var mouseTouching := false
var focused := false
## The offset from the mouse when started dragging
var initialOffset: Vector2 = Vector2.ZERO
## Original mouse position when started dragging
var initialMousePos: Vector2 = Vector2.ZERO
var dragDistance: float = 0.0
## Prevents dragging if the inital mouse click was outside the block
var dragDisabled := false
## Structure of the block
var blockStructure: Dictionary = {}
## Which side of another block it can be connected to while dragging | -1 = bottom, 0 = none, 1 = top
var detectedSnapPos: int = 0
## Which block it can be connected to while dragging
var detectedBlock: CodeBlock = null
var detectedInput: BlockInputEdit
## Block connected beneath this one
var childBlock: CodeBlock = null
var childValueBlocks: Array[CodeBlock]
## Block connected above this one
var parentBlock: CodeBlock = null
var parentInput: BlockInputEdit
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
	
	# Special properties for value blocks
	if blockStructure[&"shape"] == BlockShape.blockShapes.VALUE:
		custom_minimum_size.y = 75.0
		set_deferred(&"size:y", 0.0)
		call_deferred(&"onResize")
		valueDrop.monitoring = true
	
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
					content.add_child(input)
					if preview:
						input.mouse_filter = Control.MOUSE_FILTER_IGNORE
					else:
						# Create collision for the input so the mouse/value blocks can detect it
						var detection: Area2D = Area2D.new()
						detection.monitoring = false
						detection.set_collision_layer_value(1, false)
						detection.set_collision_layer_value(3, true)
						detection.add_to_group(&"blockValueDrop")
						detection.mouse_entered.connect(input.mouseEntered)
						detection.mouse_exited.connect(input.mouseExited)
						detection.input_event.connect(input.inputEvent)
						input.add_child(detection)
						var detectionShape: CollisionShape2D = CollisionShape2D.new()
						detectionShape.shape = RectangleShape2D.new()
						detection.add_child(detectionShape)
						input.detectionShape = detectionShape
						input.call_deferred(&"setDetectionRect")
				&"options":
					var options: BlockOptions = BlockOptions.new()
					var optionsList: Array = blockStructure[i][3].duplicate()
					match blockStructure[i][1]:
						2: optionsList.append_array(editor.signals)
						3: optionsList.append_array(BlockStructures.keyOptions)
					for j: String in optionsList:
						options.add_item(j)
					options.block = self
					options.mouse_filter = Control.MOUSE_FILTER_IGNORE
					# It switches back to 0 if not deferred
					options.call_deferred(&"select", blockStructure[i][2])
					content.add_child(options)
	
	shapeNode.blockColor = BlockStructures.categoryColors[blockStructure[&"color"]]
	shapeNode.blockShape = blockStructure[&"shape"]
	custom_minimum_size.x = shapeNode.minimumSizes[blockStructure[&"shape"]]
	# Set snapping detectors enabled/disabled for block shape
	var connectors: Array = shapeNode.connectors[blockStructure[&"shape"]]
	topDetection.monitoring = connectors[0]
	topDetection.monitorable = connectors[0]
	bottomDetection.monitoring = connectors[1]
	bottomDetection.monitorable = connectors[1]
	
	defaultColor = shapeNode.blockColor
	content.blockColor = defaultColor
	content.configureProperties()
	
	# Finally, add this block to the sprite's code
	if sprite: BuildSpriteScript.updateBlock(self, sprite)

# Drag behavior
func _process(_delta: float) -> void:
	if preview: return
	# Don't allow drag while focused, so the user can do things like select text
	if focused: return
	
	if Input.is_action_pressed(&"leftMouse"):
		if ((!mouseTouching) and (initialOffset == Vector2.ZERO)) or dragDisabled:
			dragDisabled = true
			return
		# Initial drag / click
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
			initialMousePos = get_global_mouse_position()
			getHighestInStack().setToFront()
		dragDistance = get_global_mouse_position().distance_to(initialMousePos)
		# Don't do anything until the mouse moves
		if dragDistance == 0.0:
			return
		# While dragging
		global_position = get_global_mouse_position() + initialOffset
		if childBlock: childBlock.moveWithParent(false)
		# Dragging will disconnect from parent
		if parentBlock:
			# Value blocks have a different method of disconnecting
			if parentInput:
				disconnectValueBlock()
			else:
				var previousParent: CodeBlock = parentBlock
				parentBlock.childBlock = null
				parentBlock = null
				setToFront()
				# After disconnecting, update the spriteScript for the two new stacks that were formed
				previousParent.getHighestInStack().updateSpriteScript()
				updateSpriteScript()
		# If the lowest block is trying to connect, then don't detect snapping
		if getLowestInStack() != self:
			if getLowestInStack().detectedBlock: return
		detectBlockSnap()
	else: # Left mouse isn't pressed
		if dragDistance > 0.0:
			if !mouseTouching: shapeNode.blockColor = defaultColor
			released(true)
			dragDistance = 0.0
		initialOffset = Vector2.ZERO
		initialMousePos = Vector2.ZERO
		dragDisabled = false

# topToBottom: If true, child blocks move when snapped
# If false, parent blocks move when snapped
func released(topToBottom: bool) -> void:
	if detectedBlock:
		# Value blocks have different behavior for inserting
		if valueDrop.monitoring:
			insertValueBlock()
			return
		# Snap to detected block and set a parent-child relationship
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
			# If that block already had a child, then re-order the stack to fit between
			if parentBlock.childBlock:
				var lowest: CodeBlock = getLowestInStack()
				var oldChild: CodeBlock = parentBlock.childBlock
				lowest.childBlock = oldChild
				oldChild.parentBlock = lowest
				oldChild.moveWithParent(false)
			parentBlock.childBlock = self
	# Layering
	getHighestInStack().setToFront()
	# Fix any offset from preview if dropping in middle of stack
	getHighestInStack().processOffset(null)
	detectedBlock = null
	detectedSnapPos = 0
	removePreview()
	if topToBottom: if childBlock: childBlock.moveWithParent(true)
	else: if parentBlock: parentBlock.moveWithChild()
	# Finally, update this stack in the sprite's code
	getHighestInStack().updateSpriteScript()

# Called as a value block
func insertValueBlock() -> void:
	detectedBlock = null
	if !detectedInput: return
	detectedInput.visible = false
	detectedInput.detectionShape.disabled = true
	# Reparent to the block's content container
	reparent(detectedInput.get_parent(), false)
	detectedInput.get_parent().move_child(self, detectedInput.get_index())
	# Set parent and child relationships
	parentInput = detectedInput
	parentBlock = detectedInput.block
	parentBlock.childValueBlocks.append(self)
	detectedInput = null
	# Layering and updating spriteScript
	getHighestInStack().setToFront()
	getHighestInStack().updateSpriteScript()

# Called as a value block
func disconnectValueBlock() -> void:
	# Reparent to the script area
	reparent(getContentOwner().get_parent())
	# Re-enable disconnecting input
	parentInput.visible = true
	parentInput.detectionShape.disabled = false
	# Fix parent minimum size
	# It could be a value block that got its minimum size affected by being in a content container
	fixMinimumSize()
	# Set parent-child relationships and layering
	parentBlock.childValueBlocks.erase(self)
	getContentOwner().getHighestInStack().setToFront()
	setToFront()
	parentBlock = null
	parentInput = null

# Starts at parent and goes up
func fixMinimumSize() -> void:
	if parentBlock:
		parentBlock.custom_minimum_size = Vector2(
			parentBlock.shapeNode.minimumSizes[blockStructure[&"shape"]], 0.0)
		parentBlock.size = Vector2(0.0, 0.0)
		parentBlock.fixMinimumSize()

# If the block above this one moves, re-position
# Release is for the purpose of the bottom block detecting if the stack should connect on release
func moveWithParent(release: bool) -> void:
	global_position = parentBlock.global_position
	global_position.y += parentBlock.size.y + 2.0
	if childBlock:
		childBlock.moveWithParent(release)
	else:
		# If no child block, this block is in charge of detecting if the bottom of the stack can attach
		if getHighestInStack() != self:
			if getHighestInStack().detectedBlock: return
		if release:
			if detectedSnapPos == 1:
				released(false)
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
# Get the highest-level block that isn't a value block
func getContentOwner() -> CodeBlock:
	if grabArea.monitoring and parentBlock:
		return parentBlock.getHighestInStack()
	else:
		return self

# Blocks are layered by child order, not with z_index
# If isValue is true, then this is being called on a value block
func setToFront() -> void:
	move_to_front()
	if childBlock: childBlock.setToFront()
func updateSpriteScript() -> void:
	BuildSpriteScript.updateBlock(self, sprite)
	if childBlock: childBlock.updateSpriteScript()

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
		# On top of stack
		snapPreview.global_position.y -= snapPreview.size.y + 2.0
	else:
		# Below other block, or in middle of stack
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
				detectedSnapPos = 1
				showPreview()
				return
	# Don't snap to the bottom of a block if there is a block attached above this one
	if topDetection.monitoring and !parentBlock:
		for i: Area2D in topDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapBottom"):
				detectedBlock = i.get_parent()
				detectedSnapPos = -1
				showPreview()
				return
	# For value blocks
	if valueDrop.monitoring:
		for i: Area2D in valueDrop.get_overlapping_areas():
			if i.is_in_group(&"blockValueDrop") and !is_ancestor_of(i):
				if detectedInput: detectedInput.highlight.visible = false
				detectedInput = i.get_parent()
				detectedBlock = detectedInput.block
				detectedInput.detectedBlock = self
				detectedInput.highlight.visible = true
				return
	# No possible snaps detected
	# Fix any affected stacks if dragging away from preview in middle of stack
	if detectedBlock:
		detectedBlock.getHighestInStack().processOffset(null)
		detectedBlock = null
	if detectedInput:
		detectedInput.detectedBlock = null
		detectedInput.highlight.visible = false
		detectedInput = null
	detectedSnapPos = 0
	removePreview()

func mouseEntered() -> void:
	if !preview:
		# Don't allow interaction while focused on another block
		if get_viewport().gui_get_focus_owner():
			if get_viewport().gui_get_focus_owner().get_parent() != content: return
	# Don't allow interaction if initial click was outside block
	if dragDisabled: return
	mouseTouching = true
	# Don't allow interaction if dragging (but still allow mouseTouching to change)
	if dragDistance > 0.0: return
	if !focused:
		shapeNode.blockColor = shapeNode.blockColor.lightened(0.2)

func mouseExited() -> void:
	mouseTouching = false
	# Don't allow exit if dragging (but still allow mouseTouching to change)
	if dragDistance > 0.0: return
	if !focused:
		shapeNode.blockColor = defaultColor

# When finished editing one of the inputs
func focusExit() -> void:
	focused = false
	getHighestInStack().updateSpriteScript()
	if !mouseTouching: shapeNode.blockColor = defaultColor

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int) -> void:
	if event.is_action_pressed(&"leftMouse"):
		if !mouseTouching: mouseEntered()
		clicked.emit()

func hoveringChildValue() -> bool:
	for i: CodeBlock in childValueBlocks:
		if i.get_global_rect().has_point(get_global_mouse_position()):
			return true
	return false

func onResize() -> void:
	bottomDetection.position.y = size.y
	valueDrop.position.y = size.y / 2.0
