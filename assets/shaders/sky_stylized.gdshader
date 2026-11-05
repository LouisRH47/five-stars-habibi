// Session 67: our own cartoon sky (PRD "Polish pass", Light and colour; polish plan L2).
// Written for Five Stars Habibi (CC0). The ideas are the usual ones: a colour gradient by
// height, a sun disc with a soft glow, and flat-bottomed clouds made from noise on a flat
// "cloud layer" above the map.
// - The colours come from GameConfig.LIGHT_KEYS: scripts/sky_look.gd sets them (like it
//   did for the old ProceduralSkyMaterial), so the gradient matches the old sky exactly.
// - Clouds are peach in the morning, white at noon and gold/pink at sunset (cloud_light /
//   cloud_shade, also set by sky_look.gd). They drift with the game clock (cloud_shift).
// - The lighting pass (the small picture Godot makes of the sky to light the world,
//   AT_CUBEMAP_PASS) skips the clouds, so they only cost the sky pixels you can see.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.3, 0.63, 0.85);
uniform vec3 horizon_color : source_color = vec3(0.84, 0.92, 0.95);
uniform vec3 ground_horizon : source_color = vec3(0.91, 0.83, 0.65);
uniform vec3 ground_bottom : source_color = vec3(0.79, 0.66, 0.43);
uniform float sky_curve = 0.15;        // like ProceduralSkyMaterial: small = horizon colour hugs the horizon
uniform float ground_curve = 0.02;
uniform float energy = 1.0;

uniform float sun_size = 2.5;          // degrees across... (half-size of the disc)
uniform float halo_size = 12.0;        // degrees: the soft glow round the sun
uniform float halo_strength = 0.45;
uniform float disc_energy = 6.0;       // the disc is very bright, so the glow effect catches it

uniform bool clouds_on = true;
uniform vec3 cloud_light : source_color = vec3(1.0);
uniform vec3 cloud_shade : source_color = vec3(0.8, 0.85, 0.93);
uniform vec2 cloud_shift = vec2(0.0);
uniform float cloud_cover = 0.56;      // higher = fewer clouds
uniform float cloud_soft = 0.035;      // how soft the cloud edges are
uniform float cloud_scale = 1.1;       // bigger = smaller clouds
uniform float cloud_opacity = 0.95;
uniform float cloud_low_fade = 0.105;  // no clouds below this height (sin of 6 degrees)

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Big soft lumps plus smaller puffs on their edges.
float cloud_density(vec2 p) {
	float n = value_noise(p) * 0.6 + value_noise(p * 2.3 + vec2(7.1, 3.4)) * 0.28
			+ value_noise(p * 5.3 + vec2(1.7, 9.2)) * 0.12;
	// Clouds come in groups with clear sky between them.
	return n - (1.0 - value_noise(p * 0.31 + vec2(4.0, 1.0))) * 0.1;
}

void sky() {
	vec3 dir = EYEDIR;
	float v_angle = acos(clamp(dir.y, -1.0, 1.0));
	float c = 1.0 - v_angle / (PI * 0.5);
	vec3 sky_col = mix(horizon_color, top_color, clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0));
	float g = (v_angle - PI * 0.5) / (PI * 0.5);
	vec3 ground_col = mix(ground_horizon, ground_bottom, clamp(1.0 - pow(1.0 - g, 1.0 / ground_curve), 0.0, 1.0));
	vec3 col = mix(ground_col, sky_col, step(0.0, dir.y));

	// The sun: a soft glow, and (not in the lighting pass) a bright round disc.
	float to_sun = 0.0;
	vec3 sun_col = vec3(1.0);
	if (LIGHT0_ENABLED) {
		sun_col = LIGHT0_COLOR * LIGHT0_ENERGY;
		float angle = acos(clamp(dot(dir, LIGHT0_DIRECTION), -1.0, 1.0));
		to_sun = exp(-angle / radians(halo_size));
		col += sun_col * halo_strength * to_sun * to_sun;
		if (!AT_CUBEMAP_PASS) {
			float r = radians(sun_size);
			float disc = 1.0 - smoothstep(r * 0.8, r * 1.05, angle);
			col = mix(col, mix(sun_col, vec3(1.0), 0.5) * disc_energy, disc);
		}
	}

	if (clouds_on && !AT_CUBEMAP_PASS && dir.y > cloud_low_fade) {
		// A flat cloud layer above the map: further clouds look smaller and squashed.
		vec2 p = dir.xz / (dir.y + 0.15) * cloud_scale + cloud_shift;
		float n = cloud_density(p);
		float amount = smoothstep(cloud_cover, cloud_cover + cloud_soft, n);
		if (amount > 0.0) {
			// Flat, shaded bottoms: a little further out (lower on screen) the cloud ends.
			vec2 outward = normalize(dir.xz + vec2(0.0001)) * 0.16;
			float below = cloud_density(p + outward);
			float under = 1.0 - smoothstep(cloud_cover - 0.02, cloud_cover + 0.12, below);
			vec3 cloud = mix(cloud_light, cloud_shade, under * 0.85);
			// Bright edges next to the sun.
			cloud += sun_col * to_sun * 0.35;
			// Far clouds melt into the haze at the horizon.
			cloud = mix(cloud, horizon_color, (1.0 - smoothstep(cloud_low_fade, 0.45, dir.y)) * 0.45);
			float fade = smoothstep(cloud_low_fade, cloud_low_fade + 0.12, dir.y);
			col = mix(col, cloud, amount * fade * cloud_opacity);
		}
	}

	col *= energy;
	if (!AT_CUBEMAP_PASS) {
		// A tiny bit of noise stops stripes (banding) in the smooth gradient, on every renderer.
		col += (hash(SCREEN_UV * 1013.0) - 0.5) / 255.0;
	}
	COLOR = col;
}
