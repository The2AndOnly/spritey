#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// Memory layout matching GDScript byte packing (80 bytes per sprite)
struct SpriteData {
    mat4 inv_transform; // 64 bytes (16 floats)
    vec2 size;          // 8 bytes
    vec2 offset;        // 8 bytes
};

layout(std430, set = 0, binding = 0) buffer Inputs {
    SpriteData sprite_a; // Offset 0
    SpriteData sprite_b; // Offset 80
    vec4 inter_rect;     // Offset 160 (x, y, width, height)
};

layout(std430, set = 0, binding = 1) buffer Output {
    uint collision_flag;
};

layout(set = 0, binding = 2) uniform sampler2D tex_a;
layout(set = 0, binding = 3) uniform sampler2D tex_b;

void main() {
    uvec2 gid = gl_GlobalInvocationID.xy;
    
    // Bounds check within intersection area
    if (gid.x >= uint(inter_rect.z) || gid.y >= uint(inter_rect.w)) {
        return;
    }
    
    // World coordinates at pixel center
    vec2 world_pos = vec2(inter_rect.x + float(gid.x) + 0.5, inter_rect.y + float(gid.y) + 0.5);
    
    // --- Sprite A UV Lookup ---
    vec4 local_a = sprite_a.inv_transform * vec4(world_pos, 0.0, 1.0);
    vec2 pixel_a = local_a.xy - sprite_a.offset;
    vec2 uv_a = pixel_a / sprite_a.size;
    
    // --- Sprite B UV Lookup ---
    vec4 local_b = sprite_b.inv_transform * vec4(world_pos, 0.0, 1.0);
    vec2 pixel_b = local_b.xy - sprite_b.offset;
    vec2 uv_b = pixel_b / sprite_b.size;
    
    // Check if point lands inside both texture bounds
    if (uv_a.x >= 0.0 && uv_a.x <= 1.0 && uv_a.y >= 0.0 && uv_a.y <= 1.0 &&
        uv_b.x >= 0.0 && uv_b.x <= 1.0 && uv_b.y >= 0.0 && uv_b.y <= 1.0) {
        
        float alpha_a = texture(tex_a, uv_a).a;
        float alpha_b = texture(tex_b, uv_b).a;
        
        if (alpha_a > 0.1 && alpha_b > 0.1) {
            atomicOr(collision_flag, 1u);
        }
    }
}