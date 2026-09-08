class_name ScriptBlock
extends RefCounted

var definition: Callable
var inputs: Array = []
var nextBlock: ScriptBlock = null

func execute() -> void:
	if definition.is_valid(): definition.call(inputs)
