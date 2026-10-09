class_name Sprite
extends BlockDefinitions

# SPRITE SCRIPT BLOCK DOCS:
# &"block": StringName | Name of block
# &"top": bool | True if this block is the top of the stack
# &"next": int | ID of the block to run next, if missing then no block is next
# &"value": bool | True if this block is a value block
# &"nest": int | ID of the first block in nest, if missing then no nest or blocks in nest
# &"nest2": int | Same as nest but for the second nest
# &"pos": Vector2 | Position of the block, only for top-level blocks
# &"z": int | Child index of the block, only for top-level blocks
# &"inputs": Array[Array] | Maps out each input (index is input ID), inner array is input data
## Read type 0 (raw input): [read type, input type, input]
# - input type: 0=integer, 1=float, 2=string, 3=positiveInt, 4=positiveFloat, 5=bool
# - input is string (raw input)
## Read type 1 (value block): [read type, input type, block ID]
# - input type is same as read type 0 (raw input)
# - block ID is int
## Read type 2 (options): [read type, option]
# - option is variant
# - used by empty bool inputs, where option is false
# - used by special values (see blockStructures.gd)
## Empty bool panel: [3, false]

# Contains all value blocks (they are all a singular stack) | blockID: block
var valueBlocks: Dictionary[int, CompiledBlock] = {}
# This holds the compiled script, but only the top-level blocks are listed in their category
# Ex: &"event_start": [CompiledBlock, CompiledBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
var scriptsCompiled := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# If this sprite was cloned, copy properties from the sprite that cloned it
	if original:
		gameView = original.gameView
		spriteScript = original.spriteScript
		master = original.master
		
		# Set up frames
		frameNames = original.frameNames
		croppedFrames = original.croppedFrames
		frameImages = original.frameImages
		frameTextures = original.frameTextures
		var area: Area2D = get_child(0)
		var frameNumber: int = 0
		for i: SpriteCollisionShape in area.get_children():
			frameNumber = i.frameNumber
			if frameCollisions.has(frameNumber):
				frameCollisions[frameNumber].append(i)
			else:
				frameCollisions[frameNumber] = [i]
		area.area_entered.connect(collisionEntered)
		area.area_exited.connect(collisionExited)
		area.input_event.connect(collisionInput)
		area.mouse_entered.connect(mouseEntered)
		area.mouse_exited.connect(mouseExited)
		
		# Set up transform
		spritePos = original.spritePos
		rotation = original.rotation
		size = original.size
		stretch = original.stretch
		opacity = original.opacity
		
		# Set up variables
		variables = original.variables
		# Instead of using the values from the variable objects, clones use their own dictionary
		if original.original:
			# If cloning from a clone
			for i: Variable in variables:
				localValues[i] = original.localValues[i]
		else:
			for i: Variable in variables:
				localValues[i] = i.value
	else:
		# Not created from a clone
		master = self

func compileAll() -> void:
	# First, clear previous compilation
	topLevelBlocks = {}
	valueBlocks = {}
	gameView.stopStacksInSprite(self)
	for i: int in spriteScript:
		# Value blocks are all a singular stack
		if spriteScript[i][&"value"]:
			valueBlocks[i] = gameView.compileStack(self, i, null)
			continue
		# Skips all blocks that aren't top-level
		if !spriteScript[i][&"top"]: continue
		var blockName: StringName = spriteScript[i][&"block"]
		# Create a category for the top-level blocks
		if !topLevelBlocks.has(blockName):
			topLevelBlocks[blockName] = []
		# Top-level block will be added to the category while it compiles the stack
		topLevelBlocks[blockName].append(gameView.compileStack(self, i, null))
	scriptsCompiled = true

func executeBlock(block: CompiledBlock) -> Variant:
	if block.definition.is_valid():
		if block.inputs.is_empty():
			return block.definition.call()
		else:
			# If it's an execute wait, don't re-evaluate inputs unless there is no block data
			if gameView.currentStack.executeWait and !gameView.currentStack.blockData.is_empty():
				return block.definition.call(block.inputs)
			# Build the input data from any potential value blocks
			var returnedValues: Array = []
			for i in block.inputs:
				if i is Array:
					# Execute value block
					returnedValues.append(ParseData.castType(i[0], executeBlock(valueBlocks[i[1]])))
					continue
				# Raw input or options
				returnedValues.append(i)
			return block.definition.call(returnedValues)
	return -1.0
