class_name ProjectStartButton
extends Button

@warning_ignore("unused_signal")
signal startProject()

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	startProject.emit()
