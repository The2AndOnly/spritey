class_name FrameEntry
extends Button

var textureData: Texture2D
var bitmapEdit: BitmapFrame
var frameID: int = -1

@export var entryTexture: TextureRect
@export var nameLabel: Label
@export var sizeLabel: Label

func _ready() -> void:
	bitmapEdit.frameUpdated.connect(updateFrame)
	entryTexture.texture = textureData
	updateInfo()
	pressed.connect(onPress)

func onPress() -> void:
	bitmapEdit.showFrame(textureData, frameID)

func updateFrame(newFrame: Texture2D, croppedFrame: ImageTexture) -> void:
	if bitmapEdit.frameID != frameID: return
	textureData = newFrame
	entryTexture.texture = croppedFrame
	updateInfo()

func updateInfo() -> void:
	var textureSize: Vector2 = entryTexture.texture.get_size()
	sizeLabel.text = "%d x %d" % [textureSize.x, textureSize.y]
