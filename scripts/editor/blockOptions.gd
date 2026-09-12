class_name BlockOptions
extends OptionButton

var block: CodeBlock

func _ready() -> void:
	item_selected.connect(onSelect)
	focus_entered.connect(onFocus)
	focus_exited.connect(onFocusExit)

func onSelect(_item: int) -> void:
	block.size.x = 0.0
	release_focus()

func onFocus() -> void:
	block.focused = true
	block.getHighestInStack().setToFront()
func onFocusExit() -> void:
	block.focusExit()
