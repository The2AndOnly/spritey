class_name GameView
extends SubViewport

# EVENT DATA DOCS:
# event_keyboard: [key pressed, pressed/released]

@export var editor: Editor
@export var projectUI: CanvasLayer
@export var camera: Camera2D
const baseSize: Vector2 = Vector2(1280.0, 720.0)

# Set the inital zoom of the camera so it fits the base size perfectly
@onready var scaleFactor: Vector2 = Vector2(size) / baseSize
@onready var originalZoom: float = minf(scaleFactor.x, scaleFactor.y)
@onready var originalZoomVector: Vector2 = Vector2(originalZoom, originalZoom)
# These are to optimize calculating coordinates
@onready var halfBaseSize: Vector2 = baseSize / 2.0
@onready var halfSize: Vector2 = Vector2(size.x / 2.0, size.y / 2.0)
@onready var scaledSize: Vector2 = Vector2(size.x / baseSize.x, size.y / baseSize.y) / originalZoomVector
@onready var sizeMinusOne: Vector2 = size - Vector2i(1, 1)

# This stores all of the actively running compiled stacks in the project
var activeStacks: Array[ScriptStack] = []
var currentStack: ScriptStack
# Return result from execute block
var result: Variant
var stackIterator: int = 0

var sprites: Array[Sprite] = []
var variables: Array[Variable] = []
# Index is the ID of the signal
var signals: Array[String] = ["signal1"]
var mousePosition: Vector2
# Stores key names to their index in BlockStructures.keyOptions
var actionToIndex: Dictionary[StringName, int] = {}

func _ready() -> void:
	if editor:
		editor.setMousePosition()
	else:
		setMousePosition()
	for i: int in range(BlockStructures.keyOptions.size()):
		actionToIndex[BlockStructures.keyOptions[i]] = i
	variables.append(Variable.new("variable", self, "0.0"))
	# Set the inital zoom and position of the camera
	camera.position = Vector2(size) / Vector2(2.0, 2.0)
	camera.zoom = originalZoomVector

func compileStack(sprite: Sprite, blockID: int, parentNest: CompiledBlock) -> CompiledBlock:
	var rawBlock: Dictionary = sprite.spriteScript[blockID]
	var compiledBlock: CompiledBlock = CompiledBlock.new()
	compiledBlock.sprite = sprite
	compiledBlock.definition = Callable(sprite, str(rawBlock[&"block"]).split(":")[0])
	if rawBlock.has(&"inputs"): compiledBlock.inputs = parseInput(rawBlock[&"inputs"])
	# Compile next block in stack
	if rawBlock.has(&"next"):
		compiledBlock.nextBlock = compileStack(sprite, rawBlock[&"next"], null)
	# Compile any nest
	if rawBlock.has(&"nest"):
		compiledBlock.firstInNest = compileStack(sprite, rawBlock[&"nest"], compiledBlock)
	if parentNest: compiledBlock.parentNest = parentNest
	return compiledBlock

func parseInput(inputs: Array) -> Array:
	var parsed: Array = []
	for i: Array in inputs:
		match i[0]:
			# Raw input
			0: parsed.append(ParseData.castType(i[1], i[2]))
			# Value block
			1: parsed.append([i[1], i[2]])
			# Options / empty bool / special
			2: parsed.append(i[1])
	return parsed

func _process(delta: float) -> void:
	# Stacks can be removed and appended while processing
	stackIterator = 0
	while stackIterator < activeStacks.size():
		currentStack = activeStacks[stackIterator]
		stackIterator += 1
		if currentStack.terminated:
			stackIterator -= 1
			activeStacks.remove_at(stackIterator)
			continue
		# Skip processing this stack if there is wait time
		if currentStack.waitTime > 0.0:
			currentStack.waitTime -= delta
			# If time reached zero naturally, then continue with the stack
			if currentStack.waitTime <= 0.0:
				currentStack.waitTime = -1.0
				# Execute the block one last time if it needs to finish up something
				# Must go after setting waitTime to -1.0 and before calling finishExecuteWait
				currentStack.sprite.executeBlock(currentStack.currentBlock)
				finishWaitBlock()
			else:
				if currentStack.executeWait:
					# Execute the waiting block every frame
					currentStack.waitTime = currentStack.sprite.executeBlock(currentStack.currentBlock)
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
			result = currentStack.sprite.executeBlock(currentStack.currentBlock)
			match result:
				-1.0: # Go to next block
					currentStack.currentBlock = currentStack.currentBlock.nextBlock
				# Enter nest/loop
				-3.0:
					currentStack.currentBlock = currentStack.currentBlock.firstInNest
				# Do nothing / The block set which block is next
				-5.0: pass
				# Exit frame process
				-6.0: break
				# If a block returns >= 0.0, wait for that many seconds
				# If the wait time is zero, then it will wait one frame
				_:
					currentStack.waitTime = result
					break
			# After finding next block to run
			if currentStack.terminated:
				break
			elif !currentStack.currentBlock:
				if !currentStack.exitNest.is_empty():
					currentStack.currentBlock = currentStack.exitNest.back()
					currentStack.exitNest.remove_at(-1)
		# Reached end of stack after end of process
		if !currentStack.currentBlock:
			if !currentStack.loops.is_empty():
				currentStack.currentBlock = currentStack.loops.back()
				continue
			# If no more blocks to execute, then terminate this stack
			stackIterator -= 1
			activeStacks.remove_at(stackIterator)

func event(eventBlockName: StringName, eventData: Array[Variant], storeNewStacks: bool = false) -> void:
	for sprite: Sprite in sprites:
		if !sprite.scriptsCompiled: sprite.compileAll()
		if !sprite.topLevelBlocks.has(eventBlockName): continue
		# storing the created stacks is used by "send signal and wait" blocks
		if storeNewStacks:
			currentStack.createdStacks.clear()
			for i: CompiledBlock in sprite.topLevelBlocks[eventBlockName]:
				currentStack.createdStacks.append(createStackFromEvent(i, eventData))
		else:
			for i: CompiledBlock in sprite.topLevelBlocks[eventBlockName]:
				createStackFromEvent(i, eventData)

func createStackFromEvent(startBlock: CompiledBlock, eventData: Array[Variant]) -> ScriptStack:
	# The first block must be an event, so if it has inputs then pass the eventData
	if !startBlock.inputs.is_empty():
		# If the event block returns false, then don't continue
		if !startBlock.definition.call(startBlock.inputs, eventData): return
	# Terminate all stacks that are currently running this event
	var hadActiveStacks := false
	for i: ScriptStack in activeStacks:
		if i.startEvent == startBlock:
			hadActiveStacks = true
			i.terminate()
	var newStack: ScriptStack = ScriptStack.new(startBlock.sprite, startBlock.nextBlock, startBlock)
	# If a stack was interrupted, then the new stack will be processed on the next frame.
	# If nothing was interrupted, it gets processed at the end of this frame. The reason
	# is to allow for recursive events, but also be able to start events in the same process.
	if hadActiveStacks:
		activeStacks.push_front(newStack)
		stackIterator += 1
		return newStack
	else:
		activeStacks.append(newStack)
		return newStack

func stopAllStacks() -> void:
	for sprite: Sprite in sprites:
		for i: ScriptStack in activeStacks:
			i.terminate()

func stopStacksInSprite(sprite: Sprite) -> void:
	for i: ScriptStack in activeStacks:
		if i.sprite == sprite: i.terminate()

func finishWaitBlock() -> void:
	currentStack.executeWait = false
	currentStack.blockData.clear()
	currentStack.currentBlock = currentStack.currentBlock.nextBlock

# Input is game coords, output is local coords
func toLocalCoords(position: Vector2) -> Vector2:
	return Vector2(
		(position.x * scaledSize.x) + halfSize.x,
		halfSize.y - (position.y * scaledSize.y)
	)
# Input is local coords, output is game coords
func toGameCoords(position: Vector2) -> Vector2:
	return Vector2(
		(position.x - halfSize.x) / originalZoom,
		(halfSize.y - position.y) / originalZoom
	)
func setMousePosition() -> void:
	mousePosition = toGameCoords(get_mouse_position())

# Send input events
func _input(inputEvent: InputEvent) -> void:
	if editor:
		if editor.currentView != &"sprites": return
		if inputEvent is InputEventMouseMotion:
			if !editor: setMousePosition()
			return
	
	if inputEvent is InputEventKey:
		if inputEvent.is_echo(): return
		event(&"event_keyboard", [0, 0 if inputEvent.pressed else 1]) # Any key
		for i: StringName in actionToIndex:
			if inputEvent.is_action(i) and (i != &"any"):
				event(&"event_keyboard", [
					actionToIndex[i],
					0 if inputEvent.pressed else 1
				])
				break
	elif inputEvent.is_action_released(&"mouseWheelUp"):
		event(&"event_scrolled", [0])
	elif inputEvent.is_action_released(&"mouseWheelDown"):
		event(&"event_scrolled", [1])
	elif inputEvent is InputEventMouseButton:
		if inputEvent.button_index == 1:
			if inputEvent.pressed:
				event(&"event_mouse", [0, 0])
				event(&"event_clicked", [0])
				if inputEvent.double_click: event(&"event_clicked", [1])
			else:
				event(&"event_mouse", [0, 1])
		elif inputEvent.button_index == 2:
			if inputEvent.pressed:
				event(&"event_mouse", [1, 0])
				event(&"event_clicked", [2])
			else:
				event(&"event_mouse", [1, 1])
