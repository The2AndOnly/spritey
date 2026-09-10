class_name BlockStructures
extends Node

# 0 = integer
# 1 = float
# 2 = string
# 3 = positive integer
# 4 = positive float

static var structures: Dictionary[StringName, Dictionary] = {
	&"trans_setPosition": {
		&"structure": ["set position X:", 0, "Y:", 1],
		0: [&"input", 1, "0"], # input type, value type, default
		1: [&"input", 1, "0"]
	},
	&"trans_setPositionOption": {
		&"structure": ["set position to", 0],
		0: [&"options", 1, 0, "pointer", "random"] # input type, 1 = include sprites, default, values
	},
	&"trans_setX": {
		&"structure": ["set X to", 0],
		0: [&"input", 1, "0"]
	},
	&"trans_setY": {
		&"structure": ["set Y to", 0],
		0: [&"input", 1, "0"]
	},
	&"trans_glideToPosition": {
		&"structure": ["glide", 0, "seconds to X:", 1, "Y:", 2],
		0: [&"input", 4, "1"],
		1: [&"input", 1, "0"],
		2: [&"input", 1, "0"]
	},
	&"trans_glideToOption": {
		&"structure": ["glide", 0, "seconds to", 1],
		0: [&"input", 4, "1"],
		1: [&"options", 1, 0, "pointer", "random position"]
	}
}
