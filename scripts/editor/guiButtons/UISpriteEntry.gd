class_name SpriteEntry
extends Button

var previewTexture: Texture2D
var sprite: Sprite
var editor: Editor

@export var entryTexture: TextureRect

func _ready() -> void:
	entryTexture.texture = previewTexture
	pressed.connect(onPress)

func onPress() -> void:
	editor.selectedSprite = sprite
