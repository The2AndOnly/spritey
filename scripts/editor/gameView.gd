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

var sprites: Dictionary[int, Sprite] = {}
# Index is the ID of the signal
var signals: Array[String] = ["signal1"]
var mousePosition: Vector2
# Stores key names to their index in BlockStructures.keyOptions
var actionToIndex: Dictionary[StringName, int] = {}

@warning_ignore("unused_signal")
signal event(blockName: StringName, eventData: Array[Variant])
@warning_ignore("unused_signal")
signal stopProject()

func _ready() -> void:
	if editor: editor.setMousePosition()
	else: setMousePosition()
	for i: int in range(BlockStructures.keyOptions.size()):
		actionToIndex[BlockStructures.keyOptions[i]] = i

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
		event.emit(&"event_keyboard", [0, 0 if inputEvent.pressed else 1]) # Any key
		for i: StringName in actionToIndex:
			if inputEvent.is_action(i) and (i != &"any"):
				event.emit(&"event_keyboard", [
					actionToIndex[i],
					0 if inputEvent.pressed else 1
				])
				break
		return
	
	if inputEvent is InputEventMouseButton:
		if inputEvent.button_index > 2: return
		event.emit(&"event_mouse", [inputEvent.button_index - 1, 0 if inputEvent.pressed else 1])
		return
	
	# In the editor, mouse movement input is handled by editor.gd
	if editor: return
	if inputEvent is InputEventMouseMotion:
		setMousePosition()
