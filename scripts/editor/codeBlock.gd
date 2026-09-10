class_name CodeBlock
extends MarginContainer

# There are only for the instance scene
@export var content: HBoxContainer
@export var topDetection: Area2D
@export var bottomDetection: Area2D

# If true, the block acts as a preview in the block selector palete
@export var preview := false
@export var blockName: StringName
var mouseTouching := false
var initialOffset: Vector2 = Vector2.ZERO
var dragDisabled := false
# Structure of the block
var blockStructure: Dictionary = {}
# Which side of another block it can be connected to while dragging
# -1 = bottom, 0 = none, 1 = top
var detectedSnapPos: int = 0
# Which block it can be connected to while dragging
var detectedBlock: CodeBlock = null

func _ready() -> void:
	if preview:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_entered.connect(mouseEntered)
		mouse_exited.connect(mouseExited)
		resized.connect(onResize)
	
	if BlockStructures.structures.has(blockName):
		blockStructure = BlockStructures.structures[blockName]
	
	# Build the block's labels and inputs
	for i: Variant in blockStructure[&"structure"]:
		# Labels
		if i is String:
			var label: Label = Label.new()
			label.text = i
			content.add_child(label)
		# Data inputs
		if i is int:
			match blockStructure[i][0]:
				&"input":
					var input: BlockInputEdit = BlockInputEdit.new()
					input.type = blockStructure[i][1]
					input.text = blockStructure[i][2]
					input.block = self
					if preview: input.mouse_filter = Control.MOUSE_FILTER_IGNORE
					content.add_child(input)
				&"options":
					var options: BlockOptions = BlockOptions.new()
					for j: int in range(3, blockStructure[i].size()):
						options.add_item(blockStructure[i][j])
					options.selected = blockStructure[i][2]
					options.block = self
					if preview: options.mouse_filter = Control.MOUSE_FILTER_IGNORE
					content.add_child(options)
	
	content.configureProperties()

func _process(_delta: float) -> void:
	if preview: return
	if Input.is_action_pressed(&"leftMouse"):
		if ((!mouseTouching) and (initialOffset == Vector2.ZERO)) or dragDisabled:
			dragDisabled = true
			return
		if initialOffset == Vector2.ZERO:
			initialOffset = global_position - get_global_mouse_position()
		global_position = get_global_mouse_position() + initialOffset
		detectBlockSnap()
	else:
		if initialOffset != Vector2.ZERO:
			blockReleased()
		initialOffset = Vector2.ZERO
		dragDisabled = false

func blockReleased() -> void:
	if detectedBlock:
		# Snap to detected block
		global_position = detectedBlock.global_position
		if detectedSnapPos == 1:
			global_position.y -= size.y
		else:
			global_position.y += detectedBlock.size.y

func mouseEntered() -> void:
	mouseTouching = true

func mouseExited() -> void:
	mouseTouching = false

func onResize() -> void:
	bottomDetection.position.y = size.y

func detectBlockSnap() -> void:
	for i: Area2D in bottomDetection.get_overlapping_areas():
		if i.is_in_group(&"blockSnapTop"):
			detectedBlock = i.get_parent()
			detectedSnapPos = 1
			return
	for i: Area2D in topDetection.get_overlapping_areas():
		if i.is_in_group(&"blockSnapBottom"):
			detectedBlock = i.get_parent()
			detectedSnapPos = -1
			return
	detectedBlock = null
	detectedSnapPos = 0
