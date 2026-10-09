class_name DrawCollision
extends CollisionShape2D

@export var fill_color: Color = Color(0.0, 0.683, 1.0, 0.2)
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 1.0)

func _draw() -> void:
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		var rect := Rect2(-rect_shape.size / 2.0, rect_shape.size)
		draw_rect(rect, fill_color, true)
		draw_rect(rect, outline_color, false, -1.0)
	elif shape is CircleShape2D:
		var circle := shape as CircleShape2D
		draw_circle(Vector2.ZERO, circle.radius, fill_color)
		draw_arc(Vector2.ZERO, circle.radius, 0, TAU, 32, outline_color, -1.0)
