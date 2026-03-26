shader_type spatial;
render_mode unshaded;

uniform vec4 silhouette_color : source_color = vec4(0.03, 0.03, 0.05, 1.0);
uniform vec4 rim_color : source_color = vec4(0.15, 0.15, 0.2, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.6;

void fragment() {
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = pow(rim, rim_power) * rim_intensity;
	vec3 final_color = mix(silhouette_color.rgb, rim_color.rgb, rim);
	ALBEDO = final_color;
	EMISSION = rim_color.rgb * rim * 0.3;
}
