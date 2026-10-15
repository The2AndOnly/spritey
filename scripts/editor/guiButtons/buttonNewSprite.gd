extends Button

const SPRITE_ENTRY: PackedScene = preload("uid://b4g1hm5dt1b7m")
const SPRITE_SELECTOR_GROUP: ButtonGroup = preload("uid://g30w58c26scg")
const ORANGE_MOE_1: Texture2D = preload("uid://dhmontm0rmbj8")
const ORANGE_MOE_2: Texture2D = preload("uid://duqpnvqse6a60")
const ORANGE_MOE_3: Texture2D = preload("uid://nwlo51p3pbda")

@export var spriteEntryContainer: GridContainer
@export var gameView: GameView
@export var editor: Editor

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	var spriteEntry: SpriteEntry = SPRITE_ENTRY.instantiate()
	spriteEntry.editor = editor
	spriteEntry.button_group = SPRITE_SELECTOR_GROUP
	spriteEntry.button_pressed = true
	
	var sprite: Sprite = Sprite.new()
	sprite.gameView = gameView
	# Set up sprite textures
	var spriteFrames: SpriteFrames = SpriteFrames.new()
	sprite.sprite_frames = spriteFrames
	sprite.spriteScript = { 0: { &"block": &"event_start", &"top": true, &"pos": Vector2(0, 0), &"z": 3, &"value": false, &"next": 1 }, 1: { &"block": &"vis_setSize", &"top": false, &"value": false, &"next": 2, &"inputs": [[0, 1, "30"]] }, 2: { &"block": &"ctrl_repeat", &"top": false, &"value": false, &"nest": 3, &"inputs": [[0, 3, "300"]] }, 3: { &"block": &"ctrl_createClone", &"top": false, &"value": false, &"inputs": [[2, 0]] }, 4: { &"block": &"ctrl_cloneStart", &"top": true, &"pos": Vector2(563, 18), &"z": 7, &"value": false, &"next": 5 }, 5: { &"block": &"ctrl_forever", &"top": false, &"value": false, &"nest": 6 }, 6: { &"block": &"trans_glideToOption", &"top": false, &"value": false, &"inputs": [[0, 4, "5"], [2, 1]] }, 7: { &"block": &"ctrl_forever", &"top": false, &"value": false, &"nest": 8 }, 8: { &"block": &"ctrl_ifElse", &"top": false, &"value": false, &"nest": 12, &"nest2": 11, &"inputs": [[1, 5, 10]] }, 9: { &"block": &"ctrl_cloneStart", &"top": true, &"pos": Vector2(561, 439), &"z": 10, &"value": false, &"next": 7 }, 10: { &"block": &"inter_touching", &"top": false, &"value": true, &"inputs": [[2, 1]] }, 11: { &"block": &"vis_setFrame", &"top": false, &"value": false, &"inputs": [[2, 0]] }, 12: { &"block": &"vis_setFrame", &"top": false, &"value": false, &"inputs": [[2, 1]] } }
	# Find a unique name and ID for the sprite
	var names: Array[String] = []
	for i: Sprite in gameView.sprites:
		names.append(i.spriteName)
	sprite.spriteName = ParseData.findUniqueName("sprite1", names)
	
	gameView.add_child(sprite)
	sprite.addFrame(ORANGE_MOE_1, "orange-moe-1")
	sprite.addFrame(ORANGE_MOE_2, "orange-moe-2")
	sprite.addFrame(ORANGE_MOE_3, "orange-moe-3")
	spriteEntry.previewTexture = sprite.frameTextures[0]
	# Each sprite has 500 free IDs ahead of it for potential clones
	var newID: int = gameView.sprites.size() * 501
	sprite.spriteID = newID
	gameView.idToSprite[newID] = sprite
	sprite.brushStamp = Strokes.setBrushStamp(sprite.strokeSize, 0, sprite.strokeColor)
	
	spriteEntryContainer.add_child(spriteEntry)
	sprite.disableBoundsUpdate = false
	sprite.spritePos = Vector2.ZERO
	spriteEntry.sprite = sprite
	gameView.sprites.append(sprite)
	editor.selectedSprite = sprite
