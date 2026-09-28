extends Button

@export var dialogBox: EditorDialogBox
@export var gameView: GameView
@export var editor: Editor
@export var data: StringName
@export var blockGroup: StringName
@export var showModifiers: bool
var createdPopup := false

var titles: Dictionary[StringName, String] = {
	&"signal": "Create Signal",
	&"variable": "Create Variable"
}

func _ready() -> void:
	pressed.connect(onPress)
	dialogBox.popupClosed.connect(popupClosed)
	editor.switchBlockGroup.connect(switchBlockGroup)

func onPress() -> void:
	createdPopup = true
	dialogBox.popup(titles[data], showModifiers)

func popupClosed(confirmed: bool, input: String, modifier: int) -> void:
	if !createdPopup: return
	if !confirmed: return
	createdPopup = false
	match data:
		&"signal":
			if gameView.signals.has(input): return
			gameView.signals.append(input)
			editor.updateBlockOptions.emit()
		&"variable":
			if modifier == 0: # global variable
				for i: Variable in gameView.variables: if i.name == input: return
				gameView.variables.append(Variable.new(input, gameView, "0.0"))
			else: # modifier is 1, local variable
				for i: Variable in editor.selectedSprite.variables: if i.name == input: return
				editor.selectedSprite.variables.append(Variable.new(input, gameView, "0.0", editor.selectedSprite))
			editor.updateBlockOptions.emit()

func switchBlockGroup(newGroup: StringName) -> void:
	visible = newGroup == blockGroup
