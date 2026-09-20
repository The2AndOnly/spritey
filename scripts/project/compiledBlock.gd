class_name CompiledBlock
extends RefCounted

var definition: Callable
var inputs: Array = []
var nextBlock: CompiledBlock = null
var firstInNest: CompiledBlock = null

func execute() -> void:
	if definition.is_valid(): definition.call(inputs)
