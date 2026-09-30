extends SubViewport

@export var camera: Camera2D
@export var dragDetector: Area2D
const MinZoom: Vector2 = Vector2(0.2, 0.2)
const MaxZoom: Vector2 = Vector2(1.8, 1.8)

var cameraPanning := false
var initialMouse: Vector2 = Vector2.ZERO
var initialCameraPos: Vector2 = Vector2.ZERO

func _ready() -> void:
	dragDetector.input_event.connect(dragInput)

func _input(event: InputEvent) -> void:
	if event.is_action_released(&"mouseWheelUp"):
		zoomCamera(true)
	elif event.is_action_released(&"mouseWheelDown"):
		zoomCamera(false)
	elif cameraPanning:
		if event is InputEventMouseMotion:
			camera.position = initialCameraPos + ((initialMouse - get_mouse_position()) / camera.zoom)
		elif event.is_action_released(&"leftMouse"):
			cameraPanning = false

func zoomCamera(zoomIn: bool) -> void:
	var newZoom: Vector2 = camera.zoom
	if zoomIn:
		newZoom += Vector2(0.1, 0.1)
	else:
		newZoom -= Vector2(0.1, 0.1)
	camera.zoom = newZoom.clamp(MinZoom, MaxZoom)

func dragInput(_viewport: Node, event: InputEvent, _shapeIdx: int) -> void:
	if event.is_action_pressed(&"leftMouse") and !cameraPanning:
		cameraPanning = true
		initialMouse = get_mouse_position()
		initialCameraPos = camera.position
