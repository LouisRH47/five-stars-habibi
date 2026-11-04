class_name UiPalette
extends RefCounted
## Session 66: the game's UI colours, text sizes and timings in one place (PRD "Screens").

const TEAL := Color("0F4C5C")
const ORANGE := Color("F28C28")
const SUN := Color("F2B230")
const SAND := Color("F3E3C3")
const INK := Color("1B1D22")
const PANEL := Color(0.0588, 0.1255, 0.149, 0.86)   # #0F2026 at 86%
const SOFT_TEXT := Color("C9E4EA")
const CYAN := Color("7FD3E0")
# Meter bands: normal and colour help (Okabe-Ito).
const BAND := [Color("4CC98A"), Color("F59A2E"), Color("E5483A")]
const BAND_ASSIST := [Color("0072B2"), Color("E69F00"), Color("D55E00")]
# Text sizes at the 1920x1080 base (XAG 101: PC body text at least 18 px at 1080p).
const FONT_SMALL := 16   # only for tags and captions
const FONT_BODY := 18
const FONT_LABEL := 20
const FONT_TITLE := 28
const FONT_BIG := 48
# Motion (Material 3 durations): button feedback, panels, big reveals.
const FAST := 0.12
const PANEL_TIME := 0.3
const REVEAL := 0.6

## 0 = good (green), 1 = okay (orange), 2 = bad (red), following the Colour help setting.
static func band_colour(band: int) -> Color:
	var colours: Array = BAND_ASSIST if Settings.colour_assist else BAND
	return colours[clampi(band, 0, 2)]
