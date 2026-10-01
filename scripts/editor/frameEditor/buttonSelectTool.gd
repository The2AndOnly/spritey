extends Button

@export var tool: BitmapFrame.Tools
@export var bitmapFrame: BitmapFrame

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	bitmapFrame.toolSelected = tool
