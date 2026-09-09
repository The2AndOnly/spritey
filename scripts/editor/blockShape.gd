@tool
extends Control

@export var block_color: Color = Color("0061cc"):
	set(value):
			block_color = value
			queue_redraw() # Forces editor update on change
@export var corner_radius: float = 10.0:
	set(value):
			corner_radius = value
			queue_redraw()
@export var notch_width: float = 60.0:
	set(value):
			notch_width = value
			queue_redraw()
@export var notch_height: float = 15.0:
	set(value):
			notch_height = value
			queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var r: float = corner_radius
	var pts: PackedVector2Array = PackedVector2Array()

	# 1. Top-Left Rounded Corner Arc (180° to 270°)
	pts.append_array(_create_arc_points(Vector2(r, r), r, PI, 1.5 * PI))

	# 2. Top Notch
	pts.append(Vector2(30, 0))
	pts.append(Vector2(30 + notch_width / 3, notch_height))
	pts.append(Vector2(30 + ((notch_width / 3) * 2), notch_height))
	pts.append(Vector2(30 + notch_width, 0))

	# 3. Top-Right Corner Arc (270° to 360°)
	pts.append_array(_create_arc_points(Vector2(w - r, r), r, 1.5 * PI, 2.0 * PI))

	# 4. Bottom-Right Corner Arc (0° to 90°)
	pts.append_array(_create_arc_points(Vector2(w - r, h - r), r, 0.0, 0.5 * PI))

	# 5. Bottom Notch Indent
	pts.append(Vector2(30 + notch_width, h))
	pts.append(Vector2(30 + ((notch_width / 3) * 2), h + notch_height))
	pts.append(Vector2(30 + notch_width / 3, h + notch_height))
	pts.append(Vector2(30, h))

	# 6. Bottom-Left Corner Arc (90° to 180°)
	pts.append_array(_create_arc_points(Vector2(r, h - r), r, 0.5 * PI, PI))

	# Fill geometry
	draw_polygon(pts, PackedColorArray([block_color]))
	
	# Draw smooth outline
	pts.append(pts[0]) # Close path loop
	draw_polyline(pts, block_color.darkened(0.2), 2.0)

# Helper function to generate arc points along a radius
func _create_arc_points(center: Vector2, radius: float, start_angle: float, end_angle: float, segments: int = 4) -> PackedVector2Array:
	var arc: PackedVector2Array = PackedVector2Array()
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = lerp(start_angle, end_angle, t)
		arc.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return arc
