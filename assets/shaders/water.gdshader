// Session 68 (PRD "Polish pass", W2): water that looks wet. Made for this game (no outside
// files; the ideas are the usual stylised-water ones). The old look is water_v1.gdshader.
//   - a light rim of foam where the water meets the edge, broken up by moving noise
//   - lighter at the edges, deeper blue in the middle
//   - small waves that catch the sun (sparkles)
//   - pools: moving light patterns (caustics), like sun through water on the tiles
//   - a thin ring of foam round things standing in the water (swimmers, posts), found with
//     the depth texture (works in the browser too)
// The water is a thin flat shape, so the edge is worked out from its size (edge_half or
// stream_shape, set by scripts/water_look.gd), not from the depth texture.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 water_colour : source_color = vec4(0.3, 0.6, 0.85, 1.0);
// How fast the ripples move (GameConfig.WATER_FLOW_SPEED).
uniform float flow_speed = 0.6;
// 0 stream, 1 pool (a box), 2 fountain (a round dish).
uniform int kind = 0;
// Pool: half the water's size (x, z). Fountain: x = the radius, y = the foam round the
// column in the middle. 0 = no edge foam.
uniform vec2 edge_half = vec2(0.0);
// Stream: middle line z = x0 + amp * sin(world x * freq); w = half the width. Packed as
// (z, amp, freq, half width). w = 0: no edge foam.
uniform vec4 stream_shape = vec4(0.0);
uniform vec4 foam_colour : source_color = vec4(0.94, 0.98, 1.0, 1.0);
uniform float foam_width = 0.35;     // metres of foam at the edge
uniform float deep_at = 1.2;         // metres from the edge where it's fully deep
uniform float foam_fade = 60.0;      // no foam further than this (it would flicker)
uniform float floor_gap = 0.05;      // how far under the surface the plain ground is
uniform float sparkle = 2.5;         // how bright the sun sparkles are
uniform float see_through = 0.1;     // 0 = solid, 0.1 = a little of what's under shows
uniform bool caustics = true;        // pools only; off on Graphics Low
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;

varying vec3 world_spot;
varying vec3 local_spot;
varying float facing_up;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_spot = VERTEX;
	facing_up = (MODEL_MATRIX * vec4(NORMAL, 0.0)).y;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// The wave height (the same two drifting ripples as the old water).
float waves(vec2 p, float t) {
	float a = sin(p.x * 1.4 - t * 3.0 + sin(p.y * 2.3 + t) * 1.2);
	float b = sin(p.y * 1.9 + p.x * 0.7 + t * 2.2);
	float c = sin((p.x + p.y) * 4.1 + t * 4.0) * 0.35;
	return (a + b + c) * 0.25;
}

// Bright wobbly lines like sunlight through water: the gap between the two nearest cell
// points is small along the cell borders (cells about 0.7 m).
float caustic_layer(vec2 p, float t) {
	vec2 cell = floor(p);
	float d1 = 9.0;
	float d2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			vec2 h = vec2(hash(c), hash(c + 17.3));
			vec2 point = c + 0.5 + 0.4 * sin(t + 6.2832 * h);
			float d = length(p - point);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return 1.0 - smoothstep(0.0, 0.12, d2 - d1);
}

// Metres from here to the water's edge (big = far from any edge).
float edge_distance() {
	if (kind == 1 && edge_half.x > 0.0) {
		return min(edge_half.x - abs(local_spot.x), edge_half.y - abs(local_spot.z));
	}
	if (kind == 2 && edge_half.x > 0.0) {
		// The dish's rim, and the column in the middle where the water falls (y = its radius).
		float r = length(local_spot.xz);
		return min(edge_half.x - r, r - edge_half.y);
	}
	if (kind == 0 && stream_shape.w > 0.0) {
		float middle = stream_shape.x + stream_shape.y * sin(world_spot.x * stream_shape.z);
		float slope = stream_shape.y * stream_shape.z * cos(world_spot.x * stream_shape.z);
		return stream_shape.w - abs(world_spot.z - middle) / sqrt(1.0 + slope * slope);
	}
	return 99.0;
}

void fragment() {
	vec2 p = world_spot.xz;
	float t = TIME * flow_speed;
	if (facing_up < 0.5) {
		discard;   // only the top is water (the thin sides would show as lines)
	}
	float top = 1.0;
	// Waves tilt the surface a little so the sun sparkles on them.
	float e = 0.08;
	float h = waves(p, t);
	vec2 slope = vec2(waves(p + vec2(e, 0.0), t) - h, waves(p + vec2(0.0, e), t) - h) / e;
	vec3 world_normal = normalize(vec3(-slope.x * 0.18, 1.0, -slope.y * 0.18));
	NORMAL = mix(NORMAL, normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz), top);

	float far = length(world_spot - CAMERA_POSITION_WORLD);
	float near_enough = 1.0 - smoothstep(foam_fade * 0.75, foam_fade, far);
	float edge = edge_distance();
	float deep = smoothstep(0.0, deep_at, edge);
	vec3 shallow_colour = mix(water_colour.rgb, vec3(0.75, 0.95, 0.95), 0.28);
	vec3 deep_colour = water_colour.rgb * vec3(0.62, 0.78, 0.9);
	vec3 colour = mix(shallow_colour, deep_colour, deep) * (0.92 + 0.16 * (h + 0.5));

	// Foam at the edge, broken up by slowly moving noise.
	float n = noise(p * 2.2 + vec2(t * 0.35, -t * 0.2)) * 0.65 + noise(p * 6.0 - vec2(t * 0.6)) * 0.35;
	float rim = 1.0 - smoothstep(0.0, foam_width, edge + (n - 0.5) * foam_width * 0.9);
	float foam = smoothstep(0.35, 0.6, rim * (0.65 + 0.7 * n));

	// Foam round things that stand in the water: what's behind the surface is much closer to
	// the surface than the ground under it.
	float raw = textureLod(depth_texture, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, raw) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw);
#endif
	vec4 behind = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	behind.xyz /= behind.w;
	float below = world_spot.y - (INV_VIEW_MATRIX * vec4(behind.xyz, 1.0)).y;
	float contact = (1.0 - smoothstep(floor_gap * 0.25, floor_gap * 0.7, below)) * step(-0.05, below);
	foam = max(foam, contact * smoothstep(0.3, 0.6, n + 0.2));
	foam *= near_enough * top;

	float light_lines = 0.0;
	if (caustics && kind == 1) {
		float c1 = caustic_layer(p / 0.7 + vec2(t * 0.15, t * 0.1), TIME * 0.9);
		float c2 = caustic_layer(p / 0.9 - vec2(t * 0.12, -t * 0.08) + 3.7, TIME * 0.7 + 2.0);
		light_lines = min(c1 + c2, 1.2) * (0.35 + 0.65 * deep) * near_enough;
	}
	colour += vec3(0.85, 1.0, 1.0) * light_lines * 0.22;
	ALBEDO = mix(colour, foam_colour.rgb, foam);
	ROUGHNESS = mix(0.06, 0.6, foam);
	SPECULAR = 0.5;
	ALPHA = mix(1.0 - see_through * (0.4 + 0.6 * deep), 1.0, foam);
}

// Sunlight: soft light on the water, plus sharp sparkles where a wave reflects the sun at you.
void light() {
	float facing = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += facing * ATTENUATION * LIGHT_COLOR / PI;
	float glint = pow(max(dot(reflect(-LIGHT, NORMAL), VIEW), 0.0), 64.0);
	SPECULAR_LIGHT += glint * sparkle * ATTENUATION * LIGHT_COLOR / PI;
}
