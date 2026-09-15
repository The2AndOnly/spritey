extends Button

@export var enabledWithView: Control
@export var viewName: StringName
@export var editor: Editor

func _ready() -> void:
	pressed.connect(onPress)
	editor.changedView.connect(changedView)

func onPress() -> void:
	editor.currentView = viewName

func changedView(view: StringName) -> void:
	enabledWithView.visible = view == viewName
