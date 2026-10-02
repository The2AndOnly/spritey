class_name BitmapFrame
extends TextureRect

const CANVAS_SIZE := Vector2i(1280, 720)
@export var brushStampPreview: TextureRect
enum Tools {
	BRUSH,
	ERASER
}

# Adjustable by the tool settings
var brushRadius: int = 10:
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
var toolSelected: Tools = Tools.BRUSH:
	set(value):
		toolSelected = value
		match value:
			Tools.ERASER, Tools.BRUSH:
				setBrushStamp()

var editableImage: Image
var brushStamp: Image
# The queued image gets baked onto the actual image once the mouse is released
var queuedImage: Image
# Texture version of the queued image so a preview can be shown in the _draw() function
var previewTexture: ImageTexture
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
	queuedImage.fill(Color(0.0, 0.0, 0.0, 0.0))
	previewTexture = ImageTexture.create_from_image(queuedImage)
	setBrushStamp()

# Load the frame onto a 1280x720 canvas
func showFrame(showTexture: Texture2D, id: int) -> void:
	frameID = id
	editableImage = Image.create_empty(CANVAS_SIZE.x, CANVAS_SIZE.y, false, Image.FORMAT_RGBA8)
	editableImage.fill(Color(0.0, 0.0, 0.0, 0.0))
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
		brushStampPreview.global_position = get_global_mouse_position().floor()
		brushStampPreview.global_position -= Vector2(brushRadius / 2, brushRadius / 2)

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
			stampOnPreview(targetPosition)
		else:
			for i: int in range(1, steps + 1):
				var weight: float = i / float(steps)
				var interpolated: Vector2 = Vector2(lastPosition).lerp(Vector2(targetPosition), weight).round()
				stampOnPreview(Vector2i(interpolated))
		lastPosition = targetPosition

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leftMouse"):
		currentPosition = Vector2i(get_local_mouse_position())
		drawing = true
		lastPosition = currentPosition
		texture = null
		queuedImage.blit_rect(editableImage, Rect2i(0, 0, CANVAS_SIZE.x, CANVAS_SIZE.y), Vector2i.ZERO)
		stampOnPreview(currentPosition)
		newPoints = true
	elif (event is InputEventMouseMotion) and drawing:
		currentPosition = Vector2i(get_local_mouse_position())
		if currentPosition != lastPosition:
			queuedPoints.append(currentPosition)
			newPoints = true
	elif event.is_action_released(&"leftMouse") and drawing:
		drawing = false
		lastPosition = Vector2i(-1, -1)
		bakePreview()
		queue_redraw()

# Show the preview before it gets baked
func _draw() -> void:
	if !drawing: return
	# The draw function needs a texture version of the queued image
	previewTexture.update(queuedImage)
	draw_texture(previewTexture, Vector2.ZERO)

# Create an image and texture for the brush stamp
func setBrushStamp() -> void:
	brushStamp = Image.create_empty(brushRadius, brushRadius, false, Image.FORMAT_RGBA8)
	brushStamp.fill(Color(0.0, 0.0, 0.0, 0.0))
	# The brush stamp is a pixelated circle
	var center: float = (brushRadius - 1) / 2.0
	# Draw the brush stamp
	for x: int in range(brushRadius):
		for y: int in range(brushRadius):
			var distance: float = ((x - center) ** 2) + ((y - center) ** 2)
			if distance <= (brushRadius / 2.0) ** 2:
				if toolSelected == Tools.ERASER:
					var outline: float = maxf(0.0, (brushRadius / 2.0) - 1.0) ** 2
					if distance < outline:
						brushStamp.set_pixel(x, y, Color(0.16, 0.16, 0.16, 1.0))
					else:
						brushStamp.set_pixel(x, y, Color(0.32, 0.637, 1.0, 1.0))
				else:
					brushStamp.set_pixel(x, y, color)
	# Set stamp preview
	brushStampPreview.texture = ImageTexture.create_from_image(brushStamp)
	brushStampPreview.modulate.a = alpha
	brushStampPreview.set_deferred(&"size", Vector2(0.0, 0.0))

# Stamp the brush onto the preview
func stampOnPreview(center: Vector2i) -> void:
	var trueCenter: Vector2i = center - Vector2i(brushRadius / 2, brushRadius / 2)
	if toolSelected == Tools.ERASER:
		# The eraser uses blit_rect_mask to clear pixels with the brush stamp
		var source: Image = Image.create(brushRadius, brushRadius, false, Image.FORMAT_RGBA8)
		source.fill(Color(0.0, 0.0, 0.0, 0.0))
		queuedImage.blit_rect_mask(
			source,
			brushStamp,
			Rect2i(0, 0, brushRadius, brushRadius),
			trueCenter
		)
	else:
		# The brush tool simply blends the brush stamp onto the image
		queuedImage.blend_rect(brushStamp, Rect2i(0, 0, brushRadius, brushRadius), trueCenter)

# Update the image by setting the actual texture to the preview
func bakePreview() -> void:
	editableImage.blit_rect(queuedImage, Rect2i(Vector2i.ZERO, CANVAS_SIZE), Vector2i.ZERO)
	texture = ImageTexture.create_from_image(editableImage)
	queuedImage.fill(Color(0.0, 0.0, 0.0, 0.0))
	updateFrame()

# Emit frameUpdated with the new texture and a cropped texture
func updateFrame() -> void:
	# An empty image becomes a 1x1 transparent texture
	var usedRect: Rect2i = editableImage.get_used_rect()
	if (usedRect.size.x <= 0) or usedRect.size.y <= 0:
			var empty: ImageTexture = ImageTexture.create_from_image(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
			frameUpdated.emit(empty, empty)
			return
	var cropped: Image = editableImage.get_region(usedRect)
	frameUpdated.emit(texture, ImageTexture.create_from_image(cropped))

#func withinCanvas(coord: Vector2i) -> bool:
	#return (coord.x >= 0) and (coord.x < CANVAS_SIZE.x) and (coord.y >= 0) and (coord.y < CANVAS_SIZE.y)
