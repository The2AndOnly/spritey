class_name Editor
extends Control

@export var gameView: GameView
@export var scriptView: SubViewport
@export var mousePosLabel: Label
const halfBaseSize: Vector2 = Vector2(1280.0, 720.0) / 2.0
const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

var selectedSprite: Sprite:
	set(value):
		selectedSprite = value
		changedSelectedSprite.emit(value)
var currentView: StringName = &"sprites":
	set(value):
		currentView = value
		match value:
			&"scripts":
				selectedSprite.stopAllStacks()
				if spriteBlocksLoaded != selectedSprite:
					unloadSpriteBlocks()
					loadSpriteBlocks()
					spriteBlocksLoaded = selectedSprite
				updateBlockOptions.emit()
			&"sprites":
				updateSpriteScript.emit(true)
		changedView.emit(value)
var clampedMousePos: Vector2 = Vector2.ZERO
# Having this set disables interaction with several things
var uiFocused: Control = null:
	set(value):
		uiFocused = value
		changedFocus.emit(value)
var spriteBlocksLoaded: Sprite = null

var signals: Array[String] = ["signal1"]

signal changedView(view: StringName)
signal changedFocus(newFocus: Control)
signal changedSelectedSprite(newSprite: Sprite)
signal updateBlockOptions()
@warning_ignore("unused_signal")
signal switchBlockGroup(newGroup: StringName)
signal updateSpriteScript()

func setMousePosition() -> void:
	gameView.setMousePosition()
	clampedMousePos = gameView.mousePosition.clamp(-halfBaseSize, halfBaseSize)
	gameView.mousePosition = clampedMousePos
	mousePosLabel.text = "%s, %d" % [roundi(clampedMousePos.x), roundi(clampedMousePos.y)]

func unloadSpriteBlocks() -> void:
	for i: Node in scriptView.get_children():
		if i is CodeBlock:
			i.queue_free()

# Read from sprite script to load the blocks
# see sprite.gd for spriteScript docs
func loadSpriteBlocks() -> void:
	var spriteScript: Dictionary[int, Dictionary] = selectedSprite.spriteScript
	var topBlocks: Array[CodeBlock] = []
	# Inner arrays hold the block [0] and the order [1]
	var indexes: Array[Array] = []
	for i: int in spriteScript:
		# Only load top level blocks with this loop
		if !spriteScript[i][&"top"]: continue
		topBlocks.append(loadBlock(spriteScript, i, null, null, -1, indexes))
	# Load the layers of the stack
	indexes.sort_custom(func(a, b) -> bool: return a[1] < b[1])
	for i: Array in indexes:
		i[0].setToFront()

func loadBlock(spriteScript: Dictionary[int, Dictionary], id: int, parent: CodeBlock, parentNest: CodeBlock, parentInput: int, indexes: Array[Array]) -> CodeBlock:
	var blockData: Dictionary = spriteScript[id]
	var block: CodeBlock = CODE_BLOCK.instantiate()
	block.loading = true
	block.blockName = blockData[&"block"]
	block.blockID = id
	block.sprite = selectedSprite
	block.editor = self
	block.gameView = gameView
	block.parentBlock = parent
	block.parentInputLoadID = parentInput
	block.parentNest = parentNest
	if blockData.has(&"pos"): block.loadPosition = blockData[&"pos"]
	if blockData.has(&"z"): indexes.append([block, blockData[&"z"]])
	# Set up block's values (may involve creating value blocks)
	if blockData.has(&"inputs"):
		for i: int in range(blockData[&"inputs"].size()):
			var inputData: Array = blockData[&"inputs"][i]
			match inputData[0]:
				0: # raw value
					block.valuesToLoad.append(inputData[2])
				1: # value block
					block.childValueBlocksToLoad.append(loadBlock(spriteScript, inputData[2], block, null, i, indexes))
					block.valuesToLoad.append("")
				2: # options
					block.valuesToLoad.append([inputData[1], inputData[2]])
				3: # Empty bool
					block.valuesToLoad.append(false)
	# Set up child blocks
	if blockData.has(&"next"):
		block.childBlock = loadBlock(spriteScript, blockData[&"next"], block, parentNest, -1, indexes)
	if blockData.has(&"nest"):
		block.childNest = loadBlock(spriteScript, blockData[&"nest"], null, block, -1, indexes)
	scriptView.add_child(block)
	return block

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		setMousePosition()
