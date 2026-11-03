// Heat shimmer (Session 28): a see-through sheet over the whole screen that makes the
// picture wobble a little, but only on the ground far away from the camera, like hot air
// above the roads at noon. scripts/sun_cycle.gd sets "strength" (0 = off).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float strength = 0.0;
uniform float near_distance = 18.0;
uniform float full_distance = 55.0;
uniform float amount = 0.0018;

void vertex() {
	// Stretch the 2 x 2 sheet over the whole screen, whatever the camera does.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// How far away is what we see here, and how high above the ground is it?
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	float distance = -view.z;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	float far_away = smoothstep(near_distance, full_distance, distance)
			* (1.0 - smoothstep(full_distance * 4.0, full_distance * 6.0, distance));
	float near_ground = 1.0 - smoothstep(0.4, 2.5, world.y);
	float wobble_amount = strength * far_away * near_ground * amount;
	vec2 wobble = vec2(
			sin(SCREEN_UV.y * 260.0 + TIME * 7.0 + SCREEN_UV.x * 30.0),
			cos(SCREEN_UV.y * 190.0 - TIME * 5.0)) * wobble_amount;
	ALBEDO = texture(screen_tex, SCREEN_UV + wobble).rgb;
	ALPHA = 1.0;
}
