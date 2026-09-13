extends Button

@export var spriteEntryContainer: GridContainer
@export var gameView: GameView
@export var editor: Editor

const ICON = preload("uid://d0v5t1dg4hf3k")

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
	sprite.position = gameView.getCoord(0.0, 0.0)
	
	spriteEntry.sprite = sprite
	editor.selectedSprite = sprite
