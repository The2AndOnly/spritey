class_name BlockPreview
extends MarginContainer

var shape: BlockShape.blockShapes
var nestEnd: float = 100.0:
	set(value):
		nestEnd = value
		if previewShape: previewShape.nestEnd = nestEnd
var nest2End: float = 0.0:
	set(value):
		nest2End = value
		if previewShape: previewShape.nestEnd2 = nest2End
var previewShape: BlockShape

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewShape = BlockShape.new()
	previewShape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewShape.blockColor = Color("ffffff28")
	previewShape.blockShape = shape
	add_child(previewShape)
