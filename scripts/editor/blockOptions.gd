class_name BlockOptions
extends OptionButton

var block: CodeBlock

func _ready() -> void:
	item_selected.connect(onSelect)
	pressed.connect(onPress)

func onSelect(_item: int) -> void:
	block.size.x = 0.0

func onPress() -> void:
	Input.set_custom_mouse_cursor(Global.ARROW, Input.CURSOR_ARROW)
