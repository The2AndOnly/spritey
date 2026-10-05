extends HBoxContainer

var blockColor: Color = Color("636363ff")

const BLOCK_THEME: Theme = preload("uid://bxh8j3gnclchu")
const BLOCK_LINE_EDIT: StyleBoxFlat = preload("uid://c8rhkk0ropejo")
const BLOCK_BOOL_PANEL: StyleBoxFlat = preload("uid://tkxi8ob6bwxm")
const BLOCK_OPTION_BUTTON: StyleBoxFlat = preload("uid://dmp801j6y02fr")
const BLOCK_OPTIONS_POPUP_PANEL: StyleBoxFlat = preload("uid://b136o4ympmsgo")
const BLOCK_VALUE_HIGHLIGHT: StyleBoxFlat = preload("uid://b0mbrqntfnjk6")
const BLOCK_BOOL_HIGHLIGHT: StyleBoxFlat = preload("uid://b88x671nrtn4d")
const BLOCK_POPUP_SEARCH: StyleBoxFlat = preload("uid://dl83sbry4at1n")
var searchStyle: StyleBoxFlat

func configureProperties() -> void:
	var newTheme: Theme = BLOCK_THEME.duplicate()
	var newLineEdit: StyleBoxFlat = BLOCK_LINE_EDIT.duplicate()
	var newBoolPanel: StyleBoxFlat = BLOCK_BOOL_PANEL.duplicate()
	var newOptionButton: StyleBoxFlat = BLOCK_OPTION_BUTTON.duplicate()
	var newPopupPanel: StyleBoxFlat = BLOCK_OPTIONS_POPUP_PANEL.duplicate()
	searchStyle = BLOCK_POPUP_SEARCH.duplicate()
	
	var darkenedColor: Color = blockColor.darkened(0.2)
	newLineEdit.border_color = darkenedColor
	searchStyle.border_color = darkenedColor
	newOptionButton.border_color = blockColor.darkened(0.3)
	newOptionButton.bg_color = darkenedColor
	newBoolPanel.border_color = blockColor.darkened(0.3)
	newBoolPanel.bg_color = darkenedColor
	newPopupPanel.bg_color = blockColor
	newPopupPanel.border_color = darkenedColor
	
	newTheme.set_stylebox(&"normal", &"LineEdit", newLineEdit)
	newTheme.set_stylebox(&"panel", &"Panel", newBoolPanel)
	newTheme.set_stylebox(&"hover", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"normal", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"pressed", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"panel", &"PopupMenu", newPopupPanel)
	
	theme = newTheme
	
	for i: Node in get_children():
		if i is BlockInputEdit:
			setLineEditProperties(i)
		if i is BlockOptions:
			setOptionButtonProperties(i)
			i.get_popup().about_to_popup.connect(optionsOpened.bind(i))
		if i is BlockBoolPanel:
			setBooleanPanelProperties(i)

func setLineEditProperties(lineEdit: LineEdit) -> void:
	lineEdit.context_menu_enabled = false
	lineEdit.emoji_menu_enabled = false
	lineEdit.middle_mouse_paste_enabled = false
	lineEdit.drag_and_drop_selection_enabled = false
	lineEdit.virtual_keyboard_enabled = false
	lineEdit.clear_button_enabled = false
	lineEdit.caret_blink = true
	lineEdit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if lineEdit is BlockInputEdit:
		lineEdit.expand_to_text_length = true
		lineEdit.custom_minimum_size = Vector2(60.0, 55.0)
		lineEdit.custom_maximum_size = Vector2(-1.0, 55.0)
		lineEdit.alignment = HORIZONTAL_ALIGNMENT_CENTER
		addHighlight(lineEdit, BLOCK_VALUE_HIGHLIGHT)
	# Search bar in popup
	else:
		lineEdit.add_theme_stylebox_override(&"normal", searchStyle)

func setBooleanPanelProperties(boolPanel: BlockBoolPanel) -> void:
	boolPanel.custom_minimum_size = Vector2(80.0, 55.0)
	boolPanel.custom_maximum_size = Vector2(-1.0, 55.0)
	boolPanel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	addHighlight(boolPanel, BLOCK_BOOL_HIGHLIGHT)

func setOptionButtonProperties(optionButton: BlockOptions) -> void:
	optionButton.fit_to_longest_item = false
	optionButton.selected = 0
	optionButton.search_bar_enabled = true
	optionButton.search_bar_fuzzy_search_enabled = false
	optionButton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	optionButton.custom_minimum_size = Vector2(60.0, 55.0)
	optionButton.custom_maximum_size = Vector2(-1.0, 55.0)
	optionButton.allow_reselect = true
	if optionButton.acceptBlocks:
		addHighlight(optionButton, BLOCK_VALUE_HIGHLIGHT)

# Create a highlight for if a value block is dragged over it
func addHighlight(content: Control, style: StyleBoxFlat) -> void:
	var highlight: Panel = Panel.new()
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.add_theme_stylebox_override(&"panel", style)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.show_behind_parent = true
	highlight.visible = false
	content.add_child(highlight)
	content.highlight = highlight

func optionsOpened(optionButton: BlockOptions) -> void:
	# Get the search bar of the options popup
	var lineEdits: Array[Node] = optionButton.get_popup().find_children("*", "LineEdit", true, false)
	setLineEditProperties(lineEdits[0])
	#optionButton.block.editor.uiFocused = lineEdits[0]
	# Set size of the popup
	var popup: PopupMenu = optionButton.get_popup()
	popup.min_size = Vector2i.ZERO
	popup.max_size = Vector2i(0, 500)
	var godotSize: Vector2 = popup.get_contents_minimum_size()
	var scaleOffset: float = optionButton.get_global_transform_with_canvas().get_scale().x
	var trueWidth: int = int(godotSize.x * scaleOffset)
	# Right margin
	trueWidth += int(30.0 * scaleOffset)
	# Minimum width
	trueWidth = clampi(trueWidth, int(200.0 * scaleOffset), int(1000.0 * scaleOffset))
	# The popup menu size seems to only react to setting min/max size
	popup.min_size.x = trueWidth
	popup.max_size.x = trueWidth
