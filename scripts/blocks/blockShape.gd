@tool
class_name BlockShape
extends Control

enum blockShapes {
	STACK,
	EVENT,
	VALUE,
	NEST
}
# The horizontal minimum size
var minimumSizes: Dictionary[blockShapes, float] = {
	blockShapes.STACK: 145.0,
	blockShapes.EVENT: 250.0,
	blockShapes.VALUE: 100.0,
	blockShapes.NEST: 250.0
}
# Determines which parts of the block can connect
# [top connector, bottom connector]
# Both false means the block is a value
var connectors: Dictionary[blockShapes, Array] = {
	blockShapes.STACK: [true, true],
	blockShapes.EVENT: [false, true],
	blockShapes.VALUE: [false, false],
	blockShapes.NEST: [true, true]
}

@export var blockColor: Color = Color("636363ff"):
	set(value):
			blockColor = value
			queue_redraw()
@export var blockShape: blockShapes = blockShapes.STACK:
	set(value):
			blockShape = value
			queue_redraw()
@export var nestEnd: float = 100.0:
	set(value):
		nestEnd = value
		queue_redraw()
@export var grabShape: CollisionPolygon2D
var points: PackedVector2Array = PackedVector2Array()
var cr: float = 10.0 # Corner radius
var notchWidth: float = 60.0
var notchHeight: float = 15.0
var notchDistance: float = 30.0 # Distance from left of block
var nestSideWidth: float = 30.0
var nestEndHeight: float = 55.0
# I don't know about math so I just use random angles until it works
const angleRight: float = PI * 1.5
const angleDown: float = PI * 2.0
const angleLeft: float = PI * 0.5
# Up angle is PI

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	# Most blocks are drawn outside the screen (vertically) since they go beyond the bounds of the control node
	match blockShape:
		blockShapes.STACK:
			RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(0.0, -1000, size.x, 2000))
			shapeStack()
		blockShapes.EVENT:
			RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(0.0, -1000, size.x, 2000))
			shapeEvent()
		blockShapes.VALUE:
			shapeValue()
		blockShapes.NEST:
			RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(0.0, -INF, size.x, INF))
			shapeNest()
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

func shapeValue() -> void:
	points.clear()
	
	# Top left corner
	points.append_array(drawArc(Vector2(cr, cr), cr, PI, angleRight))
	# Top right corner
	points.append_array(drawArc(Vector2(size.x - cr, cr), cr, angleRight, angleDown))
	# Bottom right corner
	points.append_array(drawArc(Vector2(size.x - cr, size.y - cr), cr, 0.0, angleLeft))
	# Bottom left corner
	points.append_array(drawArc(Vector2(cr, size.y - cr), cr, angleLeft, PI))
	
	# Fill and outline
	draw_polygon(points, PackedColorArray([blockColor]))
	points.append(points[0])
	draw_polyline(points, blockColor.darkened(0.2), 2.0)

func shapeNest() -> void:
	var nestEndBottom: float = size.y + nestEnd
	var nestEndTop: float = nestEndBottom - nestEndHeight
	var notchDistanceFromNest: float = nestSideWidth + notchDistance + 2.0
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
	points.append(Vector2(notchDistanceFromNest + notchWidth, size.y))
	points.append(Vector2(notchDistanceFromNest + ((notchWidth / 3.0) * 2.0), size.y + notchHeight))
	points.append(Vector2(notchDistanceFromNest + notchWidth / 3.0, size.y + notchHeight))
	points.append(Vector2(notchDistanceFromNest, size.y))
	
	# Inside of nest side
	points.append_array(drawArc(Vector2(nestSideWidth + cr, size.y + cr), cr, angleRight, PI))
	points.append_array(drawArc(Vector2(nestSideWidth + cr, (nestEndTop) - cr), cr, PI, angleLeft))
	
	# Nest end top notch (indent)
	points.append(Vector2(notchDistanceFromNest, nestEndTop))
	points.append(Vector2(notchDistanceFromNest + notchWidth / 3.0, nestEndTop + notchHeight))
	points.append(Vector2(notchDistanceFromNest + ((notchWidth / 3.0) * 2.0), nestEndTop + notchHeight))
	points.append(Vector2(notchDistanceFromNest + notchWidth, nestEndTop))
	
	# Nest end top right corner
	points.append_array(drawArc(Vector2(size.x - cr, nestEndTop + cr), cr, angleRight, angleDown))
	
	# Nest end bottom right corner
	points.append_array(drawArc(Vector2(size.x - cr, nestEndBottom - cr), cr, 0.0, angleLeft))
	
	# Nest end bottom notch (protrusion)
	points.append(Vector2(notchDistance + notchWidth, nestEndBottom))
	points.append(Vector2(notchDistance + ((notchWidth / 3.0) * 2.0), nestEndBottom + notchHeight))
	points.append(Vector2(notchDistance + notchWidth / 3.0, nestEndBottom + notchHeight))
	points.append(Vector2(notchDistance, nestEndBottom))
	
	# Stack end bottom left corner
	points.append_array(drawArc(Vector2(cr, nestEndBottom - cr), cr, angleLeft, PI))
	
	# Fill and outline
	draw_polygon(points, PackedColorArray([blockColor]))
	points.append(points[0])
	draw_polyline(points, blockColor.darkened(0.2), 2.0)
