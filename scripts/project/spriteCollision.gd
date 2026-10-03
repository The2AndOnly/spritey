class_name SpriteCollision
extends Node

static var rd: RenderingDevice
static var shader_rid: RID
static var pipeline_rid: RID

static var default_sampler_rid: RID

func _ready() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return
		
	# Create a default linear-clamp sampler for texture sampling
	var sampler_state = RDSamplerState.new()
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	default_sampler_rid = rd.sampler_create(sampler_state)
	
	# Load and compile GLSL shader
	var shader_file = preload("uid://dvtmfv0s1regf")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader_rid = rd.shader_create_from_spirv(shader_spirv)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)


static func get_animated_sprite_rect(sprite: AnimatedSprite2D) -> Rect2:
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return Rect2()
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return Rect2()
	var size = tex.get_size()
	var offset = sprite.offset
	if sprite.centered:
		offset -= size * 0.5
	return Rect2(offset, size)


static func check_gpu_collision(sprite_a: AnimatedSprite2D, sprite_b: AnimatedSprite2D) -> bool:
	if not rd:
		return false
		
	# 1. Broad Phase AABB
	var rect_a_local = get_animated_sprite_rect(sprite_a)
	var rect_b_local = get_animated_sprite_rect(sprite_b)
	
	var rect_a_world = sprite_a.get_global_transform() * rect_a_local
	var rect_b_world = sprite_b.get_global_transform() * rect_b_local
	var inter: Rect2 = rect_a_world.intersection(rect_b_world)
	
	if inter.size.x <= 0 or inter.size.y <= 0:
		return false

# 2. Build Inputs Buffer with std430 alignment
	var input_bytes = PackedByteArray()
	
	var xform_a_inv = sprite_a.get_global_transform().affine_inverse()
	var xform_b_inv = sprite_b.get_global_transform().affine_inverse()
	
	# Pack Sprite A (80 bytes total)
	input_bytes.append_array(transform_to_bytes(xform_a_inv))               # 64 bytes
	input_bytes.append_array(vector2_to_bytes(rect_a_local.size))            # 8 bytes
	input_bytes.append_array(vector2_to_bytes(rect_a_local.position))        # 8 bytes
	
	# Pack Sprite B (80 bytes total)
	input_bytes.append_array(transform_to_bytes(xform_b_inv))               # 64 bytes
	input_bytes.append_array(vector2_to_bytes(rect_b_local.size))            # 8 bytes
	input_bytes.append_array(vector2_to_bytes(rect_b_local.position))        # 8 bytes
	
	# Pack Intersection Rect (16 bytes)
	input_bytes.append_array(vector4_to_bytes(Vector4(inter.position.x, inter.position.y, inter.size.x, inter.size.y)))

	var input_buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)

	# 3. Build Output Buffer (Binding 1)
	var output_bytes = PackedByteArray([0, 0, 0, 0]) # 32-bit uint initialized to 0
	var output_buffer = rd.storage_buffer_create(output_bytes.size(), output_bytes)

# 4. Fetch Texture RIDs
	var tex_a_rid = sprite_a.sprite_frames.get_frame_texture(sprite_a.animation, sprite_a.frame).get_rid()
	var tex_b_rid = sprite_b.sprite_frames.get_frame_texture(sprite_b.animation, sprite_b.frame).get_rid()
	
	var rd_tex_a = RenderingServer.texture_get_rd_texture(tex_a_rid)
	var rd_tex_b = RenderingServer.texture_get_rd_texture(tex_b_rid)

	# 5. Create RDUniforms for Set 0
	var u_inputs := RDUniform.new()
	u_inputs.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_inputs.binding = 0
	u_inputs.add_id(input_buffer)

	var u_output := RDUniform.new()
	u_output.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_output.binding = 1
	u_output.add_id(output_buffer)

	# --- FIXED: Pass BOTH Sampler AND Texture IDs for sampler2D ---
	var u_tex_a := RDUniform.new()
	u_tex_a.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_tex_a.binding = 2
	u_tex_a.add_id(default_sampler_rid) # 1st ID: Sampler
	u_tex_a.add_id(rd_tex_a)              # 2nd ID: Texture

	var u_tex_b := RDUniform.new()
	u_tex_b.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_tex_b.binding = 3
	u_tex_b.add_id(default_sampler_rid) # 1st ID: Sampler
	u_tex_b.add_id(rd_tex_b)              # 2nd ID: Texture

	# Create Uniform Set
	var uniform_set = rd.uniform_set_create([u_inputs, u_output, u_tex_a, u_tex_b], shader_rid, 0)

	# 6. Execute Compute Pipeline
	var x_groups = int(ceil(inter.size.x / 16.0))
	var y_groups = int(ceil(inter.size.y / 16.0))

	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	# --- FIXED: Don't call submit()/sync() on the main RenderingDevice ---
	# Read buffer directly (Godot handles synchronization automatically)
	var result_bytes = rd.buffer_get_data(output_buffer)
	var has_collision = result_bytes.decode_u32(0) > 0

	# Cleanup temporary buffers
	rd.free_rid(input_buffer)
	rd.free_rid(output_buffer)
	
	return has_collision

# --- Helper Packing Functions ---

static func transform_to_bytes(t: Transform2D) -> PackedByteArray:
	# Mat4 identity with Transform2D embedded
	var floats = PackedFloat32Array([
		t.x.x, t.x.y, 0.0, 0.0,
		t.y.x, t.y.y, 0.0, 0.0,
		0.0,   0.0,   1.0, 0.0,
		t.origin.x, t.origin.y, 0.0, 1.0
	])
	return floats.to_byte_array()

static func vector4_to_bytes(v: Vector4) -> PackedByteArray:
	return PackedFloat32Array([v.x, v.y, v.z, v.w]).to_byte_array()

static func vector2_to_bytes(v: Vector2) -> PackedByteArray:
	return PackedFloat32Array([v.x, v.y]).to_byte_array()

func _exit_tree() -> void:
	if rd and default_sampler_rid.is_valid():
		rd.free_rid(default_sampler_rid)
