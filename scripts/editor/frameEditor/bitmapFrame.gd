class_name BitmapFrame
extends TextureRect

const CANVAS_SIZE := Vector2i(1280, 720)
@export var brushStampPreview: TextureRect

# Adjustable by the tool settings
var brushRadius: int = 5:
	set(value):
		brushRadius = value
		setBrushStamp()
var color: Color = Color("ff8c00ff"):
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
# Texture version of the queued image so a preview can be shown in the _draw() function
var previewTexture: ImageTexture
# List of coordinates that the brush stamp gets placed in the stroke
var strokePoints: Array[Vector2i] = []
var drawing := false
var currentPosition: Vector2i = Vector2i(-1, -1)
var lastPosition: Vector2i = Vector2i(-1, -1)
# Only the last element is accessed as the point to interpolate to
var queuedPoints: Array[Vector2i] = []
var newPoints := false
var frameID: int = -1

signal frameUpdated(newFrame: Texture2D)

func _ready() -> void:
	queuedImage = Image.create_empty(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	queuedImage.fill(Color("00000000"))
	previewTexture = ImageTexture.create_from_image(queuedImage)
	setBrushStamp()

# Load the frame onto a 1280x720 canvas
func showFrame(showTexture: Texture2D, id: int) -> void:
	frameID = id
	editableImage = Image.create_empty(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	editableImage.fill(Color("00000000"))
	var sourceImage: Image = showTexture.get_image()
	if sourceImage.is_compressed():
		sourceImage.decompress()
	sourceImage.convert(Image.FORMAT_RGBA8)
	# Center source image on the canvas
	var sourceSize: Vector2i = sourceImage.get_size()
	var sourceX: int = (CANVAS_SIZE.x - sourceSize.x) / 2
	var sourceY: int = (CANVAS_SIZE.y - sourceSize.y) / 2
	editableImage.blit_rect(sourceImage, Rect2i(Vector2i.ZERO, sourceSize), Vector2i(sourceX, sourceY))
	texture = ImageTexture.create_from_image(editableImage)

# Create points and redraw if there are any new points to process
func _process(_delta: float) -> void:
	if drawing:
		brushStampPreview.visible = false
		if newPoints:
			interpolatePoints()
			queue_redraw()
			newPoints = false
	else:
		brushStampPreview.visible = true
		setBrushStampPreviewPosition()

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
		drawing = true
		lastPosition = currentPosition
		strokePoints.clear()
		strokePoints.append(currentPosition)
		stampOnPreview(currentPosition)
		newPoints = true
	elif (event is InputEventMouseMotion) and drawing:
		currentPosition = Vector2i(get_local_mouse_position())
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

# Show the preview in the bounds of the current stroke before it gets baked
func _draw() -> void:
	if (!drawing) or strokePoints.is_empty(): return
	var bounds: Rect2i = getStrokeBounds()
	if (bounds.size.x <= 0) or (bounds.size.y <= 0): return
	previewTexture.update(queuedImage)
	draw_texture_rect_region(
		previewTexture,
		Rect2(bounds.position, bounds.size),
		Rect2(bounds.position, bounds.size),
		Color(1.0, 1.0, 1.0, alpha)
	)

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
	brushStampPreview.texture = ImageTexture.create_from_image(brushStamp)
	brushStampPreview.modulate.a = alpha
	brushStampPreview.set_deferred(&"size", Vector2(0.0, 0.0))

# Stamp the brush onto the preview
func stampOnPreview(center: Vector2i) -> void:
	var trueCenter: Vector2i = center - Vector2i(brushRadius / 2, brushRadius / 2)
	queuedImage.blend_rect(brushStamp, Rect2i(0, 0, brushRadius, brushRadius), trueCenter)

# Update the image by adding the preview to the actual texture
func bakePreview() -> void:
	if strokePoints.is_empty(): return
	# Only apply in the affected region
	var strokeBounds: Rect2i = getStrokeBounds()
	for x: int in range(strokeBounds.position.x, strokeBounds.end.x):
		for y: int in range(strokeBounds.position.y, strokeBounds.end.y):
			var sourceColor: Color = queuedImage.get_pixel(x, y)
			if sourceColor.a > 0.0:
				sourceColor.a = alpha
				editableImage.set_pixel(x, y, editableImage.get_pixel(x, y).blend(sourceColor))
	texture = ImageTexture.create_from_image(editableImage)
	# Reset preview
	queuedImage.fill(Color("00000000"))
	strokePoints.clear()
	# Update sprite's frame
	updateFrame()

# Get the bounding box of the stroke
func getStrokeBounds() -> Rect2i:
	var minPos: Vector2i = strokePoints[0]
	var maxPos: Vector2i = strokePoints[0]
	for i: Vector2i in strokePoints:
		minPos.x = mini(minPos.x, i.x)
		minPos.y = mini(minPos.y, i.y)
		maxPos.x = maxi(maxPos.x, i.x)
		maxPos.y = maxi(maxPos.y, i.y)
	var offset: Vector2i = Vector2i(brushRadius / 2, brushRadius / 2)
	minPos = (minPos - offset).clamp(Vector2i.ZERO, CANVAS_SIZE)
	maxPos = (maxPos + Vector2i(brushRadius, brushRadius) - offset).clamp(Vector2i.ZERO, CANVAS_SIZE)
	return Rect2i(minPos, maxPos - minPos)

# Preview of the brush that follows the mouse around
func setBrushStampPreviewPosition() -> void:
	brushStampPreview.global_position = get_global_mouse_position().floor()
	brushStampPreview.global_position -= Vector2(brushRadius / 2, brushRadius / 2)
	
# Extract the bounds of the image for the sprite to use
func updateFrame() -> void:
	# An empty image produces a 1x1 transparent texture
	var used_rect: Rect2i = editableImage.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
			var empty_tex := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
			frameUpdated.emit(empty_tex)
			return
	var cropped_image: Image = editableImage.get_region(used_rect)
	var cropped_texture := ImageTexture.create_from_image(cropped_image)
	frameUpdated.emit(texture, cropped_texture)

#func withinCanvas(coord: Vector2i) -> bool:
	#return (coord.x >= 0) and (coord.x < CANVAS_SIZE.x) and (coord.y >= 0) and (coord.y < CANVAS_SIZE.y)
