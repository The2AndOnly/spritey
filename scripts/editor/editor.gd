class_name Editor
extends Control

@export var gameView: GameView
@export var mousePosLabel: Label
const halfBaseSize: Vector2 = Vector2(1280.0, 720.0) / 2.0

var selectedSprite: Sprite
var currentView: StringName = &"sprites"
var clampedMousePos: Vector2 = Vector2.ZERO

var signals: Array[String] = ["signal1"]

@warning_ignore("unused_signal")
signal changedView(view: StringName)

func setMousePosition() -> void:
	gameView.setMousePosition()
	clampedMousePos = gameView.mousePosition.clamp(-halfBaseSize, halfBaseSize)
	gameView.mousePosition = clampedMousePos
	mousePosLabel.text = "%s, %d" % [roundi(clampedMousePos.x), roundi(clampedMousePos.y)]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		setMousePosition()
