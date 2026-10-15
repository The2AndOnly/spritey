class_name SpriteData
extends AnimatedSprite2D

const MESSAGE_BOX: PackedScene = preload("uid://btk72m2rs22ex")
const SPRITE_EFFECTS_MATERIAL: ShaderMaterial = preload("uid://binelk1vnjcyy")
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
var messageBox: MessageBox = null
var drawLayer: SpriteDrawLayer = null
@export var sizeMultiplier: Vector2 = Vector2.ONE

# master: clones touching
var collisions: Dictionary[Sprite, int]

var spriteName: String = "?"
var spriteVisible: bool = true:
	set(value):
		if visible == value: return
		visible = value
		spriteVisible = value
		if value:
			messageBox.modulate.a = 1.0
			disableBoundsUpdate = false
			updateBoundingBox()
		else:
			messageBox.modulate.a = 0.0
			disableBoundsUpdate = true

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

@export var effectsActive: int = 0:
	set(value):
		effectsActive = value
		if effectsActive == 0:
			if material:
				material = null
		else:
			if !material:
				material = SPRITE_EFFECTS_MATERIAL.duplicate()
				updateBoundingBox()

@export var effectBrightness: float = 0.0:
	set(value):
		if effectBrightness == 0.0:
			if value == 0.0:
				return
			else:
				effectsActive += 1
		else:
			if value == 0.0:
				material.set_shader_parameter(&"brightness", 0.0)
				effectBrightness = 0.0
				effectsActive -= 1
				return
		effectBrightness = value
		material.set_shader_parameter(&"brightness", value)
@export var effectHueShift: float = 0.0:
	set(value):
		if effectHueShift == 0.0:
			if value == 0.0:
				return
			else:
				effectsActive += 1
		else:
			if value == 0.0:
				material.set_shader_parameter(&"hueShift", 0.0)
				effectHueShift = 0.0
				effectsActive -= 1
				return
		effectHueShift = value
		material.set_shader_parameter(&"hueShift", value)
@export var effectSaturation: float = 0.0:
	set(value):
		if effectSaturation == 0.0:
			if value == 0.0:
				return
			else:
				effectsActive += 1
		else:
			if value == 0.0:
				material.set_shader_parameter(&"saturation", 0.0)
				effectSaturation = 0.0
				effectsActive -= 1
				return
		effectSaturation = value
		material.set_shader_parameter(&"saturation", value)
@export var effectFisheye: float = 0.0:
	set(value):
		if effectFisheye == 0.0:
			if value == 0.0:
				return
			else:
				effectsActive += 1
		else:
			if value == 0.0:
				material.set_shader_parameter(&"fisheye", 0.0)
				effectFisheye = 0.0
				effectsActive -= 1
				return
		effectFisheye = value
		material.set_shader_parameter(&"fisheye", value)

@export var strokeEnabled := false
@export var brushStamp: Image = null
@export var lastDrawPosition: Vector2 = Vector2.ZERO
@export var strokeSize: int = 3
@export var strokeColor: Color = Color(0.0, 0.68, 1.0, 1.0)
@export var strokeTool: int = 0

func updateSize() -> void:
	var baseScale: float = size / 100.0
	scale = Vector2(
		baseScale * ((stretch.x / 100.0) + 1.0),
		baseScale * ((stretch.y / 100.0) + 1.0)
	) * sizeMultiplier

func updateBoundingBox() -> void:
	if strokeEnabled and drawLayer:
		drawLayer.interpolateStroke(position, lastDrawPosition, brushStamp, strokeSize, strokeTool)
		lastDrawPosition = position
	if disableBoundsUpdate: return
	var collisionShape: CollisionShape2D = frameCollisions[spriteFrame]
	var boundingBox: Rect2
	if collisionShape.shape:
		var rect: Rect2 = collisionShape.shape.get_rect()
		boundingBox = collisionShape.global_transform * rect
	else:
		boundingBox = Rect2()
		boundingBox.position = position
	gameView.spriteBoundingBox[spriteID] = boundingBox
	if messageBox.visible: positionMessage()
	# Effects need a local bounding box
	## AI GENERATED
	if material and collisionShape.shape:
		# Get the rect in the collision shape's local space
		var shape_rect: Rect2 = collisionShape.shape.get_rect()
		
		# Transform it into the sprite's local space (using local transform, not global)
		var local_rect: Rect2 = collisionShape.transform * shape_rect
		
		# Since the sprite is centered, its local origin (0,0) is at the center (640, 360).
		# Shift the position so (0,0) matches the top-left of the 1280x720 texture.
		var top_left_x = local_rect.position.x + (1280.0 * 0.5)
		var top_left_y = local_rect.position.y + (720.0 * 0.5)
		
		# Normalize directly into 0.0 to 1.0 UV space
		var uv_rect = Vector4(
			top_left_x / 1280.0,
			top_left_y / 720.0,
			local_rect.size.x / 1280.0,
			local_rect.size.y / 720.0
		)
		material.set_shader_parameter(&"effect_rect", uv_rect)

func positionMessage() -> void:
	var boundingBox: Rect2 = gameView.spriteBoundingBox[spriteID]
	var canvasBounds: Rect2 = get_viewport().get_canvas_transform() * boundingBox
	var topCenter: Vector2 = Vector2(canvasBounds.position.x + (canvasBounds.size.x * 0.5), canvasBounds.position.y)
	messageBox.global_position = topCenter - Vector2(
		(messageBox.size.x * 0.5) * messageBox.scale.x,
		(messageBox.size.y + 90.0) * messageBox.scale.y)

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
	updateBoundingBox.call_deferred()

func _exit_tree() -> void:
	messageBox.queue_free()

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
