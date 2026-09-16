extends HBoxContainer

var blockColor: Color = Color("636363ff")

const BLOCK_THEME: Theme = preload("uid://bxh8j3gnclchu")
const BLOCK_LINE_EDIT: StyleBoxFlat = preload("uid://c8rhkk0ropejo")
const BLOCK_OPTION_BUTTON: StyleBoxFlat = preload("uid://dmp801j6y02fr")
const BLOCK_OPTIONS_POPUP_PANEL: StyleBoxFlat = preload("uid://b136o4ympmsgo")
const BLOCK_VALUE_HIGHLIGHT: StyleBoxFlat = preload("uid://b0mbrqntfnjk6")


func configureProperties() -> void:
	var newTheme: Theme = BLOCK_THEME.duplicate()
	var newLineEdit: StyleBoxFlat = BLOCK_LINE_EDIT.duplicate()
	var newOptionButton: StyleBoxFlat = BLOCK_OPTION_BUTTON.duplicate()
	var newPopupPanel: StyleBoxFlat = BLOCK_OPTIONS_POPUP_PANEL.duplicate()
	
	var darkenedColor: Color = blockColor.darkened(0.2)
	newLineEdit.border_color = darkenedColor
	newOptionButton.border_color = blockColor.darkened(0.3)
	newOptionButton.bg_color = darkenedColor
	newPopupPanel.bg_color = blockColor
	newPopupPanel.border_color = darkenedColor
	
	newTheme.set_stylebox(&"normal", &"LineEdit", newLineEdit)
	newTheme.set_stylebox(&"hover", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"normal", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"pressed", &"OptionButton", newOptionButton)
	newTheme.set_stylebox(&"panel", &"PopupMenu", newPopupPanel)
	
	theme = newTheme
	
	for i: Control in get_children():
		if i is LineEdit:
			setLineEditProperties(i, false)
		if i is OptionButton:
			setOptionButtonProperties(i)
			i.get_popup().about_to_popup.connect(optionsOpened.bind(i))

func setLineEditProperties(lineEdit: LineEdit, searchBar: bool) -> void:
	lineEdit.context_menu_enabled = false
	lineEdit.emoji_menu_enabled = false
	lineEdit.middle_mouse_paste_enabled = false
	lineEdit.drag_and_drop_selection_enabled = false
	lineEdit.virtual_keyboard_enabled = false
	lineEdit.clear_button_enabled = false
	lineEdit.caret_blink = true
	lineEdit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if !searchBar:
		lineEdit.expand_to_text_length = true
		lineEdit.custom_minimum_size = Vector2(60.0, 55.0)
		lineEdit.custom_maximum_size = Vector2(-1.0, 55.0)
	# Create a highlight for if a value block is dragged over it
	if lineEdit is BlockInputEdit:
		var highlight: Panel = Panel.new()
		highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
		highlight.add_theme_stylebox_override(&"panel", BLOCK_VALUE_HIGHLIGHT)
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.show_behind_parent = true
		highlight.visible = false
		lineEdit.add_child(highlight)
		lineEdit.highlight = highlight

func setOptionButtonProperties(optionButton: BlockOptions) -> void:
	optionButton.fit_to_longest_item = false
	optionButton.selected = 0
	optionButton.search_bar_enabled = true
	optionButton.search_bar_fuzzy_search_enabled = false
	optionButton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	optionButton.custom_minimum_size = Vector2(60.0, 55.0)
	optionButton.custom_maximum_size = Vector2(-1.0, 55.0)
	optionButton.allow_reselect = true

func optionsOpened(optionButton: BlockOptions) -> void:
	# Get the search bar of the options popup
	var lineEdits: Array[Node] = optionButton.get_popup().find_children("*", "LineEdit", true, false)
	setLineEditProperties(lineEdits[0], true)
	#optionButton.block.editor.uiFocused = lineEdits[0]
	optionButton.get_popup().min_size.x = 200
	optionButton.get_popup().max_size.y = 500
