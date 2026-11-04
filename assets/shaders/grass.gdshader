// Session 55: grass blades that sway in the wind and bend away from the bike.
// Written for Five Stars Habibi (CC0, like the "Stylized Multimesh Grass" idea on
// godotshaders.com: tufts in a MultiMesh, swayed in the vertex shader).
// Each blade's UV.y is 0 at the root and 1 at the tip. Blades shrink away far from the
// camera, so grass fades out softly instead of popping (no see-through needed).
shader_type spatial;
render_mode cull_disabled, world_vertex_coords, specular_disabled, diffuse_lambert;

uniform vec3 root_colour : source_color = vec3(0.2, 0.42, 0.14);
uniform vec3 tip_colour : source_color = vec3(0.62, 0.8, 0.32);
uniform float wind_strength = 0.08;
uniform float wind_speed = 1.4;
uniform vec3 pusher = vec3(0.0, -1000.0, 0.0);   // the bike: blades bend away from it
uniform float push_radius = 1.3;
uniform float fade_start = 28.0;
uniform float fade_end = 38.0;

varying float shade;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;   // the tuft's spot on the ground
	vec3 spot = VERTEX;
	float up = UV.y;
	float bend = up * up;
	float t = TIME * wind_speed;
	// Slow rolling waves across the lawn, plus a little flutter.
	float wave = sin(t + spot.x * 0.25 + spot.z * 0.15) + 0.35 * sin(t * 2.3 + spot.z * 0.9);
	vec3 sway = vec3(wave, 0.0, 0.5 * sin(t * 0.7 + spot.x * 0.2)) * wind_strength * bend;
	// Bend away from the bike when it rides through.
	vec3 away = spot - pusher;
	away.y = 0.0;
	float near = 1.0 - smoothstep(0.0, push_radius, length(away));
	vec3 push = normalize(away + vec3(0.0001, 0.0, 0.0)) * near * 0.3 * bend;
	push.y = -near * 0.15 * up;
	// Shrink to nothing far away.
	float keep = 1.0 - smoothstep(fade_start, fade_end, distance(root, CAMERA_POSITION_WORLD));
	VERTEX = root + ((spot - root) + sway + push) * keep;
	NORMAL = vec3(0.0, 1.0, 0.0);
	shade = 0.88 + 0.24 * hash(floor(root.xz * 3.0));
}

void fragment() {
	ALBEDO = mix(root_colour, tip_colour, UV.y) * shade;
	ROUGHNESS = 0.9;
	// Both sides of a blade are lit like the ground (face up), so none look black.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
