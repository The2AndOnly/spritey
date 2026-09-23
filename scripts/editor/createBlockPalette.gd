extends VBoxContainer

const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

@export var editor: Editor

var blockOrder: Array[StringName] = [
	&"event_start",
	&"event_keyboard",
	&"event_mouse",
	&"event_receive",
	&"event_signal",
	
	&"ctrl_wait",
	&"ctrl_waitUntil",
	&"ctrl_if",
	&"ctrl_repeat",
	&"ctrl_repeatSeconds",
	&"ctrl_while",
	&"ctrl_forever",
	&"ctrl_break",
	&"ctrl_continue",
	&"ctrl_stopOther",
	&"ctrl_stopStacks",
	
	&"inter_pointerX",
	&"inter_pointerY",
	
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
	
	&"test_print"
]

# Negative: Spacing before
# Position: Spacing after
func shapeExtraSpacing(shape: BlockShape.blockShapes) -> float:
	match shape:
		BlockShape.blockShapes.EVENT: return -28.0
		BlockShape.blockShapes.NEST: return 80.0
		_: return 0.0

func _ready() -> void:
	for i: StringName in blockOrder:
		var extraSpacing: float = shapeExtraSpacing(BlockStructures.structures[i][&"shape"])
		if extraSpacing < 0.0:
			createSpacing(abs(extraSpacing))
		var block: CodeBlock = CODE_BLOCK.instantiate()
		block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		block.offset_transform_scale = Vector2(0.7, 0.7)
		block.offset_transform_pivot_ratio = Vector2(0.0, 0.0)
		block.offset_transform_visual_only = false
		block.blockName = i
		block.preview = true
		block.editor = editor
		block.clicked.connect(blockClicked.bind(i))
		add_child(block)
		if extraSpacing > 0.0:
			createSpacing(extraSpacing)

func createSpacing(amount: float) -> void:
	var spacing: Control = Control.new()
	spacing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacing.custom_minimum_size.y = amount
	add_child(spacing)

func blockClicked(blockName: StringName) -> void:
	# Create a new block in the script area
	var block: CodeBlock = CODE_BLOCK.instantiate()
	block.blockName = blockName
	block.editor = editor
	block.sprite = editor.selectedSprite
	# Assign this new block an ID
	var i: int = 0
	var takenIds: Array[int] = editor.selectedSprite.spriteScript.keys()
	while true:
		if i in takenIds: i += 1
		else:
			block.blockID = i
			break
	editor.scriptView.add_child(block)
