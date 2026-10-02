class_name SpriteEntry
extends Button

var previewTexture: Texture2D
var sprite: Sprite
var editor: Editor
var frameDispaly: int = 0

@export var entryTexture: TextureRect

func _ready() -> void:
	entryTexture.texture = ParseData.cropTexture(previewTexture)
	editor.changedView.connect(changedView)
	pressed.connect(onPress)
	var refreshTimer: Timer = Timer.new()
	refreshTimer.wait_time = 1.0
	refreshTimer.timeout.connect(onRefresh.bind(false))
	add_child(refreshTimer)
	refreshTimer.start()

func onPress() -> void:
	editor.selectedSprite = sprite

func changedView(view: StringName) -> void:
	if view == &"sprites":
		onRefresh(true)

# If one of the frames could have been changed by editing it, then update the texture no matter what
func onRefresh(possibleChange: bool) -> void:
	if (frameDispaly == sprite.frame) and !possibleChange: return
	frameDispaly = sprite.frame
	var spriteTexture: Texture2D = sprite.sprite_frames.get_frame_texture(&"default", frameDispaly)
	entryTexture.texture = ParseData.cropTexture(spriteTexture)
