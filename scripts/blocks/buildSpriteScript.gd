class_name BuildSpriteScript
extends Node

# see sprite.gd for spriteScript docs

static func updateBlock(block: CodeBlock, sprite: Sprite) -> void:
	var spriteScriptBlock: Dictionary[StringName, Variant] = {}
	spriteScriptBlock[&"block"] = block.blockName
	spriteScriptBlock[&"top"] = block.parentBlock == null
	spriteScriptBlock[&"value"] = block.parentInput != null
	if block.childBlock: spriteScriptBlock[&"next"] = block.childBlock.blockID
	if block.childNest: spriteScriptBlock[&"nest"] = block.childNest.blockID
	# Build inputs
	var inputs: Array[Array] = []
	for i: Control in block.content.get_children():
		if i is LineEdit:
			# If not visible, then a value block is inserted
			if i.visible:
				inputs.append([0, [i.type, i.text]])
		if i is CodeBlock:
			if i.parentInput is BlockInputEdit:
				inputs.append([1, [i.parentInput.type, i.blockID]])
			else:
				inputs.append([1, [5, i.blockID]])
			updateBlock(i, sprite)
		if i is OptionButton:
			inputs.append([2, i.selected])
		# Empty bool input
		if i is BlockBoolPanel and i.visible:
			inputs.append([2, false])
	if inputs.size() > 0: spriteScriptBlock[&"inputs"] = inputs
	# Add this to the sprite
	sprite.spriteScript[block.blockID] = spriteScriptBlock
	# Require the sprite to re-compile once an event is received
	sprite.scriptsCompiled = false
