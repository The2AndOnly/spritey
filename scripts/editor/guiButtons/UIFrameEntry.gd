class_name FrameEntry
extends Button

var previewTexture
var bitmapEdit: BitmapFrame

@export var entryTexture: TextureRect

func _ready() -> void:
	entryTexture.texture = previewTexture
	pressed.connect(onPress)

func onPress() -> void:
	bitmapEdit.texture = previewTexture
	bitmapEdit.showFrame()
