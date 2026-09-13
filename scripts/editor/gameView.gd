class_name GameView
extends SubViewport

# EVENT DATA DOCS:
# event_keyboard: [key pressed, pressed/released]

@export var editor: Editor
func keyToString(key: Key) -> StringName:
	match key:
		KEY_SPACE: return &"space"
		KEY_UP: return &"up arrow"
		KEY_DOWN: return &"down arrow"
		KEY_LEFT: return &"left arrow"
		KEY_RIGHT: return &"right arrow"
		KEY_ENTER: return &"enter"
		_: return &"any"

@warning_ignore("unused_signal")
signal event(blockName: StringName, eventData: Array[Variant])

func getCoord(x: float, y: float) -> Vector2:
	return (size / 2.0) + Vector2(x, -y)

# Send keyboard events
func _input(inputEvent: InputEvent) -> void:
	if editor:
		if editor.currentView != &"sprites": return
	if inputEvent is InputEventKey:
		if inputEvent.is_echo(): return
		event.emit(&"event_keyboard", [
			BlockStructures.keyOptions.find(keyToString(inputEvent.physical_keycode)),
			0 if inputEvent.pressed else 1
		])
