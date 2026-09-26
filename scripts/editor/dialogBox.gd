class_name EditorDialogBox
extends ColorRect

@export var cancel: Button
@export var confirm: Button
@export var title: Label
@export var input: LineEdit

signal popupClosed(confirmed: bool, inputText: String)
signal popup(titleText: String)

func _ready() -> void:
	cancel.pressed.connect(cancelPressed)
	confirm.pressed.connect(confirmPressed)
	popup.connect(onPopup)

func onPopup(titleText: String) -> void:
	title.text = titleText
	input.text = ""
	input.grab_focus()
	visible = true

func cancelPressed() -> void:
	visible = false
	popupClosed.emit(false, input.text)

func confirmPressed() -> void:
	visible = false
	popupClosed.emit(input.text.strip_edges() != "", input.text)
