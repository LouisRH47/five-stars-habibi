// Session 67: thin comic outlines (polish plan L8; off unless Settings.outlines is on).
// Written for Five Stars Habibi (CC0). It only reads the depth (how far each pixel is), so it
// works on the Mac and in the browser. A full-screen square (scripts/polish/look_extras.gd)
// compares each pixel with its 4 neighbours: where the distance jumps (the edge of a building
// in front of something further away), it draws a dark teal line. Lines fade out far away.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 line_colour : source_color = vec3(0.106, 0.227, 0.251);
uniform float line_alpha = 0.4;
uniform float jump = 0.03;
uniform vec2 fade = vec2(40.0, 80.0);

void vertex() {
	// Cover the whole screen, whatever the camera does.
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

// 1 / distance at a screen point: flat surfaces change smoothly in this, edges jump.
float inv_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).x;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 view = inv_projection * vec4(ndc, 1.0);
	return 1.0 / max(-view.z / view.w, 0.001);
}

void fragment() {
	// Lines about 1.5 px wide on a 720p screen, and just as thick on bigger screens.
	vec2 px = max(1.0, VIEWPORT_SIZE.y / 480.0) / VIEWPORT_SIZE;
	float c = inv_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float l = inv_depth(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float r = inv_depth(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float u = inv_depth(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float d = inv_depth(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	// How much the neighbours bend away from a flat surface, as a part of the distance.
	float edge = max(abs(l + r - 2.0 * c), abs(u + d - 2.0 * c)) / c;
	float line = smoothstep(jump, jump * 2.0, edge);
	float dist = 1.0 / max(max(c, max(l, r)), max(u, d));  // the nearest of the five
	line *= 1.0 - smoothstep(fade.x, fade.y, dist);
	ALBEDO = line_colour;
	ALPHA = line * line_alpha;
}
