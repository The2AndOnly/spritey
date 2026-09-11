extends Control

# This allows grabbing things protuding from the block

@export var block: CodeBlock

func _ready() -> void:
	mouse_entered.connect(mouseEntered)
	mouse_exited.connect(mouseExited)
	gui_input.connect(guiInput)

func mouseEntered() -> void:
	block.mouseEntered()

func mouseExited() -> void:
	block.mouseExited()

func guiInput(event: InputEvent) -> void:
	block.gui_input.emit(event)
