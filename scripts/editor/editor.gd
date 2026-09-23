class_name Editor
extends Control

@export var gameView: GameView
@export var scriptView: SubViewport
@export var mousePosLabel: Label
const halfBaseSize: Vector2 = Vector2(1280.0, 720.0) / 2.0
const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

var selectedSprite: Sprite
var currentView: StringName = &"sprites":
	set(value):
		currentView = value
		if value == &"scripts":
			if !spriteBlocksLoaded:
				loadSpriteBlocks()
				spriteBlocksLoaded = true
		else:
			if spriteBlocksLoaded:
				unloadSpriteBlocks()
				spriteBlocksLoaded = false
		changedView.emit(value)
var clampedMousePos: Vector2 = Vector2.ZERO
# Having this set disables interaction with several things
var uiFocused: Control = null:
	set(value):
		uiFocused = value
		changedFocus.emit(value)
var spriteBlocksLoaded := false

var signals: Array[String] = ["signal1"]

signal changedView(view: StringName)
signal changedFocus(newFocus: Control)

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
	for i: int in spriteScript:
		# Only load top level blocks with this loop
		if !spriteScript[i][&"top"]: continue
		topBlocks.append(loadBlock(spriteScript, i, null, null, -1))

func loadBlock(spriteScript: Dictionary[int, Dictionary], id: int, parent: CodeBlock, parentNest: CodeBlock, parentInput: int) -> CodeBlock:
	var blockData: Dictionary = spriteScript[id]
	var block: CodeBlock = CODE_BLOCK.instantiate()
	block.loading = true
	block.blockName = blockData[&"block"]
	block.blockID = id
	block.sprite = selectedSprite
	block.editor = self
	block.parentBlock = parent
	block.parentInputLoadID = parentInput
	block.parentNest = parentNest
	if blockData.has(&"pos"): block.loadPosition = blockData[&"pos"]
	# Set up block's values (may involve creating value blocks)
	if blockData.has(&"inputs"):
		for i: int in range(blockData[&"inputs"].size()):
			var inputData: Array = blockData[&"inputs"][i]
			match inputData[0]:
				0: # raw value
					block.valuesToLoad.append(inputData[1][1])
				1: # value block
					block.childValueBlocksToLoad.append(loadBlock(spriteScript, inputData[1][1], block, null, i))
					block.valuesToLoad.append("")
				2: # options
					block.valuesToLoad.append(inputData[1])
				3: # Empty bool
					block.valuesToLoad.append(false)
	# Set up child blocks
	if blockData.has(&"next"):
		block.childBlock = loadBlock(spriteScript, blockData[&"next"], block, parentNest, -1)
	if blockData.has(&"nest"):
		block.childNest = loadBlock(spriteScript, blockData[&"nest"], null, block, -1)
	scriptView.add_child(block)
	return block

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		setMousePosition()
