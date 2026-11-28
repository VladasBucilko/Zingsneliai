extends Control
## "Miško takas" — the map for Spalvos (Burbulai colour mode). A path winds
## through the forest meadow from the start to Olis's home: 19 numbered stops
## (the levels). Finished stops have a tick, the next one glows, later ones
## are faded. Tap any open stop to play it. Little Olis stands by the stop to
## play. After stop 19 Olis's home opens: unlimited play there.
## Speaks: Sound.say("miško takas")

const BG := "res://assets/backgrounds/forest_map.png"
const HOME_TEX := "res://assets/characters/olis_home.png"
const STOPS := ColorBubbleLevels.LAST_PATH_LEVEL
const STOP_R := 38.0
## The path's shape at 1920×1080: start at the bottom left, ending under the tree.
const WAYPOINTS := [Vector2(150, 960), Vector2(420, 935), Vector2(720, 905), Vector2(1010, 860),
	Vector2(1200, 760), Vector2(1080, 650), Vector2(800, 625), Vector2(500, 600), Vector2(330, 520),
	Vector2(420, 420), Vector2(700, 395), Vector2(980, 420), Vector2(1220, 450), Vector2(1440, 420)]
const HOME_POS := Vector2(1590, 300)     # centre of the tree
const HOME_SIZE := Vector2(300, 340)

var _curve := PackedVector2Array()
var _stops: Array[Vector2] = []
var _reached := 1
var _home_open := false
var _glow := 0.0
var _home_tex: Texture2D
var _olis: Owl


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)
	_home_tex = load(HOME_TEX)
	GameUI.add_home(self)
	var title := GameUI.add_title(self, "Miško takas")
	title.add_theme_color_override("font_outline_color", Color(Palette.CARD, 0.9))
	title.add_theme_constant_override("outline_size", 14)
	_reached = BubbleColors.reached()
	_home_open = _reached >= ColorBubbleLevels.HOME_LEVEL
	_build_path()
	_olis = Owl.new().setup(150, "wave")
	var at := _owl_spot()
	_olis.position = at - Vector2(_olis.size.x / 2.0, _olis.size.y)
	add_child(_olis)
	Sound.say("miško takas")


func _process(delta: float) -> void:
	_glow += delta
	queue_redraw()


## A smooth Catmull-Rom line through the waypoints, then stops evenly along it.
func _build_path() -> void:
	var wp: Array = WAYPOINTS
	_curve.clear()
	for i in wp.size() - 1:
		var p0: Vector2 = wp[maxi(i - 1, 0)]
		var p1: Vector2 = wp[i]
		var p2: Vector2 = wp[i + 1]
		var p3: Vector2 = wp[mini(i + 2, wp.size() - 1)]
		for k in 16:
			var t := k / 16.0
			var t2 := t * t
			var t3 := t2 * t
			_curve.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	_curve.append(wp[-1])
	var lengths := [0.0]
	for i in range(1, _curve.size()):
		lengths.append(lengths[-1] + _curve[i].distance_to(_curve[i - 1]))
	var total: float = lengths[-1]
	_stops.clear()
	# Stop 1 a little after the start; the last stop a little before the tree.
	for s in STOPS:
		var d := lerpf(total * 0.06, total * 0.97, float(s) / float(STOPS - 1))
		var j := 1
		while j < lengths.size() - 1 and lengths[j] < d:
			j += 1
		var seg: float = lengths[j] - lengths[j - 1]
		var t: float = 0.0 if seg <= 0.0 else (d - float(lengths[j - 1])) / seg
		_stops.append(_curve[j - 1].lerp(_curve[j], t))


## Where little Olis stands: next to the stop to play (or by his home).
func _owl_spot() -> Vector2:
	if _home_open:
		return HOME_POS + Vector2(-HOME_SIZE.x * 0.55, HOME_SIZE.y * 0.5)
	var s := _stops[_reached - 1]
	return s + Vector2(-70, -STOP_R + 10)


func _home_rect() -> Rect2:
	return Rect2(HOME_POS - HOME_SIZE / 2.0, HOME_SIZE)


func _draw() -> void:
	# The path: a soft sandy track with a slightly darker edge.
	draw_polyline(_curve, Color("#C9B48A", 0.55), 64.0, true)
	draw_polyline(_curve, Color("#F3E6C4", 0.95), 48.0, true)
	for i in range(0, _curve.size() - 1, 4):     # little pebbles along the middle
		draw_circle(_curve[i], 3.0, Color("#D9C59B", 0.8))
	# Start flag
	var st := _curve[0]
	draw_line(st, st + Vector2(0, -90), Palette.TEXT, 5.0, true)
	draw_colored_polygon(PackedVector2Array([st + Vector2(0, -90), st + Vector2(56, -74),
		st + Vector2(0, -58)]), Color("#EC97AC"))
	# Olis's home
	var hr := _home_rect()
	draw_texture_rect(_home_tex, hr, false, Color(1, 1, 1, 1.0 if _home_open else 0.55))
	if _home_open:
		var a := 0.25 + 0.15 * sin(_glow * 3.0)
		draw_arc(HOME_POS + Vector2(0, HOME_SIZE.y * 0.45), 70, 0, TAU, 48, Color(Palette.BUTTER, a + 0.3), 8.0, true)
	else:
		_padlock(HOME_POS + Vector2(0, HOME_SIZE.y * 0.25))
	# Stops
	var font := get_theme_default_font()
	for i in _stops.size():
		var n := i + 1
		var c := _stops[i]
		var done := n < _reached
		var next := n == _reached and not _home_open
		var open := n <= _reached
		draw_circle(c + Vector2(0, 5), STOP_R, Color(Palette.SHADOW, 0.5 if open else 0.25))
		if next:
			var pulse := 1.0 + 0.12 * sin(_glow * 3.0)
			draw_circle(c, STOP_R * 1.35 * pulse, Color(Palette.BUTTER, 0.45))
		var fill := Palette.CARD
		if done:
			fill = Color("#B8DCB0")
		elif next:
			fill = Palette.BUTTER
		elif not open:
			fill = Color(Palette.CARD, 0.6)
		draw_circle(c, STOP_R, fill)
		draw_arc(c, STOP_R, 0, TAU, 48, Color(Palette.TEXT, 0.25 if open else 0.12), 3.0, true)
		var txt := str(n)
		var fs := 34
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-tw / 2.0, 12), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(Palette.TEXT, 1.0 if open else 0.4))
		if done:
			var k := c + Vector2(STOP_R * 0.75, -STOP_R * 0.75)
			draw_circle(k, 16, Color("#86C691"))
			draw_polyline(PackedVector2Array([k + Vector2(-8, 0), k + Vector2(-2, 6), k + Vector2(8, -6)]),
				Color.WHITE, 4.0, true)


func _padlock(c: Vector2) -> void:
	draw_circle(c, 34, Color(Palette.CARD, 0.85))
	var col := Palette.TEXT_MUTED
	draw_arc(c + Vector2(0, -6), 11, PI, TAU, 16, col, 4.5, true)
	draw_rect(Rect2(c + Vector2(-16, -6), Vector2(32, 24)), col)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var p: Vector2 = event.position
	for i in _stops.size():
		if p.distance_to(_stops[i]) <= STOP_R * 1.4:
			if i + 1 <= _reached:
				accept_event()
				BubbleColors.open_level(get_tree(), i + 1)
			return
	if _home_rect().has_point(p) and _home_open:
		accept_event()
		BubbleColors.open_level(get_tree(), ColorBubbleLevels.HOME_LEVEL)
