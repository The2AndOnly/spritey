class_name ScriptStack
extends Node

var currentBlock: CompiledBlock
var startEvent: CompiledBlock
# Negative wait time means no wait
var waitTime: float = -1.0

func _init(startBlock: CompiledBlock, eventBlock: CompiledBlock) -> void:
	currentBlock = startBlock
	startEvent = eventBlock
