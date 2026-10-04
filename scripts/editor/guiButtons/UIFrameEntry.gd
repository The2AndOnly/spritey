class_name FrameEntry
extends Button

var textureData: Texture2D
var sprite: Sprite
var bitmapEdit: BitmapFrame
var frameID: int = -1
var nameField: LineEdit

@export var entryTexture: TextureRect
@export var nameLabel: Label
@export var sizeLabel: Label
@export var idLabel: Label

func _ready() -> void:
	bitmapEdit.frameUpdated.connect(updateFrame)
	entryTexture.texture = ParseData.cropTexture(textureData)
	nameField.changeFrameName.connect(updateName)
	updateInfo()
	pressed.connect(onPress)

func onPress() -> void:
	bitmapEdit.showFrame(textureData, frameID)
	nameField.text = nameLabel.text
	sprite.frame = frameID

func updateFrame(newFrame: Texture2D) -> void:
	if bitmapEdit.frameID != frameID: return
	textureData = newFrame
	entryTexture.texture = ParseData.cropTexture(newFrame)
	sprite.sprite_frames.set_frame(&"default", frameID, newFrame)
	sprite.frameSizes[frameID] = Vector2i(entryTexture.texture.get_size())
	updateInfo()

func updateName(newName: String) -> void:
	if bitmapEdit.frameID != frameID: return
	sprite.frameNames[frameID] = newName
	updateInfo()

func updateInfo() -> void:
	var textureSize: Vector2i = sprite.frameSizes[frameID]
	sizeLabel.text = "%d x %d" % [textureSize.x, textureSize.y]
	nameLabel.text = sprite.frameNames[frameID]
	idLabel.text = str(frameID + 1)
