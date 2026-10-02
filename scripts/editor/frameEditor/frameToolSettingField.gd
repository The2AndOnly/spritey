extends LineEdit

@export var bitmapFrame: BitmapFrame
@export var editor: Editor
@export var setting: StringName

signal changeFrameName(newName: String)

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
		&"frameName":
			if newText.strip_edges() == "":
				text = editor.selectedSprite.frameNames[bitmapFrame.frameID]
				return
			var usedNames: Array[String] = editor.selectedSprite.frameNames.duplicate()
			usedNames.remove_at(bitmapFrame.frameID)
			var newName: String = ParseData.findUniqueName(newText, usedNames)
			text = newName
			changeFrameName.emit(newName)
func focusExit() -> void:
	submitted(text)

func changed(newText: String) -> void:
	match setting:
		&"brushSize":
			bitmapFrame.brushRadius = clampi(int(newText), 1, 200)
