extends ColorPickerButton

@export var bitmapFrame: BitmapFrame
@export var setting: StringName

func _ready() -> void:
	color_changed.connect(colorChanged)

func colorChanged(newColor: Color) -> void:
	match setting:
		&"brushColor": bitmapFrame.color = newColor
