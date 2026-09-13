class_name Sprite
extends BlockDefinitions

# SPRITE SCRIPT BLOCK DOCS:
# &"block": StringName | Name of block
# &"top": bool | True if this block is the top of the stack
# &"next": int | ID of the block to run next, if missing then no block is next
# &"inputs": Array[Array] | Maps out each input, inner array is input data
## read type: 0=raw input, 1=value block, 2=options
## Input data for read type 0: [read type, [input type, input]]
## - input type: 0=integer, 1=float, 2=string, 3=positiveInt, 4=positiveFloat
## - input is string (raw input)
## Input data for read type 2: [read type, option]
## - option is int (selected option)

var spriteScript: Dictionary[int, Dictionary] = {}
# This holds the compiled script, but only the top-level blocks are listed in their category
# Ex: &"event_start": [CompiledBlock, CompiledBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
var scriptsCompiled := false

func _ready() -> void:
	gameView.event.connect(receivedEvent)

func receivedEvent(eventBlockName: StringName, eventData: Array[Variant]) -> void:
	if !scriptsCompiled: compileAll()
	if !topLevelBlocks.has(eventBlockName): return
	for i: CompiledBlock in topLevelBlocks[eventBlockName]:
		runStack(i, eventData)

# For block parsing

func compileAll() -> void:
	# First, clear previous compilation
	topLevelBlocks = {}
	for i: int in spriteScript:
		# Skips all blocks that aren't top-level
		if !spriteScript[i][&"top"]: continue
		var blockName: StringName = spriteScript[i][&"block"]
		# Create a category for the top-level blocks
		if !topLevelBlocks.has(blockName):
			topLevelBlocks[blockName] = []
		# Top-level block will be added to the category while it compiles the stack
		topLevelBlocks[blockName].append(compileStack(i))
	scriptsCompiled = true

func compileStack(blockID: int) -> CompiledBlock:
	var rawBlock: Dictionary = spriteScript[blockID]
	var compiledBlock: CompiledBlock = CompiledBlock.new()
	compiledBlock.definition = Callable(self, rawBlock[&"block"])
	if rawBlock.has(&"inputs"): compiledBlock.inputs = parseInput(rawBlock[&"inputs"])
	# Compile next block in stack
	if rawBlock.has(&"next"):
		compiledBlock.nextBlock = compileStack(rawBlock[&"next"])
	return compiledBlock

func runStack(startBlock: CompiledBlock, eventData: Array[Variant]) -> void:
	var block: CompiledBlock = startBlock
	var cancelStack := false
	# The first block must be an event, so if it has inputs then pass the eventData
	if !block.inputs.is_empty():
		if block.definition.call(block.inputs, eventData): return
	block = block.nextBlock
	# Stops once it reaches a block with nextBlock set to null, or if a block returns true
	while block:
		if block.definition.is_valid():
			if block.inputs.is_empty():
				cancelStack = block.definition.call()
			else:
				cancelStack = block.definition.call(block.inputs)
		if cancelStack: return
		block = block.nextBlock

func parseInput(inputs: Array) -> Array:
	var parsed: Array = []
	for i: Array in inputs:
		# Raw input
		if i[0] == 0:
			parsed.append(castType(i[1][0], i[1][1]))
		# Options
		if i[0] == 2:
			parsed.append(i[1])
	return parsed

func castType(type: int, value: String) -> Variant:
	match type:
		0: # integer
			return int(value)
		1: # float
			return float(value)
		2: # string
			return value
		3: # positive integer
			return abs(int(value))
		4: # positive float
			return abs(float(value))
	return null
