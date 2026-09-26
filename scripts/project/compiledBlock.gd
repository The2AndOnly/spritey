class_name CompiledBlock
extends RefCounted

var sprite: Sprite
var definition: Callable
var inputs: Array = []
var nextBlock: CompiledBlock = null
var firstInNest: CompiledBlock = null
var parentNest: CompiledBlock = null

func execute() -> void:
	if definition.is_valid(): definition.call(inputs)

func exitNests(stack: ScriptStack) -> void:
	if parentNest:
		parentNest.exitNests(stack)
		if parentNest.nextBlock in stack.exitNest: stack.exitNest.remove_at(-1)
