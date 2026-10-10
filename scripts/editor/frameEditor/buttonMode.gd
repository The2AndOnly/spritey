extends Button

@export var bitmapFrame: BitmapFrame
@export var mode: StringName = &"collisions"
@export var collisionLayer: ColorRect
@export var enabledWithMode: Array[Control]
@export var disabledWithMode: Array[Control]

func _ready() -> void:
	pressed.connect(onPress)

func onPress() -> void:
	for i: Control in enabledWithMode:
		i.visible = button_pressed
	for i: Control in disabledWithMode:
		i.visible = !button_pressed
	match mode:
		&"collisions":
			bitmapFrame.disabled = button_pressed
			collisionLayer.enabled = button_pressed
