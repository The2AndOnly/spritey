extends Button

const SPRITE_ENTRY: PackedScene = preload("uid://b4g1hm5dt1b7m")
const SPRITE_SELECTOR_GROUP: ButtonGroup = preload("uid://g30w58c26scg")

@export var spriteEntryContainer: GridContainer
@export var gameView: GameView
@export var editor: Editor

const ORANGE_MOE_1: Texture2D = preload("uid://dhmontm0rmbj8")
const ORANGE_MOE_2: Texture2D = preload("uid://duqpnvqse6a60")

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	var spriteEntry: SpriteEntry = SPRITE_ENTRY.instantiate()
	spriteEntry.editor = editor
	spriteEntry.button_group = SPRITE_SELECTOR_GROUP
	spriteEntry.button_pressed = true
	
	var sprite: Sprite = Sprite.new()
	sprite.gameView = gameView
	# Set up sprite textures
	var spriteFrames: SpriteFrames = SpriteFrames.new()
	sprite.sprite_frames = spriteFrames
	sprite.addFrame(ORANGE_MOE_1, "orange-moe-1")
	sprite.addFrame(ORANGE_MOE_2, "orange-moe-2")
	spriteEntry.previewTexture = sprite.sprite_frames.get_frame_texture(&"default", 0)
	# Find a unique name and ID for the sprite
	var names: Array[String] = []
	for i: Sprite in gameView.sprites:
		names.append(i.spriteName)
	sprite.spriteName = ParseData.findUniqueName("sprite1", names)
	
	gameView.add_child(sprite)
	spriteEntryContainer.add_child(spriteEntry)
	sprite.spritePos = Vector2.ZERO
	spriteEntry.sprite = sprite
	gameView.sprites.append(sprite)
	editor.selectedSprite = sprite
