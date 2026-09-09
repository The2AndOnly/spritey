extends HBoxContainer

func _ready() -> void:
	configureProperties()

func configureProperties() -> void:
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
	lineEdit.keep_editing_on_text_submit = false
	if !searchBar:
		lineEdit.expand_to_text_length = true
		lineEdit.custom_minimum_size = Vector2(60.0, 0.0)
		lineEdit.custom_maximum_size = Vector2(-1.0, 55.0)

func setOptionButtonProperties(optionButton: OptionButton) -> void:
	optionButton.fit_to_longest_item = false
	optionButton.selected = 0
	optionButton.search_bar_enabled = true
	optionButton.search_bar_fuzzy_search_enabled = false
	optionButton.custom_maximum_size = Vector2(-1.0, 55.0)

func optionsOpened(optionButton: OptionButton) -> void:
	var lineEdits: Array[Node] = optionButton.get_popup().find_children("*", "LineEdit", true, false)
	setLineEditProperties(lineEdits[0], true)
