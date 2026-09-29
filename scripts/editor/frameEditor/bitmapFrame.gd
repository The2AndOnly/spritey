class_name BitmapFrame
extends TextureRect

var editable_image: Image
var image_texture: ImageTexture

func showFrame() -> void:
	# 1. Extract the Image data from the existing Texture2D
	if texture:
		editable_image = texture.get_image()
		# Ensure the image is uncompressed so we can use set_pixel
		if editable_image.is_compressed():
			editable_image.decompress()
	else:
		push_error("No texture assigned to TextureRect!")
		return

	# 2. Create an ImageTexture wrapper and assign it back to this TextureRect
	image_texture = ImageTexture.create_from_image(editable_image)
	texture = image_texture


func _gui_input(event: InputEvent) -> void:
	# Check for left-click press or drag inside the TextureRect
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draw_at_mouse(event.position)
	elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		draw_at_mouse(event.position)


func draw_at_mouse(local_pos: Vector2) -> void:
	# Convert local UI coordinates to actual pixel coordinates on the image
	var tex_size = editable_image.get_size()
	var pixel_x = int(local_pos.x * (tex_size.x / size.x))
	var pixel_y = int(local_pos.y * (tex_size.y / size.y))

	# Boundary check to prevent crash if clicked outside bounds
	if pixel_x >= 0 and pixel_x < tex_size.x and pixel_y >= 0 and pixel_y < tex_size.y:
		# Set pixel to black
		editable_image.set_pixel(pixel_x, pixel_y, Color.BLACK)
		
		# Update the GPU texture
		image_texture.update(editable_image)
