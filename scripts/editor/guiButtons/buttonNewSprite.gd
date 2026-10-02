extends Button

const SPRITE_ENTRY: PackedScene = preload("uid://b4g1hm5dt1b7m")
const SPRITE_SELECTOR_GROUP: ButtonGroup = preload("uid://g30w58c26scg")

@export var spriteEntryContainer: GridContainer
@export var gameView: GameView
@export var editor: Editor

const DEFAULT_FRAME: Texture2D = preload("uid://dhmontm0rmbj8")

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	var spriteEntry: SpriteEntry = SPRITE_ENTRY.instantiate()
	spriteEntry.previewTexture = DEFAULT_FRAME
	spriteEntry.editor = editor
	spriteEntryContainer.add_child(spriteEntry)
	spriteEntry.button_group = SPRITE_SELECTOR_GROUP
	spriteEntry.button_pressed = true
	
	var sprite: Sprite = Sprite.new()
	var spriteFrames: SpriteFrames = SpriteFrames.new()
	spriteFrames.add_frame(&"default", DEFAULT_FRAME)
	sprite.sprite_frames = spriteFrames
	sprite.gameView = gameView
	# Find a unique name and ID for the sprite
	var names: Array[String] = []
	for i: Sprite in gameView.sprites:
		names.append(i.spriteName)
	sprite.spriteName = ParseData.findUniqueName("sprite1", names)
	
	gameView.add_child(sprite)
	sprite.spritePos = Vector2.ZERO
	spriteEntry.sprite = sprite
	gameView.sprites.append(sprite)
	editor.selectedSprite = sprite
