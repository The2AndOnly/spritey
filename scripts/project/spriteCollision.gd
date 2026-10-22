class_name SpriteCollision
extends Node

const CollisionShader: RDShaderFile = preload("uid://dvtmfv0s1regf")

static var renderer: RenderingDevice
static var shader: RID
static var pipeline: RID
static var sampler: RID
const fullTextureRect: Rect2 = Rect2(Vector2(-640.0, -360.0), Vector2(1280.0, 720.0))

func _ready() -> void:
	renderer = RenderingServer.get_rendering_device()
	var samplerState = RDSamplerState.new()
	samplerState.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samplerState.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler = renderer.sampler_create(samplerState)
	shader = renderer.shader_create_from_spirv(CollisionShader.get_spirv())
	pipeline = renderer.compute_pipeline_create(shader)

static func spritesTouching(sprite1: Sprite, sprite2: Sprite, rectList: Dictionary[int, Rect2], spriteList: Dictionary[int, Sprite], filterEnabled: bool = false, nameFilter: String = "") -> bool:
	var sprite1ID: int = sprite1.spriteID
	var sprite2ID: int = sprite2.spriteID
	var sprite1Rect: Rect2 = rectList[sprite1ID]
	var sprite2CloneCount: int = sprite2.clones.size() + 1
	for id: int in range(sprite2ID, sprite2ID + sprite2CloneCount):
		if !sprite1Rect.intersects(rectList[id]): continue
		var clone: Sprite = spriteList[id]
		if clone == sprite1: continue
		if filterEnabled:
			if clone.spriteName != nameFilter: continue
		
		# Get collision data
		var sprite1Texture: Texture2D = sprite1.frameTextures[sprite1.frame]
		var sprite1Transform: Transform2D = sprite1.global_transform
		var globalSprite1Rect: Rect2 = sprite1Transform * fullTextureRect
		var cloneTexture: Texture2D = clone.frameTextures[clone.frame]
		var cloneTransform: Transform2D = clone.global_transform
		var intersection: Rect2 = globalSprite1Rect.intersection(cloneTransform * fullTextureRect)
		
		# Send data to the shader
		var inputs: PackedByteArray = PackedByteArray()
		# Construct data for sprite1
		inputs.append_array(transformBytes(sprite1Transform.affine_inverse()))
		inputs.append_array(vector2Bytes(fullTextureRect.size))
		inputs.append_array(vector2Bytes(fullTextureRect.position))
		# Construct data for clone
		inputs.append_array(transformBytes(cloneTransform.affine_inverse()))
		inputs.append_array(vector2Bytes(fullTextureRect.size))
		inputs.append_array(vector2Bytes(fullTextureRect.position))
		# Construct data for the intersection rect
		inputs.append_array(vector4Bytes(Vector4(intersection.position.x, intersection.position.y, intersection.size.x, intersection.size.y)))
		var inputBuffer: RID = renderer.storage_buffer_create(inputs.size(), inputs)
		
		# Default output is 0 (no collision)
		var outputData: PackedByteArray = PackedByteArray([0, 0, 0, 0])
		var outputBuffer: RID = renderer.storage_buffer_create(outputData.size(), outputData)
		
		# Create uniforms to communicate with collision.glsl
		var uniformInputs: RDUniform = RDUniform.new()
		uniformInputs.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniformInputs.binding = 0
		uniformInputs.add_id(inputBuffer)
		var uniformOutputs: RDUniform = RDUniform.new()
		uniformOutputs.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		uniformOutputs.binding = 1
		uniformOutputs.add_id(outputBuffer)
		# Bind to the sampler2Ds for the sprite textures
		var uniformTexture1: RDUniform = RDUniform.new()
		uniformTexture1.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniformTexture1.binding = 2
		uniformTexture1.add_id(sampler)
		uniformTexture1.add_id(RenderingServer.texture_get_rd_texture(sprite1Texture.get_rid()))
		var uniformTexture2: RDUniform = RDUniform.new()
		uniformTexture2.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniformTexture2.binding = 3
		uniformTexture2.add_id(sampler)
		uniformTexture2.add_id(RenderingServer.texture_get_rd_texture(cloneTexture.get_rid()))
		# Build the uniform set
		var uniformSet = renderer.uniform_set_create(
			[uniformInputs, uniformOutputs, uniformTexture1, uniformTexture2],
			shader, 0)
		
		# Execute the shader
		var compute: int = renderer.compute_list_begin()
		renderer.compute_list_bind_compute_pipeline(compute, pipeline)
		renderer.compute_list_bind_uniform_set(compute, uniformSet, 0)
		var xGroups: int = int(ceil(intersection.size.x / 16.0))
		var yGroups: int = int(ceil(intersection.size.y / 16.0))
		renderer.compute_list_dispatch(compute, xGroups, yGroups, 1)
		renderer.compute_list_end()
		# Get the results and clean up RIDs
		var result: PackedByteArray = renderer.buffer_get_data(outputBuffer)
		renderer.free_rid(inputBuffer)
		renderer.free_rid(outputBuffer)
		
		if result.decode_u32(0) > 0: return true
	return false

static func spriteTouchingPoint(sprite: Sprite, point: Vector2, rectList: Dictionary[int, Rect2]) -> bool:
	if !sprite.visible: return false
	if !rectList[sprite.spriteID].has_point(point): return false
	
	var image: Image = sprite.frameImages[sprite.frame]
	var localPoint: Vector2 = sprite.global_transform.affine_inverse() * point
	var pixelPosition: Vector2i = Vector2i(localPoint - fullTextureRect.position)
	# All sprite frames are always 1280 x 720
	if (pixelPosition.x < 0) or (pixelPosition.x >= 1280) or\
	(pixelPosition.y < 0) or (pixelPosition.y >= 720):
		return false
	
	return image.get_pixel(pixelPosition.x, pixelPosition.y).a > 0.01

static func spritesTouchingPoint(sprite: Sprite, point: Vector2, rectList: Dictionary[int, Rect2], spriteList: Dictionary[int, Sprite], filterEnabled: bool = false, nameFilter: String = "") -> bool:
	var spriteID: int = sprite.spriteID
	var cloneCount: int = sprite.clones.size() + 1
	for id: int in range(spriteID, spriteID + cloneCount):
		if !rectList[id].has_point(point): continue
		var clone: Sprite = spriteList[id]
		if !clone.visible: continue
		if filterEnabled:
			if clone.spriteName != nameFilter: continue
		# Checks passed to run the pixel detection
		var image: Image = clone.frameImages[clone.frame]
		var localPoint: Vector2 = clone.global_transform.affine_inverse() * point
		var pixelPosition: Vector2i = Vector2i(localPoint - fullTextureRect.position)
		# All sprite frames are always 1280 x 720
		if (pixelPosition.x < 0) or (pixelPosition.x >= 1280) or\
		(pixelPosition.y < 0) or (pixelPosition.y >= 720):
			continue
		if image.get_pixel(pixelPosition.x, pixelPosition.y).a > 0.01: return true
	return false

static func transformBytes(transform: Transform2D) -> PackedByteArray:
	# glsl uses mat4 to represent transform
	return PackedFloat32Array([
		transform.x.x, transform.x.y, 0.0, 0.0,
		transform.y.x, transform.y.y, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		transform.origin.x, transform.origin.y, 0.0, 1.0
	]).to_byte_array()

static func vector4Bytes(vector: Vector4) -> PackedByteArray:
	return PackedFloat32Array([vector.x, vector.y, vector.z, vector.w]).to_byte_array()

static func vector2Bytes(vector: Vector2) -> PackedByteArray:
	return PackedFloat32Array([vector.x, vector.y]).to_byte_array()

# These RIDs have to be manually freed
func _exit_tree() -> void:
	if !renderer: return
	if sampler.is_valid():
		renderer.free_rid(sampler)
	if pipeline.is_valid():
		renderer.free_rid(pipeline)
	if shader.is_valid():
		renderer.free_rid(shader)
