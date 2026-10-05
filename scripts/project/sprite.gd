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

var spriteScript: Dictionary[int, Dictionary] = {}
# Contains all value blocks (they are all a singular stack) | blockID: block
var valueBlocks: Dictionary[int, CompiledBlock] = {}
# This holds the compiled script, but only the top-level blocks are listed in their category
# Ex: &"event_start": [CompiledBlock, CompiledBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
var scriptsCompiled := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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
