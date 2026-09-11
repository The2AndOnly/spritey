class_name BlockInputEdit
extends LineEdit

# 0 = integer
# 1 = float
# 2 = string
# 3 = positive integer
# 4 = positive float
var type: int = 0
var block: CodeBlock

func _ready() -> void:
	text_changed.connect(onType)

func onType(_newText: String) -> void:
	block.size.x = 0.0
