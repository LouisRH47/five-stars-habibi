// Session 68: the glowing ring on the ground under the delivery beam (made for this game).
// Drawn on a flat square: a soft bright ring near the edge and a faint glow inside it.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(0.95, 0.55, 0.16, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float ring = 0.8;       // where the ring is (1 = the square's edge)
uniform float thickness = 0.09; // how thick the ring is (same units)

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float band = 1.0 - smoothstep(0.0, thickness, abs(d - ring));
	float inside = (1.0 - smoothstep(ring - 0.05, ring, d)) * 0.18;
	float dashes = 0.75 + 0.25 * sin(atan(UV.y - 0.5, UV.x - 0.5) * 12.0 + TIME * 1.5);
	ALBEDO = colour.rgb * 1.1 + vec3(0.25) * band;
	ALPHA = clamp(strength * (band * 0.85 * dashes + inside), 0.0, 1.0);
}
