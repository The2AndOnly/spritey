class_name GameView
extends SubViewport

# EVENT DATA DOCS:
# event_keyboard: [key pressed, pressed/released]

@export var editor: Editor
const baseSize: Vector2 = Vector2(1280.0, 720.0)
# These are to optimize calculating coordinates
const halfBaseSize: Vector2 = baseSize / 2.0
@onready var halfSize: Vector2 = Vector2(size.x / 2.0, size.y / 2.0)
@onready var scaledSize: Vector2 = Vector2(size.x / baseSize.x, size.y / baseSize.y)
@onready var sizeMinusOne: Vector2 = size - Vector2i(1, 1)

var mousePosition: Vector2
func keyToString(key: Key) -> StringName:
	match key:
		KEY_SPACE: return &"space"
		KEY_UP: return &"up arrow"
		KEY_DOWN: return &"down arrow"
		KEY_LEFT: return &"left arrow"
		KEY_RIGHT: return &"right arrow"
		KEY_ENTER: return &"enter"
		KEY_Q: return &"Q"
		KEY_W: return &"W"
		KEY_E: return &"E"
		KEY_R: return &"R"
		KEY_T: return &"T"
		KEY_Y: return &"Y"
		KEY_U: return &"U"
		KEY_I: return &"I"
		KEY_O: return &"O"
		KEY_P: return &"P"
		KEY_A: return &"A"
		KEY_S: return &"S"
		KEY_D: return &"D"
		KEY_F: return &"F"
		KEY_G: return &"G"
		KEY_H: return &"H"
		KEY_J: return &"J"
		KEY_K: return &"K"
		KEY_L: return &"L"
		KEY_Z: return &"Z"
		KEY_X: return &"X"
		KEY_C: return &"C"
		KEY_V: return &"V"
		KEY_B: return &"B"
		KEY_N: return &"N"
		KEY_M: return &"M"
		KEY_0: return &"0"
		KEY_1: return &"1"
		KEY_2: return &"2"
		KEY_3: return &"3"
		KEY_4: return &"4"
		KEY_5: return &"5"
		KEY_6: return &"6"
		KEY_7: return &"7"
		KEY_8: return &"8"
		KEY_9: return &"9"
		_: return &"any"

@warning_ignore("unused_signal")
signal event(blockName: StringName, eventData: Array[Variant])
@warning_ignore("unused_signal")
signal stopProject()

func _ready() -> void:
	if editor: editor.setMousePosition()
	else: setMousePosition()

func _process(_delta: float) -> void:
	event.emit(&"test_process", [])

# Input is game coords, output is local coords
func toLocalCoords(position: Vector2) -> Vector2:
	return Vector2(
		(position.x * (scaledSize.x)) + (halfSize.x),
		(halfSize.y) - (position.y * (scaledSize.y))
	)
# Input is local coords, output is game coords
func toGameCoords(position: Vector2) -> Vector2:
	return Vector2(
		(position.x - halfSize.x) / scaledSize.x,
		(halfSize.y - position.y) / scaledSize.y
	)
func getRandomCoord() -> Vector2:
	return Vector2(
		randf_range(-halfBaseSize.x, halfBaseSize.x),
		randf_range(-halfBaseSize.y, halfBaseSize.y)
	)
func setMousePosition() -> void:
	mousePosition = toGameCoords(get_mouse_position())

# Send input events
func _input(inputEvent: InputEvent) -> void:
	if editor: if editor.currentView != &"sprites": return
	
	if inputEvent is InputEventKey:
		if inputEvent.is_echo(): return
		event.emit(&"event_keyboard", [
			BlockStructures.keyOptions.find(keyToString(inputEvent.physical_keycode)),
			0 if inputEvent.pressed else 1
		])
		return
	
	if inputEvent is InputEventMouseButton:
		if inputEvent.button_index > 2: return
		event.emit(&"event_mouse", [inputEvent.button_index - 1, 0 if inputEvent.pressed else 1])
		return
	
	# In the editor, mouse movement input is handled by editor.gd
	if editor: return
	if inputEvent is InputEventMouseMotion:
		setMousePosition()
