class_name BlockStructures
extends Node

# TODO: Add an "in editor" boolean block

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
## 4 - global and local variables
## 5 - frames
# special value (not shown on block but passed through block definition):
# [&"special", Variant]
# blockOptions with ability to insert value blocks (as string): &"soptions"

static var categoryColors: Dictionary[StringName, Color] = {
	&"transform": Color("0050a6ff"),
	&"events": Color("b52a2aff"),
	&"expressions": Color("a6981eff"),
	&"control": Color("9e501cff"),
	&"interaction": Color("4d9413ff"),
	&"visuals": Color("872056ff"),
	&"variables": Color("139094ff"),
	&"lists": Color("0f7355ff"),
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
	&"0",&"1",&"2",&"3",&"4",&"5",&"6",&"7",&"8",&"9",
	&"ctrl",
	&"shift",
	&"alt",
	&"backspace"
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
	&"event_clickedCollision": {
		&"structure": ["when", 0, "clicked collision"],
		0: [&"options", 0, 0, ["left", "double", "right"]],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"event_clicked": {
		&"structure": ["when", 0, "clicked this sprite"],
		0: [&"options", 0, 0, ["left", "double", "right"]],
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
	&"event_signalAndWait": {
		&"structure": ["send signal", 0, "and wait"],
		0: [&"options", 2, 0, []],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"event_scrolled": {
		&"structure": ["when scrolled", 0],
		0: [&"options", 0, 0, ["up", "down"]],
		&"color": &"events",
		&"shape": BlockShape.blockShapes.EVENT
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
	&"trans_moveSteps": {
		&"structure": ["move", 0, "steps"],
		0: [&"input", 1, "10"],
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
		0: [&"input", 1, "10"],
		&"color": &"transform",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"trans_changeY": {
		&"structure": ["change Y by", 0],
		0: [&"input", 1, "10"],
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
		0: [&"input", 0, "1"],
		1: [&"input", 2, "text"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_substring": {
		&"structure": ["chars", 0, "to", 1, "of", 2],
		0: [&"input", 0, "1"],
		1: [&"input", 0, "3"],
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
		0: [&"options", 0, 0, ["floor", "ceiling", "sin", "cos", "tan", "asin", "acos", "atan", "sign", "sqrt", "ln", "log", "e^"]],
		1: [&"input", 1, "0"],
		&"color": &"expressions",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"exp_doubleMath": {
		&"structure": [0, "of", 1, "and", 2],
		0: [&"options", 0, 0, ["max", "min", "power", "atan2", "hypotenuse"]],
		1: [&"input", 1, "1"],
		2: [&"input", 1, "5"],
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
	&"inter_mousePressed": {
		&"structure": [0, "mouse pressed"],
		0: [&"options", 0, 0, ["left", "right"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"inter_distanceTo": {
		&"structure": ["distance to", 0],
		0: [&"options", 1, 0, ["pointer", "this sprite"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_distanceToName": {
		&"structure": ["distance to", 0, "of name", 1],
		0: [&"options", 1, 0, ["this sprite"]],
		1: [&"input", 2, ""],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_localTime": {
		&"structure": ["current", 0],
		0: [&"options", 0, 0, ["year", "month", "date", "day of week", "hour", "minute", "second"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_timeSince1970": {
		&"structure": ["time since 1970"],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_deltaTime": {
		&"structure": ["delta time"],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"inter_colliding": {
		&"structure": ["colliding with", 0],
		0: [&"options", 1, 0, ["pointer", "this sprite"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	&"inter_collisionEnabled": {
		&"structure": ["set collision to", 0],
		0: [&"options", 0, 0, ["enabled", "disabled"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"inter_touching": {
		&"structure": ["touching", 0],
		0: [&"options", 1, 0, ["this sprite", "pointer"]],
		&"color": &"interaction",
		&"shape": BlockShape.blockShapes.BOOLEAN
	},
	#&"inter_touchingName": {
		#&"structure": ["touching", 0, "of name", 1],
		#0: [&"options", 1, 0, ["this sprite"]],
		#1: [&"input", 2, ""],
		#&"color": &"interaction",
		#&"shape": BlockShape.blockShapes.BOOLEAN
	#},
	
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
	&"ctrl_ifElse": {
		&"structure": ["if   ", 0, "then"],
		&"nestEnd": &"else",
		0: [&"bool"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.DOUBLE_NEST
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
	&"ctrl_cloneStart": {
		&"structure": ["when created as clone"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"ctrl_cloneStartName": {
		&"structure": ["when created as clone with name", 0],
		0: [&"input", 2, ""],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.EVENT
	},
	&"ctrl_createClone": {
		&"structure": ["clone", 0],
		0: [&"options", 1, 0, ["this sprite"]],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_createCloneName": {
		&"structure": ["clone", 0, "with name", 1],
		0: [&"options", 1, 0, ["this sprite"]],
		1: [&"input", 2, ""],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_deleteThisClone": {
		&"structure": ["delete this clone"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STOP
	},
	&"ctrl_deleteClones": {
		&"structure": ["delete clones in", 0],
		0: [&"options", 1, 0, ["this sprite", "project"]],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_deleteCloneName": {
		&"structure": ["delete clones with name", 0],
		0: [&"input", 2, ""],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"ctrl_cloneName": {
		&"structure": ["clone name"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"ctrl_cloneCount": {
		&"structure": ["clone count of", 0],
		0: [&"options", 1, 0, ["this sprite", "project"]],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"ctrl_isClone": {
		&"structure": ["is clone"],
		&"color": &"control",
		&"shape": BlockShape.blockShapes.BOOLEAN
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
		0: [&"input", 1, "5"],
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
		1: [&"input", 1, "5"],
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
		0: [&"input", 1, "-5"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_opacity": {
		&"structure": ["opacity"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.VALUE
	},
	&"vis_changeFrame": {
		&"structure": ["change frame by", 0],
		0: [&"input", 0, "1"],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_setFrame": {
		&"structure": ["set frame to", 0],
		0: [&"soptions", 5, 0, []],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"vis_frame": {
		&"structure": ["frame", 0],
		0: [&"options", 0, 0, ["number", "name", "width", "height"]],
		&"color": &"visuals",
		&"shape": BlockShape.blockShapes.VALUE
	},
	
	## VARIABLES
	
	&"var_setTo": {
		&"structure": ["set", 0, "to", 1],
		0: [&"options", 4, 0, []],
		1: [&"input", 2, "0"],
		&"color": &"variables",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"var_changeBy": {
		&"structure": ["change", 0, "by", 1],
		0: [&"options", 4, 0, []],
		1: [&"input", 1, "1"],
		&"color": &"variables",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"var_showVar": {
		&"structure": ["show", 0],
		0: [&"options", 4, 0, []],
		&"color": &"variables",
		&"shape": BlockShape.blockShapes.STACK
	},
	&"var_hideVar": {
		&"structure": ["hide", 0],
		0: [&"options", 4, 0, []],
		&"color": &"variables",
		&"shape": BlockShape.blockShapes.STACK
	},
	
	## TESTS
	
	&"test_print": {
		&"structure": ["print", 0],
		0: [&"input", 2, ""],
		&"color": &"unknown",
		&"shape": BlockShape.blockShapes.STACK
	}
}
