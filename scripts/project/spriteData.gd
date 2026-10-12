class_name SpriteData
extends AnimatedSprite2D

#const VAR_GRAPHIC: PackedScene = preload("uid://bawekqtjf8tpg")

#@onready var directionGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var xposGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var yposGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var sizeGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
#@onready var opacityGraphic: VarGraphic = VAR_GRAPHIC.instantiate()

@export var gameView: GameView
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
# Used to calculate the bounding box of the visible area of the texture
var frameCollisions: Dictionary[int, CollisionShape2D] = {}
var touchingMouse := false
var spriteID: int
var disableBoundsUpdate := true
@export var sizeMultiplier: Vector2 = Vector2.ONE

# master: clones touching
var collisions: Dictionary[Sprite, int]

var spriteName: String = "?"
@export var spritePos: Vector2 = Vector2.ZERO:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)
		#changePos.emit(value)
		updateBoundingBox()

@export var direction: float = 90.0:
	set(value):
		direction = wrapf(value, -180.0, 180.0)
		rotation_degrees = direction - 90.0
		#changeDirection.emit(value)
		updateBoundingBox()

@export var size: float = 100.0:
	set(value):
		size = max(0.0, value)
		updateSize()
		updateBoundingBox()
@export var stretch: Vector2 = Vector2.ZERO:
	set(value):
		stretch = Vector2(max(-100.0, value.x), max(-100.0, value.y))
		updateSize()
		updateBoundingBox()

@export var opacity: float = 100.0:
	set(value):
		opacity = clampf(value, 0.0, 100.0)
		modulate.a = opacity / 100.0

@export var spriteFrame: int = 0:
	set(value):
		frame = value
		spriteFrame = value
		updateBoundingBox()

func updateSize() -> void:
	var baseScale: float = size / 100.0
	scale = Vector2(
		baseScale * ((stretch.x / 100.0) + 1.0),
		baseScale * ((stretch.y / 100.0) + 1.0)
	) * sizeMultiplier

func updateBoundingBox() -> void:
	if disableBoundsUpdate: return
	var collisionShape: CollisionShape2D = frameCollisions[spriteFrame]
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
	if usedRect.has_area():
		var collision: CollisionShape2D = ParseData.imageRectToCollision(usedRect)
		add_child(collision)
		frameCollisions[frameCollisions.size()] = collision
	else:
		var placeholder: CollisionShape2D = CollisionShape2D.new()
		add_child(placeholder)
		frameCollisions[frameCollisions.size()] = placeholder

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
