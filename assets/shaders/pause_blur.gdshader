shader_type canvas_item;
// Session 71: the game behind the pause menu goes soft and blurry with a dark tint.
// It reads the screen at a smaller mip level (blurrier) and mixes 9 nearby samples, so it
// still looks soft on renderers that don't make screen mipmaps (Compatibility in the browser).

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float lod = 2.5;
uniform float spread = 3.0;
uniform vec4 tint : source_color = vec4(0.106, 0.114, 0.133, 1.0);
uniform float tint_amount = 0.35;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * spread * exp2(lod * 0.5);
	vec3 sum = vec3(0.0);
	float weight = 0.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			float w = (x == 0 && y == 0) ? 2.0 : 1.0;
			sum += textureLod(screen, SCREEN_UV + vec2(float(x), float(y)) * px, lod).rgb * w;
			weight += w;
		}
	}
	COLOR = vec4(mix(sum / weight, tint.rgb, tint_amount), 1.0);
}
