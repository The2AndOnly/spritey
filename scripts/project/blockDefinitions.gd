class_name BlockDefinitions
extends Sprite2D

# If a block returns true, then it stops executing that stack

var gameView: GameView

## EVENTS

func event_keyboard(inputs: Array, eventData: Array[Variant]) -> bool:
	if inputs[0] == 0:
		# Any key
		return inputs[1] != eventData[1]
	# Specific key
	return inputs != eventData

## TRANSFORM

func trans_setX(inputs: Array) -> bool:
	position.x = gameView.toLocalCoords(Vector2(inputs[0], 0.0)).x
	return false

func trans_setY(inputs: Array) -> bool:
	position.y = gameView.toLocalCoords(Vector2(0.0, inputs[0])).y
	return false

func trans_changeX(inputs: Array) -> bool:
	position.x += inputs[0]
	return false

func trans_changeY(inputs: Array) -> bool:
	position.y -= inputs[0]
	return false

func trans_setPosition(inputs: Array) -> bool:
	position = gameView.toLocalCoords(Vector2(inputs[0], inputs[1]))
	return false

func trans_setPositionOption(inputs: Array) -> bool:
	match inputs[0]:
		0:
			position = gameView.toLocalCoords(gameView.mousePosition)
		1:
			position = gameView.getRandomCoord()
	return false
