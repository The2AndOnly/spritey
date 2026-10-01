class_name FrameEntry
extends Button

var textureData: Texture2D
var bitmapEdit: BitmapFrame
var frameID: int = -1

@export var entryTexture: TextureRect

func _ready() -> void:
	bitmapEdit.frameUpdated.connect(updateFrame)
	entryTexture.texture = textureData
	pressed.connect(onPress)

func onPress() -> void:
	bitmapEdit.showFrame(textureData, frameID)

func updateFrame(newFrame: Texture2D, croppedFrame: ImageTexture) -> void:
	if bitmapEdit.frameID != frameID: return
	textureData = newFrame
	entryTexture.texture = croppedFrame
