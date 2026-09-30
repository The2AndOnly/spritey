class_name BitmapFrame
extends TextureRect

const CANVAS_SIZE := Vector2i(1280, 720)
const MIN_POINT_DISTANCE: float = 1.0

@export var brushRadius: int = 4
@export var brushColor: Color = Color("ff0000ff")

var editableImage: Image
var brushStamp: Image
var brushTexture: ImageTexture
var previewImage: Image
var previewTexture: ImageTexture
var stroke_points: Array[Vector2i] = []
var drawing: bool = false
var last_mouse_pos := Vector2i(-1, -1)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	init_preview_image()

func _process(_delta: float) -> void:
	if drawing and is_dirty:
		process_pending_points()
		queue_redraw()
		is_dirty = false

func process_pending_points() -> void:
	if pending_motion_points.is_empty():
		return

	var target_pos = pending_motion_points[-1]
	pending_motion_points.clear()

	if target_pos != last_mouse_pos:
		# HERE: Calculates spacing interval based on exact brushRadius
		var step_dist := maxf(1.0, float(brushRadius) * 0.15)
		
		var dist := Vector2(last_mouse_pos).distance_to(Vector2(target_pos))
		var steps := int(dist / step_dist)
		
		if steps > 0:
			for i in range(1, steps + 1):
				var t := float(i) / float(steps)
				var interpolated_pt := Vector2(last_mouse_pos).lerp(Vector2(target_pos), t).round()
				var pt := Vector2i(interpolated_pt)
				
				stroke_points.append(pt)
				stamp_to_preview(pt)
		else:
			stroke_points.append(target_pos)
			stamp_to_preview(target_pos)
			
		last_mouse_pos = target_pos

func init_preview_image() -> void:
	previewImage = Image.create(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	previewImage.fill(Color(0, 0, 0, 0))
	previewTexture = ImageTexture.create_from_image(previewImage)

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

func stamp_to_preview(center_pos: Vector2i) -> void:
	if not brushStamp or brushStamp.get_width() != brushRadius:
		updateBrushStamp()

	if brushRadius <= 1:
		if is_valid_canvas_pos(center_pos):
			previewImage.set_pixel(center_pos.x, center_pos.y, brushColor)
	else:
		var src_rect := Rect2i(0, 0, brushRadius, brushRadius)
		# HERE: Centering offset for stamping onto CPU Image
		var offset := Vector2i(brushRadius / 2, brushRadius / 2)
		var dest_pos := center_pos - offset
		previewImage.blend_rect(brushStamp, src_rect, dest_pos)


func bake_preview_to_main_canvas() -> void:
	var full_rect := Rect2i(0, 0, CANVAS_SIZE.x, CANVAS_SIZE.y)
	
	# 1. Single C++ memory blend on mouse up
	editableImage.blend_rect(previewImage, full_rect, Vector2i.ZERO)
	
	# 2. Update VRAM texture ONCE at the end of the stroke
	texture = ImageTexture.create_from_image(editableImage)
	
	# 3. Reset preview image in CPU memory
	previewImage.fill(Color(0, 0, 0, 0))

var frame_points: Array[Vector2i] = []

var pending_motion_points: Array[Vector2i] = []
var is_dirty: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leftMouse"):
		var pos = Vector2i(get_local_mouse_position())
		if is_valid_canvas_pos(pos):
			drawing = true
			last_mouse_pos = pos
			
			stroke_points.clear()
			stroke_points.append(pos)
			stamp_to_preview(pos)
			is_dirty = true

	elif (event is InputEventMouseMotion) and drawing:
		var pos = Vector2i(get_local_mouse_position())
		if is_valid_canvas_pos(pos) and pos != last_mouse_pos:
			# Append to a pending buffer to throttle execution
			pending_motion_points.append(pos)
			is_dirty = true

	elif event.is_action_released(&"leftMouse") and drawing:
		drawing = false
		process_pending_points() # Process remaining points before baking
		bake_preview_to_main_canvas()
		last_mouse_pos = Vector2i(-1, -1)
		stroke_points.clear()
		queue_redraw()


func _draw() -> void:
	if not drawing or stroke_points.is_empty() or not brushTexture:
		return

	# HERE: Centering offset for GPU preview drawing
	var offset := Vector2(brushRadius / 2, brushRadius / 2)
	
	for pt in stroke_points:
		var draw_pos := Vector2(pt) - offset
		draw_texture(brushTexture, draw_pos)


func is_valid_canvas_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < CANVAS_SIZE.x and pos.y >= 0 and pos.y < CANVAS_SIZE.y

func updateBrushStamp() -> void:
	# brushRadius represents exact pixel diameter (1, 2, 3, 4, etc.)
	if brushRadius <= 1:
		brushStamp = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		brushStamp.set_pixel(0, 0, brushColor)
		brushTexture = ImageTexture.create_from_image(brushStamp)
		return

	var diameter := brushRadius
	var center := (diameter - 1) / 2.0  # Floating point center allows even dimensions
	var radius_sq := (diameter / 2.0) * (diameter / 2.0)

	brushStamp = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	brushStamp.fill(Color(0, 0, 0, 0))

	for x in range(diameter):
		for y in range(diameter):
			# Measure distance from true center (handles even and odd diameters)
			var dx := (x - center)
			var dy := (y - center)
			if (dx * dx) + (dy * dy) <= radius_sq:
				brushStamp.set_pixel(x, y, brushColor)

	brushTexture = ImageTexture.create_from_image(brushStamp)

# Bresenham's algorithm for gapless pixel lines
func get_bresenham_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var dx = abs(to.x - from.x)
	var dy = -abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx + dy
	var curr = from

	while true:
		points.append(curr)
		if curr == to:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			curr.x += sx
		if e2 <= dx:
			err += dx
			curr.y += sy

	return points
