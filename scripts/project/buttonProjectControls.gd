extends Button

@export var gameView: GameView
@export var action: StringName

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	match action:
		&"start":
			gameView.stopAllStacks()
			gameView.deleteAllClones()
			gameView.event(&"event_start", [])
		&"stop":
			gameView.stopAllStacks()
	release_focus()
