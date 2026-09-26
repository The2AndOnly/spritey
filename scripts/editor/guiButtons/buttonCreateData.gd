extends Button

@export var dialogBox: EditorDialogBox
@export var gameView: GameView
@export var editor: Editor
@export var data: StringName
@export var blockGroup: StringName

var titles: Dictionary[StringName, String] = {
	&"signal": "Create Signal"
}

func _ready() -> void:
	pressed.connect(onPress)
	dialogBox.popupClosed.connect(popupClosed)
	editor.switchBlockGroup.connect(switchBlockGroup)

func onPress() -> void:
	dialogBox.popup.emit(titles[data])

func popupClosed(confirmed: bool, input: String) -> void:
	if !confirmed: return
	match data:
		&"signal":
			if gameView.signals.has(input): return
			gameView.signals.append(input)
			editor.updateBlockOptions.emit()

func switchBlockGroup(newGroup: StringName) -> void:
	visible = newGroup == blockGroup
