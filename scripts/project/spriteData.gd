class_name SpriteData
extends Sprite2D

var gameView: GameView

var variables: Array[Variable] = []

var spritePos: Vector2 = Vector2.ZERO:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)

var direction: float = 90.0:
	set(value):
		direction = wrapf(value, -180.0, 180.0)
		rotation_degrees = direction - 90.0

var size: float = 100.0:
	set(value):
		size = max(0.0, value)
		updateSize()
var stretch: Vector2 = Vector2.ZERO:
	set(value):
		stretch = Vector2(max(-100.0, value.x), max(-100.0, value.y))
		updateSize()

var opacity: float = 100.0:
	set(value):
		opacity = clampf(value, 0.0, 100.0)
		modulate.a = opacity / 100.0

func updateSize() -> void:
	var baseScale: float = size / 100.0
	scale = Vector2(
		baseScale * ((stretch.x / 100.0) + 1.0),
		baseScale * ((stretch.y / 100.0) + 1.0)
	)
