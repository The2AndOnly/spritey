class_name SpriteCollision
extends Node

const CollisionShader: RDShaderFile = preload("uid://dvtmfv0s1regf")

static var renderer: RenderingDevice
static var shader: RID
static var pipeline: RID
static var sampler: RID

func _ready() -> void:
	renderer = RenderingServer.get_rendering_device()
	var samplerState = RDSamplerState.new()
	samplerState.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	samplerState.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler = renderer.sampler_create(samplerState)
	shader = renderer.shader_create_from_spirv(CollisionShader.get_spirv())
	pipeline = renderer.compute_pipeline_create(shader)

static func spritesTouching(sprite1: AnimatedSprite2D, sprite2: AnimatedSprite2D) -> bool:
	if (!sprite1.visible) or !sprite2.visible: return false
	
	var sprite1Texture: Texture2D = sprite1.sprite_frames.get_frame_texture(&"default", sprite1.frame)
	var sprite2Texture: Texture2D = sprite2.sprite_frames.get_frame_texture(&"default", sprite2.frame)
	
	# Get the axis-aligned bounding boxes
	var sprite1Rect: Rect2 = getTextureRect(sprite1Texture)
	var sprite2Rect: Rect2 = getTextureRect(sprite2Texture)
	var sprite1Transform: Transform2D = getTransform(sprite1)
	var sprite2Transform: Transform2D = getTransform(sprite2)
	var globalSprite1Rect: Rect2 = sprite1Transform * sprite1Rect
	var intersection: Rect2 = globalSprite1Rect.intersection(sprite2Transform * sprite2Rect)
	if (intersection.size.x <= 0) or intersection.size.y <= 0: return false
	
	# Send data to the shader
	var inputs: PackedByteArray = PackedByteArray()
	# Construct data for sprite1
	inputs.append_array(transformBytes(sprite1Transform.affine_inverse()))
	inputs.append_array(vector2Bytes(sprite1Rect.size))
	inputs.append_array(vector2Bytes(sprite1Rect.position))
	# Construct data for sprite2
	inputs.append_array(transformBytes(sprite2Transform.affine_inverse()))
	inputs.append_array(vector2Bytes(sprite2Rect.size))
	inputs.append_array(vector2Bytes(sprite2Rect.position))
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
	uniformTexture2.add_id(RenderingServer.texture_get_rd_texture(sprite2Texture.get_rid()))
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
	
	return result.decode_u32(0) > 0

static func getTextureRect(texture: Texture2D) -> Rect2:
	var size: Vector2 = texture.get_size()
	return Rect2(Vector2.ZERO - (size * 0.5), size)

# This exists to fix detection with flipped sprites
static func getTransform(sprite: AnimatedSprite2D) -> Transform2D:
	var transform: Transform2D = sprite.get_global_transform()
	if sprite.flip_h:
		transform = transform.scaled_local(Vector2(-1, 1))
	if sprite.flip_v:
		transform = transform.scaled_local(Vector2(1, -1))
	return transform

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
