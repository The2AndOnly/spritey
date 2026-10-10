extends ColorRect

@onready var CANVAS_SIZE = BitmapFrame.CANVAS_SIZE
@export var bitmapFrame: BitmapFrame
@export var editor: Editor
var enabled := false
var drawCollisions: Array[DrawCollision] = []
var dragCreate: DrawCollision = null
var shapeDragStart: Vector2 = Vector2.ZERO

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
		newShape.frameNumber = bitmapFrame.frameID
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
			collision.position = i.position + Vector2(CANVAS_SIZE / 2.0)
			collision.shape = rectangle
			add_child(collision)
			drawCollisions.append(collision)

func _input(event: InputEvent) -> void:
	if !enabled: return
	if event is InputEventMouseMotion:
		if !dragCreate: return
		# Adjust preview while dragging
		var shape: RectangleShape2D = dragCreate.shape
		shape.size = (get_local_mouse_position() - shapeDragStart).abs()
		dragCreate.position = shapeDragStart + shape.size / 2.0
		if get_local_mouse_position().y < shapeDragStart.y:
			dragCreate.position.y -= shape.size.y
		if get_local_mouse_position().x < shapeDragStart.x:
			dragCreate.position.x -= shape.size.x
	elif event.is_action_pressed(&"leftMouse"):
		# Create preview collision
		dragCreate = DrawCollision.new()
		shapeDragStart = get_local_mouse_position()
		dragCreate.position = shapeDragStart
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(0.0, 0.0)
		dragCreate.shape = shape
		add_child(dragCreate)
	elif event.is_action_released(&"leftMouse"):
		if !dragCreate: return
		if (dragCreate.shape.size.x == 0.0) or (dragCreate.shape.size.y == 0.0):
			dragCreate.queue_free()
			return
		# Add collision to sprite from preview
		var sprite: Sprite = editor.selectedSprite
		var frame: int = bitmapFrame.frameID
		if !sprite.frameCollisions.is_empty():
			sprite.frameCollisions[frame][0].autoShape = false
		var newCollision: SpriteCollisionShape = SpriteCollisionShape.new()
		newCollision.frameNumber = frame
		var newShape: RectangleShape2D = RectangleShape2D.new()
		newShape.size = dragCreate.shape.size
		newCollision.shape = newShape
		newCollision.position = dragCreate.position - CANVAS_SIZE / 2.0
		sprite.frameCollisions[frame].append(newCollision)
		sprite.get_child(0).add_child(newCollision)
		drawCollisions.append(dragCreate)
		dragCreate = null
	
	
	
	
