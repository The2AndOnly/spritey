class_name BlockOptions
extends OptionButton

var block: CodeBlock

func _ready() -> void:
	item_selected.connect(onSelect)

func onSelect(_item: int) -> void:
	block.size.x = 0.0
