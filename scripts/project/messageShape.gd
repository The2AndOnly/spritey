class_name MessageShape
extends Control

var color: Color = Color("fffce0ff"):
	set(value):
		color = value
		queue_redraw()
var tailWidth: float = 60.0
var tailHeight: float = 60.0
var points: PackedVector2Array = PackedVector2Array()

func _draw() -> void:
	points.clear()
	var halfWidth: float = size.x / 2.0
	points.append(Vector2.ZERO)
	points.append(Vector2(size.x, 0.0))
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(halfWidth + tailWidth, size.y))
	points.append(Vector2(halfWidth, size.y + tailHeight))
	points.append(Vector2(halfWidth - tailWidth, size.y))
	points.append(Vector2(0.0, size.y))
	draw_polygon(points, PackedColorArray([color]))
	points.append(points[0])
	draw_polyline(points, color.darkened(0.5), 5.0)
