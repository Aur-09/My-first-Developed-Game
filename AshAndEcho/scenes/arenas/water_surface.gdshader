shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.012, 0.095, 0.15, 1.0);
uniform vec4 shallows_color : source_color = vec4(0.025, 0.30, 0.34, 1.0);
uniform vec4 glint_color : source_color = vec4(0.24, 0.72, 0.72, 1.0);

void vertex() {
	float swell = sin(VERTEX.x * 0.34 + TIME * 0.72) * 0.10;
	float cross_wave = cos(VERTEX.z * 0.52 - TIME * 0.58) * 0.055;
	VERTEX.y += swell + cross_wave;
}

void fragment() {
	float bands = sin(UV.x * 190.0 + sin(UV.y * 42.0 + TIME * 0.42) * 2.2);
	float ripples = cos(UV.y * 145.0 - UV.x * 34.0 - TIME * 0.5);
	float variation = 0.5 + 0.5 * (bands * 0.62 + ripples * 0.38);
	ALBEDO = mix(deep_color.rgb, shallows_color.rgb, variation * 0.74);
	ROUGHNESS = 0.19;
	METALLIC = 0.42;
	SPECULAR = 0.82;
	EMISSION = glint_color.rgb * smoothstep(0.78, 0.99, variation) * 0.26;
}
