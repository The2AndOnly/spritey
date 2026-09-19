class_name BlockPreview
extends MarginContainer

var shape: BlockShape.blockShapes
var nestEnd: float = 100.0:
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
	previewShape.nestEnd = nestEnd
	add_child(previewShape)
