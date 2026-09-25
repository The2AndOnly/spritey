class_name UISpriteEntry
extends Button

const SPRITE_SELECTOR_GROUP: ButtonGroup = preload("uid://g30w58c26scg")

var previewTexture: Texture2D
var sprite: Sprite
var editor: Editor

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
	
	button_group = SPRITE_SELECTOR_GROUP
	toggle_mode = true
	button_pressed = true
	
	pressed.connect(onPress)

func onPress() -> void:
	editor.selectedSprite = sprite
