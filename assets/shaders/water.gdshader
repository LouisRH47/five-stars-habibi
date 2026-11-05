// Moving water for the stream, the ponds, the fountain and the pools (Session 30, made
// better in Session 81). Made for this game (no outside files). It keeps the old look Louis
// liked (two sets of soft ripples drifting across, with little bright glints where they
// meet) and adds:
//   - the ripples tilt the surface, so the sun sparkles on it
//   - the far water reflects a little sky (it gets lighter when you look along it)
//   - pools (pool_floor = 1): you see the tiled floor, the dark lane lines and moving
//     light patterns (caustics) through the water, shifting as you move
shader_type spatial;

uniform vec4 water_colour : source_color = vec4(0.3, 0.6, 0.85, 1.0);
// How fast the ripples move (GameConfig.WATER_FLOW_SPEED).
uniform float flow_speed = 0.6;
// How much the ripples tilt the surface (0 = flat mirror-like, 1 = choppy).
uniform float wave_tilt = 0.5;
// The sky colour the water reflects when you look along it.
uniform vec4 sky_colour : source_color = vec4(0.78, 0.9, 0.98, 1.0);
// Pools only: 1 = draw the tiled floor seen through the water, 0 = a stream or pond.
uniform float pool_floor = 0.0;
// Pools only: how deep the floor looks (metres) and how big a floor tile is.
uniform float floor_depth = 1.2;
uniform float tile_size = 0.25;
// Pools only: dark lane lines on the floor. lane_spacing 0 = none. lanes_along_x: the lines
// run along x (else along z). lane_origin: where the first gap between lanes is (z or x).
uniform float lane_spacing = 0.0;
uniform float lane_origin = 0.0;
uniform bool lanes_along_x = true;
uniform vec4 lane_colour : source_color = vec4(0.05, 0.2, 0.45, 1.0);

varying vec3 world_spot;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_spot.xz;
	float t = TIME * flow_speed;
	// The two old ripple sets, plus their slopes (so the surface can tilt).
	float a_in = p.x * 1.4 - t * 3.0 + sin(p.y * 2.3 + t) * 1.2;
	float b_in = p.y * 1.9 + p.x * 0.7 + t * 2.2;
	float a = sin(a_in);
	float b = sin(b_in);
	vec2 slope = vec2(cos(a_in) * 1.4, cos(a_in) * cos(p.y * 2.3 + t) * 2.76)
			+ vec2(cos(b_in) * 0.7, cos(b_in) * 1.9);
	// A third, smaller and quicker set of ripples for detail.
	float c_in = dot(p, vec2(-3.1, 2.7)) + t * 4.0;
	slope += vec2(-3.1, 2.7) * cos(c_in) * 0.3;
	float ripple = (a + b) * 0.25 + 0.5;  // 0 to 1
	float glint = smoothstep(0.8, 0.95, ripple);

	vec3 up = normalize(vec3(-slope.x * 0.05 * wave_tilt, 1.0, -slope.y * 0.05 * wave_tilt));
	NORMAL = normalize((VIEW_MATRIX * vec4(up, 0.0)).xyz);

	vec3 colour = water_colour.rgb * (0.82 + 0.25 * ripple) + vec3(glint * 0.3);
	if (pool_floor > 0.5) {
		// Look "through" the water: the floor point you see moves with the view direction.
		vec3 camera = INV_VIEW_MATRIX[3].xyz;
		vec3 to_eye = normalize(camera - world_spot);
		vec2 fp = p - to_eye.xz / max(to_eye.y, 0.25) * floor_depth + slope * 0.02;
		vec2 cell = abs(fract(fp / tile_size) - 0.5);
		float grout = smoothstep(0.44, 0.5, max(cell.x, cell.y));
		float lane = 0.0;
		if (lane_spacing > 0.0) {
			float across = lanes_along_x ? fp.y : fp.x;
			float d = abs(fract((across - lane_origin) / lane_spacing) - 0.5) * lane_spacing;
			lane = 1.0 - smoothstep(0.1, 0.14, d);
		}
		// Caustics: bright wobbly lines of light on the floor.
		vec2 cp = fp * 2.2;
		float k = sin(cp.x * 3.1 + t * 1.3 + sin(cp.y * 2.7 - t)) + sin(cp.y * 3.4 - t * 1.1 + sin(cp.x * 2.2 + t));
		float caustic = smoothstep(1.3, 1.9, k);
		vec3 floor_colour = water_colour.rgb * (1.0 - grout * 0.12);
		floor_colour = mix(floor_colour, lane_colour.rgb, lane * 0.7);
		colour = floor_colour * (0.92 + 0.1 * ripple) + vec3(caustic * 0.12) + vec3(glint * 0.06);
	}
	// Looking along the water you see more of the sky in it.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(colour, sky_colour.rgb, fresnel * 0.45);
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
}
