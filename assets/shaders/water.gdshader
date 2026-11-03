// Moving water for the stream and the fountain (Session 30). Made for this game (no
// outside files). Two sets of soft ripples drift across the surface, with little bright
// glints where they meet, so the water looks like it's flowing.
shader_type spatial;

uniform vec4 water_colour : source_color = vec4(0.3, 0.6, 0.85, 1.0);
// How fast the ripples move (GameConfig.WATER_FLOW_SPEED).
uniform float flow_speed = 0.6;

varying vec3 world_spot;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_spot.xz;
	float t = TIME * flow_speed;
	float a = sin(p.x * 1.4 - t * 3.0 + sin(p.y * 2.3 + t) * 1.2);
	float b = sin(p.y * 1.9 + p.x * 0.7 + t * 2.2);
	float ripple = (a + b) * 0.25 + 0.5;  // 0 to 1
	float glint = smoothstep(0.8, 0.95, ripple);
	ALBEDO = water_colour.rgb * (0.82 + 0.25 * ripple) + vec3(glint * 0.3);
	ROUGHNESS = 0.2;
	SPECULAR = 0.6;
}
