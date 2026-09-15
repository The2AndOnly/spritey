class_name Editor
extends Control

@export var gameView: GameView
@export var scriptView: SubViewport
@export var mousePosLabel: Label
const halfBaseSize: Vector2 = Vector2(1280.0, 720.0) / 2.0

var selectedSprite: Sprite
var currentView: StringName = &"sprites":
	set(value):
		currentView = value
		changedView.emit(value)
var clampedMousePos: Vector2 = Vector2.ZERO
# Having this set disables interaction with several things
var uiFocused: Control = null:
	set(value):
		uiFocused = value
		changedFocus.emit(value)

var signals: Array[String] = ["signal1"]

signal changedView(view: StringName)
signal changedFocus(newFocus: Control)

func setMousePosition() -> void:
	gameView.setMousePosition()
	clampedMousePos = gameView.mousePosition.clamp(-halfBaseSize, halfBaseSize)
	gameView.mousePosition = clampedMousePos
	mousePosLabel.text = "%s, %d" % [roundi(clampedMousePos.x), roundi(clampedMousePos.y)]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		setMousePosition()
