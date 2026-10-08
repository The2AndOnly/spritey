class_name ParseData
extends Object

static func castType(type: int, value: Variant) -> Variant:
	match type:
		0: # integer
			return int(value)
		1: # float
			return float(value)
		2: # string
			if value is float:
				return stringNumber(value)
			return str(value)
		3: # positive integer
			return max(0, int(value))
		4: # positive float
			return max(0.0, float(value))
		5: # bool (has no casting since only bool blocks can be inserted)
			return value
	return null

static func stringNumber(value: float) -> String:
	return ("%.3f" % value).rstrip("0").trim_suffix(".")

static func findUniqueName(desired: String, existing: Array[String]) -> String:
	if !existing.has(desired.strip_edges()): return desired.strip_edges()
	var regex: RegEx = RegEx.new()
	# Splits name into text (with whitespaces) and the number at the end
	regex.compile("^(.*?)(\\d+)?$")
	var result: RegExMatch = regex.search(desired)
	var baseName: String = result.get_string(1).strip_edges(true, false)
	var countStart: int = 2
	
	var count: int = countStart
	var possibleName: String = "%s%d" % [baseName, count]
	while existing.has(possibleName):
		count += 1
		possibleName = "%s%d" % [baseName, count]
	return possibleName.strip_edges()

static func forceTextureSize(source: Texture2D, size: Vector2i = Vector2i(1280, 720)) -> Texture2D:
	var sourceImage: Image = source.get_image()
	var sourceSize: Vector2i = sourceImage.get_size()
	# Shrink images larger than the target size to fit
	if (sourceSize.x > size.x) or sourceSize.y > size.y:
		var scale: float = minf(float(size.x) / float(sourceSize.x), float(size.y) / float(sourceSize.y))
		var newSize: Vector2i = Vector2i(int(sourceSize.x * scale), int(sourceSize.y * scale))
		sourceImage.resize(newSize.x, newSize.y, Image.INTERPOLATE_NEAREST)
		sourceSize = sourceImage.get_size()
	# Make a transparent image with the specified size and center the source onto it
	var newImage: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	newImage.fill(Color(0.0, 0.0, 0.0, 0.0))
	if sourceImage.is_compressed():
		sourceImage.decompress()
	sourceImage.convert(Image.FORMAT_RGBA8)
	# Center source image on the canvas
	var sourceX: int = (size.x - sourceSize.x) / 2
	var sourceY: int = (size.y - sourceSize.y) / 2
	newImage.blit_rect(sourceImage, Rect2i(Vector2i.ZERO, sourceSize), Vector2i(sourceX, sourceY))
	return ImageTexture.create_from_image(newImage)

static func cropTexture(sourceImage: Image) -> Texture2D:
	var usedRect: Rect2i = sourceImage.get_used_rect()
	# An empty image becomes a 1x1 transparent texture
	if !usedRect.has_area():
			var empty: ImageTexture = ImageTexture.create_from_image(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
			return empty
	return ImageTexture.create_from_image(sourceImage.get_region(usedRect))

static func imageRectToCollision(sourceRect: Rect2i) -> SpriteCollisionShape:
	var collision: SpriteCollisionShape = SpriteCollisionShape.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = sourceRect.size
	collision.shape = shape
	# Sprite center origin offset
	collision.position = sourceRect.position - Vector2i(640, 360)
	# Shape center origin offset
	collision.position += shape.size / 2.0
	collision.autoShape = true
	return collision
