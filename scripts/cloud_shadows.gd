extends Node3D
## Session 67: big soft cloud shadows sliding slowly over the community (polish plan L7).
## A try, off by default (GameConfig.CLOUD_SHADOWS): Louis keeps it if it looks good on his Mac.
## One huge Decal pointing down, with a soft noise picture made here (repeated 2 x 2, so the
## decal can jump back by one repeat without you seeing it). It drifts the same way as the
## sky's clouds. Medium and High only. Added by scripts/polish/look_extras.gd.

const SPEED := 45.0          # metres per game hour (about 1.5 m/s)
const HEIGHT := 140.0        # metres: the decal reaches from below the ground to above the roofs

var decal: Decal
var _period := 0.0


func _ready() -> void:
	_period = GameConfig.CLOUD_SHADOW_SIZE * 0.5
	decal = Decal.new()
	decal.name = "Decal"
	decal.size = Vector3(GameConfig.CLOUD_SHADOW_SIZE, HEIGHT, GameConfig.CLOUD_SHADOW_SIZE)
	decal.texture_albedo = _make_texture()
	decal.modulate = Color(0.1, 0.12, 0.2, 1.0)
	decal.albedo_mix = 1.0
	decal.normal_fade = 0.4      # only on surfaces facing up, not stretched down walls
	decal.upper_fade = 0.1
	decal.lower_fade = 0.1
	decal.cull_mask = 1
	add_child(decal)
	add_to_group("graphics")
	apply_graphics()


func apply_graphics() -> void:
	visible = GameConfig.CLOUD_SHADOWS and Settings.graphics >= 1


func _process(_delta: float) -> void:
	if not visible:
		return
	# Drift against CLOUD_WIND (that's the way the sky clouds move), and jump back by one repeat.
	var drift := -GameConfig.CLOUD_WIND.normalized() * GameState.clock_hours() * SPEED
	var x := fposmod(drift.x + _period * 0.5, _period) - _period * 0.5
	var z := fposmod(drift.y + _period * 0.5, _period) - _period * 0.5
	decal.position = Vector3(x, HEIGHT * 0.35, z)


## A soft, see-through cloud pattern, 2 x 2 copies of one picture that repeats seamlessly.
func _make_texture() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	noise.seed = 67
	var one := noise.get_seamless_image(256, 256)
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var n := one.get_pixel(x, y).r
			var a := smoothstep(0.52, 0.66, n) * GameConfig.CLOUD_SHADOW_ALPHA
			var c := Color(1, 1, 1, a)
			image.set_pixel(x, y, c)
			image.set_pixel(x + 256, y, c)
			image.set_pixel(x, y + 256, c)
			image.set_pixel(x + 256, y + 256, c)
	return ImageTexture.create_from_image(image)
