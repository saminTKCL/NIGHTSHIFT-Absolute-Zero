shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 fog_color : source_color = vec4(0.08, 0.1, 0.14, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.15;
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.02;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

float noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = noise(i);
	float b = noise(i + vec2(1.0, 0.0));
	float c = noise(i + vec2(0.0, 1.0));
	float d = noise(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		val += smooth_noise(p) * amp;
		p *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec2 uv = UV * noise_scale;
	uv.x += TIME * scroll_speed;
	float fog = fbm(uv) * fog_density;
	float edge_fade = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	edge_fade *= smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.7, UV.y);
	fog *= edge_fade;
	ALBEDO = fog_color.rgb;
	ALPHA = fog * fog_color.a;
}
