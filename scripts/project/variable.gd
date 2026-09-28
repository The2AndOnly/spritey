class_name Variable
extends Object

const VAR_GRAPHIC: PackedScene = preload("uid://bawekqtjf8tpg")

var sprite: Sprite = null
var name: String = ""
var value: String = "":
	set(val):
		value = val
		if visible: setGraphicValue(val)
var graphic: VarGraphic
var position: Vector2 = Vector2.ZERO
var visible := false:
	set(val):
		visible = val
		graphic.visible = val
		if val: setGraphicValue(value)
var gameView: GameView

func setGraphicValue(graphicValue: String) -> void:
	if graphicValue.is_valid_float():
		graphic.valueLabel.text = ParseData.stringNumber(float(graphicValue))
	else:
		graphic.valueLabel.text = graphicValue

func _init(varName: String, varGameView: GameView, defaultValue: String, spriteOwner: Sprite = null) -> void:
	name = varName
	value = defaultValue
	sprite = spriteOwner
	gameView = varGameView
	var newGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
	gameView.projectUI.add_child(newGraphic)
	newGraphic.nameLabel.text = "%s: %s" % [spriteOwner.name, varName] if spriteOwner else varName
	newGraphic.visible = false
	newGraphic.gameView = varGameView
	graphic = newGraphic
