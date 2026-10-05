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
var clones: Array[Sprite] = []
var original: Sprite = null
# Index is the frame number
var frameNames: Array[String] = []
var croppedFrames: Array[Texture2D] = []
var frameImages: Array[Image] = []

var spriteName: String = "?"
var spritePos: Vector2 = Vector2.ZERO:
	set(value):
		spritePos = value
		position = gameView.toLocalCoords(value)
		#changePos.emit(value)

var direction: float = 90.0:
	set(value):
		direction = wrapf(value, -180.0, 180.0)
		rotation_degrees = direction - 90.0
		#changeDirection.emit(value)

var size: float = 100.0:
	set(value):
		size = max(0.0, value)
		updateSize()
var stretch: Vector2 = Vector2.ZERO:
	set(value):
		stretch = Vector2(max(-100.0, value.x), max(-100.0, value.y))
		updateSize()

var opacity: float = 100.0:
	set(value):
		opacity = clampf(value, 0.0, 100.0)
		modulate.a = opacity / 100.0

func updateSize() -> void:
	var baseScale: float = size / 100.0
	scale = Vector2(
		baseScale * ((stretch.x / 100.0) + 1.0),
		baseScale * ((stretch.y / 100.0) + 1.0)
	)

func addFrame(newFrame: Texture2D, frameName: String) -> void:
	var resizedTexture: Texture2D = ParseData.forceTextureSize(newFrame)
	sprite_frames.add_frame(&"default", resizedTexture)
	frameNames.append(ParseData.findUniqueName(frameName, frameNames))
	croppedFrames.append(ParseData.cropTexture(newFrame))
	frameImages.append(resizedTexture.get_image())

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
