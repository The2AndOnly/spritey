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
	&"exp_add",
	&"exp_subtract",
	&"exp_multiply",
	&"exp_divide",
	&"exp_random",
	&"exp_join",
	&"trans_setPosition",
	&"trans_setPositionOption",
	&"trans_setX",
	&"trans_setY",
	&"trans_changeX",
	&"trans_changeY",
	&"trans_glideToPosition",
	&"trans_glideToOption",
	&"test_print",
	&"test_process",
	&"test_emptyStack",
	&"test_emptyEvent",
	&"test_emptyValue"
]
func shapeExtraSpacing(shape: BlockShape.blockShapes) -> float:
	match shape:
		BlockShape.blockShapes.EVENT: return 28.0
		_: return 0.0

func _ready() -> void:
	for i: StringName in blockOrder:
		var extraSpacing: float = shapeExtraSpacing(BlockStructures.structures[i][&"shape"])
		if extraSpacing != 0.0:
			var spacing: Control = Control.new()
			spacing.mouse_filter = Control.MOUSE_FILTER_IGNORE
			spacing.custom_minimum_size.y = extraSpacing
			add_child(spacing)
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
