class_name BlockStructures
extends Node

# INPUT DOCS:
# blockInputEdit (lineEdit):
# [&"input", 0, "0"] - input type, value type, default
## VALUE TYPES:
## 0 - integer
## 1 - float
## 2 - string
## 3 - positive integer
## 4 - positive float
## 5 - infer between float and integer when building sprite script
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
		1: [&"options", 1, 0, ["pointer", "random position"]],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
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
		&"structure": ["random", 0, "to", 1],
		0: [&"input", 5, "1"],
		1: [&"input", 5, "5"],
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
	
	## CONTROL
	
	&"ctrl_wait": {
		&"structure": ["wait", 0, "seconds"],
		0: [&"input", 4, "1"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	
	## TESTS
	
	&"test_print": {
		&"structure": ["print", 0],
		0: [&"input", 2, ""],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"test_process": {
		&"structure": ["process"],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"test_emptyStack": {
		&"structure": [],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"test_emptyEvent": {
		&"structure": [],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"test_emptyValue": {
		&"structure": [],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.VALUE
	}
}
