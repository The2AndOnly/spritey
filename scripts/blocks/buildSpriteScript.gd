class_name BuildSpriteScript
extends Node

# see sprite.gd for spriteScript docs

static func updateBlock(block: CodeBlock, sprite: Sprite) -> void:
	var spriteScriptBlock: Dictionary[StringName, Variant] = {}
	spriteScriptBlock[&"block"] = block.blockName
	spriteScriptBlock[&"top"] = block.parentBlock == null
	spriteScriptBlock[&"value"] = block.parentInput != null
	if block.childBlock: spriteScriptBlock[&"next"] = block.childBlock.blockID
	# Build inputs
	var inputs: Array[Array] = []
	for i: Control in block.content.get_children():
		if i is LineEdit:
			# If not visible, then a value block is inserted
			if i.visible:
				# Type of 5 has to infer between float or integer
				if i.type == 5:
					if "." in i.text:
						inputs.append([0, [1, i.text]])
					else:
						inputs.append([0, [0, i.text]])
				else:
					inputs.append([0, [i.type, i.text]])
		if i is CodeBlock:
			inputs.append([1, [i.parentInput.type, i.blockID]])
			updateBlock(i, sprite)
		if i is OptionButton:
			inputs.append([2, i.selected])
	if inputs.size() > 0: spriteScriptBlock[&"inputs"] = inputs
	# Add this to the sprite
	sprite.spriteScript[block.blockID] = spriteScriptBlock
	# Require the sprite to re-compile once an event is received
	sprite.scriptsCompiled = false
