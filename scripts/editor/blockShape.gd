@tool
class_name BlockShape
extends Control

enum blockShapes {
	STACK,
	EVENT
}
# The horizontal minimum size
var minimumSizes: Dictionary[blockShapes, float] = {
	blockShapes.STACK: 145.0,
	blockShapes.EVENT: 250.0
}
# Determines which parts of the block can connect
# [top connector, bottom connector]
# Both false means the block is a reporter
var connectors: Dictionary[blockShapes, Array] = {
	blockShapes.STACK: [true, true],
	blockShapes.EVENT: [false, true]
}

@export var blockColor: Color = Color("636363ff"):
	set(value):
			blockColor = value
			queue_redraw()
@export var blockShape: blockShapes = blockShapes.STACK:
	set(value):
			blockShape = value
			queue_redraw()
@export var grabShape: CollisionPolygon2D
var points: PackedVector2Array = PackedVector2Array()
var cr: float = 10.0 # Corner radius
var notchWidth: float = 60.0
var notchHeight: float = 15.0
var notchDistance: float = 30.0 # Distance from left of block
const angleRight: float = PI * 1.5
const angleDown: float = PI * 2.0
const angleLeft: float = PI * 0.5
# Up angle is PI

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	match blockShape:
		blockShapes.STACK:
			shapeStack()
		blockShapes.EVENT:
			shapeEvent()
	if !Engine.is_editor_hint():
		if grabShape: grabShape.polygon = points

# For drawing curved lines
func drawArc(center: Vector2, radius: float, angleStart: float, angleEnd: float, detail: int = 4) -> PackedVector2Array:
	var arc: PackedVector2Array = PackedVector2Array()
	for i: int in range(detail + 1):
		var angle: float = lerp(angleStart, angleEnd, i / float(detail))
		arc.append(center + (Vector2(cos(angle), sin(angle)) * radius))
	return arc

func shapeStack() -> void:
	points.clear()
	
	# Top left corner
	points.append_array(drawArc(Vector2(cr, cr), cr, PI, angleRight))
	
	# Top notch (indent)
	points.append(Vector2(notchDistance, 0.0))
	points.append(Vector2(notchDistance + notchWidth / 3.0, notchHeight))
	points.append(Vector2(notchDistance + ((notchWidth / 3.0) * 2.0), notchHeight))
	points.append(Vector2(notchDistance + notchWidth, 0.0))
	
	# Top right corner
	points.append_array(drawArc(Vector2(size.x - cr, cr), cr, angleRight, angleDown))
	
	# Bottom right corner
	points.append_array(drawArc(Vector2(size.x - cr, size.y - cr), cr, 0.0, angleLeft))
	
	# Bottom notch (protrusion)
	points.append(Vector2(notchDistance + notchWidth, size.y))
	points.append(Vector2(notchDistance + ((notchWidth / 3.0) * 2.0), size.y + notchHeight))
	points.append(Vector2(notchDistance + notchWidth / 3.0, size.y + notchHeight))
	points.append(Vector2(notchDistance, size.y))
	
	# Bottom left corner
	points.append_array(drawArc(Vector2(cr, size.y - cr), cr, angleLeft, PI))
	
	# Fill and outline
	draw_polygon(points, PackedColorArray([blockColor]))
	points.append(points[0])
	draw_polyline(points, blockColor.darkened(0.2), 2.0)

func shapeEvent() -> void:
	var roundedTopHeight: float = 40.0
	var roundedTopWidth: float = 100.0
	points.clear()
	
	# Rounded top
	points.append_array(drawArc(Vector2(roundedTopHeight, 0.0), roundedTopHeight, PI, angleRight, 10))
	points.append(Vector2(roundedTopWidth, -roundedTopHeight))
	points.append_array(drawArc(Vector2(roundedTopWidth + roundedTopHeight, 0.0), roundedTopHeight, angleRight, angleDown, 10))
	
	# Top right corner
	points.append_array(drawArc(Vector2(size.x - cr, cr), cr, angleRight, angleDown))
	
	# Bottom right corner
	points.append_array(drawArc(Vector2(size.x - cr, size.y - cr), cr, 0.0, angleLeft))
	
	# Bottom notch (protrusion)
	points.append(Vector2(notchDistance + notchWidth, size.y))
	points.append(Vector2(notchDistance + ((notchWidth / 3.0) * 2.0), size.y + notchHeight))
	points.append(Vector2(notchDistance + notchWidth / 3.0, size.y + notchHeight))
	points.append(Vector2(notchDistance, size.y))
	
	# Bottom left corner
	points.append_array(drawArc(Vector2(cr, size.y - cr), cr, angleLeft, PI))
	
	# Fill and outline
	draw_polygon(points, PackedColorArray([blockColor]))
	points.append(points[0])
	draw_polyline(points, blockColor.darkened(0.2), 2.0)
