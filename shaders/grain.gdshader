shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float grain_amount : hint_range(0.0, 0.5) = 0.05;
uniform float grain_size : hint_range(1.0, 4.0) = 1.5;
uniform float time_scale : hint_range(0.0, 60.0) = 25.0;

float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 scene_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 grain_uv = UV * grain_size;
	float noise = random(grain_uv + vec2(TIME * time_scale, 0.0));
	noise = (noise - 0.5) * grain_amount;
	float luminance = dot(scene_color.rgb, vec3(0.299, 0.587, 0.114));
	float grain_mask = 1.0 - luminance * 0.5;
	COLOR.rgb = scene_color.rgb + vec3(noise * grain_mask);
	COLOR.a = scene_color.a;
}
