// Session 62: a parked car with its own paint colour (scripts/car_park_cars.gd).
// The Kenney cars get their colours from one colour atlas. Where the body uses the paint
// cell of the atlas, this swaps in the car's colour (from the MultiMesh custom data) and keeps
// the cell's light-to-dark shading; windows, lights and trim keep their own colours.
shader_type spatial;

uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform vec4 paint_rect = vec4(0.0);     // u0, v0, u1, v1 of the paint cell
uniform float paint_light = 0.6;         // the paint cell's average lightness

varying vec3 paint;

void vertex() {
	paint = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	vec3 colour = texture(atlas, UV).rgb;
	bool painted = UV.x >= paint_rect.x && UV.x <= paint_rect.z && UV.y >= paint_rect.y && UV.y <= paint_rect.w;
	float light = dot(colour, vec3(0.299, 0.587, 0.114));
	ALBEDO = painted ? paint * clamp(light / paint_light, 0.6, 1.3) : colour;
	ROUGHNESS = painted ? 0.5 : 0.8;
	SPECULAR = 0.3;
}
