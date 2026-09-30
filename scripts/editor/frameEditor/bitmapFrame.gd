class_name BitmapFrame
extends TextureRect

const CANVAS_SIZE := Vector2i(1280, 720)
const MIN_POINT_DISTANCE: float = 4.0

@export var brushRadius: int = 2
@export var brushColor: Color = Color("ff0000ff")

var editableImage: Image
var active_points: Array[Vector2] = []
var brushStamp: Image

# Load the frame onto a 1280x720 canvas
func showFrame(showTexture: Texture2D) -> void:
	editableImage = Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	editableImage.fill(Color("00000000"))
	var sourceImage: Image = showTexture.get_image()
	if sourceImage.is_compressed():
		sourceImage.decompress()
	sourceImage.convert(Image.FORMAT_RGBA8)
	var sourceSize: Vector2i = sourceImage.get_size()
	# Center source image on the canvas
	var sourceX: int = (CANVAS_SIZE.x - sourceSize.x) / 2
	var sourceY: int = (CANVAS_SIZE.y - sourceSize.y) / 2
	editableImage.blit_rect(sourceImage, Rect2i(Vector2i.ZERO, sourceSize), Vector2i(sourceX, sourceY))
	texture = ImageTexture.create_from_image(editableImage)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leftMouse"):
		active_points.clear()
		active_points.append(event.position)
		queue_redraw()

	elif (event is InputEventMouseMotion) and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var current_pos = event.position
		
		# Distance check eliminates micro-jitter / miter spikes
		if active_points.is_empty() or active_points[-1].distance_to(current_pos) >= MIN_POINT_DISTANCE:
			active_points.append(current_pos)
			queue_redraw()

	elif event.is_action_released(&"leftMouse"):
		if not active_points.is_empty():
			bake_stroke_to_image()
			active_points.clear()
			queue_redraw()


# Fast GPU preview while dragging
func _draw() -> void:
	if active_points.size() == 1:
		draw_circle(active_points[0], brushRadius, brushColor)
	elif active_points.size() > 1:
		for i in range(1, active_points.size()):
			var p1 = active_points[i - 1]
			var p2 = active_points[i]
			draw_line(p1, p2, brushColor, brushRadius * 2.0, true)
			draw_circle(p2, brushRadius, brushColor)
		draw_circle(active_points[0], brushRadius, brushColor)


# Bakes the finished GPU stroke into editableImage WITHOUT touching the Viewport or Camera
func bake_stroke_to_image() -> void:
	if active_points.is_empty():
		return

	# Draw lines between points directly onto the 1280x720 CPU buffer on mouse release
	for i in range(active_points.size()):
		var pt = Vector2i(active_points[i])
		if i == 0:
			stamp_brush_to_image(pt)
		else:
			var prev_pt = Vector2i(active_points[i - 1])
			var dist = Vector2(prev_pt).distance_to(Vector2(pt))
			var steps = max(int(dist / (float(brushRadius) * 0.1)), 1)
			for step in range(steps + 1):
				var t = float(step) / float(steps)
				var interp = Vector2i(Vector2(prev_pt).lerp(Vector2(pt), t).round())
				stamp_brush_to_image(interp)

	# Update the texture ONCE at the end of the stroke (1280x720 locked permanently)
	texture = ImageTexture.create_from_image(editableImage)


func stamp_brush_to_image(center: Vector2i) -> void:
	if not brushStamp:
		updateBrushStamp()
	var src_rect := Rect2i(0, 0, brushStamp.get_width(), brushStamp.get_height())
	var dest_pos := center - Vector2i(brushRadius, brushRadius)
	editableImage.blend_rect(brushStamp, src_rect, dest_pos)


func updateBrushStamp() -> void:
	var diameter = brushRadius * 2
	brushStamp = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	brushStamp.fill(Color(0, 0, 0, 0))
	for x in range(diameter):
		for y in range(diameter):
			var dx = x - brushRadius
			var dy = y - brushRadius
			if (dx * dx) + (dy * dy) <= (brushRadius * brushRadius):
				brushStamp.set_pixel(x, y, brushColor)
