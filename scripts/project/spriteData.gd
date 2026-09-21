class_name SpriteData
extends Sprite2D

var gameView: GameView

var spritePos: Vector2:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)
