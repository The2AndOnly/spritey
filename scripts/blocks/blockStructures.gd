class_name BlockStructures
extends Node

# INPUT DOCS:
# Inputs are expected to start from 0 and increment by 1 from left to right
# blockInputEdit (lineEdit):
# [&"input", 0, "0"] - input type, value type, default
## VALUE TYPES:
## 0 - integer
## 1 - float
## 2 - string
## 3 - positive integer
## 4 - positive float
# blockOptions (optionButton):
# [&"options", 0, 0, ["option1"]] - input type, option addon, default, values
## OPTION ADDONS:
## 0 - none
## 1 - sprites
## 2 - events
## 3 - keyboard keys

static var categoryColors: Dictionary[StringName, Color] = {
	&"transform": Color("0050a6ff"),
	&"events": Color("b52a2aff"),
	&"expressions": Color("a6981eff"),
	&"control": Color("9e501cff"),
	&"interaction": Color("1c734dff"),
	&"visuals": Color("7a1d4dff"),
	&"unknown": Color("636363ff")
}

static var keyOptions: Array[StringName] = [
	&"any",
	&"space",
	&"up arrow",
	&"down arrow",
	&"left arrow",
	&"right arrow",
	&"enter",
	&"A",&"B",&"C",&"D",&"E",&"F",&"G",&"H",&"I",&"J",&"K",&"L",&"M",
	&"N",&"O",&"P",&"Q",&"R",&"S",&"T",&"U",&"V",&"W",&"X",&"Y",&"Z",
	&"0",&"1",&"2",&"3",&"4",&"5",&"6",&"7",&"8",&"9"
]

static var structures: Dictionary[StringName, Dictionary] = {
	
	## EVENTS
	
	&"event_start": {
		&"structure": ["when project started"],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"event_keyboard": {
		&"structure": ["when", 0, "key", 1],
		0: [&"options", 3, 1, []],
		1: [&"options", 0, 0, ["pressed", "released"]],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"event_mouse": {
		&"structure": ["when", 0, "mouse button", 1],
		0: [&"options", 0, 0, ["left", "right"]],
		1: [&"options", 0, 0, ["pressed", "released"]],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"event_receive": {
		&"structure": ["when signal", 0, "received"],
		0: [&"options", 2, 0, []],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"event_signal": {
		&"structure": ["send signal", 0],
		0: [&"options", 2, 0, []],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.STACK
	},
	
	## TRANSFORM
	
	&"trans_setPosition": {
		&"structure": ["set position X:", 0, "Y:", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_setPositionOption": {
		&"structure": ["set position to", 0],
		0: [&"options", 1, 0, ["pointer", "random"]],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_setX": {
		&"structure": ["set X to", 0],
		0: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_setY": {
		&"structure": ["set Y to", 0],
		0: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_changeX": {
		&"structure": ["change X by", 0],
		0: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_changeY": {
		&"structure": ["change Y by", 0],
		0: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_glideToPosition": {
		&"structure": ["glide", 0, "seconds to X:", 1, "Y:", 2],
		0: [&"input", 4, "1"],
		1: [&"input", 1, "0"],
		2: [&"input", 1, "0"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_glideToOption": {
		&"structure": ["glide", 0, "seconds to", 1],
		0: [&"input", 4, "1"],
		1: [&"options", 1, 0, ["pointer", "random"]],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_XPos": {
		&"structure": ["x position"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"trans_YPos": {
		&"structure": ["y position"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"trans_setDirection": {
		&"structure": ["set direction to", 0],
		0: [&"input", 1, "90"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_turnDegrees": {
		&"structure": ["turn", 0, "degrees"],
		0: [&"input", 1, "15"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_pointTowards": {
		&"structure": ["point towards", 0],
		0: [&"options", 1, 0, ["pointer", "random"]],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_direction": {
		&"structure": ["direction"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.VALUE
	},
	
	## EXPRESSIONS
	
	&"exp_add": {
		&"structure": [0, "+", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_subtract": {
		&"structure": [0, "-", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_multiply": {
		&"structure": [0, "*", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_divide": {
		&"structure": [0, "/", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "1"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_random": {
		&"structure": ["random", 0, 1, "to", 2],
		0: [&"options", 0, 0, ["integer", "decimal"]],
		1: [&"input", 1, "1"],
		2: [&"input", 1, "5"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_join": {
		&"structure": ["join", 0, 1],
		0: [&"input", 2, "text1"],
		1: [&"input", 2, "text2"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_ternary": {
		&"structure": [0, "if", 1, "else", 2],
		0: [&"input", 2, ""],
		1: [&"bool"],
		2: [&"input", 2, ""],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_equals": {
		&"structure": [0, "=", 1],
		0: [&"input", 2, "0"],
		1: [&"input", 2, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_greater": {
		&"structure": [0, ">", 1],
		0: [&"input", 2, "1"],
		1: [&"input", 2, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_less": {
		&"structure": [0, "<", 1],
		0: [&"input", 2, "0"],
		1: [&"input", 2, "1"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_and": {
		&"structure": [0, "and", 1],
		0: [&"bool"],
		1: [&"bool"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_or": {
		&"structure": [0, "or", 1],
		0: [&"bool"],
		1: [&"bool"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_not": {
		&"structure": ["not", 0],
		0: [&"bool"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"exp_charOf": {
		&"structure": ["char", 0, "of", 1],
		0: [&"input", 0, "0"],
		1: [&"input", 2, "text"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_substring": {
		&"structure": ["chars", 0, "to", 1, "of", 2],
		0: [&"input", 0, "0"],
		1: [&"input", 0, "2"],
		2: [&"input", 2, "text"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_textLength": {
		&"structure": ["length of", 0],
		0: [&"input", 2, "text"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_mod": {
		&"structure": [0, "mod", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "1"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_exponent": {
		&"structure": [0, "^", 1],
		0: [&"input", 1, "0"],
		1: [&"input", 1, "2"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_abs": {
		&"structure": ["abs", 0],
		0: [&"input", 1, "-1"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_round": {
		&"structure": ["round", 0],
		0: [&"input", 1, "1.5"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_math": {
		&"structure": [0, "of", 1],
		0: [&"options", 0, 0, ["floor", "ceiling", "sin", "cos", "tan", "asin", "acos", "atan", "sqrt", "ln", "log", "e^"]],
		1: [&"input", 1, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	
	## INTERACTION
	
	&"inter_pointerX": {
		&"structure": ["pointer x"],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_pointerY": {
		&"structure": ["pointer y"],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_keyPressed": {
		&"structure": ["key", 0, "pressed"],
		0: [&"options", 3, 1, []],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	
	## CONTROL
	
	&"ctrl_wait": {
		&"structure": ["wait", 0, "seconds"],
		0: [&"input", 4, "1"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_waitUntil": {
		&"structure": ["wait until", 0],
		0: [&"bool"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_if": {
		&"structure": ["if   ", 0, "then"],
		0: [&"bool"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.NEST
	},
	&"ctrl_repeat": {
		&"structure": ["repeat", 0],
		0: [&"input", 3, "20"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.NEST
	},
	&"ctrl_repeatSeconds": {
		&"structure": ["repeat for", 0, "seconds"],
		0: [&"input", 4, "1"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.NEST
	},
	&"ctrl_while": {
		&"structure": ["while", 0],
		0: [&"bool"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.NEST
	},
	&"ctrl_forever": {
		&"structure": ["forever"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.NEST
	},
	&"ctrl_break": {
		&"structure": ["break"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STOP
	},
	&"ctrl_continue": {
		&"structure": ["continue"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STOP
	},
	&"ctrl_stopStacks": {
		&"structure": ["stop", 0],
		0: [&"options", 0, 0, ["this stack", "project"]],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STOP
	},
	&"ctrl_stopOther": {
		&"structure": ["stop other stacks in sprite"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	
	## VISUALS
	
	&"vis_show": {
		&"structure": ["show"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_hide": {
		&"structure": ["hide"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_visible": {
		&"structure": ["visible"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"vis_setSize": {
		&"structure": ["set size to", 0, "%"],
		0: [&"input", 1, "100"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_changeSize": {
		&"structure": ["change size by", 0],
		0: [&"input", 1, "2"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_size": {
		&"structure": ["size"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"vis_setStretch": {
		&"structure": ["set", 0, "stretch to", 1],
		0: [&"options", 0, 0, ["horizontal", "vertical"]],
		1: [&"input", 1, "0"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_changeStretch": {
		&"structure": ["change", 0, "stretch by", 1],
		0: [&"options", 0, 0, ["horizontal", "vertical"]],
		1: [&"input", 1, "2"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_stretch": {
		&"structure": [0, "stretch"],
		0: [&"options", 0, 0, ["horizontal", "vertical"]],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"vis_setFlip": {
		&"structure": ["set", 0, "flip to", 1],
		0: [&"options", 0, 0, ["horizontal", "vertical"]],
		1: [&"options", 0, 0, ["enabled", "disabled"]],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_flip": {
		&"structure": [0, "flipped"],
		0: [&"options", 0, 0, ["horizontal", "vertical"]],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"vis_setOpacity": {
		&"structure": ["set opacity to", 0, "%"],
		0: [&"input", 1, "100"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_changeOpacity": {
		&"structure": ["change opacity by", 0],
		0: [&"input", 1, "-2"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_opacity": {
		&"structure": ["opacity"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.VALUE
	},
	
	## TESTS
	
	&"test_print": {
		&"structure": ["print", 0],
		0: [&"input", 2, ""],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.STACK
	}
}
