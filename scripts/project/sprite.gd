class_name Sprite
extends BlockDefinitions

# SPRITE SCRIPT BLOCK DOCS:
# &"block": StringName | Name of block
# &"top": bool | True if this block is the top of the stack
# &"next": int | ID of the block to run next, if missing then no block is next
# &"value": bool | True if this block is a value block
# &"nest": int | ID of the first block in nest, if missing then no nest or blocks in nest
# &"inputs": Array[Array] | Maps out each input (index is input ID), inner array is input data
## Read type 0 (raw input): [read type, [input type, input]]
# - input type: 0=integer, 1=float, 2=string, 3=positiveInt, 4=positiveFloat, 5=bool
# - input is string (raw input)
## Read type 1 (value block): [read type, [input type, block ID]]
# - input type is same as read type 0 (raw input)
# - block ID is int
## Read type 2 (options): [read type, option]
# - option is int (selected option)
# - also used by empty bool inputs, so option can be false

var spriteScript: Dictionary[int, Dictionary] = {}
# This holds the compiled script, but only the top-level blocks are listed in their category
# Ex: &"event_start": [CompiledBlock, CompiledBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
# Contains all value blocks (they are all a singular stack) | blockID: block
var valueBlocks: Dictionary[int, CompiledBlock] = {}
var scriptsCompiled := false
# Return result from execute block
var result: Variant
# This stores all of the actively running compiled stacks in the sprite
var activeStacks: Array[ScriptStack] = []

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
	# Stop all execution
	activeStacks.clear()
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
	# Compile any nest
	if rawBlock.has(&"nest"):
		compiledBlock.firstInNest = compileStack(rawBlock[&"nest"])
	return compiledBlock

func runStackFromEvent(startBlock: CompiledBlock, eventData: Array[Variant]) -> void:
	# The first block must be an event, so if it has inputs then pass the eventData
	if !startBlock.inputs.is_empty():
		# If the event block returns false, then don't continue
		if !startBlock.definition.call(startBlock.inputs, eventData): return
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
			# If time reached zero naturally, then continue with the stack
			if currentStack.waitTime <= 0.0:
				currentStack.waitTime = -1.0
				# Execute the block one last time if it needs to finish up something
				# Must go after setting waitTime to -1.0 and before calling finishExecuteWait
				executeBlock(currentStack.currentBlock)
				finishWaitBlock()
			else:
				if currentStack.executeWait:
					# Execute the waiting block every frame
					currentStack.waitTime = executeBlock(currentStack.currentBlock)
					# If the block returns -1.0, it's done waiting
					if currentStack.waitTime == -1.0:
						finishWaitBlock()
			continue
		# Wait one frame for a wait time of 0.0
		elif currentStack.waitTime == 0.0:
			currentStack.waitTime = -1.0
			currentStack.currentBlock = currentStack.currentBlock.nextBlock
			continue
		# Process stack
		while currentStack.currentBlock:
			result = executeBlock(currentStack.currentBlock)
			# If a block returns -2.0, terminate this stack
			if result == -2.0:
				activeStacks.remove_at(i)
				break
			# If a block returns > 0.0, wait for that many seconds
			# If the wait time is zero, then it will wait one frame
			if result >= 0.0:
				currentStack.waitTime = result if result > 0.0 else 0.0
				break
			# If the result didn't catch anything, then execute the next block on this frame
			if result == -3.0:
				currentStack.currentBlock = currentStack.currentBlock.firstInNest
			else:
				currentStack.currentBlock = currentStack.currentBlock.nextBlock
		# Reached the end of a stack or nest
		if !currentStack.currentBlock:
			if !currentStack.loops.is_empty():
				currentStack.currentBlock = currentStack.loops.back()
				continue
			if currentStack.exitNest:
				currentStack.currentBlock = currentStack.exitNest
				currentStack.exitNest = null
				continue
			# If no more blocks to execute, then terminate this stack
			activeStacks.remove_at(i)

func finishWaitBlock() -> void:
	currentStack.executeWait = false
	currentStack.blockData.clear()
	currentStack.currentBlock = currentStack.currentBlock.nextBlock

func executeBlock(block: CompiledBlock) -> Variant:
	if block.definition.is_valid():
		if block.inputs.is_empty():
			return block.definition.call()
		else:
			# If it's an execute wait, don't re-evaluate inputs unless there is no block data
			if currentStack.executeWait and !currentStack.blockData.is_empty():
				return block.definition.call(block.inputs)
			# Build the input data from any potential value blocks
			var returnedValues: Array = []
			for i in block.inputs:
				if i is Array:
					# Execute value block
					returnedValues.append(castType(i[0], executeBlock(valueBlocks[i[1]])))
					continue
				# Raw input or options
				returnedValues.append(i)
			return block.definition.call(returnedValues)
	return -1.0

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
			return str(value)
		3: # positive integer
			return max(0, int(value))
		4: # positive float
			return max(0.0, float(value))
		5: # bool (has no casting since only bool blocks can be inserted)
			return value
	return null
