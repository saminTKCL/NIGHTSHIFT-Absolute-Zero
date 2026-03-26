shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.6;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float danger_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 danger_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);

void fragment() {
	vec4 scene_color = texture(TEXTURE, UV);
	vec2 uv = UV - 0.5;
	float dist = length(uv * vec2(1.0, 0.8));
	float vignette = smoothstep(vignette_softness, vignette_softness + vignette_intensity, dist);
	vignette *= vignette_opacity;
	vec3 vig_color = mix(vignette_color.rgb, danger_color.rgb, danger_intensity);
	float final_intensity = mix(vignette, min(vignette + 0.3, 1.0), danger_intensity);
	COLOR.rgb = mix(scene_color.rgb, vig_color, final_intensity);
	COLOR.a = scene_color.a;
}
