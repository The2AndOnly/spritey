class_name BitmapFrame
extends TextureRect

const CANVAS_SIZE := Vector2i(1280, 720)

# Adjustable by the tool settings
var brushRadius: int = 5:
	set(value):
		brushRadius = value
		setBrushStamp()
var color: Color = Color("000000ff"):
	set(value):
		color = value
		alpha = color.a
		color.a = 1.0
		setBrushStamp()
var alpha: float = 1.0

var editableImage: Image
var brushStamp: Image
# The queued image modified while drawing, but it's hidden for performance
# It gets baked onto the actual image once the mouse is released
var queuedImage: Image
# Texture version of the brush stamp so the preview can draw it
var brushTexture: ImageTexture
# List of coordinates that the brush stamp gets placed in the stroke
# Used to calculate the stroke bounds
var strokePoints: Array[Vector2i] = []
var drawing := false
var currentPosition: Vector2i = Vector2i(-1, -1)
var lastPosition: Vector2i = Vector2i(-1, -1)
# Only the last element is accessed as the point to interpolate to
var queuedPoints: Array[Vector2i] = []
var newPoints := false

var previewTexture: ImageTexture

func _ready() -> void:
	queuedImage = Image.create_empty(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	queuedImage.fill(Color("00000000"))
	previewTexture = ImageTexture.create_from_image(queuedImage)
	setBrushStamp()

# Load the frame onto a 1280x720 canvas
func showFrame(showTexture: Texture2D) -> void:
	editableImage = Image.create_empty(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
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

# Create points and redraw if there are any new points to process
func _process(_delta: float) -> void:
	if drawing and newPoints:
		interpolatePoints()
		queue_redraw()
		newPoints = false

# This creates several points between the current and last position for the brush stamp
# Take the latest input in case mouse inputs get detected multiple times per frame
func interpolatePoints() -> void:
	if queuedPoints.is_empty(): return
	var targetPosition = queuedPoints[-1]
	queuedPoints.clear()
	
	if targetPosition != lastPosition:
		var distance: float = Vector2(lastPosition).distance_to(Vector2(targetPosition))
		var steps: int = int(distance / maxf(1.0, float(brushRadius) * 0.05))
		if steps == 0:
			strokePoints.append(targetPosition)
			stampOnPreview(targetPosition)
		else:
			for i: int in range(1, steps + 1):
				var weight: float = i / float(steps)
				var interpolated: Vector2 = Vector2(lastPosition).lerp(Vector2(targetPosition), weight).round()
				strokePoints.append(Vector2i(interpolated))
				stampOnPreview(Vector2i(interpolated))
		lastPosition = targetPosition

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leftMouse"):
		currentPosition = Vector2i(get_local_mouse_position())
		if !withinCanvas(currentPosition): return
		drawing = true
		lastPosition = currentPosition
		strokePoints.clear()
		strokePoints.append(currentPosition)
		stampOnPreview(currentPosition)
		newPoints = true
	elif (event is InputEventMouseMotion) and drawing:
		currentPosition = Vector2i(get_local_mouse_position())
		if !withinCanvas(currentPosition): return
		if currentPosition != lastPosition:
			queuedPoints.append(currentPosition)
			newPoints = true
	# Bake the preview onto the actual image when released
	elif event.is_action_released(&"leftMouse") and drawing:
		drawing = false
		lastPosition = Vector2i(-1, -1)
		bakePreview()
		strokePoints.clear()
		queue_redraw()

func _draw() -> void:
	if not drawing or strokePoints.is_empty():
		return

	# Calculate dirty bounding rect of current stroke
	var bounds := get_stroke_bounds()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return

	# Update previewTexture with queuedImage contents
	previewTexture.update(queuedImage)

	# Modulate entire stroke uniformly with chosen alpha
	var preview_modulate := Color(1.0, 1.0, 1.0, alpha)

	# Draw only modified rect to keep GPU work minimal
	draw_texture_rect_region(
		previewTexture,
		Rect2(bounds.position, bounds.size),
		Rect2(bounds.position, bounds.size),
		preview_modulate
	)

## Shows a preview of the stroke while drawing before it gets baked
#func _draw() -> void:
	#if (!drawing) or (strokePoints.is_empty()) or !brushTexture:
		#return
	#for i: Vector2i in strokePoints:
		#draw_texture(brushTexture, Vector2(i) - Vector2(brushRadius / 2, brushRadius / 2))

func withinCanvas(coord: Vector2i) -> bool:
	return (coord.x >= 0) and (coord.x < CANVAS_SIZE.x) and (coord.y >= 0) and (coord.y < CANVAS_SIZE.y)

# Create an image and texture for the brush stamp
func setBrushStamp() -> void:
	brushStamp = Image.create_empty(brushRadius, brushRadius, false, Image.FORMAT_RGBA8)
	brushStamp.fill(Color("00000000"))
	# The brush stamp is a pixelated circle
	var center: float = (brushRadius - 1) / 2.0
	for x: int in range(brushRadius):
		for y: int in range(brushRadius):
			if ((x - center) ** 2) + ((y - center) ** 2) <= (brushRadius / 2.0) ** 2:
				brushStamp.set_pixel(x, y, color)
	brushTexture = ImageTexture.create_from_image(brushStamp)

# Stamp the brush onto the preview
func stampOnPreview(center: Vector2i) -> void:
	var trueCenter: Vector2i = center - Vector2i(brushRadius / 2, brushRadius / 2)
	queuedImage.blend_rect(brushStamp, Rect2i(0, 0, brushRadius, brushRadius), trueCenter)

func bakePreview() -> void:
	if strokePoints.is_empty():
		return
	# If the stroke is fully opaque (alpha == 1.0), use fast native blend_rect
	if alpha == 1.0:
		editableImage.blend_rect(queuedImage, Rect2i(0, 0, CANVAS_SIZE.x, CANVAS_SIZE.y), Vector2i.ZERO)
	else:
		# Calculate the dirty bounding rect of the stroke to avoid scanning all 1280x720 pixels
		var dirty_rect := get_stroke_bounds()
		
		# Apply alpha modulation to the modified region only
		for x in range(dirty_rect.position.x, dirty_rect.end.x):
			for y in range(dirty_rect.position.y, dirty_rect.end.y):
				var src_color := queuedImage.get_pixel(x, y)
				if src_color.a > 0.0:
					# Apply stroke alpha to source pixel
					src_color.a *= alpha
					
					# Blend manually onto editableImage
					var dst_color := editableImage.get_pixel(x, y)
					var blended := dst_color.blend(src_color)
					editableImage.set_pixel(x, y, blended)

	# Update main GPU texture once
	texture = ImageTexture.create_from_image(editableImage)
	
	# Reset preview
	queuedImage.fill(Color(0, 0, 0, 0))
	strokePoints.clear()

# Helper to find the affected area of the stroke for fast baking
func get_stroke_bounds() -> Rect2i:
	var min_pos := strokePoints[0]
	var max_pos := strokePoints[0]

	for pt in strokePoints:
		min_pos.x = mini(min_pos.x, pt.x)
		min_pos.y = mini(min_pos.y, pt.y)
		max_pos.x = maxi(max_pos.x, pt.x)
		max_pos.y = maxi(max_pos.y, pt.y)

	var offset := Vector2i(brushRadius / 2, brushRadius / 2)
	min_pos = (min_pos - offset).clamp(Vector2i.ZERO, CANVAS_SIZE)
	max_pos = (max_pos + Vector2i(brushRadius, brushRadius) - offset).clamp(Vector2i.ZERO, CANVAS_SIZE)

	return Rect2i(min_pos, max_pos - min_pos)

## Add the preview to the actual texture
#func bakePreview() -> void:
	#editableImage.blend_rect(queuedImage, Rect2i(0, 0, CANVAS_SIZE.x, CANVAS_SIZE.y), Vector2i.ZERO)
	#texture = ImageTexture.create_from_image(editableImage)
	## Reset preview
	#queuedImage.fill(Color("00000000"))
