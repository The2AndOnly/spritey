extends VBoxContainer

@export var editor: Editor
@export var gameView: GameView
@export var nameField: LineEdit
@export var xposField: LineEdit
@export var yposField: LineEdit
@export var directionField: LineEdit
@export var sizeField: LineEdit
@export var visibleTrue: Button
@export var visibleFalse: Button
var currentSprite: Sprite
var spriteName: String
var xpos: String
var ypos: String
var direction: String
var spriteSize: String
var spriteVisible: bool

func _ready() -> void:
	editor.changedSelectedSprite.connect(newSelectedSprite)
	xposField.text_changed.connect(xposTextChanged)
	yposField.text_changed.connect(yposTextChanged)
	directionField.text_changed.connect(directionTextChanged)
	sizeField.text_changed.connect(sizeTextChanged)
	visibleTrue.pressed.connect(visibleChanged.bind(true))
	visibleFalse.pressed.connect(visibleChanged.bind(false))
	# For fields to react after submitting
	yposField.text_submitted.connect(yposSubmitted)
	yposField.focus_exited.connect(yposFocusExit)
	xposField.text_submitted.connect(xposSubmitted)
	xposField.focus_exited.connect(xposFocusExit)
	directionField.text_submitted.connect(directionSubmitted)
	directionField.focus_exited.connect(directionFocusExit)
	sizeField.text_submitted.connect(sizeSubmitted)
	sizeField.focus_exited.connect(sizeFocusExit)
	nameField.text_submitted.connect(nameSubmitted)
	nameField.focus_exited.connect(nameFocusExit)

func newSelectedSprite(sprite: Sprite) -> void:
	currentSprite = sprite
	nameField.text = sprite.spriteName
	setDisplays()

func _process(_delta: float) -> void:
	if currentSprite: # TODO: remove in future, there should always be a current sprite (the background)
		setDisplays()

func setDisplays() -> void:
	xpos = ParseData.stringNumber(currentSprite.spritePos.x)
	ypos = ParseData.stringNumber(currentSprite.spritePos.y)
	direction = ParseData.stringNumber(currentSprite.direction)
	spriteSize = ParseData.stringNumber(currentSprite.size)
	if xposField.text != xpos: xposField.text = xpos
	if yposField.text != ypos: yposField.text = ypos
	if directionField.text != direction: directionField.text = direction
	if sizeField.text != spriteSize: sizeField.text = spriteSize
	
	if currentSprite.visible:
		visibleTrue.button_pressed = true
	else:
		visibleFalse.button_pressed = true

func xposTextChanged(newText: String) -> void:
	currentSprite.spritePos.x = float(newText)
func xposSubmitted(newText: String) -> void:
	xposField.text = ParseData.stringNumber(float(newText))
func xposFocusExit() -> void:
	xposSubmitted(xposField.text)

func yposTextChanged(newText: String) -> void:
	currentSprite.spritePos.y = float(newText)
func yposSubmitted(newText: String) -> void:
	yposField.text = ParseData.stringNumber(float(newText))
func yposFocusExit() -> void:
	yposSubmitted(yposField.text)

func directionTextChanged(newText: String) -> void:
	currentSprite.direction = float(newText)
func directionSubmitted(newText: String) -> void:
	directionField.text = ParseData.stringNumber(wrapf(float(newText), -180.0, 180.0))
func directionFocusExit() -> void:
	directionSubmitted(directionField.text)

func sizeTextChanged(newText: String) -> void:
	currentSprite.size = float(newText)
func sizeSubmitted(newText: String) -> void:
	sizeField.text = ParseData.stringNumber(max(0.0, float(newText)))
func sizeFocusExit() -> void:
	sizeSubmitted(sizeField.text)

func visibleChanged(visibility: bool) -> void:
	currentSprite.visible = visibility

func nameSubmitted(newText: String) -> void:
	if newText.strip_edges() == "":
		nameField.text = currentSprite.spriteName
		return
	var names: Array[String] = []
	for i: Sprite in gameView.sprites:
		if i != currentSprite: names.append(i.spriteName)
	currentSprite.spriteName = ParseData.findUniqueName(newText, names)
	nameField.text = currentSprite.spriteName
func nameFocusExit() -> void:
	nameSubmitted(nameField.text)
