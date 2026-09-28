class_name EditorDialogBox
extends ColorRect

@export var cancel: Button
@export var confirm: Button
@export var title: Label
@export var input: LineEdit
@export var modifiers: HBoxContainer
@export var modifierButtons: Array[Button]

signal popupClosed(confirmed: bool, inputText: String, modifier: int)

func _ready() -> void:
	cancel.pressed.connect(cancelPressed)
	confirm.pressed.connect(confirmPressed)
	input.text_submitted.connect(submitted)

func popup(titleText: String, showModifiers: bool) -> void:
	title.text = titleText
	modifiers.visible = showModifiers
	modifierButtons[0].button_pressed = true
	input.text = ""
	input.grab_focus()
	visible = true

func cancelPressed() -> void:
	visible = false
	popupClosed.emit(false, input.text, -1)

func confirmPressed() -> void:
	var modifierPressed: int = -1
	for i: int in range(modifierButtons.size()):
		if modifierButtons[i].button_pressed: modifierPressed = i
	visible = false
	popupClosed.emit(input.text.strip_edges() != "", input.text.strip_edges(), modifierPressed)

func submitted(_new: String) -> void:
	confirmPressed()
