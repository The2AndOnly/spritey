class_name ScriptStack
extends RefCounted

var sprite: Sprite
var cloned := false
var currentBlock: CompiledBlock
var startEvent: CompiledBlock
# Wait time of -1.0 means no wait
var waitTime: float = -1.0
# If true, then it keeps calling the waiting block every frame
var executeWait := false
# Go to this block instead of terminating when reached the end of a stack (in process)
var exitNest: Array[CompiledBlock] = []
# Go back to this block instead of terminating when reached the end of a stack
var loops: Array[CompiledBlock] = []
# For looping blocks to count their iterations
var loopData: Array[float] = []
# Any data used by the execute wait block
var blockData: Array[Variant] = []
# Used by "send signal and wait" blocks
var createdStacks: Array[ScriptStack] = []
var terminated := false

func _init(stackSprite: Sprite, startBlock: CompiledBlock, eventBlock: CompiledBlock) -> void:
	sprite = stackSprite
	cloned = stackSprite.original != null
	currentBlock = startBlock
	startEvent = eventBlock

func terminate() -> void:
	terminated = true
	loops.clear()
	exitNest.clear()
