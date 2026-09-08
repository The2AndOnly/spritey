class_name UISpriteEntry
extends Button

var previewTexture: Texture2D
var sprite: Sprite

@onready var textureMargin: MarginContainer = MarginContainer.new()
@onready var texture: TextureRect = TextureRect.new()

func _ready() -> void:
	custom_minimum_size = Vector2(150.0, 150.0)
	# setup texture
	add_child(textureMargin)
	textureMargin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	textureMargin.add_theme_constant_override(&"margin_left", 15)
	textureMargin.add_theme_constant_override(&"margin_right", 15)
	textureMargin.add_theme_constant_override(&"margin_top", 15)
	textureMargin.add_theme_constant_override(&"margin_bottom", 15)
	textureMargin.add_child(texture)
	texture.texture = previewTexture
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	pressed.connect(onPress)

func onPress() -> void:
	owner.selectedSprite = sprite
