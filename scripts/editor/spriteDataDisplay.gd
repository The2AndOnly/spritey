extends VBoxContainer

@export var editor: Editor
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
	# Extra signals for fields that react after submitting
	directionField.text_submitted.connect(directionSubmitted)
	directionField.focus_exited.connect(directionFocusExit)
	nameField.text_submitted.connect(nameSubmitted)
	nameField.focus_exited.connect(nameFocusExit)

func newSelectedSprite(sprite: Sprite) -> void:
	currentSprite = sprite
	nameField.text = sprite.name
	setDisplays()

func _process(_delta: float) -> void:
	if currentSprite: # TODO: remove in future, there should always be a current sprite (the background)
		if currentSprite.activeStacks.is_empty(): return
		setDisplays()

func setDisplays() -> void:
	xpos = displayNumber(currentSprite.spritePos.x)
	ypos = displayNumber(currentSprite.spritePos.y)
	direction = displayNumber(currentSprite.direction)
	spriteSize = displayNumber(currentSprite.size)
	if xposField.text != xpos: xposField.text = xpos
	if yposField.text != ypos: yposField.text = ypos
	if directionField.text != direction: directionField.text = direction
	if sizeField.text != spriteSize: sizeField.text = spriteSize
	
	if currentSprite.visible:
		visibleTrue.button_pressed = true
	else:
		visibleFalse.button_pressed = true

func displayNumber(value: float) -> String:
	if is_equal_approx(value, floorf(value)):
		return str(int(value))
	else:
		return "%.1f" % value

func xposTextChanged(newText: String) -> void:
	currentSprite.spritePos.x = float(newText)

func yposTextChanged(newText: String) -> void:
	currentSprite.spritePos.y = float(newText)

func directionTextChanged(newText: String) -> void:
	currentSprite.direction = float(newText)
func directionSubmitted(newText: String) -> void:
	directionField.text = displayNumber(wrapf(float(newText), -180.0, 180.0))
func directionFocusExit() -> void:
	directionSubmitted(directionField.text)

func sizeTextChanged(newText: String) -> void:
	currentSprite.size = float(newText)

func visibleChanged(visibility: bool) -> void:
	currentSprite.visible = visibility

func nameSubmitted(newText: String) -> void:
	if newText == "":
		nameField.text = currentSprite.name
		return
	var names: Array[String] = []
	for i: Sprite in editor.sprites:
		if i != currentSprite: names.append(i.name)
	currentSprite.name = editor.findUniqueName(newText, names)
	nameField.text = currentSprite.name
func nameFocusExit() -> void:
	nameSubmitted(nameField.text)
