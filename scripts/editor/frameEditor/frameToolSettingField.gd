extends LineEdit

@export var bitmapFrame: BitmapFrame
@export var setting: StringName

func _ready() -> void:
	focus_exited.connect(focusExit)
	text_submitted.connect(submitted)
	text_changed.connect(changed)

func submitted(newText: String) -> void:
	match setting:
		&"brushSize":
			var newSize: int = clampi(int(newText), 1, 200)
			text = str(newSize)
			bitmapFrame.brushRadius = newSize
func focusExit() -> void:
	submitted(text)

func changed(newText: String) -> void:
	bitmapFrame.brushRadius = clampi(int(newText), 1, 200)
