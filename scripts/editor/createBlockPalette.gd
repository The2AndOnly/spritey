extends VBoxContainer

const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

@export var editor: Editor
@export var gameView: GameView
@export var blockGroup: StringName
@export var container: ScrollContainer
@export var camera: Camera2D

var blockOrder: Dictionary[StringName, Array] = {
	&"events": [
		&"event_start",
		&"event_keyboard",
		&"event_mouse",
		&"event_clicked",
		&"event_scrolled",
		&"event_receive",
		&"event_signal",
		&"event_signalAndWait",
		&"test_print"
	],
	&"control": [
		&"ctrl_wait",
		&"ctrl_waitUntil",
		&"ctrl_if",
		&"ctrl_ifElse",
		&"ctrl_repeat",
		&"ctrl_repeatSeconds",
		&"ctrl_forever",
		&"ctrl_while",
		&"ctrl_break",
		&"ctrl_continue",
		&"ctrl_stopOther",
		&"ctrl_stopStacks",
		&"ctrl_cloneStart",
		&"ctrl_cloneStartName",
		&"ctrl_createClone",
		&"ctrl_createCloneName",
		&"ctrl_deleteThisClone",
		&"ctrl_deleteClones",
		&"ctrl_deleteCloneName",
		&"ctrl_setCloneName",
		&"ctrl_cloneName",
		&"ctrl_cloneCount",
		&"ctrl_isClone"
	],
	&"interaction": [
		&"inter_pointerX",
		&"inter_pointerY",
		&"inter_touching",
		&"inter_touchingName",
		&"inter_touchingPoint",
		&"inter_touchingPointName",
		&"inter_keyPressed",
		&"inter_mousePressed",
		&"inter_distanceTo",
		&"inter_distanceToCoord",
		&"inter_deltaTime",
		&"inter_localTime",
		&"inter_timeSince1970"
	],
	&"visuals": [
		&"vis_show",
		&"vis_hide",
		&"vis_visible",
		&"vis_setSize",
		&"vis_changeSize",
		&"vis_size",
		&"vis_changeFrame",
		&"vis_setFrame",
		&"vis_frame",
		&"vis_showMessage",
		&"vis_showMessageSeconds",
		&"vis_setStretch",
		&"vis_changeStretch",
		&"vis_stretch",
		&"vis_setFlip",
		&"vis_flip",
		&"vis_setOpacity",
		&"vis_changeOpacity",
		&"vis_opacity",
		&"vis_setLayerOption",
		&"vis_setZIndex",
		&"vis_changeZIndex",
		&"vis_ZIndex",
		&"vis_setEffect",
		&"vis_changeEffect",
		&"vis_clearEffects"
	],
	&"transform": [
		&"trans_setPosition",
		&"trans_setPositionOption",
		&"trans_moveSteps",
		&"trans_setX",
		&"trans_setY",
		&"trans_changeX",
		&"trans_changeY",
		&"trans_glideToPosition",
		&"trans_glideToOption",
		&"trans_XPos",
		&"trans_YPos",
		&"trans_setDirection",
		&"trans_turnDegrees",
		&"trans_pointTowards",
		&"trans_direction"
	],
	&"expressions": [
		&"exp_add",
		&"exp_subtract",
		&"exp_multiply",
		&"exp_divide",
		&"exp_random",
		&"exp_join",
		&"exp_ternary",
		&"exp_equals",
		&"exp_greater",
		&"exp_less",
		&"exp_and",
		&"exp_or",
		&"exp_not",
		&"exp_charOf",
		&"exp_substring",
		&"exp_textLength",
		&"exp_textContains",
		&"exp_inCase",
		&"exp_mod",
		&"exp_abs",
		&"exp_round",
		&"exp_math",
		&"exp_doubleMath"
	],
	&"variables": [
		&"var_setTo",
		&"var_changeBy",
		&"var_showVar",
		&"var_hideVar"
	],
	&"canvas": [
		&"draw_beginStroke",
		&"draw_endStroke",
		&"draw_clearAll",
		&"draw_strokeTool",
		&"draw_setStrokeSize",
		&"draw_changeStrokeSize"
	]
}
# Clicked blocks are created by releasing it in the palette
var clickedBlock: CodeBlock = null
# Dragged blocks are created by holding it and moving the mouse outside the palette
var draggedBlock: CodeBlock = null

# Negative: Spacing before
# Positive: Spacing after
func shapeExtraSpacing(shape: BlockShape.blockShapes) -> float:
	match shape:
		BlockShape.blockShapes.EVENT: return -35.0
		BlockShape.blockShapes.NEST: return 70.0
		BlockShape.blockShapes.DOUBLE_NEST: return 130.0
		_: return 0.0

func _ready() -> void:
	editor.switchBlockGroup.connect(switchBlockGroup)
	editor.updateBlockOptions.connect(updateList)
	mouse_exited.connect(mouseExit)
	add_theme_constant_override(&"separation", -9)
	for i: StringName in blockOrder[blockGroup]:
		createBlock(i)

func createBlock(blockName: StringName, checkBox: VarGraphicCheckbox = null, atFront: bool = false, spacing: float = -999.0) -> void:
	var extraSpacing: float
	if spacing == -999.0:
		extraSpacing = shapeExtraSpacing(BlockStructures.structures[blockName][&"shape"])
	else:
		extraSpacing = spacing
	if extraSpacing < 0.0:
		createSpacing(abs(extraSpacing))
	var block: CodeBlock = CODE_BLOCK.instantiate()
	block.blockName = blockName
	block.preview = true
	block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	block.editor = editor
	block.gameView = gameView
	block.clicked.connect(blockClicked.bind(block))
	block.mouseReleased.connect(blockReleased.bind(block))
	block.grabArea.mouse_exited.connect(blockMouseExit)
	if checkBox:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hbox.offset_transform_enabled = true
		hbox.offset_transform_scale = Vector2(0.6, 0.6)
		hbox.offset_transform_pivot_ratio = Vector2(0.0, 0.0)
		hbox.offset_transform_visual_only = false
		hbox.add_theme_constant_override(&"separation", 15)
		checkBox.custom_minimum_size.x = 100.0
		hbox.add_child(checkBox)
		hbox.add_child(block)
		add_child(hbox)
		if atFront:
			move_child(hbox, 0)
	else:
		block.offset_transform_scale = Vector2(0.6, 0.6)
		block.offset_transform_pivot_ratio = Vector2(0.0, 0.0)
		block.offset_transform_visual_only = false
		add_child(block)
		if atFront:
			move_child(block, 0)
	if extraSpacing > 0.0:
		createSpacing(extraSpacing)

func createSpacing(amount: float) -> void:
	var spacing: Control = Control.new()
	spacing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacing.custom_minimum_size.y = amount
	add_child(spacing)

func blockClicked(block: CodeBlock) -> void:
	clickedBlock = block
	draggedBlock = block

func blockReleased(block: CodeBlock) -> void:
	if block != clickedBlock: return
	var offset: Vector2 = Vector2(200.0, 100.0) / (camera.zoom * 0.8)
	var newBlock: CodeBlock = instantiateBlock(block.blockName, camera.global_position - offset)
	await get_tree().physics_frame
	newBlock.makeSpace(newBlock)

func mouseExit() -> void:
	# Fix bug where the block stays highlighted when moving mouse out of palette
	for i: Control in get_children():
		if i is CodeBlock:
			i.mouseExited()
	if draggedBlock:
		var initialOffset: Vector2 = Vector2(-60.0, -35.0)
		var newBlock: CodeBlock = instantiateBlock(draggedBlock.blockName, camera.get_global_mouse_position() + initialOffset)
		newBlock.mouseEntered()
		newBlock.initialMousePos = newBlock.get_global_mouse_position()
		newBlock.initialOffset = initialOffset
		newBlock.mouseTouching = false
	clickedBlock = null
	draggedBlock = null

# Make it so if the mouse leaves any block then it can't create one by releasing again
func blockMouseExit() -> void:
	clickedBlock = null

func _input(event: InputEvent) -> void:
	if event.is_action_released(&"leftMouse"):
		draggedBlock = null

func instantiateBlock(blockName: StringName, blockPosition: Vector2) -> CodeBlock:
	# Create a new block in the script area
	var newBlock: CodeBlock = CODE_BLOCK.instantiate()
	newBlock.blockName = blockName
	newBlock.editor = editor
	newBlock.gameView = gameView
	newBlock.sprite = editor.selectedSprite
	# Assign this new block an ID
	var i: int = 0
	var spriteScript: Dictionary[int, Dictionary] = editor.selectedSprite.spriteScript
	while spriteScript.has(i):
		i += 1
	newBlock.blockID = i
	# Setting position has to go after adding child
	editor.scriptView.add_child(newBlock)
	newBlock.global_position = blockPosition
	return newBlock

func switchBlockGroup(newGroup: StringName) -> void:
	container.visible = newGroup == blockGroup

func updateList() -> void:
	match blockGroup:
		&"variables":
			# Clear previous
			for i: Node in find_children("*", "CodeBlock", true, false):
				if i.blockName.contains(&"var_value:"):
					i.get_parent().queue_free()
			# Sort global and local variables
			var sortedVars: Array[Variable] = gameView.variables.duplicate()
			# TODO: remove check since there should always be selected sprite in the future
			if editor.selectedSprite: sortedVars.append_array(editor.selectedSprite.variables)
			sortedVars.sort_custom(func(a: Variable, b: Variable) -> bool:
				return a.name.naturalnocasecmp_to(b.name) > 0)
			# Create var_value blocks
			var structureName: StringName
			for i: Variable in sortedVars:
				if i.sprite:
					structureName = &"var_value:" + i.name + &":" + i.sprite.spriteName
				else:
					structureName = &"var_value:" + i.name
				BlockStructures.structures[structureName] = {
					&"structure": [0, i.name],
					0: [&"special", i],
					&"color": &"variables",
					&"shape": BlockShape.blockShapes.VALUE
				}
				var checkbox: VarGraphicCheckbox = VarGraphicCheckbox.new()
				checkbox.variable = i
				createBlock(structureName, checkbox, true, 0.0)
