class_name BlockDefinitions
extends SpriteData

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
# -3.0 - Enter nest
# -5.0 - Does nothing
# -6.0 - Exit process this frame

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
	spritePos.x = inputs[0]
	return -1.0
func trans_setY(inputs: Array) -> float:
	spritePos.y = inputs[0]
	return -1.0
func trans_changeX(inputs: Array) -> float:
	spritePos.x += inputs[0]
	return -1.0
func trans_changeY(inputs: Array) -> float:
	spritePos.y += inputs[0]
	return -1.0

func trans_XPos() -> float:
	return round(spritePos.x)
func trans_YPos() -> float:
	return round(spritePos.y)

func trans_setPosition(inputs: Array) -> float:
	spritePos = Vector2(inputs[0], inputs[1])
	return -1.0
func trans_setPositionOption(inputs: Array) -> float:
	spritePos = H_getPositionFromOption(inputs[0])
	return -1.0
func H_getPositionFromOption(option: int) -> Vector2:
	match option:
		0:
			return gameView.mousePosition
		1:
			return gameView.getRandomCoord()
	return spritePos

func trans_glideToPosition(inputs: Array) -> float:
	return H_glideToDestination(inputs, Vector2(inputs[1], inputs[2]))
func trans_glideToOption(inputs: Array) -> float:
	return H_glideToDestination(inputs, H_getPositionFromOption(inputs[1]))
func H_glideToDestination(inputs: Array, destination: Vector2) -> float:
	if currentStack.waitTime == -1.0:
		if currentStack.executeWait:
			# Finished gliding
			spritePos = currentStack.blockData[1]
			return 0.0
		else:
			# Initial execution
			var time: float = inputs[0]
			if time <= 0.0: return -1.0
			currentStack.executeWait = true
			currentStack.blockData.append_array([spritePos, destination, time])
			return time
	else:
		# While gliding
		spritePos = currentStack.blockData[0].lerp(
			currentStack.blockData[1],
			1.0 - (currentStack.waitTime / currentStack.blockData[2])
		)
		return currentStack.waitTime

func trans_setDirection(inputs: Array) -> float:
	direction = inputs[0]
	return -1.0
func trans_turnDegrees(inputs: Array) -> float:
	direction += inputs[0]
	return -1.0
func trans_pointTowards(inputs: Array) -> float:
	if inputs[0] == 0:
		look_at(get_global_mouse_position())
		direction = rotation_degrees + 90.0
	else:
		direction = randi_range(-179, 180)
	return -1.0
func trans_direction() -> float:
	return direction

## CONTROL

func ctrl_wait(inputs: Array) -> float:
	return inputs[0]

func ctrl_waitUntil(inputs: Array) -> float:
	if currentStack.executeWait:
		return -1.0 if inputs[0] else 1.0
	else:
		if inputs[0]: return -1.0
		currentStack.executeWait = true
		return 1.0

func ctrl_repeat(inputs: Array) -> float:
	if currentStack.currentBlock in currentStack.loops:
		# While looping
		currentStack.loopData[-1] -= 1.0
		if currentStack.loopData[-1] <= 0.0:
			# Loop finished
			currentStack.loops.remove_at(-1)
			currentStack.loopData.remove_at(-1)
			return -1.0
		else:
			# Continue loop
			return -3.0
	else:
		# Initial call
		if inputs[0] <= 0: return -1.0
		currentStack.loops.append(currentStack.currentBlock)
		currentStack.loopData.append(inputs[0])
		return -3.0
func ctrl_repeatSeconds(inputs: Array) -> float:
	if currentStack.currentBlock in currentStack.loops:
		# While looping
		currentStack.loopData[-1] -= get_process_delta_time()
		if currentStack.loopData[-1] <= 0.0:
			# Loop finished
			currentStack.loops.remove_at(-1)
			currentStack.loopData.remove_at(-1)
			return -1.0
		else:
			# Continue loop
			return -3.0
	else:
		# Initial call
		if inputs[0] <= 0.0: return -1.0
		currentStack.loops.append(currentStack.currentBlock)
		currentStack.loopData.append(inputs[0])
		return -3.0

func ctrl_while(inputs: Array) -> float:
	if currentStack.currentBlock in currentStack.loops:
		# While looping
		if inputs[0]:
			# Continue loop
			return -3.0
		else:
			# Loop finished
			currentStack.loops.remove_at(-1)
			return -1.0
	else:
		# Initial call
		if inputs[0]:
			currentStack.loops.append(currentStack.currentBlock)
			return -3.0
		else:
			return -1.0

func ctrl_forever() -> float:
	if !(currentStack.currentBlock in currentStack.loops):
		currentStack.loops.append(currentStack.currentBlock)
	return -3.0

func ctrl_if(inputs: Array) -> float:
	if inputs[0]:
		currentStack.exitNest.append(currentStack.currentBlock.nextBlock)
		return -3.0
	else:
		return -1.0

func ctrl_break() -> float:
	if !currentStack.loops.is_empty():
		currentStack.currentBlock.exitNests(currentStack)
		currentStack.currentBlock = currentStack.loops.back().nextBlock
		currentStack.loops.remove_at(-1)
		return -5.0
	else:
		return -1.0

func ctrl_continue() -> float:
	if !currentStack.loops.is_empty():
		currentStack.currentBlock.exitNests(currentStack)
		currentStack.currentBlock = currentStack.loops.back()
		return -6.0
	else:
		return -1.0

func ctrl_stopStacks(inputs: Array) -> float:
	if inputs[0] == 1: # Stop project
		gameView.stopProject.emit()
	currentStack.terminate()
	return -5.0

func ctrl_stopOther() -> float:
	for i: ScriptStack in activeStacks:
		if i == currentStack: continue
		i.terminate()
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
func exp_mod(inputs: Array) -> float:
	return fmod(inputs[0], inputs[1])
func exp_exponent(inputs: Array) -> float:
	return inputs[0] ** inputs[1]

func exp_and(inputs: Array) -> bool:
	return inputs[0] and inputs[1]
func exp_or(inputs: Array) -> bool:
	return inputs[0] or inputs[1]
func exp_not(inputs: Array) -> bool:
	return !inputs[0]

func exp_equals(inputs: Array) -> bool:
	var val1: String = inputs[0]
	var val2: String = inputs[1]
	if val1.is_valid_float() and val2.is_valid_float():
		# Necessary so it won't return false with 2.0 and 2
		return float(val1) == float(val2)
	return val1 == val2
func exp_greater(inputs: Array) -> bool:
	var val1: String = inputs[0]
	var val2: String = inputs[1]
	if val1.is_valid_float() and val2.is_valid_float():
		return float(val1) > float(val2)
	return val1 == val2
func exp_less(inputs: Array) -> bool:
	var val1: String = inputs[0]
	var val2: String = inputs[1]
	if val1.is_valid_float() and val2.is_valid_float():
		return float(val1) < float(val2)
	return val1 == val2

func exp_random(inputs: Array) -> Variant:
	if inputs[0] == 0:
		return randi_range(inputs[1], inputs[2])
	else:
		return randf_range(inputs[1], inputs[2])

func exp_join(inputs: Array) -> String:
	return inputs[0] + inputs[1]
func exp_charOf(inputs: Array) -> String:
	var index: int = inputs[0]
	var text: String = inputs[1]
	if index < 0:
		index += text.length()
	return text.substr(index, 1)
func exp_substring(inputs: Array) -> String:
	var index: int = inputs[0]
	var lastIndex: int = inputs[1]
	var text: String = inputs[2]
	if index < 0:
		index += text.length()
	if lastIndex < 0:
		lastIndex += text.length()
	if lastIndex > index:
		return text.substr(index, (lastIndex - index) + 1)
	else:
		return text.substr(lastIndex, (index - lastIndex) + 1)

func exp_textLength(inputs: Array) -> int:
	return inputs[0].length()

func exp_ternary(inputs: Array) -> String:
	return inputs[0] if inputs[1] else inputs[2]

func exp_abs(inputs: Array) -> float:
	return abs(inputs[0])
func exp_round(inputs: Array) -> int:
	return roundi(inputs[0])

func exp_math(inputs: Array) -> float:
	match inputs[0]:
		0: return floorf(inputs[1])
		1: return ceilf(inputs[1])
		2: return sin(deg_to_rad(inputs[1]))
		3: return cos(deg_to_rad(inputs[1]))
		4: return tan(deg_to_rad(inputs[1]))
		5: return rad_to_deg(asin(inputs[1]))
		6: return rad_to_deg(acos(inputs[1]))
		7: return rad_to_deg(atan(inputs[1]))
		8: return sqrt(inputs[1])
		9: return log(inputs[1])
		10: return log(inputs[1]) / log(10.0)
		11: return exp(inputs[1])
	return 0.0

## VISUALS

func vis_show() -> float:
	visible = true
	return -1.0
func vis_hide() -> float:
	visible = false
	return -1.0

func vis_visible() -> bool:
	return visible
func vis_setSize(inputs: Array) -> float:
	size = inputs[0]
	return -1.0
func vis_changeSize(inputs: Array) -> float:
	size += inputs[0]
	return -1.0
func vis_size() -> float:
	return size

func vis_setStretch(inputs: Array) -> float:
	if inputs[0] == 0:
		stretch.x = inputs[1]
	else:
		stretch.y = inputs[1]
	return -1.0
func vis_changeStretch(inputs: Array) -> float:
	if inputs[0] == 0:
		stretch.x += inputs[1]
	else:
		stretch.y += inputs[1]
	return -1.0
func vis_stretch(inputs: Array) -> float:
	if inputs[0] == 0:
		return stretch.x
	else:
		return stretch.y

func vis_setFlip(inputs: Array) -> float:
	if inputs[0] == 0:
		flip_h = inputs[1] == 0
	else:
		flip_v = inputs[1] == 0
	return -1.0
func vis_flip(inputs: Array) -> bool:
	if inputs[0] == 0:
		return flip_h
	else:
		return flip_v

func vis_setOpacity(inputs: Array) -> float:
	opacity = inputs[0]
	return -1.0
func vis_changeOpacity(inputs: Array) -> float:
	opacity += inputs[0]
	return -1.0
func vis_opacity() -> float:
	return opacity

## INTERACTION

func inter_pointerX() -> float:
	return round(gameView.mousePosition.x)
func inter_pointerY() -> float:
	return round(gameView.mousePosition.y)
func inter_keyPressed(inputs: Array) -> bool:
	var index: int = inputs[0]
	if index == 0:
		return Input.is_action_pressed(&"any") or Input.is_action_pressed(&"any2") or Input.is_action_pressed(&"any3")
	return Input.is_action_pressed(BlockStructures.keyOptions[index])

## TEST

func test_print(inputs: Array) -> float:
	print(inputs[0])
	return -1.0
