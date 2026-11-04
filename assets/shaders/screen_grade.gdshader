// Session 67: a soft vignette (polish plan L4): the corners of the screen a little darker,
// which pulls your eye to the middle. Written for Five Stars Habibi (CC0). A see-through
// ColorRect over the 3D world and under the HUD (scripts/polish/look_extras.gd).
shader_type canvas_item;

uniform vec3 tint : source_color = vec3(0.106, 0.114, 0.133);  // #1B1D22
uniform float strength = 0.22;

void fragment() {
	// 0 in the middle, about 1 in the corners (an oval the shape of the screen).
	float dark = smoothstep(0.55, 1.0, length(UV - 0.5) * 1.4);
	COLOR = vec4(tint, dark * strength);
}
