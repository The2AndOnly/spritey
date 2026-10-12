class_name CodeBlock
extends MarginContainer

@export_group("for instance scene")
@export var content: HBoxContainer
@export var contentMargin: MarginContainer
@export var topDetection: Area2D
@export var bottomDetection: Area2D
@export var valueDrop: Area2D
@export var nestDetection: Area2D
@export var shapeNode: BlockShape
@export var grabArea: Area2D
const DefaultNestEnd: float = 100.0
const NestEndHeight: float = 57.0
const NestSideWidth: float = 32.0

## If true, the block acts as a preview in the block selector palette
var preview := false
var editor: Editor
var gameView: GameView
## Which sprite's script this block is a part of
var sprite: Sprite
## The ID of the block in a spriteScript
var blockID: int
var blockName: StringName
var mouseTouching := false
## The offset from the mouse when started dragging
var initialOffset: Vector2 = Vector2.ZERO
## Original mouse position when started dragging
var initialMousePos: Vector2 = Vector2.ZERO
var dragDistance: float = 0.0
## Prevents dragging if the inital mouse click was outside the block
var dragDisabled := false
var blockStructure: Dictionary = {}
## Ignore the pre-defined structure from blockStructures.gd
var customStructure := false
## Which side of another block it can be connected to while dragging
# -1 = bottom | 0 = none | 1 = top | -2 = first in nest | 2 = nesting full stack
# -3 = first in nest2
var detectedSnapPos: int = 0
## Which block it can be connected to while dragging
var detectedBlock: CodeBlock = null
var detectedInput: Control
var nestEnd: float = 0.0
## Nest end goes back to this if dragging out of a preview
var fallbackNestEnd: float = 0.0
## Block connected beneath this one
var childBlock: CodeBlock = null
var childValueBlocks: Array[CodeBlock]
## The first inside of the nest, only set for nest blocks
var childNest: CodeBlock = null
## Block connected above this one, null if first in nest
var parentBlock: CodeBlock = null
var parentInput: Control
## Set for every block inside a nest
var parentNest: CodeBlock = null
var snapPreview: BlockPreview = null
## For setting the color back when done hovering
var defaultColor: Color
var height: float = 0.0
## Used for forcing the block to be dragged further until detecting something else
var detectPosition: Vector2 = Vector2.ZERO
## Just so you don't have to check the block shape
var boolBlock := false
## Index is input ID
var inputIds: Array[Control] = []

# All variables for the nest again for the nest2
@export var nest2Detection: Area2D
@export var nestEndContent: Node2D
const DefaultNest2End: float = 100.0
var nest2End: float = 0.0
var fallbackNest2End: float = 0.0
var childNest2: CodeBlock = null
var parentNest2: CodeBlock = null

# For loading
var loading := false
var parentInputLoadID: int = -1
var childValueBlocksToLoad: Array[CodeBlock] = []
var loadPosition: Vector2 = Vector2.ZERO
var valuesToLoad: Array[Variant] = []

signal clicked()
signal mouseReleased()

func _ready() -> void:
	grabArea.mouse_entered.connect(mouseEntered)
	grabArea.mouse_exited.connect(mouseExited)
	grabArea.input_event.connect(inputEvent)
	editor.changedFocus.connect(changedFocus)
	editor.updateBlockOptions.connect(updateBlockOptions)
	if !preview: editor.updateSpriteScript.connect(updateSpriteScript)
	resized.connect(onResize)
	
	if !customStructure:
		blockStructure = BlockStructures.structures[blockName]
	
	# Special properties for certain blocks
	var shape: BlockShape.blockShapes = blockStructure[&"shape"]
	match shape:
		BlockShape.blockShapes.VALUE:
			nestDetection.queue_free()
			nestDetection = null
			nest2Detection.queue_free()
			nest2Detection = null
			nestEndContent.queue_free()
			custom_minimum_size.y = 65.0
			set_deferred(&"size:y", 0.0)
		BlockShape.blockShapes.BOOLEAN:
			nestDetection.queue_free()
			nestDetection = null
			nest2Detection.queue_free()
			nest2Detection = null
			nestEndContent.queue_free()
			valueDrop.set_collision_mask_value(4, true)
			custom_minimum_size.y = 65.0
			boolBlock = true
			set_deferred(&"size:y", 0.0)
		BlockShape.blockShapes.NEST:
			nest2Detection.queue_free()
			nest2Detection = null
			valueDrop.queue_free()
			valueDrop = null
			nestEndContent.queue_free()
			fallbackNestEnd = shapeNode.nestEnd
			setNestEnd.call_deferred(fallbackNestEnd, false)
		BlockShape.blockShapes.DOUBLE_NEST:
			valueDrop.queue_free()
			valueDrop = null
			fallbackNestEnd = shapeNode.nestEnd
			setNestEnd.call_deferred(fallbackNestEnd, false)
			fallbackNest2End = shapeNode.nestEnd2
			setNest2End.call_deferred(fallbackNest2End, false)
		_:
			shapeNode.drawBottomNotch = shape != BlockShape.blockShapes.STOP
			valueDrop.queue_free()
			valueDrop = null
			nestDetection.queue_free()
			nestDetection = null
			nest2Detection.queue_free()
			nest2Detection = null
			nestEndContent.queue_free()
			# Fix nest end indent on load
			if loading and !shapeNode.drawBottomNotch:
				if parentNest:
					parentNest.shapeNode.drawNestEndIndent = false
				elif parentNest2:
					parentNest2.shapeNode.drawSecondNestEndIndent = false
	
	# Read the structure to build the block's labels and inputs
	for i: Variant in blockStructure[&"structure"]:
		# Labels
		if i is String:
			var label: Label = Label.new()
			label.text = i
			content.add_child(label)
		# Data inputs
		if i is int:
			var inputType: StringName = blockStructure[i][0]
			match inputType:
				&"input":
					var input: BlockInputEdit = BlockInputEdit.new()
					input.type = blockStructure[i][1]
					if !valuesToLoad.is_empty():
						input.text = valuesToLoad[i]
					else:
						input.text = blockStructure[i][2]
					input.block = self
					inputIds.append(input)
					content.add_child(input)
					if preview:
						input.mouse_filter = Control.MOUSE_FILTER_IGNORE
					else:
						addInputArea(input)
				&"options", &"soptions":
					var options: BlockOptions = BlockOptions.new()
					options.id = i
					if !valuesToLoad.is_empty():
						options.itemSelected = valuesToLoad[i]
					else:
						options.itemSelected = blockStructure[i][2]
					setOptionsList(options)
					options.block = self
					options.acceptBlocks = inputType == &"soptions"
					options.mouse_filter = Control.MOUSE_FILTER_IGNORE
					inputIds.append(options)
					content.add_child(options)
					if preview:
						options.mouse_filter = Control.MOUSE_FILTER_IGNORE
					else:
						addInputArea(options, options.acceptBlocks)
				&"bool":
					var boolean: BlockBoolPanel = BlockBoolPanel.new()
					boolean.mouse_filter = Control.MOUSE_FILTER_IGNORE
					boolean.block = self
					inputIds.append(boolean)
					content.add_child(boolean)
					if !preview: addInputArea(boolean)
				&"special":
					var special: BlockSpecialValue = BlockSpecialValue.new()
					special.value = blockStructure[i][1]
					content.add_child(special)
	shapeNode.blockColor = BlockStructures.categoryColors[blockStructure[&"color"]]
	shapeNode.blockShape = shape
	custom_minimum_size.x = shapeNode.minimumSizes[shape]
	# Set snapping detectors enabled/disabled for block shape
	var connectors: Array = shapeNode.connectors[shape]
	if !connectors[0]:
		topDetection.queue_free()
	if !connectors[1]:
		bottomDetection.queue_free()
	# Configure block styling
	defaultColor = shapeNode.blockColor
	content.blockColor = defaultColor
	content.configureProperties()
	onResize.call_deferred()
	# Finish up connections after the editor loads this block
	if loading:
		if nestDetection: loadNestEnd.call_deferred()
		for i: CodeBlock in childValueBlocksToLoad:
			i.detectedInput = inputIds[i.parentInputLoadID]
			i.insertValueBlock.call_deferred(false)
		global_position = loadPosition
		loading = false
	else:
		# If not loading, it was created from the palette
		if sprite: BuildSpriteScript.updateBlock(self, sprite)

# Create collision for the input so the mouse/value blocks can detect it
func addInputArea(blockInput: Control, optionsAcceptBlocks: bool = false) -> void:
	var detection: Area2D = Area2D.new()
	detection.monitoring = false
	detection.set_collision_layer_value(1, false)
	if blockInput is BlockBoolPanel:
		detection.set_collision_layer_value(4, true)
		detection.add_to_group(&"blockValueDrop")
		detection.input_pickable = false
	else:
		detection.input_event.connect(blockInput.inputEvent)
		detection.set_collision_layer_value(3, true)
		if blockInput is BlockInputEdit:
			detection.add_to_group(&"blockValueDrop")
			detection.mouse_entered.connect(blockInput.mouseEntered)
			detection.mouse_exited.connect(blockInput.mouseExited)
		elif optionsAcceptBlocks:
			detection.add_to_group(&"blockValueDrop")
	blockInput.add_child(detection)
	var detectionShape: CollisionShape2D = CollisionShape2D.new()
	detectionShape.shape = RectangleShape2D.new()
	detection.add_child(detectionShape)
	blockInput.detectionShape = detectionShape
	blockInput.setDetectionRect.call_deferred()

# Add the addons to the dropdown menus
func setOptionsList(options: BlockOptions) -> void:
	var optionsList: Array = blockStructure[options.id][3].duplicate()
	options.clear()
	options.items.clear()
	for i in range(optionsList.size()): options.items.append(i)
	match blockStructure[options.id][1]:
		1: # Sprites
			var sortedSprites: Array[Sprite] = []
			# Get non-clones
			for i: Sprite in gameView.sprites:
				if !i.original: sortedSprites.append(i)
			sortedSprites.sort_custom(func(a: Sprite, b: Sprite) -> bool:
				return a.spriteName.naturalnocasecmp_to(b.spriteName) < 0)
			sortedSprites.erase(editor.selectedSprite)
			var spriteNames: Array[StringName] = []
			for i: Sprite in sortedSprites:
				spriteNames.append(i.spriteName)
			optionsList.append_array(spriteNames)
			options.items.append_array(sortedSprites)
		2: # Signals
			var sortedSignals: Array[String] = gameView.signals.duplicate()
			sortedSignals.sort_custom(func(a: String, b: String) -> bool:
				return a.naturalnocasecmp_to(b) < 0)
			for i: String in sortedSignals:
				optionsList.append(i)
				options.items.append(i)
		3: # Keyboard keys
			optionsList.append_array(BlockStructures.keyOptions)
			for i in range(options.items.size(), optionsList.size()): options.items.append(i)
		4: # Variables
			var sortedVars: Array[Variable] = gameView.variables.duplicate()
			# TODO: remove check since there should always be selected sprite in the future
			if editor.selectedSprite: sortedVars.append_array(editor.selectedSprite.variables)
			sortedVars.sort_custom(func(a: Variable, b: Variable) -> bool:
				return a.name.naturalnocasecmp_to(b.name) < 0)
			var varNames: Array[StringName] = []
			for i: Variable in sortedVars:
				varNames.append(i.name)
			optionsList.append_array(varNames)
			options.items.append_array(sortedVars)
		5: # Frames
			# TODO: remove check since there should always be selected sprite in the future
			if !editor.selectedSprite: return
			optionsList.append_array(editor.selectedSprite.frameNames)
			for i: int in range(optionsList.size()): options.items.append(i)
	for j: String in optionsList:
		options.add_item(j)
	if options.items.size() > 0:
		if preview:
			options.select.call_deferred(options.itemSelected)
		else:
			# The item selected should be synced with the internal items array
			var sharedIndex: int = max(0, options.items.find(options.itemSelected))
			options.itemSelected = options.items[sharedIndex]
			options.select.call_deferred(sharedIndex)
	fixMinimumSize.call_deferred()
	if options.detectionShape:
		await get_tree().process_frame
		options.setDetectionRect()

func updateBlockOptions() -> void:
	for i: Node in content.get_children():
		if i is BlockOptions:
			setOptionsList(i)

# Drag behavior
func _process(_delta: float) -> void:
	if preview: return
	if editor.uiFocused:
		dragDisabled = false
		return
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
		if childBlock: childBlock.dragWithParent(false)
		if childNest: childNest.dragWithParent(false)
		if childNest2: childNest2.dragWithParent(false)
		# Dragging will disconnect from parent
		disconnectFromParent()
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

func disconnectFromParent() -> void:
	if parentBlock:
		# Value blocks have a different method of disconnecting
		if parentInput:
			disconnectValueBlock()
		else:
			parentBlock.childBlock = null
			parentBlock = null
			# If this was part of a stack in a nest, then fix the nestEnd
			if parentNest:
				parentNest.setNestEnd(calculateStackHeight(parentNest.childNest), true)
				parentNest.shapeNode.drawNestEndIndent = true
				parentNest = null
				setChildrenParentNests()
			if parentNest2:
				parentNest2.setNest2End(calculateStackHeight(parentNest2.childNest2), true)
				parentNest2.shapeNode.drawSecondNestEndIndent = true
				parentNest2 = null
				setChildrenParentNests()
			setToFront()
	# If removed the first block in a nest
	elif parentNest:
		parentNest.setNestEnd(DefaultNestEnd, true)
		parentNest.shapeNode.drawNestEndIndent = true
		parentNest.childNest = null
		parentNest = null
		setChildrenParentNests()
	elif parentNest2:
		parentNest2.setNest2End(DefaultNest2End, true)
		parentNest2.shapeNode.drawSecondNestEndIndent = true
		parentNest2.childNest2 = null
		parentNest2 = null
		setChildrenParentNests()

# topToBottom: If true, child blocks move when snapped
# If false, parent blocks move when snapped
func released(topToBottom: bool) -> void:
	z_index = 0
	if detectedBlock:
		# Value blocks have different behavior for inserting
		if valueDrop:
			insertValueBlock()
			return
		# Snap to detected block and set a parent-child relationship
		global_position = detectedBlock.global_position
		if detectedSnapPos == 1:
			# Snapped as parent, on top of other block
			global_position.y -= height
			childBlock = detectedBlock
			detectedBlock.parentBlock = self
		elif detectedSnapPos == -2:
			# Snapped as first inside nest
			parentNest = detectedBlock
			setChildrenParentNests()
			# If there were already blocks in the nest, then set that as child of this stack
			if parentNest.childNest:
				# For empty nest blocks, this means nesting everything
				if nestDetection and !childNest:
					childNest = parentNest.childNest
					childNest.parentNest = self
					childNest.setChildrenParentNests()
					setNestEnd(calculateStackHeight(childNest), true)
					if !childNest.getLowestInStack().bottomDetection:
						shapeNode.drawNestEndIndent = false
						parentNest.shapeNode.drawNestEndIndent = true
				else:
					var lowest: CodeBlock = getLowestInStack()
					lowest.childBlock = parentNest.childNest
					lowest.childBlock.parentBlock = lowest
			if !getLowestInStack().bottomDetection:
				parentNest.shapeNode.drawNestEndIndent = false
			parentNest.childNest = self
			parentNest.setNestEnd(calculateStackHeight(parentNest.childNest), true)
		elif detectedSnapPos == -3:
			# Snapped as first inside nest2
			parentNest2 = detectedBlock
			setChildrenParentNests()
			# If there were already blocks in the nest, then set that as child of this stack
			if parentNest2.childNest2:
				# For empty nest blocks, this means nesting everything
				if nestDetection and !childNest:
					childNest = parentNest2.childNest2
					childNest.parentNest2 = null
					childNest.parentNest = self
					childNest.setChildrenParentNests()
					setNestEnd(calculateStackHeight(childNest), true)
					if !childNest.getLowestInStack().bottomDetection:
						shapeNode.drawNestEndIndent = false
						parentNest2.shapeNode.drawNestEndIndent = true
				else:
					var lowest: CodeBlock = getLowestInStack()
					lowest.childBlock = parentNest2.childNest2
					lowest.childBlock.parentBlock = lowest
			if !getLowestInStack().bottomDetection:
				parentNest2.shapeNode.drawSecondNestEndIndent = false
			parentNest2.childNest2 = self
			parentNest2.setNest2End(calculateStackHeight(parentNest2.childNest2), true)
		# Nest block nesting entire stack
		elif detectedSnapPos == 2:
			global_position.y -= size.y + 2.0
			global_position.x -= NestSideWidth
			childNest = detectedBlock
			childNest.parentNest = self
			childNest.setChildrenParentNests()
			setNestEnd(calculateStackHeight(childNest), true)
			if !childNest.getLowestInStack().bottomDetection:
				shapeNode.drawNestEndIndent = false
		else:
			# Snapped as child, below other block
			global_position.y += detectedBlock.height
			parentBlock = detectedBlock
			parentNest = detectedBlock.parentNest
			parentNest2 = detectedBlock.parentNest2
			setChildrenParentNests()
			# If that block already had a child, then re-order the stack to fit between
			if parentBlock.childBlock:
				# For empty nest blocks, this means nesting everything below it
				if nestDetection and !childNest:
					childNest = parentBlock.childBlock
					childNest.parentBlock = null
					childNest.parentNest = self
					childNest.setChildrenParentNests()
					setNestEnd(calculateStackHeight(childNest), true)
					if !childNest.getLowestInStack().bottomDetection:
						shapeNode.drawNestEndIndent = false
						if parentNest: parentNest.shapeNode.drawNestEndIndent = true
				else:
					var lowest: CodeBlock = getLowestInStack()
					lowest.childBlock = parentBlock.childBlock
					lowest.childBlock.parentBlock = lowest
			parentBlock.childBlock = self
			# If snapped into a nest, fix the nestEnd
			if parentNest:
				parentNest.setNestEnd(calculateStackHeight(parentNest.childNest), true)
				if !getLowestInStack().bottomDetection:
					parentNest.shapeNode.drawNestEndIndent = false
			if parentNest2:
				parentNest2.setNest2End(calculateStackHeight(parentNest2.childNest2), true)
				if !getLowestInStack().bottomDetection:
					parentNest2.shapeNode.drawSecondNestEndIndent = false
	# Layering
	var highest: CodeBlock = getHighestInStack()
	highest.setToFront()
	# Fix any offset from preview if dropping in middle of stack
	highest.processOffset(null)
	#highest.makeSpace()
	detectedBlock = null
	detectedSnapPos = 0
	if snapPreview: snapPreview.queue_free()
	if topToBottom:
		if childBlock: childBlock.dragWithParent(true)
		if childNest: childNest.dragWithParent(true)
		if childNest2: childNest2.dragWithParent(true)
	else:
		if parentBlock: parentBlock.moveWithChild()

# Called as a value block
func insertValueBlock(setFront: bool = true) -> void:
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
	parentBlock.fixMinimumSize()
	if setFront: getHighestInStack().setToFront()

# Called as a value block
func disconnectValueBlock() -> void:
	# Reparent to the script area
	reparent(getContentOwner().get_parent())
	# Re-enable disconnecting input
	parentInput.visible = true
	parentInput.detectionShape.disabled = false
	# It could be a value block that got its minimum size affected by being in a content container
	parentBlock.fixMinimumSize()
	parentBlock.childValueBlocks.erase(self)
	# Change z_index due to flickering bug
	z_index = 1
	# Prevents multiple inputs being highlighted on disconnect
	detectedInput = parentInput
	parentBlock = null
	parentInput = null

func fixMinimumSize() -> void:
	custom_minimum_size = Vector2(
		shapeNode.minimumSizes[blockStructure[&"shape"]],
		65.0 if valueDrop else 85.0
	)
	# It's obsessed with giving me warnings unless I set deferred
	set_deferred(&"size", Vector2(0.0, 0.0))
	if parentBlock: parentBlock.fixMinimumSize()

# Release is for the purpose of the bottom block detecting if the stack should connect on release
func dragWithParent(release: bool) -> void:
	if parentBlock:
		global_position = parentBlock.global_position
		global_position.y += parentBlock.height
	elif parentNest:
		global_position = parentNest.global_position
		global_position += Vector2(NestSideWidth, parentNest.size.y + 2.0)
	elif parentNest2:
		global_position = parentNest2.global_position
		global_position += Vector2(NestSideWidth, parentNest2.size.y + parentNest2.nestEnd + 2.0)
	if childNest: childNest.dragWithParent(release)
	if childNest2: childNest2.dragWithParent(release)
	if childBlock:
		childBlock.dragWithParent(release)
	else:
		# If no child block, this block is in charge of detecting if the bottom of the stack can attach
		# Unless it's part of a nest
		if parentNest or parentNest2: return
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
	global_position.y -= height
	if parentBlock: parentBlock.moveWithChild()
# If the block above this one moves, re-position
func moveWithParent() -> void:
	if parentBlock:
		global_position = parentBlock.global_position
		global_position.y += parentBlock.height
	elif parentNest:
		global_position = parentNest.global_position
		global_position += Vector2(NestSideWidth, parentNest.size.y + 2.0)
	elif parentNest2:
		global_position = parentNest2.global_position
		global_position += Vector2(NestSideWidth, parentNest2.size.y + parentNest2.nestEnd + 2.0)
	if childBlock: childBlock.moveWithParent()
	if childNest: childNest.moveWithParent()
	if childNest2: childNest2.moveWithParent()

# Get the top block with no parent in the stack
func getHighestInStack() -> CodeBlock:
	if parentBlock:
		return parentBlock.getHighestInStack()
	else:
		return self
# Get the highest-level block, searching past parent nests
func getRootBlock() -> CodeBlock:
	if parentBlock:
		return parentBlock.getRootBlock()
	elif parentNest:
		return parentNest.getRootBlock()
	elif parentNest2:
		return parentNest2.getRootBlock()
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
	if valueDrop and parentBlock:
		return parentBlock.getHighestInStack()
	else:
		return self

# Blocks are layered by child order, not with z_index
# If isValue is true, then this is being called on a value block
func setToFront() -> void:
	move_to_front()
	if childBlock: childBlock.setToFront()
	if childNest: childNest.setToFront()
	if childNest2: childNest2.setToFront()
func updateSpriteScript(fromEvent: bool) -> void:
	if fromEvent and parentBlock: return
	BuildSpriteScript.updateBlock(self, sprite)
	if childBlock: childBlock.updateSpriteScript(false)

# Snap preview
func showPreview() -> void:
	if snapPreview == null:
		snapPreview = BlockPreview.new()
		snapPreview.custom_minimum_size = Vector2(size.x, size.y)
		snapPreview.shape = shapeNode.blockShape
		detectedBlock.add_sibling(snapPreview)
	snapPreview.previewShape.drawBottomNotch = shapeNode.drawBottomNotch
	snapPreview.nestEnd = DefaultNestEnd
	if nest2End: snapPreview.nest2End = DefaultNest2End
	# Layering
	detectedBlock.getRootBlock().setToFront()
	snapPreview.move_to_front()
	getHighestInStack().setToFront()
	# Position preview
	snapPreview.global_position = detectedBlock.global_position
	if detectedSnapPos == 1:
		# On top of stack
		if nestDetection:
			snapPreview.global_position.y -= size.y + snapPreview.nestEnd + snapPreview.nest2End + 2.0
		else:
			snapPreview.global_position.y -= size.y + 2.0
	elif detectedSnapPos == -2:
		# First inside nest
		snapPreview.global_position.y += detectedBlock.height - detectedBlock.nestEnd - detectedBlock.nest2End
		snapPreview.global_position.x += NestSideWidth
		snapPreview.previewShape.drawBottomNotch = true
		if nestDetection:
			if !childNest and detectedBlock.childNest: snapPreview.nestEnd = calculateStackHeight(detectedBlock.childNest)
			detectedBlock.setNestEnd(nestedNestPreviewHeight(detectedBlock.childNest) + calculateStackHeight(detectedBlock.childNest), false)
		else:
			detectedBlock.setNestEnd(height + calculateStackHeight(detectedBlock.childNest), false)
		# Shift blocks if there were already blocks in that nest
		if detectedBlock.childNest:
			detectedBlock.childNest.offset_transform_position.y = size.y + 2.0
			if childNest:
				detectedBlock.childNest.offset_transform_position.y += DefaultNestEnd + snapPreview.nest2End
			elif nestDetection:
				detectedBlock.childNest.offset_transform_position.x += NestSideWidth
			detectedBlock.childNest.processOffset(detectedBlock.childNest)
	elif detectedSnapPos == -3:
		# First inside nest2
		snapPreview.global_position.y += detectedBlock.height - detectedBlock.nest2End
		snapPreview.global_position.x += NestSideWidth
		snapPreview.previewShape.drawBottomNotch = true
		if nestDetection:
			if !childNest and detectedBlock.childNest2: snapPreview.nestEnd = calculateStackHeight(detectedBlock.childNest2)
			detectedBlock.setNest2End(nestedNestPreviewHeight(detectedBlock.childNest2) + calculateStackHeight(detectedBlock.childNest2), false)
		else:
			detectedBlock.setNest2End(height + calculateStackHeight(detectedBlock.childNest2), false)
		# Shift blocks if there were already blocks in that nest
		if detectedBlock.childNest2:
			detectedBlock.childNest2.offset_transform_position.y = size.y + 2.0
			if childNest:
				detectedBlock.childNest2.offset_transform_position.y += DefaultNestEnd + snapPreview.nest2End
			elif nestDetection:
				detectedBlock.childNest2.offset_transform_position.x += NestSideWidth
			detectedBlock.childNest2.processOffset(detectedBlock.childNest2)
	# Nest block nesting entire stack
	elif detectedSnapPos == 2:
		snapPreview.global_position.y -= snapPreview.size.y + 2.0
		snapPreview.global_position.x -= NestSideWidth
		snapPreview.nestEnd = calculateStackHeight(detectedBlock)
	else:
		# Below other block, or in middle of stack
		snapPreview.global_position.y += detectedBlock.height
		# Shift blocks if placing in middle of another stack
		if detectedBlock.childBlock:
			detectedBlock.childBlock.offset_transform_position.y = size.y + 2.0
			if nestDetection:
				if childNest:
					detectedBlock.childBlock.offset_transform_position.y += DefaultNestEnd + snapPreview.nest2End
				# If this is an empty nest block, then show nesting every block below
				else:
					detectedBlock.childBlock.offset_transform_position.x += NestSideWidth
					snapPreview.nestEnd = calculateStackHeight(detectedBlock.childBlock)
			detectedBlock.getHighestInStack().processOffset(detectedBlock.childBlock)
		# If this stack is part of a nest, fix the nestEnd
		if detectedBlock.parentNest:
			snapPreview.previewShape.drawBottomNotch = true
			if nestDetection:
				detectedBlock.parentNest.setNestEnd(detectedBlock.parentNest.fallbackNestEnd + nestedNestPreviewHeight(detectedBlock.childBlock), false)
			else:
				detectedBlock.parentNest.setNestEnd(detectedBlock.parentNest.fallbackNestEnd + height, false)
		if detectedBlock.parentNest2:
			snapPreview.previewShape.drawBottomNotch = true
			if nestDetection:
				detectedBlock.parentNest2.setNest2End(detectedBlock.parentNest2.fallbackNest2End + nestedNestPreviewHeight(detectedBlock.childBlock), false)
			else:
				detectedBlock.parentNest2.setNest2End(detectedBlock.parentNest2.fallbackNest2End + height, false)
	detectPosition = snapPreview.global_position
# Expected to be called from top-level block with one block offset
func processOffset(affected: CodeBlock) -> void:
	# If called null then reset all offsets for this stack
	if !affected:
		offset_transform_position = Vector2(0.0, 0.0)
		if childBlock: childBlock.processOffset(null)
		if childNest: childNest.processOffset(null)
		if childNest2: childNest2.processOffset(null)
		return
	if parentBlock:
		if self != affected: offset_transform_position = parentBlock.offset_transform_position
	elif parentNest:
		if self != affected: offset_transform_position = parentNest.offset_transform_position
	elif parentNest2:
		if self != affected: offset_transform_position = parentNest2.offset_transform_position
	if childBlock:
		childBlock.processOffset(affected)
	if childNest: childNest.processOffset(affected)
	if childNest2: childNest2.processOffset(affected)

func detectBlockSnap() -> void:
	if detectedBlock and !valueDrop:
		# Don't detect another snap until moved far enough away from the previous detection
		if detectPosition.distance_to(global_position) < 100.0: return
		detectPosition = Vector2.ZERO
		# Fix any changes made to other blocks with previews from the previous frame
		detectedBlock.getHighestInStack().processOffset(null)
		if detectedBlock.nestDetection:
			detectedBlock.setNestEnd(detectedBlock.fallbackNestEnd, false)
			if detectedBlock.nest2Detection:
				detectedBlock.setNest2End(detectedBlock.fallbackNest2End, false)
		else:
			if detectedBlock.parentNest:
				detectedBlock.parentNest.setNestEnd(detectedBlock.parentNest.fallbackNestEnd, false)
			if detectedBlock.parentNest2:
				detectedBlock.parentNest2.setNest2End(detectedBlock.parentNest2.fallbackNest2End, false)
	# Don't snap to the top of a block if there is a block attached below this one
	if bottomDetection and !childBlock:
		for i: Area2D in bottomDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapTop"):
				detectedBlock = i.get_parent()
				# Don't snap to the top of a block if it already has a parent
				if detectedBlock.parentBlock or detectedBlock.parentNest or detectedBlock.parentNest2: break
				detectedSnapPos = 1
				showPreview()
				return
	# Don't snap to the bottom of a block if there is a block attached above this one
	if topDetection and !parentBlock:
		for i: Area2D in topDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapBottom"):
				detectedBlock = i.get_parent()
				# Don't snap in middle of stacks if this is an end block (unless nest block)
				if (!getLowestInStack().bottomDetection) and detectedBlock.childBlock:
					if !nestDetection: break
				detectedSnapPos = -1
				showPreview()
				return
			elif i.is_in_group(&"blockSnapNest"):
				detectedBlock = i.get_parent()
				# Don't snap into top of nest if this is an end block (unless nest block)
				if (!getLowestInStack().bottomDetection) and detectedBlock.childNest:
					if !nestDetection: break
				detectedSnapPos = -2
				showPreview()
				return
			elif i.is_in_group(&"blockSnapNest2"):
				detectedBlock = i.get_parent()
				if (!getLowestInStack().bottomDetection) and detectedBlock.childNest2:
					if !nestDetection: break
				detectedSnapPos = -3
				showPreview()
				return
	# For value blocks
	if valueDrop:
		for i: Area2D in valueDrop.get_overlapping_areas():
			if i.is_in_group(&"blockValueDrop") and !is_ancestor_of(i):
				if detectedInput:
					if detectedInput == i.get_parent(): return
					detectedInput.highlight.visible = false
				detectedInput = i.get_parent()
				detectedBlock = detectedInput.block
				detectedInput.highlight.visible = true
				detectedBlock.getRootBlock().setToFront()
				setToFront()
				return
	# For nest blocks to nest an entire stack from the top
	if nestDetection and !parentBlock:
		for i: Area2D in nestDetection.get_overlapping_areas():
			if i.is_in_group(&"blockSnapTop"):
				detectedBlock = i.get_parent()
				if detectedBlock.parentBlock or detectedBlock.parentNest or detectedBlock.parentNest2: break
				detectedSnapPos = 2
				showPreview()
				return
	# No possible snaps detected
	detectedBlock = null
	if detectedInput:
		detectedInput.highlight.visible = false
		detectedInput = null
	detectedSnapPos = 0
	if snapPreview:
		snapPreview.queue_free()

# Goes down the stack and adds heights of blocks
# Adding NestEndHeight to results since almost every use of this function did that
func calculateStackHeight(fromBlock: CodeBlock) -> float:
	if !fromBlock: return NestEndHeight
	var currentBlock: CodeBlock = fromBlock
	var stackHeight: float = 0.0
	stackHeight += currentBlock.height
	while currentBlock.childBlock:
		currentBlock = currentBlock.childBlock
		stackHeight += currentBlock.height
	return stackHeight + NestEndHeight
func nestedNestPreviewHeight(nesting: CodeBlock) -> float:
	if nesting and !childNest:
		return ((size.y + snapPreview.nestEnd + snapPreview.nest2End + 2.0) - (calculateStackHeight(nesting)) + NestEndHeight)
	else:
		return size.y + snapPreview.nestEnd + snapPreview.nest2End + 2.0

func setNestEnd(newEnd: float, setFallback: bool, setParentNest: bool = true) -> void:
	if parentNest and setParentNest:
		parentNest.setNestEnd(parentNest.nestEnd + (newEnd - nestEnd), setFallback)
	elif parentNest2 and setParentNest:
		parentNest2.setNest2End(parentNest2.nest2End + (newEnd - nestEnd), setFallback)
	nestEnd = newEnd
	shapeNode.nestEnd = newEnd
	if setFallback: fallbackNestEnd = newEnd
	onResize()

func setNest2End(newEnd: float, setFallback: bool, setParentNest: bool = true) -> void:
	if parentNest and setParentNest:
		parentNest.setNestEnd(parentNest.nestEnd + (newEnd - nest2End), setFallback)
	elif parentNest2 and setParentNest:
		parentNest2.setNest2End(parentNest2.nest2End + (newEnd - nest2End), setFallback)
	nest2End = newEnd
	shapeNode.nestEnd2 = newEnd
	if setFallback: fallbackNest2End = newEnd
	onResize()

func setChildrenParentNests() -> void:
	if childBlock:
		childBlock.parentNest = parentNest
		childBlock.parentNest2 = parentNest2
		childBlock.setChildrenParentNests()

# When loading a sprite's blocks
func loadNestEnd() -> void:
	if childNest:
		childNest.loadNestEnd()
		setNestEnd(calculateStackHeight(childNest), true, false)
	if childNest2:
		childNest2.loadNestEnd()
		setNest2End(calculateStackHeight(childNest2), true, false)
	elif childBlock:
		childBlock.loadNestEnd()

func mouseEntered() -> void:
	# Don't allow interaction if initial click was outside block
	if dragDisabled: return
	mouseTouching = true
	# Only allow mouseTouching to change if UI is focused
	if editor.uiFocused: return
	# Don't allow interaction if dragging (but still allow mouseTouching to change)
	if dragDistance > 0.0: return
	shapeNode.blockColor = shapeNode.blockColor.lightened(0.2)

func mouseExited() -> void:
	mouseTouching = false
	if editor.uiFocused: return
	# Don't allow exit if dragging (but still allow mouseTouching to change)
	if dragDistance > 0.0: return
	shapeNode.blockColor = defaultColor

func changedFocus(newFocus: Control) -> void:
	if newFocus == null:
		if mouseTouching: mouseEntered()
	else:
		if mouseTouching: mouseExited()

func inputEvent(_viewport: Node, event: InputEvent, _shapeIdx: int) -> void:
	if event.is_action_pressed(&"leftMouse"):
		if !mouseTouching: mouseEntered()
		clicked.emit()
	elif event.is_action_released(&"leftMouse"):
		mouseReleased.emit()

func hoveringChildValue() -> bool:
	for i: CodeBlock in childValueBlocks:
		if i.get_global_rect().has_point(get_global_mouse_position()):
			return true
	return false

func makeSpace() -> void:
	var overlap: CodeBlock
	for i: Area2D in grabArea.get_overlapping_areas():
		overlap = i.get_parent()
		if (!overlap.parentBlock) and (!overlap.parentNest) and !overlap.parentNest2:
			if overlap.global_position.distance_to(global_position) > 50.0: continue
			overlap.global_position += Vector2(50.0, 50.0)
			overlap.moveWithParent()
			overlap.makeSpace()

func onResize() -> void:
	height = size.y + nestEnd + nest2End
	height += 2.0 # For outline
	if bottomDetection: bottomDetection.position.y = height
	if valueDrop:
		valueDrop.position.y = size.y / 2.0
		fixMinimumSize.call_deferred()
	if nestDetection:
		nestDetection.position.y = size.y
		if childNest: childNest.moveWithParent()
		if nest2Detection:
			nest2Detection.position.y = size.y + nestEnd
			nestEndContent.position.y = (size.y + nestEnd) - 53.0
			if childNest2: childNest2.moveWithParent()
	if childBlock: childBlock.moveWithParent()
	if parentNest: parentNest.setNestEnd(calculateStackHeight(getHighestInStack()), true)
	if parentNest2: parentNest2.setNest2End(calculateStackHeight(getHighestInStack()), true)
	if boolBlock:
		contentMargin.add_theme_constant_override(&"margin_left", int(size.y / 3.0))
		contentMargin.add_theme_constant_override(&"margin_right", int(size.y / 3.0))
		fixMinimumSize.call_deferred()
