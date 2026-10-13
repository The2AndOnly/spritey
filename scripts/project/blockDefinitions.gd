class_name BlockDefinitions
extends SpriteData

# Helper functions are marked with "H_"

## INPUTS ARRAY:
# The items are in the order that the inputs are listed in blockStructures.gd
# If a block has execute wait functions, it can NOT access these inputs again
# Execute wait blocks should store needed inputs in gameView.currentStack.blockData

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
# -7.0 - Enter nest2

## EVENTS

func event_keyboard(inputs: Array, eventData: Array[Variant]) -> bool:
	if inputs[0] == 0:
		# Any key
		return inputs[1] == eventData[1]
	# Specific key
	return inputs == eventData

func event_mouse(inputs: Array, eventData: Array[Variant]) -> bool:
	return inputs == eventData
func event_scrolled(inputs: Array, eventData: Array[Variant]) -> bool:
	return inputs == eventData

func event_clicked(inputs: Array, eventData: Array[Variant]) -> bool:
	if !SpriteCollision.spriteTouchingPoint(self, get_global_mouse_position(), gameView.spriteBoundingBox): return false
	return inputs == eventData

func event_signal(inputs: Array) -> float:
	gameView.event(&"event_receive", inputs)
	return -1.0

func event_signalAndWait(inputs: Array) -> float:
	if gameView.currentStack.executeWait:
		for i: ScriptStack in gameView.currentStack.createdStacks:
			if gameView.activeStacks.has(i):
				return 1.0
		return -1.0
	else:
		gameView.event(&"event_receive", inputs, true)
		gameView.currentStack.executeWait = true
		return 1.0

func event_receive(inputs: Array, eventData: Array[Variant]) -> bool:
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
	return spritePos.x
func trans_YPos() -> float:
	return spritePos.y

func trans_setPosition(inputs: Array) -> float:
	spritePos = Vector2(inputs[0], inputs[1])
	return -1.0
func trans_setPositionOption(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is int:
		spritePos = H_getPositionFromOption(option)
	else:
		spritePos = option.spritePos
	return -1.0
func H_getPositionFromOption(option: int) -> Vector2:
	match option:
		0:
			return gameView.mousePosition.round()
		1:
			return Vector2(randi_range(-640, 640), randi_range(-360, 360))
	return spritePos

func trans_moveSteps(inputs: Array) -> float:
	var rotated: Vector2 = Vector2.RIGHT.rotated(rotation)
	rotated.y = -rotated.y
	spritePos += rotated * inputs[0]
	return -1.0

func trans_glideToPosition(inputs: Array) -> float:
	return H_glideToDestination(inputs, Vector2(inputs[1], inputs[2]))
func trans_glideToOption(inputs: Array) -> float:
	var option: Variant = inputs[1]
	if option is Sprite:
		return H_glideToDestination(inputs, option.spritePos)
	else:
		return H_glideToDestination(inputs, H_getPositionFromOption(inputs[1]))
func H_glideToDestination(inputs: Array, destination: Vector2) -> float:
	if gameView.currentStack.waitTime == -1.0:
		if gameView.currentStack.executeWait:
			# Finished gliding
			spritePos = gameView.currentStack.blockData[1]
			return 0.0
		else:
			# Initial execution
			var time: float = inputs[0]
			if time <= 0.0: return -1.0
			gameView.currentStack.executeWait = true
			gameView.currentStack.blockData.append_array([spritePos, destination, time])
			return time
	else:
		# While gliding
		spritePos = gameView.currentStack.blockData[0].lerp(
			gameView.currentStack.blockData[1],
			1.0 - (gameView.currentStack.waitTime / gameView.currentStack.blockData[2])
		)
		return gameView.currentStack.waitTime

func trans_setDirection(inputs: Array) -> float:
	direction = inputs[0]
	return -1.0
func trans_turnDegrees(inputs: Array) -> float:
	direction += inputs[0]
	return -1.0
func trans_pointTowards(inputs: Array) -> float:
	if inputs[0] == 0:
		look_at(get_global_mouse_position())
		direction = snappedf(rotation_degrees + 90.0, 0.1)
	else:
		direction = randi_range(-179, 180)
	return -1.0
func trans_direction() -> float:
	return direction

## CONTROL

func ctrl_wait(inputs: Array) -> float:
	return inputs[0]

func ctrl_waitUntil(inputs: Array) -> float:
	if gameView.currentStack.executeWait:
		return -1.0 if inputs[0] else 1.0
	else:
		if inputs[0]: return -1.0
		gameView.currentStack.executeWait = true
		return 1.0

func ctrl_repeat(inputs: Array) -> float:
	if gameView.currentStack.currentBlock in gameView.currentStack.loops:
		# While looping
		gameView.currentStack.loopData[-1] -= 1.0
		if gameView.currentStack.loopData[-1] <= 0.0:
			# Loop finished
			gameView.currentStack.loops.remove_at(-1)
			gameView.currentStack.loopData.remove_at(-1)
			return -1.0
		else:
			# Continue loop
			return -3.0
	else:
		# Initial call
		if inputs[0] <= 0: return -1.0
		gameView.currentStack.loops.append(gameView.currentStack.currentBlock)
		gameView.currentStack.loopData.append(inputs[0])
		return -3.0
func ctrl_repeatSeconds(inputs: Array) -> float:
	if gameView.currentStack.currentBlock in gameView.currentStack.loops:
		# While looping
		gameView.currentStack.loopData[-1] -= gameView.delta
		if gameView.currentStack.loopData[-1] <= 0.0:
			# Loop finished
			gameView.currentStack.loops.remove_at(-1)
			gameView.currentStack.loopData.remove_at(-1)
			return -1.0
		else:
			# Continue loop
			return -3.0
	else:
		# Initial call
		if inputs[0] <= 0.0: return -1.0
		gameView.currentStack.loops.append(gameView.currentStack.currentBlock)
		gameView.currentStack.loopData.append(inputs[0])
		return -3.0

func ctrl_while(inputs: Array) -> float:
	if gameView.currentStack.currentBlock in gameView.currentStack.loops:
		# While looping
		if inputs[0]:
			# Continue loop
			return -3.0
		else:
			# Loop finished
			gameView.currentStack.loops.remove_at(-1)
			return -1.0
	else:
		# Initial call
		if inputs[0]:
			gameView.currentStack.loops.append(gameView.currentStack.currentBlock)
			return -3.0
		else:
			return -1.0

func ctrl_forever() -> float:
	if !(gameView.currentStack.currentBlock in gameView.currentStack.loops):
		gameView.currentStack.loops.append(gameView.currentStack.currentBlock)
	return -3.0

func ctrl_if(inputs: Array) -> float:
	if inputs[0]:
		var exitNest: CompiledBlock = gameView.currentStack.currentBlock.nextBlock
		if exitNest:
			gameView.currentStack.exitNest.append(exitNest)
		return -3.0
	else:
		return -1.0

func ctrl_ifElse(inputs: Array) -> float:
	var exitNest: CompiledBlock = gameView.currentStack.currentBlock.nextBlock
	if exitNest:
		gameView.currentStack.exitNest.append(exitNest)
	if inputs[0]:
		return -3.0
	else:
		return -7.0

func ctrl_break() -> float:
	if !gameView.currentStack.loops.is_empty():
		gameView.currentStack.currentBlock.exitNests(gameView.currentStack)
		gameView.currentStack.currentBlock = gameView.currentStack.loops.back().nextBlock
		gameView.currentStack.loops.remove_at(-1)
		return -5.0
	else:
		return -1.0

func ctrl_continue() -> float:
	if !gameView.currentStack.loops.is_empty():
		gameView.currentStack.currentBlock.exitNests(gameView.currentStack)
		gameView.currentStack.currentBlock = gameView.currentStack.loops.back()
		return -6.0
	else:
		return -1.0

func ctrl_stopStacks(inputs: Array) -> float:
	if inputs[0] == 1: # Stop project
		gameView.stopAllStacks()
	gameView.currentStack.terminate()
	return -5.0

func ctrl_stopOther() -> float:
	for i: ScriptStack in gameView.activeStacks:
		if i.sprite != self: continue
		if i == gameView.currentStack: continue
		i.terminate()
	return -1.0

func ctrl_cloneStartName(inputs: Array, eventData: Array[Variant]) -> bool:
	return inputs == eventData

func ctrl_createClone(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is int:
		H_clone(self, spriteName)
	else:
		H_clone(option, option.spriteName)
	return -1.0
func ctrl_createCloneName(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is int:
		H_clone(self, inputs[1])
	else:
		H_clone(option, inputs[1])
	return -1.0
func H_clone(sprite: Sprite, cloneName: String) -> void:
	if gameView.cloneCount >= 500: return
	gameView.cloneCount += 1
	var clone: Sprite
	var targetMaster: Sprite = sprite.master
	clone = sprite.duplicate()
	clone.original = sprite
	clone.spriteName = cloneName
	var cloneID: int = targetMaster.spriteID + 1
	while gameView.idToSprite.has(cloneID): cloneID += 1
	clone.spriteID = cloneID
	targetMaster.clones.append(clone)
	gameView.add_child(clone)
	gameView.sprites.append(clone)
	gameView.triggerCloneEvent(clone)

func ctrl_deleteThisClone() -> float:
	# Checking if "original" exists
	if original:
		master.clones.erase(self)
		gameView.sprites.erase(self)
		gameView.idToSprite.erase(spriteID)
		queue_free()
		gameView.cloneCount -= 1
	return -1.0

func ctrl_deleteClones(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is int:
		if option == 0:
			gameView.deleteSpriteClones(self)
		else:
			gameView.deleteAllClones()
	else:
		gameView.deleteSpriteClones(option)
	return -1.0

func ctrl_deleteCloneName(inputs: Array) -> float:
	var cloneName: String = inputs[0]
	var sprites: Array[Sprite] = gameView.sprites
	var queueDelete: Array[Sprite] = []
	for i: int in range(sprites.size() - 1, -1, -1):
		var targetClones: Array[Sprite] = sprites[i].clones
		for j: int in range(targetClones.size() - 1, -1, -1):
			var clone: Sprite = targetClones[j]
			if clone.spriteName == cloneName:
				clone.queue_free()
				gameView.cloneCount -= 1
				targetClones.remove_at(j)
				queueDelete.append(clone)
	for i: Sprite in queueDelete:
		gameView.idToSprite.erase(i.spriteID)
		gameView.sprites.erase(i)
	return -1.0

func ctrl_setCloneName(inputs: Array) -> float:
	if original: spriteName = inputs[0]
	return -1.0
func ctrl_cloneName() -> String:
	return spriteName

func ctrl_cloneCount(inputs: Array) -> int:
	var option: Variant = inputs[0]
	if option is int:
		if option == 0:
			option = master
		else:
			return gameView.cloneCount
	return option.clones.size()
func ctrl_isClone() -> bool:
	return original != null

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
	return fposmod(inputs[0], inputs[1])

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
		index = maxi(index, 0)
	elif index > 0:
		index -= 1
	else:
		return ""
	return text.substr(index, 1)
func exp_substring(inputs: Array) -> String:
	var index: int = inputs[0]
	var lastIndex: int = inputs[1]
	var text: String = inputs[2]
	if index < 0:
		index += text.length()
		index = maxi(index, 0)
	elif index > 0:
		index -= 1
		index = mini(index, text.length() - 1)
	else:
		return ""
	if lastIndex < 0:
		lastIndex += text.length()
		lastIndex = maxi(lastIndex, 0)
	elif lastIndex > 0:
		lastIndex -= 1
	else:
		return ""
	if lastIndex > index:
		return text.substr(index, (lastIndex - index) + 1)
	else:
		return text.substr(lastIndex, (index - lastIndex) + 1).reverse()

func exp_textLength(inputs: Array) -> int:
	return inputs[0].length()

func exp_textContains(inputs: Array) -> bool:
	var contains: String = inputs[1]
	if contains == "": return true
	return inputs[0].contains(contains)

func exp_inCase(inputs: Array) -> String:
	if inputs[1] == 0:
		return inputs[0].to_upper()
	return inputs[0].to_lower()

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
		8: return sign(inputs[1])
		9: return sqrt(inputs[1])
		10: return log(inputs[1])
		11: return log(inputs[1]) / log(10.0)
		12: return exp(inputs[1])
		13: return ~int(inputs[1])
	return 0.0

func exp_doubleMath(inputs: Array) -> float:
	match inputs[0]:
		0: return maxf(inputs[1], inputs[2])
		1: return minf(inputs[1], inputs[2])
		2: return inputs[1] ** inputs[2]
		3: return atan2(inputs[1], inputs[2])
		4: return sqrt((inputs[1] ** 2) + (inputs[2] ** 2))
		5: return int(inputs[1]) & int(inputs[2])
		6: return int(inputs[1]) | int(inputs[2])
		7: return int(inputs[1]) ^ int(inputs[2])
		8: return int(inputs[1]) << int(inputs[2])
		9: return int(inputs[1]) >> int(inputs[2])
	return 0.0

## VISUALS

func vis_show() -> float:
	visible = true
	messageBox.modulate.a = 1.0
	return -1.0
func vis_hide() -> float:
	visible = false
	messageBox.modulate.a = 0.0
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
		sizeMultiplier.x = -1.0 if inputs[1] == 0 else 1.0
	else:
		sizeMultiplier.y = -1.0 if inputs[1] == 0 else 1.0
	updateSize()
	updateBoundingBox()
	return -1.0
func vis_flip(inputs: Array) -> bool:
	if inputs[0] == 0:
		return sizeMultiplier.x == -1.0
	else:
		return sizeMultiplier.y == -1.0

func vis_setOpacity(inputs: Array) -> float:
	opacity = inputs[0]
	return -1.0
func vis_changeOpacity(inputs: Array) -> float:
	opacity += inputs[0]
	return -1.0
func vis_opacity() -> float:
	return opacity

func vis_changeFrame(inputs: Array) -> float:
	spriteFrame = posmod(spriteFrame + inputs[0], frameNames.size())
	return -1.0
func vis_setFrame(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is String:
		if option.is_valid_float():
			spriteFrame = posmod(int(option) - 1, frameNames.size())
		else:
			spriteFrame = frameNames.find(option)
	else:
		spriteFrame = inputs[0]
	return -1.0
func vis_frame(inputs: Array) -> Variant:
	match inputs[0]:
		0:
			return spriteFrame + 1
		1:
			return frameNames[spriteFrame]
		2:
			return int(croppedFrames[spriteFrame].get_size().x)
		3:
			return int(croppedFrames[spriteFrame].get_size().y)
	return ""

func vis_setLayerOption(inputs: Array) -> float:
	if inputs[0] == 0:
		gameView.move_child(self, -1)
	else:
		gameView.move_child(self, 0)
	return -1.0

func vis_setZIndex(inputs: Array) -> float:
	z_index = inputs[0]
	return -1.0
func vis_changeZIndex(inputs: Array) -> float:
	z_index += inputs[0]
	return -1.0
func vis_ZIndex() -> int:
	return z_index

func vis_showMessage(inputs: Array) -> float:
	H_showMessage(inputs[0])
	return -1.0
func vis_showMessageSeconds(inputs: Array) -> float:
	var currentStack: ScriptStack = gameView.currentStack
	if currentStack.waitTime == -1.0:
		if currentStack.executeWait:
			messageBox.hideAfterTwoFrames(currentStack.blockData[-1])
			return -1.0
		else:
			var time: float = inputs[1]
			if time <= 0.0:
				messageBox.visible = false
				return -1.0
			H_showMessage(inputs[0])
			currentStack.executeWait = true
			currentStack.blockData.append(messageBox.currentCall)
			return time
	else: return currentStack.waitTime
func H_showMessage(text: String) -> void:
	if text.strip_edges() == "":
		messageBox.visible = false
	else:
		messageBox.visible = true
		messageBox.currentCall += 1
		messageBox.text = text
		H_fixMessageMinimumSize.call_deferred()
		positionMessage.call_deferred()
func H_fixMessageMinimumSize() -> void:
	if messageBox.size.x < 320.0:
		messageBox.size.x = 320.0
	if messageBox.size.y < 258.0:
		messageBox.size.y = 258.0

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

func inter_mousePressed(inputs: Array) -> bool:
	if inputs[0] == 0:
		return Input.is_action_pressed(&"leftMouse")
	else:
		return Input.is_action_pressed(&"rightMouse")

func inter_distanceTo(inputs: Array) -> float:
	var option: Variant = inputs[0]
	if option is int:
		if option == 0:
			return spritePos.round().distance_to(gameView.mousePosition.round())
		else:
			option = master
	return spritePos.round().distance_to(option.spritePos.round())
func inter_distanceToCoord(inputs: Array) -> float:
	return spritePos.round().distance_to(Vector2(inputs[0], inputs[1]).round())

func inter_localTime(inputs: Array) -> int:
	var date: Dictionary = Time.get_datetime_dict_from_system(false)
	match inputs[0]:
		0: return date["year"]
		1: return date["month"]
		2: return date["day"]
		3: return date["weekday"] + 1
		4: return date["hour"]
		5: return date["minute"]
		6: return date["second"]
		_: return 0
func inter_timeSince1970() -> float:
	return Time.get_unix_time_from_system()

func inter_deltaTime() -> float:
	return gameView.delta

func inter_touching(inputs: Array) -> bool:
	if !visible: return false
	var option: Variant = inputs[0]
	if option is int:
		if option == 0:
			return SpriteCollision.spriteTouchingPoint(self, get_global_mouse_position(), gameView.spriteBoundingBox)
		else:
			option = master
	return SpriteCollision.spritesTouching(self, option, gameView.spriteBoundingBox, gameView.idToSprite)
func inter_touchingName(inputs: Array) -> bool:
	if !visible: return false
	var option: Variant = inputs[0]
	if option is int:
		option = master
	return SpriteCollision.spritesTouching(self, option, gameView.spriteBoundingBox, gameView.idToSprite, true, inputs[1])
func inter_touchingPoint(inputs: Array) -> bool:
	var option: Variant = inputs[0]
	if option is int:
		option = self
	if !option.visible: return false
	return SpriteCollision.spriteTouchingPoint(option, gameView.toLocalCoords(Vector2(inputs[1], inputs[2])), gameView.spriteBoundingBox)

## VARIABLES

# Global variables and local variables on original sprites will use the variable object directly
# Local variables on clones use their own dictionary of values
func var_value(inputs: Array) -> Variant:
	var variable: Variable = inputs[0]
	if variable.sprite:
		if gameView.currentStack.cloned:
			return localValues[variable]
	return variable.value
func var_setTo(inputs: Array) -> float:
	var variable: Variable = inputs[0]
	if variable.sprite:
		if gameView.currentStack.cloned:
			localValues[variable] = inputs[1]
			return -1.0
	variable.value = inputs[1]
	return -1.0
func var_changeBy(inputs: Array) -> float:
	var variable: Variable = inputs[0]
	if variable.sprite:
		if gameView.currentStack.cloned:
			localValues[variable] = str(float(localValues[variable]) + inputs[1])
			return -1.0
	variable.value = str(float(variable.value) + inputs[1])
	return -1.0
func var_showVar(inputs: Array) -> float:
	inputs[0].visible = true
	return -1.0
func var_hideVar(inputs: Array) -> float:
	inputs[0].visible = false
	return -1.0

## TEST

func test_print(inputs: Array) -> float:
	print(inputs[0])
	return -1.0
