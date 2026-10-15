class_name SpriteDrawLayer
extends Node2D

var drawTexture: ImageTexture
var drawImage: Image
var emptyCanvas: Image
var pendingChanges := false

func _ready() -> void:
	emptyCanvas = Image.create_empty(1280, 720, false, Image.FORMAT_RGBA8)
	drawImage = emptyCanvas.duplicate()
	drawTexture = ImageTexture.create_from_image(drawImage)

func _draw() -> void:
	drawTexture.update(drawImage)
	draw_texture(drawTexture, Vector2.ZERO)
	pendingChanges = false

func interpolateStroke(targetPosition: Vector2, lastPosition: Vector2, brushStamp: Image, brushRadius: int, toolSelected: int) -> void:
	var trueTargetPos: Vector2 = targetPosition - position
	var trueLastPos: Vector2 = lastPosition - position
	if trueTargetPos != trueLastPos:
		var distance: float = Vector2(trueLastPos).distance_to(Vector2(trueTargetPos))
		var steps: int = int(distance / maxf(1.0, float(brushRadius) * 0.05))
		if steps == 0:
			stampBrush(trueTargetPos, brushStamp, brushRadius, toolSelected)
		else:
			for i: int in range(1, steps + 1):
				var weight: float = i / float(steps)
				var interpolated: Vector2 = Vector2(trueLastPos).lerp(Vector2(trueTargetPos), weight).round()
				stampBrush(Vector2(interpolated), brushStamp, brushRadius, toolSelected)

func stampBrush(center: Vector2, brushStamp: Image, brushRadius: int, toolSelected: int) -> void:
	var trueCenter: Vector2 = center - Vector2(brushRadius / 2, brushRadius / 2)
	if toolSelected == 1:
		# The eraser uses blit_rect_mask to clear pixels with the brush stamp
		var source: Image = Image.create(brushRadius, brushRadius, false, Image.FORMAT_RGBA8)
		source.fill(Color(0.0, 0.0, 0.0, 0.0))
		drawImage.blit_rect_mask(
			source,
			brushStamp,
			Rect2i(0, 0, brushRadius, brushRadius),
			Vector2i(trueCenter))
	else:
		# The brush tool simply blends the brush stamp onto the image
		drawImage.blend_rect(brushStamp, Rect2i(0, 0, brushRadius, brushRadius), Vector2i(trueCenter))
	pendingChanges = true

func clearAll() -> void:
	drawImage = emptyCanvas.duplicate()
	pendingChanges = true

#func stampFrame(frame: Image, rect: Rect2i, center: Vector2) -> void:
	#drawImage.blend_rect(frame, rect, Vector2i(center - position))
	#pendingChanges = true
