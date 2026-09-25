extends Button

@export var spriteEntryContainer: GridContainer
@export var gameView: GameView
@export var editor: Editor

const ICON: Texture2D = preload("uid://tixr4qmml0y4")

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	var spriteEntry: UISpriteEntry = UISpriteEntry.new()
	spriteEntry.previewTexture = ICON
	spriteEntry.editor = editor
	spriteEntryContainer.add_child(spriteEntry)
	
	var sprite: Sprite = Sprite.new()
	sprite.texture = ICON
	sprite.gameView = gameView
	gameView.add_child(sprite)
	sprite.spritePos = Vector2.ZERO
	spriteEntry.sprite = sprite
	
	# Find a unique name and ID for the sprite
	var names: Array[String] = []
	var takenIDs: Array[int] = []
	for i: Sprite in gameView.sprites.values():
		names.append(i.name)
		takenIDs.append(i.spriteID)
	sprite.name = ParseData.findUniqueName("sprite1", names)
	var i: int = 0
	while takenIDs.has(i):
		i += 1
	sprite.spriteID = i
	
	gameView.sprites[i] = sprite
	editor.selectedSprite = sprite
