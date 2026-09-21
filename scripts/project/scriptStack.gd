class_name ScriptStack
extends RefCounted

var currentBlock: CompiledBlock
var startEvent: CompiledBlock
# Wait time of -1.0 means no wait
var waitTime: float = -1.0
# If true, then it keeps calling the waiting block every frame
var executeWait := false
# Go to this block instead of terminating when reached the end of a stack
var exitNest: CompiledBlock = null
# Go back to this block instead of terminating when reached the end of a stack
var loops: Array[CompiledBlock] = []
# For looping blocks to count their iterations
var loopData: Array[int] = []
# Any data used by the execute wait block
var blockData: Array[Variant] = []

func _init(startBlock: CompiledBlock, eventBlock: CompiledBlock) -> void:
	currentBlock = startBlock
	startEvent = eventBlock
