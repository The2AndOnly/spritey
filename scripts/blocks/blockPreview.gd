class_name BlockPreview
extends MarginContainer

var shape: BlockShape.blockShapes
var height: float = 0.0
var nestEnd: float = 0.0:
	set(value):
		nestEnd = value
		if previewShape: previewShape.nestEnd = nestEnd
var previewShape: BlockShape

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewShape = BlockShape.new()
	previewShape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewShape.blockColor = Color("ffffff28")
	previewShape.blockShape = shape
	add_child(previewShape)
