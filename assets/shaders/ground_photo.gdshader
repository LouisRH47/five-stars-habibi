shader_type spatial;
// Session 82: big ground surfaces (lawns and sand) from real photos (Poly Haven, CC0), laid
// in world metres so nothing stretches. So you can't see the photo repeat:
//  - the main photo is drawn twice (normal size, and bigger and turned), and a soft noise
//    picture blends between the two copies;
//  - a second photo (the lawn's leafy_grass) fills big soft patches picked by the same noise.
// SurfaceTextures sets every number below from its SURFACES table.

uniform sampler2D main_photo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D patch_photo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform float main_metres = 5.0;    // metres one main photo covers
uniform float patch_metres = 2.5;   // metres one patch photo covers
uniform float noise_metres = 70.0;  // metres one noise picture covers (size of the patches)
uniform vec3 main_tint : source_color = vec3(1.0);
uniform vec3 patch_tint : source_color = vec3(1.0);
uniform float patch_share = 0.0;    // about how much of the ground is the patch photo (0 to 1)

varying vec3 world_spot;
varying vec3 world_normal;

void vertex() {
	world_spot = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Flat ground uses x and z; the steep sides of a hill or box use the other two axes.
	vec2 spot = world_spot.xz;
	if (abs(world_normal.x) > 0.7) {
		spot = world_spot.zy;
	} else if (abs(world_normal.z) > 0.7) {
		spot = world_spot.xy;
	}
	float big = texture(noise, spot / noise_metres).r;
	float small = texture(noise, spot / (noise_metres * 0.37) + vec2(0.31, 0.67)).r;
	// The main photo twice: normal size, and 1.6 times bigger turned about 37 degrees.
	vec2 turned = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * spot;
	vec3 first = texture(main_photo, spot / main_metres).rgb;
	vec3 second = texture(main_photo, turned / (main_metres * 1.6) + vec2(0.5)).rgb;
	vec3 ground = mix(first, second, smoothstep(0.3, 0.7, small)) * main_tint;
	if (patch_share > 0.0) {
		vec3 patch = texture(patch_photo, spot / patch_metres).rgb * patch_tint;
		float amount = smoothstep(1.0 - patch_share - 0.15, 1.0 - patch_share + 0.15, big);
		ground = mix(ground, patch, amount);
	}
	ALBEDO = ground * (0.94 + 0.12 * small);
	ROUGHNESS = 0.95;
	SPECULAR = 0.3;
}
