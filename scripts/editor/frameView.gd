extends SubViewport

@export var camera: Camera2D
const MinZoom: Vector2 = Vector2(0.5, 0.5)
const MaxZoom: Vector2 = Vector2(10.0, 10.0)

var cameraPanning := false
var initialMouse: Vector2 = Vector2.ZERO
var initialCameraPos: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_released(&"mouseWheelUp"):
		zoomCamera(true)
	elif event.is_action_released(&"mouseWheelDown"):
		zoomCamera(false)
	elif event.is_action_pressed(&"middleMouse"):
		cameraPanning = true
		initialMouse = get_mouse_position()
		initialCameraPos = camera.position
	elif event.is_action_released(&"middleMouse"):
		cameraPanning = false
	elif cameraPanning:
		if event is InputEventMouseMotion:
			camera.position = initialCameraPos + ((initialMouse - get_mouse_position()) / camera.zoom)

func zoomCamera(zoomIn: bool) -> void:
	var newZoom: Vector2 = camera.zoom
	if zoomIn:
		newZoom += Vector2(0.1, 0.1)
	else:
		newZoom -= Vector2(0.1, 0.1)
	camera.zoom = newZoom.clamp(MinZoom, MaxZoom)
