class_name SpriteEntry
extends Button

var previewTexture: Texture2D
var sprite: Sprite
var editor: Editor
var frameDispaly: int = 0

@export var entryTexture: TextureRect

func _ready() -> void:
	entryTexture.texture = ParseData.cropTexture(previewTexture.get_image())
	editor.changedView.connect(changedView)
	pressed.connect(onPress)
	var refreshTimer: Timer = Timer.new()
	refreshTimer.wait_time = 0.3
	refreshTimer.timeout.connect(onRefresh)
	add_child(refreshTimer)
	refreshTimer.start()

func onPress() -> void:
	editor.selectedSprite = sprite

func changedView(view: StringName) -> void:
	if view == &"sprites":
		onRefresh()

func onRefresh() -> void:
	entryTexture.texture = sprite.croppedFrames[sprite.frame]
