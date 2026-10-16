class_name Strokes
extends Node

# Tool selected
# 0 - brush
# 1 - eraser

static func setBrushStamp(brushRadius: int, toolSelected: int, color: Color) -> Image:
	var brushStamp: Image = Image.create_empty(brushRadius, brushRadius, false, Image.FORMAT_RGBA8)
	brushStamp.fill(Color(0.0, 0.0, 0.0, 0.0))
	# The brush stamp is a pixelated circle
	var center: float = (brushRadius - 1) * 0.5
	# Draw the brush stamp
	for x: int in range(brushRadius):
		for y: int in range(brushRadius):
			var distance: float = ((x - center) ** 2) + ((y - center) ** 2)
			if distance <= (brushRadius * 0.5) ** 2:
				if toolSelected == 1:
					var outline: float = maxf(0.0, (brushRadius * 0.5) - 1.0) ** 2
					if distance < outline:
						brushStamp.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.471))
					else:
						brushStamp.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.784))
				else:
					brushStamp.set_pixel(x, y, color)
	return brushStamp
