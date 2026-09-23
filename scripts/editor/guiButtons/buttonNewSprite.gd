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
	editor.selectedSprite = sprite
