class_name ScriptStack
extends RefCounted

var currentBlock: CompiledBlock
var startEvent: CompiledBlock
# Wait time of -1.0 means no wait
var waitTime: float = -1.0
# If true, then it keeps calling the waiting block every frame
var executeWait := false
# Any data used by the execute wait block
var blockData: Array[Variant] = []

func _init(startBlock: CompiledBlock, eventBlock: CompiledBlock) -> void:
	currentBlock = startBlock
	startEvent = eventBlock
