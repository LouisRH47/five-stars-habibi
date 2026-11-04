// Session 67: a soft beam of sunlight with floating dust (polish plan L6), written for
// Five Stars Habibi (CC0; the idea is the usual "fake god rays": a see-through shape that
// adds light, fading along its length and at its edges, and more see-through where you look
// along its side). scripts/light_shafts.gd makes the shapes and sets "strength" by the hour.
// UV.x goes across a side of the beam (0 to 1), UV.y along it (0 at the glass, 1 at the end).
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec3 colour : source_color = vec3(1.0, 0.86, 0.62);
uniform float strength = 0.18;
uniform float dust_speed = 0.05;   // metres per second the dust drifts

varying vec3 world_pos;

float hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float soft_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), u.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), u.x), u.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), u.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), u.x), u.y);
	return mix(a, b, u.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Brightest near the glass, gone at the far end; soft at both ends and both edges.
	float along = smoothstep(0.0, 0.12, UV.y) * pow(1.0 - UV.y, 1.3);
	float across = smoothstep(0.0, 0.3, UV.x) * smoothstep(1.0, 0.7, UV.x);
	// Looking along a side (not through it) makes it fade, so no hard edges show.
	float facing = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.5);
	vec3 drift = world_pos * 1.4 + vec3(0.0, -TIME * dust_speed * 1.4, TIME * dust_speed * 0.7);
	float haze = 0.65 + 0.35 * soft_noise(drift);
	// Little specks of dust catching the light.
	vec3 cell = floor(world_pos * 14.0 + vec3(0.0, -TIME * dust_speed * 14.0, 0.0));
	float speck = step(0.992, hash3(cell)) * 2.5;
	float a = strength * along * across * facing * (haze + speck);
	ALBEDO = colour;
	ALPHA = clamp(a, 0.0, 1.0);
}
