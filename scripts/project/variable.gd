class_name Variable
extends Object

const VAR_GRAPHIC: PackedScene = preload("uid://bawekqtjf8tpg")

var sprite: Sprite = null
var name: String = "?"
var value: String = "":
	set(val):
		value = val
		changeValue.emit(val)
var graphic: VarGraphic
var position: Vector2 = Vector2.ZERO
var visible := false:
	set(val):
		visible = val
		graphic.visible = val
		changeValue.emit(value)
var gameView: GameView

signal changeValue(new: String)

func _init(varName: String, varGameView: GameView, defaultValue: String, spriteOwner: Sprite = null) -> void:
	name = varName
	value = defaultValue
	sprite = spriteOwner
	gameView = varGameView
	var newGraphic: VarGraphic = VAR_GRAPHIC.instantiate()
	newGraphic.gameView = varGameView
	newGraphic.variable = self
	gameView.projectUI.add_child(newGraphic)
	newGraphic.nameLabel.text = "%s: %s" % [spriteOwner.spriteName, varName] if spriteOwner else varName
	newGraphic.visible = false
	graphic = newGraphic
