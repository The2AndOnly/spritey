shader_type canvas_item;

uniform float brightness = 0.0f;
uniform float hueShift = 0.5f;
uniform float saturation = 0.0f;
uniform float fisheye = 70.0f;
uniform vec4 effect_rect = vec4(0.25, 0.25, 0.5, 0.5);

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0f, -1.0f / 3.0f, 2.0f / 3.0f, -1.0f);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10f;
    return vec3(abs(q.z + (q.w - q.y) / (6.0f * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0f, 2.0f / 3.0f, 1.0f / 3.0f, 3.0f);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0f - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0f, 1.0f), c.y);
}

mat3 saturationMatrix(float sat) {
    vec3 luminance = vec3(0.2126, 0.7152, 0.0722);
    float oneMinusSat = 1.0 - sat;
    vec3 red = vec3(luminance.x * oneMinusSat);
    red.r += sat;
    vec3 green = vec3(luminance.y * oneMinusSat);
    green.g += sat;
    vec3 blue = vec3(luminance.z * oneMinusSat);
    blue.b += sat;
    return mat3(red, green, blue);
}

void fragment() {
	
	// Check if the current pixel is strictly inside the rectangular region
	bool inside = (UV.x >= effect_rect.x && UV.x <= (effect_rect.x + effect_rect.z) &&
	               UV.y >= effect_rect.y && UV.y <= (effect_rect.y + effect_rect.w));
	if (inside) {
		vec2 uv = UV;
		if (fisheye != 0.0) {
			float newAmount = (fisheye / 100.0) + 1.0;
			vec2 local_uv = (UV - effect_rect.xy) / effect_rect.zw;
			vec2 kCenter = vec2(0.5);
			
			vec2 vec = (local_uv - kCenter) / kCenter;
			float vecLength = length(vec);
			
			if (vecLength > 0.0) {
				float r = pow(min(vecLength, 1.0), newAmount) * max(1.0, vecLength);
				vec2 unit = vec / vecLength;
				local_uv = kCenter + r * unit * kCenter;
			}
			uv = effect_rect.xy + local_uv * effect_rect.zw;
		}
		vec4 color = texture(TEXTURE, uv);
		vec3 final_rgb = color.rgb + brightness;
		if (saturation != 0.0) {
			final_rgb = saturationMatrix(saturation + 1.0f) * final_rgb;
		}
		if (hueShift != 0.0) {
			vec3 hsv = rgb2hsv(final_rgb);
			hsv.x += hueShift;
			final_rgb = hsv2rgb(hsv);
		}
		COLOR = vec4(final_rgb, color.a);
	}
}
