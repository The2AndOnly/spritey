extends Button

const FRAME_ENTRY: PackedScene = preload("uid://cak3veot0rt61")
const FRAME_SELECTOR_GROUP: ButtonGroup = preload("uid://ysu73lx0nf7n")
@export var action: StringName
@export var editor: Editor
@export var bitmapEdit: BitmapFrame
@export var frameNameField: LineEdit
@export var frameEntryContainer: VBoxContainer
@export var fileDialog: FileDialog

var firstFileOpen := true

func _ready() -> void:
	pressed.connect(onPress)
	if fileDialog:
		fileDialog.files_selected.connect(filesSelected)

func onPress() -> void:
	match action:
		&"empty":
			addFrame(ImageTexture.create_from_image(Image.create_empty(1280, 720, false, Image.FORMAT_RGBA8)), "frame1")
		&"upload":
			if firstFileOpen:
				fileDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
				firstFileOpen = false
			fileDialog.popup_file_dialog()

func addFrame(newFrame: Texture2D, newName: String, forcePress: bool = true) -> void:
	var selectedSprite: Sprite = editor.selectedSprite
	var uniqueName: String = ParseData.findUniqueName(newName, selectedSprite.frameNames)
	selectedSprite.addFrame(newFrame, uniqueName)
	var entry: FrameEntry = FRAME_ENTRY.instantiate()
	entry.textureData = newFrame
	entry.bitmapEdit = bitmapEdit
	entry.sprite = selectedSprite
	entry.frameID = selectedSprite.frameNames.size() - 1
	entry.nameField = frameNameField
	frameEntryContainer.add_child(entry)
	entry.button_group = FRAME_SELECTOR_GROUP
	if forcePress:
		entry.button_pressed = true
		entry.onPress()

func filesSelected(paths: PackedStringArray) -> void:
	for i: int in paths.size():
		var path: String = paths[i]
		var fileBytes = FileAccess.get_file_as_bytes(path)
		if fileBytes.is_empty(): return
		var uploaded: Image = Image.new()
		var error: Error = ERR_FILE_CORRUPT
		# Read the first four bytes to find the true file type of the image
		var firstFourBytes = fileBytes.slice(0, 4).hex_encode()
		if firstFourBytes.begins_with("89504e47"):
			error = uploaded.load_png_from_buffer(fileBytes)
		elif firstFourBytes.begins_with("52494646"):
			error = uploaded.load_webp_from_buffer(fileBytes)
		elif firstFourBytes.begins_with("ffd8ff"):
			error = uploaded.load_jpg_from_buffer(fileBytes)
		else:
			error = uploaded.load(path)
		if error == OK:
			addFrame(ParseData.forceTextureSize(ImageTexture.create_from_image(uploaded)), path.get_basename().get_file(), i == paths.size() - 1)
		else:
			print(error)
