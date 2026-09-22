class_name SpriteData
extends Sprite2D

var gameView: GameView
# This stores all of the actively running compiled stacks in the sprite
var activeStacks: Array[ScriptStack] = []

var spritePos: Vector2:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)
