extends SceneTree
## Session 82: makes the ground photo textures from the Poly Haven photos (CC0) saved in
## tools/texture_sources/, and puts them in assets/textures/. Run it from the project folder:
##   Godot --headless --path . -s tools/make_photo_textures.gd
## Then run Godot --headless --path . --import so Godot picks up the new pictures.
##   leafy_grass_diff_1k.jpg     the leafy_grass photo, copied as it is (mixed into the lawns)
##   paving_sandy_1k.jpg         brick_pavement_02, recoloured warm sandy grey (pavers, footpaths)
##   blue_track_photo_1k.jpg     running_track, turned so its lane lines run along the track,
##                               a bit more blue, twice as long as wide (4 m across, 8 m along)
##   red_walking_track_1k.jpg    one lane of running_track (no line), recoloured red-brown
## Every step is plain maths, so the files come out the same every time.

const SOURCES := "res://tools/texture_sources/"
const OUT := "res://assets/textures/"

const SANDY_GREY := Color(0.77, 0.69, 0.56)   # the pavers' average colour after recolouring
const PAVER_CONTRAST := 1.15                  # >1: joints a bit darker, stones a bit lighter
const TRACK_BLUE_BOOST := 2.1                 # how much more colourful the blue track gets
const TRACK_RED := Color(0.62, 0.31, 0.24)    # the walking tracks' average colour
const TRACK_RED_CONTRAST := 2.2
## The first lane of running_track (rows of pixels between the white lines).
const LANE_FIRST_ROW := 18
const LANE_LAST_ROW := 493
const SECOND_LANE_FIRST_ROW := 527
const SECOND_LANE_LAST_ROW := 1004


func _initialize() -> void:
	_copy("leafy_grass_diff_1k.jpg")
	_paving()
	_blue_track()
	_red_track()
	print("Made the Session 82 textures in assets/textures/")
	quit()


func _load(file: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(SOURCES + file))


func _save(image: Image, file: String) -> void:
	image.save_jpg(ProjectSettings.globalize_path(OUT + file), 0.92)
	print("  ", file, " ", image.get_size())


func _copy(file: String) -> void:
	DirAccess.copy_absolute(ProjectSettings.globalize_path(SOURCES + file), ProjectSettings.globalize_path(OUT + file))
	print("  ", file, " (copied)")


## The average brightness of a picture (0 to 1).
func _mean_light(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			total += image.get_pixel(x, y).get_luminance()
			count += 1
	return total / count


## Every pixel becomes `colour`, lighter or darker the way the photo was (keeps the detail).
func _recolour(image: Image, colour: Color, contrast: float) -> void:
	var mean := _mean_light(image)
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x, y).get_luminance() / mean
			var shade := 1.0 + (light - 1.0) * contrast
			image.set_pixel(x, y, Color(colour.r * shade, colour.g * shade, colour.b * shade).clamp())


func _paving() -> void:
	var image := _load("brick_pavement_02_diff_1k.jpg")
	_recolour(image, SANDY_GREY, PAVER_CONTRAST)
	_save(image, "paving_sandy_1k.jpg")


func _blue_track() -> void:
	var photo := _load("running_track_diff_1k.jpg")
	var size := photo.get_width()
	# The photo's second lane is darker than the first: make it as light, so both lanes match.
	var first := _mean_light(photo.get_region(Rect2i(0, LANE_FIRST_ROW, size, LANE_LAST_ROW - LANE_FIRST_ROW)))
	var second := _mean_light(photo.get_region(Rect2i(0, SECOND_LANE_FIRST_ROW, size, SECOND_LANE_LAST_ROW - SECOND_LANE_FIRST_ROW)))
	for y in range(SECOND_LANE_FIRST_ROW - 2, SECOND_LANE_LAST_ROW + 2):
		for x in size:
			var c := photo.get_pixel(x, y) * (first / second)
			photo.set_pixel(x, y, Color(c.r, c.g, c.b).clamp())
	# Turn it a quarter turn (lines then run up the picture), make it more blue, and put two
	# copies one above the other: across the 4 m track it's one picture wide, along it 8 m.
	var image := Image.create(size, size * 2, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var colour := photo.get_pixel(y, x)
			colour.s = minf(1.0, colour.s * TRACK_BLUE_BOOST)
			image.set_pixel(x, y, colour)
			image.set_pixel(x, y + size, colour)
	_save(image, "blue_track_photo_1k.jpg")


func _red_track() -> void:
	var photo := _load("running_track_diff_1k.jpg")
	var lane := photo.get_region(Rect2i(0, LANE_FIRST_ROW, photo.get_width(), LANE_LAST_ROW - LANE_FIRST_ROW))
	# The lane and its mirror image under it, so the top and bottom edges meet with no seam.
	var flipped := lane.duplicate() as Image
	flipped.flip_y()
	var image := Image.create(lane.get_width(), lane.get_height() * 2, false, Image.FORMAT_RGB8)
	image.blit_rect(lane, Rect2i(Vector2i.ZERO, lane.get_size()), Vector2i.ZERO)
	image.blit_rect(flipped, Rect2i(Vector2i.ZERO, lane.get_size()), Vector2i(0, lane.get_height()))
	_recolour(image, TRACK_RED, TRACK_RED_CONTRAST)
	_save(image, "red_walking_track_1k.jpg")
