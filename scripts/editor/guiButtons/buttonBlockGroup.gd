extends Button

@export var blockGroup: StringName
@export var editor: Editor

func _ready() -> void:
	pressed.connect(onPress)
	text = blockGroup.capitalize()
	add_theme_color_override(&"font_color", BlockStructures.categoryColors[blockGroup])

func onPress() -> void:
	editor.switchBlockGroup.emit(blockGroup)
