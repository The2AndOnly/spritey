extends VBoxContainer

const CODE_BLOCK: PackedScene = preload("uid://pskgxv2e6pjo")

@export var scriptView: SubViewport

var blockOrder: Array[StringName] = [
	&"event_start",
	&"trans_setPosition",
	&"trans_setPositionOption",
	&"trans_setX",
	&"trans_setY",
	&"trans_glideToPosition",
	&"trans_glideToOption",
	&"test_emptyStack",
	&"test_emptyEvent"
]

func _ready() -> void:
	for i: StringName in blockOrder:
		var block: CodeBlock = CODE_BLOCK.instantiate()
		block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		block.offset_transform_scale = Vector2(0.7, 0.7)
		block.offset_transform_pivot_ratio = Vector2(0.0, 0.0)
		block.offset_transform_visual_only = false
		block.blockName = i
		block.preview = true
		block.gui_input.connect(blockGuiInput.bind(i))
		add_child(block)

func blockGuiInput(event: InputEvent, blockName: StringName) -> void:
	if event.is_action_pressed(&"leftMouse"):
		# Create a new block in the script area
		var block: CodeBlock = CODE_BLOCK.instantiate()
		block.blockName = blockName
		block.scriptView = scriptView
		scriptView.add_child(block)
