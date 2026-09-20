class_name BlockDefinitions
extends Sprite2D

# Helper functions are marked with "H_"

## INPUTS ARRAY:
# The items are in the order that the inputs are listed in blockStructures.gd
# If a block has execute wait functions, it CAN NOT access these inputs again
# Execute wait blocks should store needed inputs in currentStack.blockData

## BLOCK RETURNS:
# Value blocks can return any value necessary
# Event blocks return true if the stack can begin
# Stack blocks return floats:
# > 0.0 - Pause the stack for that many seconds
# -1.0 - Move to next block / stop executing
# 0.0 - Pause the stack for 1 frame
# -2.0 - Terminate stack

var gameView: GameView
var currentStack: ScriptStack

## EVENTS

func event_keyboard(inputs: Array, eventData: Array[Variant]) -> bool:
	if inputs[0] == 0:
		# Any key
		return inputs[1] == eventData[1]
	# Specific key
	return inputs == eventData

func event_mouse(inputs: Array, eventData: Array[Variant]) -> bool:
	return inputs == eventData

## TRANSFORM

func trans_setX(inputs: Array) -> float:
	position.x = gameView.toLocalCoords(Vector2(inputs[0], 0.0)).x
	return -1.0
func trans_setY(inputs: Array) -> float:
	position.y = gameView.toLocalCoords(Vector2(0.0, inputs[0])).y
	return -1.0
func trans_changeX(inputs: Array) -> float:
	position.x += inputs[0]
	return -1.0
func trans_changeY(inputs: Array) -> float:
	position.y -= inputs[0]
	return -1.0

func trans_setPosition(inputs: Array) -> float:
	position = gameView.toLocalCoords(Vector2(inputs[0], inputs[1]))
	return -1.0
func trans_setPositionOption(inputs: Array) -> float:
	position = H_getPositionFromOption(inputs[0])
	return -1.0
func H_getPositionFromOption(option: int) -> Vector2:
	match option:
		0:
			return gameView.toLocalCoords(gameView.mousePosition)
		1:
			return gameView.getRandomCoord()
	return position

func trans_glideToPosition(inputs: Array) -> float:
	return H_glideToDestination(inputs, gameView.toLocalCoords(Vector2(inputs[1], inputs[2])))
func trans_glideToOption(inputs: Array) -> float:
	return H_glideToDestination(inputs, H_getPositionFromOption(inputs[1]))
func H_glideToDestination(inputs: Array, destination: Vector2) -> float:
	if currentStack.waitTime == -1.0:
		if currentStack.executeWait:
			# Finished gliding
			position = currentStack.blockData[1]
			return 0.0
		else:
			# Initial execution
			if inputs[0] <= 0.0: return -1.0
			currentStack.executeWait = true
			currentStack.blockData.append_array([position, destination, inputs[0]])
			return inputs[0]
	else:
		# While gliding
		position = currentStack.blockData[0].lerp(
			currentStack.blockData[1],
			1.0 - (currentStack.waitTime / currentStack.blockData[2])
		)
		return currentStack.waitTime

## CONTROL

func ctrl_wait(inputs: Array) -> float:
	return inputs[0]

func ctrl_repeat(inputs: Array) -> float:
	return -1.0

## EXPRESSIONS

func exp_add(inputs: Array) -> float:
	return inputs[0] + inputs[1]
func exp_subtract(inputs: Array) -> float:
	return inputs[0] - inputs[1]
func exp_multiply(inputs: Array) -> float:
	return inputs[0] * inputs[1]
func exp_divide(inputs: Array) -> float:
	return inputs[0] / inputs[1]

func exp_random(inputs: Array) -> Variant:
	if (inputs[0] is float) or (inputs[1] is float):
		return randf_range(inputs[0], inputs[1])
	return randi_range(inputs[0], inputs[1])

func exp_join(inputs: Array) -> String:
	return inputs[0] + inputs[1]

## TEST

func test_print(inputs: Array) -> float:
	print(inputs[0])
	return -1.0
