extends Button

@export var gameView: GameView
@export var action: StringName

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	match action:
		&"start":
			gameView.event.emit(&"event_start", [])
		&"stop":
			gameView.stopProject.emit()
	release_focus()
