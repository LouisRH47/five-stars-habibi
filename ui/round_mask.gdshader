// Cuts a picture to a circle with a soft edge (the round mini-map, Session 20).
// Used on the SubViewportContainer that shows the map, so UV runs 0 to 1 across it.
shader_type canvas_item;

void fragment() {
	float edge = distance(UV, vec2(0.5));
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= 1.0 - smoothstep(0.495, 0.5, edge);
}
