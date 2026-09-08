extends Button

@export var gameView: GameView

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	gameView.event.emit(&"event_start")
