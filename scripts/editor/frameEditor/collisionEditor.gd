extends ColorRect

@onready var CANVAS_SIZE = BitmapFrame.CANVAS_SIZE
@export var bitmapFrame: BitmapFrame
@export var editor: Editor
var drawCollisions: Array[DrawCollision] = []

func _ready() -> void:
	bitmapFrame.frameUpdated.connect(onUpdate)

func onUpdate(newFrame: Texture2D) -> void:
	var spriteCollisions: Dictionary[int, Array] = editor.selectedSprite.frameCollisions
	var collisionShapes: Array = spriteCollisions[bitmapFrame.frameID]
	if collisionShapes[0].autoShape:
		for i: SpriteCollisionShape in collisionShapes:
			i.queue_free()
		var croppedImage: Rect2i = newFrame.get_image().get_used_rect()
		var newShape: SpriteCollisionShape = ParseData.imageRectToCollision(croppedImage)
		newShape.autoShape = true
		editor.selectedSprite.get_child(0).add_child(newShape)
		spriteCollisions[bitmapFrame.frameID] = [newShape]
		showCollisions(spriteCollisions)

func showCollisions(spriteCollisions: Dictionary[int, Array]) -> void:
	for i: DrawCollision in drawCollisions:
		i.queue_free()
	drawCollisions.clear()
	for i: SpriteCollisionShape in spriteCollisions[bitmapFrame.frameID]:
		var collision: DrawCollision = DrawCollision.new()
		var shape: Shape2D = i.shape
		if shape is RectangleShape2D:
			var rectangle: RectangleShape2D = RectangleShape2D.new()
			rectangle.size = shape.size
			collision.position = i.position + Vector2(CANVAS_SIZE / 2)
			collision.shape = rectangle
			add_child(collision)
			drawCollisions.append(collision)
