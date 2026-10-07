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

# This causes lag when running on dozens of sprites all checking for dozens of sprites
# I've spent days trying to optimize this but just couldn't
# The biggest concern is that just the bounding box check alone causes lag
# The only solution I can think of, is instead of looping through "checkSprites" it
# could somehow treat every sprite as one and pass that through the shader
static func spritesTouching(sprite1: Sprite, checkSprites: Array[Sprite]) -> bool:
	# Get sprite1 data
	var rect1: Rect2 = getCroppedRect(sprite1)
	var sprite1Transform: Transform2D = getTransform(sprite1)
	var sprite1Texture: Texture2D = sprite1.frameTextures[sprite1.frame]
	var globalSprite1Rect: Rect2 = sprite1Transform * fullTextureRect
	
	for sprite2: Sprite in checkSprites:
		if !sprite2.visible: continue
		
		var rect2: Rect2 = getCroppedRect(sprite2)
		if (rect1.position.x >= rect2.end.x) or (rect1.end.x <= rect2.position.x) or\
		(rect1.position.y >= rect2.end.y) or (rect1.end.y <= rect2.position.y):
			continue
		
		# Get intersection and sprite2 data
		var sprite2Transform: Transform2D = getTransform(sprite2)
		var sprite2Texture: Texture2D = sprite2.frameTextures[sprite2.frame]
		var intersection: Rect2 = globalSprite1Rect.intersection(sprite2Transform * fullTextureRect)
		
		# Send data to the shader
		var inputs: PackedByteArray = PackedByteArray()
		# Construct data for sprite1
		inputs.append_array(transformBytes(sprite1Transform.affine_inverse()))
		inputs.append_array(vector2Bytes(fullTextureRect.size))
		inputs.append_array(vector2Bytes(fullTextureRect.position))
		# Construct data for sprite2
		inputs.append_array(transformBytes(sprite2Transform.affine_inverse()))
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
		
		if result.decode_u32(0) > 0: return true
	return false

# Checking for a point is just a single CPU pixel check
static func spriteTouchingPoint(sprite: Sprite, point: Vector2) -> bool:
	if !sprite.visible: return false
	
	var image: Image = sprite.frameImages[sprite.frame]
	var myFrameRect: Rect2 = sprite.frameRects[sprite.frame]
	var localPoint: Vector2 = getTransform(sprite).affine_inverse() * point
	if !myFrameRect.has_point(localPoint):
		return false
	
	var pixelPosition: Vector2i = Vector2i(localPoint - fullTextureRect.position)
	# All sprite frames are always 1280 x 720
	if (pixelPosition.x < 0) or (pixelPosition.x >= 1280) or\
	(pixelPosition.y < 0) or (pixelPosition.y >= 720):
		return false
	
	return image.get_pixel(pixelPosition.x, pixelPosition.y).a > 0.01

# This exists to fix detection with flipped sprites
static func getTransform(sprite: AnimatedSprite2D) -> Transform2D:
	var transform: Transform2D = sprite.get_global_transform()
	if sprite.flip_h:
		transform = transform.scaled_local(Vector2(-1, 1))
	if sprite.flip_v:
		transform = transform.scaled_local(Vector2(1, -1))
	return transform

static func getCroppedRect(sprite: Sprite) -> Rect2:
	var frameRect: Rect2 = sprite.frameRects[sprite.frame]
	var scale: Vector2 = sprite.scale
	return Rect2(sprite.global_position + (frameRect.position * scale), frameRect.size * scale)

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
