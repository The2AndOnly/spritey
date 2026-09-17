class_name BlockDefinitions
extends Sprite2D

## INPUTS ARRAY:
# The items are in the order that the inputs are listed in blockStructures.gd
# The last item is either null, or the ScriptStack executing the block if it's waiting
# If the scriptStack's waitTime is -1.0, then whatever the block returns doesn't matter

## BLOCK RETURNS:
# false - Continue with next block
# true - Terminate stack
# positive float - pause the stack for that many seconds
# -1.0 - Stop waiting
# 0.0 - pause the stack for 1 frame

var gameView: GameView

## EVENTS

func event_keyboard(inputs: Array, eventData: Array[Variant]) -> bool:
	if inputs[0] == 0:
		# Any key
		return inputs[1] != eventData[1]
	# Specific key
	return inputs != eventData

func event_mouse(inputs: Array, eventData: Array[Variant]) -> bool:
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

func trans_glideToPosition(inputs: Array) -> float:
	var progress: float
	if inputs[3]:
		if inputs[3].waitTime == -1.0:
			# Finished gliding
			position = gameView.toLocalCoords(Vector2(inputs[1], inputs[2]))
			return -1.0
		else:
			# While gliding
			progress = inputs[0] - (inputs[3].waitTime / inputs[0])
			position = gameView.toLocalCoords(Vector2(
				lerpf(0.0, inputs[1], progress),
				lerpf(0.0, inputs[2], progress)
			))
			return inputs[3].waitTime
	else:
		# Initial execution
		progress = 0.0
		return inputs[0]

## CONTROL

func ctrl_wait(inputs: Array) -> float:
	if inputs[1]: return inputs[1].waitTime
	return inputs[0]

## EXPRESSIONS

func exp_add(inputs: Array) -> float:
	return inputs[0] + inputs[1]
func exp_subtract(inputs: Array) -> float:
	return inputs[0] - inputs[1]
func exp_multiply(inputs: Array) -> float:
	return inputs[0] * inputs[1]
func exp_divide(inputs: Array) -> float:
	return inputs[0] / inputs[1]

func exp_randomFloat(inputs: Array) -> float:
	return randf_range(inputs[0], inputs[1])
func exp_randomInt(inputs: Array) -> int:
	return randi_range(inputs[0], inputs[1])

func exp_join(inputs: Array) -> String:
	return inputs[0] + inputs[1]

## TEST

func test_print(inputs: Array) -> bool:
	print(inputs[0])
	return false
