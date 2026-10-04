#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// Total: 176 bytes

struct SpriteData {
    mat4 transform; // 64 bytes
    vec2 size; // 8 bytes
    vec2 position; // 8 bytes
};

layout(std430, set = 0, binding = 0) buffer inputs {
    SpriteData sprite1; // 80 bytes
    SpriteData sprite2; // 80 bytes
    vec4 intersection; // 16 bytes
};

layout(std430, set = 0, binding = 1) buffer outputs {
    uint collision;
};

layout(set = 0, binding = 2) uniform sampler2D texture1;
layout(set = 0, binding = 3) uniform sampler2D texture2;

void main() {
    uvec2 invocation = gl_GlobalInvocationID.xy;
    if ((invocation.x >= uint(intersection.z)) || (invocation.y >= uint(intersection.w))) {
        return;
    }
    
    vec2 globalPosition = vec2(intersection.x + float(invocation.x) + 0.5, intersection.y + float(invocation.y) + 0.5);
    vec4 local1 = sprite1.transform * vec4(globalPosition, 0.0, 1.0);
    vec2 uv1 = (local1.xy - sprite1.position) / sprite1.size;
    vec4 local2 = sprite2.transform * vec4(globalPosition, 0.0, 1.0);
    vec2 uv2 = (local2.xy - sprite2.position) / sprite2.size;
    
    if ((uv1.x >= 0.0) && (uv1.x <= 1.0) && (uv1.y >= 0.0) && (uv1.y <= 1.0) &&
        (uv2.x >= 0.0) && (uv2.x <= 1.0) && (uv2.y >= 0.0) && (uv2.y <= 1.0)) {
        float alpha1 = texture(texture1, uv1).a;
        float alpha2 = texture(texture2, uv2).a;
        if ((alpha1 > 0.1) && (alpha2 > 0.1)) {
            atomicOr(collision, 1u);
        }
    }
}