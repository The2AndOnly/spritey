class_name SpriteData
extends AnimatedSprite2D

#const VAR_GRAPHIC: PackedScene = preload("uid://bawekqtjf8tpg")

#@onready var directionGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var xposGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var yposGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var sizeGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var opacityGraphic: VarGraphic = VAR_GRAPHIC.instantiate()

var gameView: GameView
var spriteScript: Dictionary[int, Dictionary] = {}
var variables: Array[Variable] = []
# Used only by clones
var localValues: Dictionary[Variable, String]
var clones: Array[Sprite] = []
# The sprite this was cloned from
var original: Sprite = null
# The very original sprite
var master: Sprite = null
# Index is the frame number
var frameNames: Array[String] = []
var croppedFrames: Array[Texture2D] = []
var frameImages: Array[Image] = []
var frameTextures: Array[Texture2D] = []
# frame number: Array of SpriteCollisionShape
var frameCollisions: Dictionary[int, Array] = {}
var touchingMouse := false
var spriteID: int

# master: clones touching
var collisions: Dictionary[Sprite, int]

var spriteName: String = "?"
var spritePos: Vector2 = Vector2.ZERO:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)
		#changePos.emit(value)
		updateBoundingBox()

var direction: float = 90.0:
	set(value):
		direction = wrapf(value, -180.0, 180.0)
		rotation_degrees = direction - 90.0
		#changeDirection.emit(value)
		updateBoundingBox()

var size: float = 100.0:
	set(value):
		size = max(0.0, value)
		updateSize()
		updateBoundingBox()
var stretch: Vector2 = Vector2.ZERO:
	set(value):
		stretch = Vector2(max(-100.0, value.x), max(-100.0, value.y))
		updateSize()
		updateBoundingBox()

var opacity: float = 100.0:
	set(value):
		opacity = clampf(value, 0.0, 100.0)
		modulate.a = opacity / 100.0

var spriteFrame: int = 0:
	set(value):
		frame = value
		if spriteFrame != value:
			for i: SpriteCollisionShape in frameCollisions[spriteFrame]:
				i.disabled = true
			for i: SpriteCollisionShape in frameCollisions[value]:
				i.disabled = false
			spriteFrame = value
		updateBoundingBox()

func updateSize() -> void:
	var baseScale: float = size / 100.0
	scale = Vector2(
		baseScale * ((stretch.x / 100.0) + 1.0),
		baseScale * ((stretch.y / 100.0) + 1.0)
	)

func updateBoundingBox() -> void:
	var collisionShape: SpriteCollisionShape = frameCollisions[frame][0]
	if collisionShape.shape:
		var rect: Rect2 = collisionShape.shape.get_rect()
		gameView.spriteBoundingBox[spriteID] = collisionShape.global_transform * rect
	else:
		gameView.spriteBoundingBox[spriteID] = Rect2()

# Only disable autoCollision if another script adds its own collision to the frame
func addFrame(newFrame: Texture2D, frameName: String, autoCollision: bool = true) -> void:
	var resizedTexture: Texture2D = ParseData.forceTextureSize(newFrame)
	var image: Image = resizedTexture.get_image()
	var croppedTexture: Texture2D = ParseData.cropTexture(image)
	sprite_frames.add_frame(&"default", resizedTexture)
	frameNames.append(ParseData.findUniqueName(frameName, frameNames))
	croppedFrames.append(croppedTexture)
	frameImages.append(image)
	frameTextures.append(resizedTexture)
	# Add a basic bounding collision to the new frame
	if !autoCollision: return
	var usedRect: Rect2i = image.get_used_rect()
	var frameNumber: int = frameCollisions.size()
	if usedRect.has_area():
		var collision: SpriteCollisionShape = ParseData.imageRectToCollision(usedRect)
		get_child(0).add_child(collision)
		collision.frameNumber = frameNumber
		collision.disabled = true
		frameCollisions[frameNumber] = [collision]
	else:
		var placeholder: SpriteCollisionShape = SpriteCollisionShape.new()
		get_child(0).add_child(placeholder)
		placeholder.autoShape = true
		placeholder.frameNumber = frameNumber
		placeholder.disabled = true
		frameCollisions[frameNumber] = [placeholder]

func collisionEntered(area: Area2D) -> void:
	var detected: Sprite = area.get_parent().master
	collisions[detected] = collisions.get(detected, 0) + 1

func collisionExited(area: Area2D) -> void:
	var detected: Sprite = area.get_parent().master
	if collisions.has(detected):
		var count: int = collisions[detected] - 1
		if count <= 0:
			collisions.erase(detected)
		else:
			collisions[detected] = count

func collisionInput(_viewport: Node, event: InputEvent, _shapeIdx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				gameView.singleEvent(&"event_clickedCollision", [0], self)
				if event.double_click: gameView.singleEvent(&"event_clickedCollision", [1], self)
		elif event.button_index == 2:
			if event.pressed:
				gameView.singleEvent(&"event_clickedCollision", [2], self)

func mouseEntered() -> void:
	touchingMouse = true
func mouseExited() -> void:
	touchingMouse = false

#func _ready() -> void:
	#gameView.projectUI.add_child(directionGraphic)
	#gameView.projectUI.add_child(xposGraphic)
	#gameView.projectUI.add_child(yposGraphic)
	#gameView.projectUI.add_child(sizeGraphic)
	#gameView.projectUI.add_child(opacityGraphic)
	#directionGraphic.gameView = gameView
	#xposGraphic.gameView = gameView
	#yposGraphic.gameView = gameView
	#sizeGraphic.gameView = gameView
	#opacityGraphic.gameView = gameView
	## ready should only be called as a Sprite
	#directionGraphic.sprite = self
	#xposGraphic.sprite = self
	#yposGraphic.sprite = self
	#sizeGraphic.sprite = self
	#opacityGraphic.sprite = self
	#directionGraphic.spriteProperty = &"direction"
	#xposGraphic.spriteProperty = &"xpos"
	#yposGraphic.spriteProperty = &"ypos"
	#sizeGraphic.spriteProperty = &"size"
	#opacityGraphic.spriteProperty = &"opacity"
	#updateDataGraphicNames()
	#directionGraphic.valueLabel.text = ParseData.stringNumber(direction)
	#xposGraphic.valueLabel.text = ParseData.stringNumber(spritePos.x)
	#yposGraphic.valueLabel.text = ParseData.stringNumber(spritePos.y)
	#sizeGraphic.valueLabel.text = ParseData.stringNumber(size)
	#opacityGraphic.valueLabel.text = ParseData.stringNumber(opacity)
#
#func updateDataGraphicNames() -> void:
	#directionGraphic.nameLabel.text = "%s: %s" % [spriteName, "direction"]
	#xposGraphic.nameLabel.text = "%s: %s" % [spriteName, "x position"]
	#yposGraphic.nameLabel.text = "%s: %s" % [spriteName, "y position"]
	#sizeGraphic.nameLabel.text = "%s: %s" % [spriteName, "size"]
	#opacityGraphic.nameLabel.text = "%s: %s" % [spriteName, "opacity"]
#
#signal changeDirection(new: float)
#signal changePos(new: Vector2)
#signal changeSize(new: float)
#signal changeOpacity(new: float)
