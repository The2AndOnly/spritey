class_name Sprite
extends Sprite2D

var gameView: GameView
var spriteScript: Dictionary[int, Dictionary] = {
	0: {
		&"block": &"event_start",
		&"parent": null,
		&"top": true,
		&"next": 1,
		&"inputs": null
	},
	1: {
		&"block": &"trans_setX",
		&"parent": 0,
		&"top": false,
		&"next": 2,
		&"inputs": [
			[1, [0, "100"]] # [inputType, [dataType, input]]
		]
	},
	2: {
		&"block": &"trans_setY",
		&"parent": 1,
		&"top": false,
		&"next": null,
		&"inputs": [
			[1, [0, "-300"]]
		]
	}
}
# This holds all the ScriptBlocks under the block name
# Ex: &"event_start": [ScriptBlock, ScriptBlock]
var topLevelBlocks: Dictionary[StringName, Array] = {}
var scriptsCompiled := false

func _ready() -> void:
	gameView.event.connect(receivedEvent)

func receivedEvent(blockName: StringName) -> void:
	if !scriptsCompiled: compileAll()
	if !topLevelBlocks.has(blockName): return
	for i: ScriptBlock in topLevelBlocks[blockName]:
		runStack(i)

# For block parsing

func compileAll() -> void:
	# Compile scripts and define top-level blocks
	for i: int in spriteScript:
		if !spriteScript[i][&"top"]: continue
		var blockName: StringName = spriteScript[i][&"block"]
		# Create a category for the top-level blocks
		if !topLevelBlocks.has(blockName):
			topLevelBlocks[blockName] = []
		# Top level block will be added to the category
		topLevelBlocks[blockName].append(compileStack(i))

func compileStack(blockID: int) -> ScriptBlock:
	var rawBlock: Dictionary = spriteScript[blockID]
	var compiledBlock: ScriptBlock = ScriptBlock.new()
	compiledBlock.definition = Callable(self, rawBlock[&"block"])
	if rawBlock[&"inputs"]: compiledBlock.inputs = parseInput(rawBlock[&"inputs"])
	# Compile next block in stack
	if rawBlock[&"next"]:
		compiledBlock.nextBlock = compileStack(rawBlock[&"next"])
	return compiledBlock

func runStack(startBlock: ScriptBlock) -> void:
	var block: ScriptBlock = startBlock
	block = block.nextBlock # Skip the top-level block
	# Stops once it reaches a block with nextBlock set to null
	while block:
		if block.inputs.is_empty():
			block.definition.call()
		else:
			block.definition.call(block.inputs)
		block = block.nextBlock

func parseInput(inputs: Array) -> Array:
	var parsed: Array = []
	for i: Array in inputs:
		# Raw input
		if i[0] == 1:
			parsed.append(castType(i[1][0], i[1][1]))
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
	return null

# Block definitions

func trans_setX(inputs: Array) -> void:
	position.x = gameView.getCoord(inputs[0], 0.0).x

func trans_setY(inputs: Array) -> void:
	position.y = gameView.getCoord(0.0, inputs[0]).y
