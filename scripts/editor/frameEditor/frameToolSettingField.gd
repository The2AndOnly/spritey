extends LineEdit

@export var bitmapFrame: BitmapFrame
@export var setting: StringName

func _ready() -> void:
	focus_exited.connect(focusExit)
	text_submitted.connect(submitted)

func submitted(newText: String) -> void:
	match setting:
		&"brushSize":
			var newSize: int = clampi(int(newText), 1, 200)
			text = str(newSize)
			bitmapFrame.brushRadius = newSize
func focusExit() -> void:
	submitted(text)
