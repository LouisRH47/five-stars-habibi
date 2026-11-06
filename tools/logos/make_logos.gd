extends SceneTree
## Draws the logos of the three delivery companies (Session 88).
##
## Step 1, icons (works headless, no window):
##   Godot --path . --headless -s tools/logos/make_logos.gd
##   Builds each icon as an SVG drawing in code, saves assets/logos/<id>.svg and renders
##   <id>_1024.png and <id>_256.png (square, see-through background).
##
## Step 2, word marks (needs a window, because headless Godot can't draw text):
##   Godot --path . -s tools/logos/make_logos.gd -- --marks
##   Puts the icon next to the English name (Baloo 2) and the Arabic name (Noto Sans
##   Arabic) and saves <id>_mark_1024.png (1024 x 256) and <id>_mark_256.png (256 x 64).
##   The words are drawn by Godot, not the SVG, because Godot's SVG reader skips <text>
##   and Godot's own text drawing joins Arabic letters properly, right to left.
##
## Colours and names come from data/companies.gd. Afterwards run
##   Godot --path . --headless --import
## so the game picks up the new pictures.

const Companies = preload("res://data/companies.gd")
const OUT_DIR := "res://assets/logos/"
const MARK_SIZE := Vector2i(1024, 256)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if "--marks" in OS.get_cmdline_user_args():
		_make_marks()
	else:
		_make_icons()
		quit()


# ---------- Icons (SVG) ----------

func _make_icons() -> void:
	for company: Dictionary in Companies.COMPANIES:
		var id: String = company["id"]
		var svg := _icon_svg(id, company["colour"])
		var file := FileAccess.open(OUT_DIR + id + ".svg", FileAccess.WRITE)
		file.store_string(svg)
		file.close()
		for size: int in [1024, 256]:
			var img := Image.new()
			var err := img.load_svg_from_string(svg, size / 256.0)
			if err != OK:
				push_error("Could not draw %s (error %d)" % [id, err])
				continue
			img.save_png(OUT_DIR + "%s_%d.png" % [id, size])
		print("Drew icon: ", id)


func _icon_svg(id: String, colour: Color) -> String:
	var body := ""
	match id:
		"snackaroo":
			body = _snackaroo(colour)
		"zoomaroo":
			body = _zoomaroo(colour)
		"deliverooz":
			body = _deliverooz(colour)
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" '
		+ 'viewBox="0 0 256 256">\n' + body + '</svg>\n')


func _hex(c: Color) -> String:
	return "#" + c.to_html(false)


## Orange takeaway bag (tapered, folded top with a handle slot) with a white lightning bolt.
func _snackaroo(c: Color) -> String:
	var main := _hex(c)
	var fold := _hex(c.darkened(0.14))
	var slot := _hex(c.darkened(0.42))
	var bag := 'd="M70 62 H186 Q204 62 206 80 L220 204 Q222 230 196 230 H60 Q34 230 36 204 L50 80 Q52 62 70 62 Z"'
	var bolt := 'points="138,122 90,182 122,182 106,228 168,160 134,160 158,122"'
	return (
		# white sticker edge, so it reads on dark and light backgrounds
		'<path %s fill="#ffffff" stroke="#ffffff" stroke-width="16" stroke-linejoin="round"/>\n' % bag
		+ '<path %s fill="%s"/>\n' % [bag, main]
		# folded top of the bag, with a handle slot
		+ '<path d="M70 62 H186 Q204 62 206 80 L209.7 112 H46.3 L50 80 Q52 62 70 62 Z" fill="%s"/>\n' % fold
		+ '<rect x="100" y="78" width="56" height="18" rx="9" fill="%s"/>\n' % slot
		# shine
		+ '<ellipse cx="70" cy="160" rx="10" ry="26" fill="#ffffff" opacity="0.28" transform="rotate(5 70 160)"/>\n'
		+ '<polygon %s fill="#ffffff" stroke="#ffffff" stroke-width="8" stroke-linejoin="round"/>\n' % bolt
	)


## Green speech bubble with a winking face.
func _zoomaroo(c: Color) -> String:
	var main := _hex(c)
	var bubble := 'x="22" y="30" width="212" height="164" rx="70"'
	var tail := 'd="M62 170 L40 234 L120 186 Z"'
	return (
		'<rect %s fill="#ffffff" stroke="#ffffff" stroke-width="16"/>\n' % bubble
		+ '<path %s fill="#ffffff" stroke="#ffffff" stroke-width="16" stroke-linejoin="round"/>\n' % tail
		+ '<rect %s fill="%s"/>\n' % [bubble, main]
		+ '<path %s fill="%s" stroke="%s" stroke-width="4" stroke-linejoin="round"/>\n' % [tail, main, main]
		+ '<ellipse cx="62" cy="76" rx="20" ry="11" fill="#ffffff" opacity="0.25" transform="rotate(-30 62 76)"/>\n'
		# open eye (a dot) and winking eye (a curved line)
		+ '<circle cx="94" cy="98" r="16" fill="#ffffff"/>\n'
		+ '<path d="M142 102 Q160 80 178 102" fill="none" stroke="#ffffff" stroke-width="13" stroke-linecap="round"/>\n'
		# smile
		+ '<path d="M82 134 Q128 182 174 134" fill="none" stroke="#ffffff" stroke-width="14" stroke-linecap="round"/>\n'
	)


## Teal parcel box with a heart, three speed dashes behind it and a bounce shadow.
## (Deliberately no animal: a real delivery brand uses a teal kangaroo.)
func _deliverooz(c: Color) -> String:
	var main := _hex(c)
	var lid := _hex(c.darkened(0.2))
	var tape := _hex(c.lightened(0.45))
	var box := 'x="92" y="78" width="136" height="124" rx="22"'
	var lid_rect := 'x="84" y="64" width="152" height="42" rx="16"'
	var dashes := ""
	for d: Array in [[104, 40, 70], [140, 14, 70], [176, 40, 70]]:
		dashes += ('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="14" stroke-linecap="round"/>\n'
			% [d[1], d[0], d[2], d[0], main])
	var heart := 'd="M0 20 C-36 -4 -22 -34 0 -15 C22 -34 36 -4 0 20 Z" transform="translate(160 150)"'
	return (
		'<ellipse cx="160" cy="236" rx="58" ry="9" fill="%s" opacity="0.35"/>\n' % main
		+ '<g stroke="#ffffff" stroke-width="28" stroke-linecap="round">'
		+ dashes.replace('stroke="%s" stroke-width="14" ' % main, '') + '</g>\n'
		+ dashes
		+ '<g transform="rotate(-8 160 140)">\n'
		+ '<rect %s fill="#ffffff" stroke="#ffffff" stroke-width="16"/>\n' % box
		+ '<rect %s fill="#ffffff" stroke="#ffffff" stroke-width="16"/>\n' % lid_rect
		+ '<rect %s fill="%s"/>\n' % [box, main]
		+ '<rect %s fill="%s"/>\n' % [lid_rect, lid]
		+ '<rect x="148" y="64" width="24" height="42" fill="%s"/>\n' % tape
		+ '<path %s fill="#ffffff"/>\n' % heart
		+ '</g>\n'
	)


# ---------- Word marks (Godot labels in a SubViewport) ----------

func _make_marks() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Word marks need a window. Run without --headless.")
		quit(1)
		return
	var baloo := FontVariation.new()
	baloo.base_font = load("res://assets/fonts/Baloo2.ttf")
	baloo.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
	var noto := FontVariation.new()
	noto.base_font = load("res://assets/fonts/NotoSansArabic.ttf")
	noto.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}

	for company: Dictionary in Companies.COMPANIES:
		var id: String = company["id"]
		var vp := SubViewport.new()
		vp.size = MARK_SIZE
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vp)
		_build_mark(vp, company, baloo, noto)
		for i in 3:
			await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		_unpremultiply(img)
		img.save_png(OUT_DIR + id + "_mark_1024.png")
		var small := img.duplicate() as Image
		small.resize(MARK_SIZE.x / 4, MARK_SIZE.y / 4, Image.INTERPOLATE_LANCZOS)
		small.save_png(OUT_DIR + id + "_mark_256.png")
		vp.queue_free()
		print("Drew word mark: ", id)
	quit()


## The see-through viewport stores colours already multiplied by their alpha, which
## gives soft edges a grey rim. Divide it back out so edges keep their real colour.
func _unpremultiply(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a > 0.0 and p.a < 1.0:
				img.set_pixel(x, y, Color(minf(p.r / p.a, 1.0), minf(p.g / p.a, 1.0), minf(p.b / p.a, 1.0), p.a))


func _build_mark(vp: SubViewport, company: Dictionary, baloo: Font, noto: Font) -> void:
	var icon_img := Image.load_from_file(OUT_DIR + company["id"] + "_1024.png")
	var icon := TextureRect.new()
	icon.texture = ImageTexture.create_from_image(icon_img)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(12, 12)
	icon.size = Vector2(232, 232)
	vp.add_child(icon)

	var left := 262.0
	var room := MARK_SIZE.x - left - 16.0
	var english := _label(company["name"], baloo, 132, company["dark"], room)
	english.position = Vector2(left, -16)
	vp.add_child(english)
	var arabic := _label(company["arabic"], noto, 80, company["colour"], room)
	arabic.position = Vector2(left + 6, 112)
	vp.add_child(arabic)


## A label with a white outline; shrinks the font until the text fits the room.
func _label(text: String, font: Font, size: int, colour: Color, room: float) -> Label:
	while size > 20 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > room:
		size -= 4
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", maxi(8, size / 7))
	return label
