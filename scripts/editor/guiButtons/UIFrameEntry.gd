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
	entryTexture.texture = ParseData.cropTexture(textureData.get_image())
	nameField.changeFrameName.connect(updateName)
	updateInfo()
	pressed.connect(onPress)

func onPress() -> void:
	bitmapEdit.showFrame(textureData, frameID)
	nameField.text = nameLabel.text
	sprite.spriteFrame = frameID

# After making a change to the sprite's texture
func updateFrame(newFrame: Texture2D) -> void:
	if bitmapEdit.frameID != frameID: return
	textureData = newFrame
	sprite.sprite_frames.set_frame(&"default", frameID, newFrame)
	var image: Image = newFrame.get_image()
	var cropped: Texture2D = ParseData.cropTexture(image)
	sprite.croppedFrames[frameID] = cropped
	sprite.frameImages[frameID] = image
	sprite.frameTextures[frameID] = newFrame
	entryTexture.texture = cropped
	fixSpriteBoundingBox()
	updateInfo()

func updateName(newName: String) -> void:
	if bitmapEdit.frameID != frameID: return
	sprite.frameNames[frameID] = newName
	updateInfo()

func updateInfo() -> void:
	var textureSize: Vector2i = Vector2i(sprite.croppedFrames[frameID].get_size())
	sizeLabel.text = "%d x %d" % [textureSize.x, textureSize.y]
	nameLabel.text = sprite.frameNames[frameID]
	idLabel.text = str(frameID + 1)

func fixSpriteBoundingBox() -> void:
	sprite.get_child(frameID).queue_free()
	var croppedImage: Rect2i = textureData.get_image().get_used_rect()
	var newShape: CollisionShape2D = ParseData.imageRectToCollision(croppedImage)
	sprite.add_child(newShape)
	sprite.move_child(newShape, frameID)
	sprite.frameCollisions[frameID] = newShape
