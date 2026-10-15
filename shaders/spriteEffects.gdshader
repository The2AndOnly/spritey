// AI GENERATED
shader_type canvas_item;

uniform float brightness = 0.0f;
uniform float hueShift = 0.0f;
uniform float saturation = 0.0f;
uniform float fisheye = 0.0f;
uniform vec4 effect_rect = vec4(0.25, 0.25, 0.5, 0.5);

vec3 rgb2hsl(vec3 c) {
    float cmin = min(c.r, min(c.g, c.b));
    float cmax = max(c.r, max(c.g, c.b));
    float delta = cmax - cmin;
    
    vec3 hsl = vec3(0.0);
    hsl.z = (cmax + cmin) * 0.5; // Lightness
    
    if (delta > 0.0) {
        if (hsl.z < 0.5) {
            hsl.y = delta / (cmax + cmin);
        } else {
            hsl.y = delta / (2.0 - cmax - cmin);
        }
        
        if (cmax == c.r) {
            hsl.x = (c.g - c.b) / delta + (c.g < c.b ? 6.0 : 0.0);
        } else if (cmax == c.g) {
            hsl.x = (c.b - c.r) / delta + 2.0;
        } else {
            hsl.x = (c.r - c.g) / delta + 4.0;
        }
        hsl.x /= 6.0;
    }
    return hsl;
}

// HSL to RGB conversion
vec3 hsl2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    float c_val = (1.0 - abs(2.0 * c.z - 1.0)) * c.y;
    return (rgb - 0.5) * c_val + c.z;
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
		vec3 final_rgb = color.rgb + (brightness / 100.0f);
		if ((saturation != 0.0f) || (hueShift != 0.0f)) {
			vec3 hsl = rgb2hsl(final_rgb);
			hsl.x = fract(hsl.x + (hueShift / 100.0f));
			hsl.y *= max(0.0f, ((saturation / 100.0f) + 1.0f));
			final_rgb = hsl2rgb(hsl);
		}
		COLOR = vec4(final_rgb, color.a);
	}
}
