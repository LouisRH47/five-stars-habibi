// Session 68: the delivery beam (made for this game, no outside files). A soft light column
// that fades out towards the top, with faint stripes drifting up and a brighter edge.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(0.95, 0.55, 0.16, 1.0);
// How see-through the whole beam is (0 = gone, 1 = full). The burst fades it out with this.
uniform float strength : hint_range(0.0, 1.0) = 1.0;
// The column's height in metres (GameConfig.MARKER_HEIGHT), to fade it out at the top.
uniform float height = 4.0;
uniform float stripe_gap = 0.6;     // metres between stripes
uniform float stripe_speed = 0.8;   // metres per second, upwards

varying float up;   // 0 at the bottom, 1 at the top
varying float world_y;

void vertex() {
	up = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float fade = pow(1.0 - smoothstep(0.05, 1.0, up), 1.3);
	float stripes = 0.5 + 0.5 * sin((world_y - TIME * stripe_speed) * 6.2832 / stripe_gap);
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	vec3 glow = colour.rgb * (1.1 + 0.3 * stripes) + vec3(0.4) * edge;
	ALBEDO = glow;
	ALPHA = clamp(strength * fade * (0.5 + 0.18 * stripes + 0.4 * edge), 0.0, 1.0);
}
