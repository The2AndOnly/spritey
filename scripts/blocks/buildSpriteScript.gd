class_name BuildSpriteScript
extends Node

# see sprite.gd for spriteScript docs

static func updateBlock(block: CodeBlock, sprite: Sprite) -> void:
	var spriteScriptBlock: Dictionary[StringName, Variant] = {}
	spriteScriptBlock[&"block"] = block.blockName
	spriteScriptBlock[&"top"] = block.parentBlock == null
	if block.childBlock: spriteScriptBlock[&"next"] = block.childBlock.blockID
	# Build inputs
	var inputs: Array[Array] = []
	for i: Control in block.content.get_children():
		if i is LineEdit:
			inputs.append([0, [i.type, i.text]]) # CHANGE 0 WHEN REPORTERS GET ADDED
		if i is OptionButton:
			inputs.append([2, i.selected])
	spriteScriptBlock[&"inputs"] = inputs
	# Add this to the sprite
	sprite.spriteScript[block.blockID] = spriteScriptBlock
	# Require the sprite to re-compile once an event is received
	sprite.scriptsCompiled = false
