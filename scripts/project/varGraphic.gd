class_name VarGraphic
extends Control

@export var nameLabel: Label
@export var valueLabel: Label
@export var dragArea: PanelContainer
var variable: Variable
var mouseTouching := false
var dragging := false
var disableDrag := false
var initialOffset: Vector2 = Vector2.ZERO
var gameView: GameView

func _ready() -> void:
	dragArea.mouse_entered.connect(mouseEntered)
	dragArea.mouse_exited.connect(mouseExited)

func _process(_delta: float) -> void:
	if !visible: return
	if Input.is_action_pressed(&"leftMouse"):
		if disableDrag: return
		if (!mouseTouching) and !dragging:
			disableDrag = true
			return
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
			move_to_front()
			dragging = true
		var targetPosition: Vector2 = get_global_mouse_position() + initialOffset
		global_position = Vector2(
			clampf(targetPosition.x, 0.0, gameView.size.x - dragArea.size.x),
			clampf(targetPosition.y, 0.0, gameView.size.y - dragArea.size.y)
		)
	elif dragging:
		dragging = false
		initialOffset = Vector2.ZERO
	else:
		disableDrag = false

func mouseEntered() -> void:
	mouseTouching = true

func mouseExited() -> void:
	mouseTouching = false
