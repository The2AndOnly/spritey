class_name Sprite
extends BlockDefinitions

# SPRITE SCRIPT BLOCK DOCS:
# &"block": StringName | Name of block
# &"top": bool | True if this block is the top of the stack
# &"next": int | ID of the block to run next, if missing then no block is next
# &"inputs": Array[Array] | Maps out each input (index is input ID), inner array is input data
# &"value": bool | True if this block is a value block
## Read type 0 (raw input): [read type, [input type, input]]
# - input type: 0=integer, 1=float, 2=string, 3=positiveInt, 4=positiveFloat
# - input is string (raw input)
## Read type 1 (value block): [read type, [input type, block ID]]
# - input type is same as read type 0 (raw input)
# - block ID is int
## Read type 2 (options): [read type, option]
# - option is int (selected option)

var spriteScript: Dictionary[int, Dictionary] = {}
# This holds the compiled script, but only the top-level blocks are listed in their category
# Ex: &"event_start": [CompiledBlock, CompiledBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
# Contains all value blocks (they are all a singular stack) | blockID: block
var valueBlocks: Dictionary[int, CompiledBlock] = {}
var scriptsCompiled := false
# This stores all of the actively running compiled stacks in the sprite
var activeStacks: Array[ScriptStack] = []
# Return result from execute block
var result: Variant
# Used in stack processing
var currentStack: ScriptStack

func _ready() -> void:
	gameView.event.connect(receivedEvent)

func receivedEvent(eventBlockName: StringName, eventData: Array[Variant]) -> void:
	if !scriptsCompiled: compileAll()
	if !topLevelBlocks.has(eventBlockName): return
	for i: CompiledBlock in topLevelBlocks[eventBlockName]:
		runStackFromEvent(i, eventData)

# For block parsing

func compileAll() -> void:
	# First, clear previous compilation
	topLevelBlocks = {}
	valueBlocks = {}
	for i: int in spriteScript:
		# Value blocks are all a singular stack
		if spriteScript[i][&"value"]:
			valueBlocks[i] = compileStack(i)
			continue
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

func runStackFromEvent(startBlock: CompiledBlock, eventData: Array[Variant]) -> void:
	# The first block must be an event, so if it has inputs then pass the eventData
	if !startBlock.inputs.is_empty():
		if startBlock.definition.call(startBlock.inputs, eventData): return
	# Clear any previous running stacks from this event
	# Iterate backwards so stacks can be removed
	for i: int in range(activeStacks.size() - 1, -1, -1):
			if activeStacks[i].startEvent == startBlock:
				activeStacks.remove_at(i)
	activeStacks.append(ScriptStack.new(startBlock.nextBlock, startBlock))

func _process(delta: float) -> void:
	# Iterate backwards so stacks can be removed
	for i: int in range(activeStacks.size() - 1, -1, -1):
		currentStack = activeStacks[i]
		# Skip processing this stack if there is wait time
		if currentStack.waitTime > 0.0:
			currentStack.waitTime -= delta
			if currentStack.waitTime <= 0.0: currentStack.waitTime = -1.0
			continue
		# Wait one frame for a wait time of 0.0
		elif currentStack.waitTime == 0.0:
			currentStack.waitTime = -1.0
			continue
		# Process stack
		while currentStack.currentBlock:
			result = executeBlock(currentStack.currentBlock)
			if result is bool:
				# If a block returns true, terminate this stack
				if result:
					activeStacks.remove_at(i)
					break
			elif result is float:
				# If a block returns a positive float, wait for that many seconds
				if result > 0.0:
					currentStack.waitTime = result
					currentStack.currentBlock = currentStack.currentBlock.nextBlock
					break
				# If the wait time is negative, then it will just execute the same block next frame
				if result < 0.0:
					break
				# If the wait time is zero, then it will wait one frame
				if result == 0.0:
					currentStack.waitTime = 0.0
					currentStack.currentBlock = currentStack.currentBlock.nextBlock
					break
			# If the result didn't catch anything, then execute the next block on this frame
			currentStack.currentBlock = currentStack.currentBlock.nextBlock
			# If the next block is null, then the stack will terminate
			if !currentStack.currentBlock:
				activeStacks.remove_at(i)
				break

func executeBlock(block: CompiledBlock) -> Variant:
	if block.definition.is_valid():
		if block.inputs.is_empty():
			return block.definition.call()
		else:
			# Build the input data from any potential value blocks
			var returnedValues: Array = []
			for i in block.inputs:
				if i is Array:
					returnedValues.append(
						castType(i[0], executeBlock(valueBlocks[i[1]]))
					)
					continue
				returnedValues.append(i)
			return block.definition.call(returnedValues)
	return false

func parseInput(inputs: Array) -> Array:
	var parsed: Array = []
	for i: Array in inputs:
		var valueOne: Variant = i[1]
		match i[0]:
			# Raw input
			0: parsed.append(castType(valueOne[0], valueOne[1]))
			# Value block
			1: parsed.append([valueOne[0], valueOne[1]])
			# Options
			2: parsed.append(valueOne)
	return parsed

func castType(type: int, value: Variant) -> Variant:
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
