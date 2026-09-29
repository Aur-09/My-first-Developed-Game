shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 ember_color : source_color = vec4(0.95, 0.15, 0.025, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.68, 0.14, 1.0);
uniform float flicker_strength = 0.18;

void vertex() {
	float sway = sin(TIME * 6.0 + UV.y * 8.0 + UV.x * 5.0) * flicker_strength * UV.y;
	VERTEX.x += sway;
	VERTEX.z += cos(TIME * 4.2 + UV.y * 7.0 + UV.x * 4.0) * flicker_strength * 0.45 * UV.y;
}

void fragment() {
	float tip = smoothstep(0.72, 1.0, UV.y);
	float base_glow = smoothstep(0.02, 0.32, UV.y);
	float pulse = 0.86 + 0.14 * sin(TIME * 8.0 + UV.x * 9.0);
	vec3 flame = mix(core_color.rgb, ember_color.rgb, tip);
	ALBEDO = flame * pulse;
	EMISSION = flame * (1.7 + 0.7 * base_glow);
	ALPHA = 0.88 + 0.12 * base_glow;
}
