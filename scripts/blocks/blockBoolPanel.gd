class_name BlockBoolPanel
extends Panel

var block: CodeBlock
var highlight: Panel
var detectionShape: CollisionShape2D

func setDetectionRect() -> void:
	detectionShape.shape.size = size
	detectionShape.position = size / Vector2(2.0, 2.0)
