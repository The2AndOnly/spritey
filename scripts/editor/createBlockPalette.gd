extends VBoxContainer

const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

@export var editor: Editor
@export var gameView: GameView
@export var blockGroup: StringName
@export var container: ScrollContainer

var blockOrder: Dictionary[StringName, Array] = {
	&"events": [
		&"event_start",
		&"event_keyboard",
		&"event_mouse",
		&"event_receive",
		&"event_signal",
		&"test_print"
	],
	&"control": [
		&"ctrl_wait",
		&"ctrl_waitUntil",
		&"ctrl_if",
		&"ctrl_repeat",
		&"ctrl_repeatSeconds",
		&"ctrl_forever",
		&"ctrl_while",
		&"ctrl_break",
		&"ctrl_continue",
		&"ctrl_stopOther",
		&"ctrl_stopStacks",
	],
	&"interaction": [
		&"inter_pointerX",
		&"inter_pointerY",
		&"inter_keyPressed",
	],
	&"visuals": [
		&"vis_show",
		&"vis_hide",
		&"vis_visible",
		&"vis_setSize",
		&"vis_changeSize",
		&"vis_size",
		&"vis_setStretch",
		&"vis_changeStretch",
		&"vis_stretch",
		&"vis_setFlip",
		&"vis_flip",
		&"vis_setOpacity",
		&"vis_changeOpacity",
		&"vis_opacity",
	],
	&"transform": [
		&"trans_setPosition",
		&"trans_setPositionOption",
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
		&"trans_direction",
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
		&"exp_mod",
		&"exp_exponent",
		&"exp_abs",
		&"exp_round",
		&"exp_math",
	],
	&"variables": [
		&"var_setTo",
		&"var_changeBy"
	]
}

# Negative: Spacing before
# Position: Spacing after
func shapeExtraSpacing(shape: BlockShape.blockShapes) -> float:
	match shape:
		BlockShape.blockShapes.EVENT: return -28.0
		BlockShape.blockShapes.NEST: return 80.0
		_: return 0.0

func _ready() -> void:
	editor.switchBlockGroup.connect(switchBlockGroup)
	editor.updateBlockOptions.connect(updateList)
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
	block.clicked.connect(blockClicked.bind(block.blockName))
	if checkBox:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		hbox.offset_transform_enabled = true
		hbox.offset_transform_scale = Vector2(0.7, 0.7)
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
		block.offset_transform_scale = Vector2(0.7, 0.7)
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

func blockClicked(clicked: StringName) -> void:
	# Create a new block in the script area
	var block: CodeBlock = CODE_BLOCK.instantiate()
	block.blockName = clicked
	block.editor = editor
	block.gameView = gameView
	block.sprite = editor.selectedSprite
	# Assign this new block an ID
	var i: int = 0
	var spriteScript: Dictionary[int, Dictionary] = editor.selectedSprite.spriteScript
	while spriteScript.has(i):
		i += 1
	block.blockID = i
	editor.scriptView.add_child(block)

func switchBlockGroup(newGroup: StringName) -> void:
	container.visible = newGroup == blockGroup

func updateList() -> void:
	match blockGroup:
		&"variables":
			# Clear previous
			for i: Node in find_children("*", "CodeBlock", true, false):
				if i.blockName.contains(&"var_value:"):
					i.queue_free()
			# Sort global and local variables
			var sortedVars: Array[Variable] = gameView.variables.duplicate()
			# TODO: remove check since there should always be selected sprite in the future
			if editor.selectedSprite: sortedVars.append_array(editor.selectedSprite.variables)
			sortedVars.sort_custom(func(a: Variable, b: Variable) -> bool:
				return a.name.naturalnocasecmp_to(b.name) > 0)
			# Create var_value blocks
			var structureName: StringName
			for i: Variable in sortedVars:
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
