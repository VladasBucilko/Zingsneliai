extends Control
## "Miško takas" — the map for Spalvos (Burbulai colour mode). A path winds
## through the forest meadow from the start to Olis's home: 19 numbered stops
## (the levels). Finished stops have a tick, the next one glows, later ones
## are faded. Little Olis stands by the stop to play. Tapping an open stop
## opens a small card: "Lygis N" with a big Play button and an X to close.
## After finishing a level the map opens with Olis walking along the path to
## the next stop, then the card for it pops up. After stop 19 Olis's home
## opens: unlimited play there. Speaks Sound.say("olio namai") for the home.
## Speaks: Sound.say("miško takas")

const BG := "res://assets/backgrounds/forest_map.png"
const HOME_TEX := "res://assets/characters/olis_home.png"
const STOPS := ColorBubbleLevels.LAST_PATH_LEVEL
const STOP_R := 38.0
## The path's shape at 1920×1080, seen in perspective: it starts close to us at
## the bottom left and winds back across the meadow to the tree. Rows further
## away are closer together and the path, stops and Olis get smaller (persp()).
const WAYPOINTS := [Vector2(-70, 1012), Vector2(140, 1002), Vector2(360, 992), Vector2(620, 968), Vector2(880, 958),
	Vector2(1110, 922), Vector2(1270, 868), Vector2(1305, 800), Vector2(1200, 752),
	Vector2(980, 736), Vector2(760, 716), Vector2(565, 702), Vector2(425, 668), Vector2(372, 624),
	Vector2(445, 584), Vector2(620, 566), Vector2(800, 546), Vector2(990, 532), Vector2(1160, 512),
	Vector2(1320, 502), Vector2(1478, 494)]
const NEAR_Y := 1000.0
const FAR_Y := 490.0
const FAR_SCALE := 0.6
const HOME_POS := Vector2(1625, 280)     # centre of the tree
const HOME_SIZE := Vector2(380, 431)

var _curve := PackedVector2Array()
var _stops: Array[Vector2] = []
var _reached := 1
var _home_open := false
var _glow := 0.0
var _home_tex: Texture2D
var _olis: Owl
var _olis_holder: Control      # scaled with distance (Olis animates his own scale)
var _card: Control


## How big things are at screen height y: 1 close to us, smaller further away.
static func persp(y: float) -> float:
	return lerpf(FAR_SCALE, 1.0, clampf((y - FAR_Y) / (NEAR_Y - FAR_Y), 0.0, 1.0))


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
	var layer := _PathLayer.new()
	layer.curve = _curve
	layer.persp = persp
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.show_behind_parent = true      # drawn once, under the stops and the tree
	add_child(layer)
	move_child(layer, 1)                 # right after the background
	_olis = Owl.new().setup(170, "wave")
	_olis_holder = Control.new()
	_olis_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_olis_holder.size = _olis.size
	_olis_holder.pivot_offset = Vector2(_olis.size.x / 2.0, _olis.size.y)
	_olis_holder.add_child(_olis)
	add_child(_olis_holder)
	var from := BubbleColors.walk_from
	BubbleColors.walk_from = 0
	if from > 0 and from < ColorBubbleLevels.HOME_LEVEL:
		_walk(from)
	else:
		_place_olis(_owl_spot())
		Sound.say("miško takas")


func _place_olis(feet: Vector2) -> void:
	_olis_holder.position = feet - Vector2(_olis.size.x / 2.0, _olis.size.y)
	_olis_holder.scale = Vector2.ONE * persp(feet.y)


## Olis hops along the path from the finished stop to the next one, then the
## Play card for it opens.
func _walk(from: int) -> void:
	var start := _spot_for(from)
	var end := _owl_spot()
	_place_olis(start)
	_olis.set_pose("cheer")
	await get_tree().create_timer(0.5).timeout
	var a := _stops[from - 1]
	var b: Vector2 = _stops[from] if from < STOPS else HOME_POS + Vector2(0, HOME_SIZE.y * 0.45)
	var secs := 0.3 if Settings.reduce_motion else 1.4
	var t := create_tween()
	t.tween_method(func(k: float):
		var p := a.lerp(b, k)
		var feet := p + (end - b) * k + (start - a) * (1.0 - k)
		if not Settings.reduce_motion:
			feet.y -= absf(sin(k * PI * 4.0)) * 22.0    # little hops
		_place_olis(feet), 0.0, 1.0, secs).set_trans(Tween.TRANS_SINE)
	await t.finished
	_olis.set_pose("happy")
	Sound.sfx("chime")
	await get_tree().create_timer(0.3).timeout
	_olis.set_pose("idle")
	_open_card(_reached if not _home_open else ColorBubbleLevels.HOME_LEVEL)


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
	# Length "on the ground": far-away pieces count more, so the stops get
	# closer together on screen the further back they are.
	var lengths := [0.0]
	for i in range(1, _curve.size()):
		var mid := (_curve[i].y + _curve[i - 1].y) / 2.0
		lengths.append(lengths[-1] + _curve[i].distance_to(_curve[i - 1]) / persp(mid))
	var total: float = lengths[-1]
	_stops.clear()
	# Stop 1 a little after the start; the last stop a little before the tree.
	for s in STOPS:
		var d := lerpf(total * 0.05, total * 0.95, float(s) / float(STOPS - 1))
		var j := 1
		while j < lengths.size() - 1 and lengths[j] < d:
			j += 1
		var seg: float = lengths[j] - lengths[j - 1]
		var t: float = 0.0 if seg <= 0.0 else (d - float(lengths[j - 1])) / seg
		_stops.append(_curve[j - 1].lerp(_curve[j], t))


## Where little Olis stands: next to the stop to play (or by his home).
func _owl_spot() -> Vector2:
	return _spot_for(ColorBubbleLevels.HOME_LEVEL if _home_open else _reached)


func _spot_for(n: int) -> Vector2:
	if n >= ColorBubbleLevels.HOME_LEVEL:
		return HOME_POS + Vector2(-HOME_SIZE.x * 0.55, HOME_SIZE.y * 0.5)
	var s := _stops[n - 1]
	return s + Vector2(-72, -STOP_R + 12) * persp(s.y)


## A small card in the middle: "Lygis N" (or "Olio namai"), Play and an X.
func _open_card(n: int) -> void:
	if _card:
		_card.queue_free()
	var home := n >= ColorBubbleLevels.HOME_LEVEL
	var cover := Control.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Palette.CANVAS, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(dim)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CARD
	sb.set_corner_radius_all(56)
	sb.shadow_color = Palette.SHADOW
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 10)
	sb.content_margin_left = 110
	sb.content_margin_right = 110
	sb.content_margin_top = 70
	sb.content_margin_bottom = 70
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	cover.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 40)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var title := Label.new()
	title.text = "Olio namai" if home else "Lygis %d" % n
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Palette.TEXT)
	col.add_child(title)
	var dots := _ColorDots.new()
	dots.count = ColorBubbleLevels.params(mini(n, ColorBubbleLevels.LAST_PATH_LEVEL)).colors
	col.add_child(dots)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 56)
	col.add_child(row)
	var play := RoundButton.new(RoundButton.Kind.PLAY)
	play.pressed.connect(func(): BubbleColors.open_level(get_tree(), n))
	row.add_child(play)
	var close := RoundButton.new(RoundButton.Kind.CLEAR)
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func():
		cover.queue_free()
		_card = null)
	row.add_child(close)
	add_child(cover)
	_card = cover
	panel.pivot_offset = panel.size / 2.0
	if not Settings.reduce_motion:
		cover.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(cover, "modulate:a", 1.0, 0.25)
	if home:
		Sound.say("olio namai")
	else:
		Sound.say("lygis")


## The level's colours as a row of little bubbles on the card.
class _ColorDots extends Control:
	var count := 2

	func _init() -> void:
		custom_minimum_size = Vector2(6 * 70, 60)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := count * 70.0
		var x0 := (size.x - w) / 2.0 + 35.0
		for i in count:
			var c := Vector2(x0 + i * 70.0, 30)
			draw_circle(c, 26, ColorBubbleLevels.COLORS[i])
			draw_circle(c + Vector2(-8, -9), 6, Color(1, 1, 1, 0.7))


func _home_rect() -> Rect2:
	return Rect2(HOME_POS - HOME_SIZE / 2.0, HOME_SIZE)


func _draw() -> void:
	# Start flag beside the path where it comes in from the edge
	# (the path itself is drawn once by _PathLayer)
	var st := Vector2(232, 968)
	draw_line(st, st + Vector2(0, -90), Palette.TEXT, 5.0, true)
	draw_colored_polygon(PackedVector2Array([st + Vector2(0, -90), st + Vector2(56, -74),
		st + Vector2(0, -58)]), Color("#EC97AC"))
	# Olis's home
	var hr := _home_rect()
	_ground_shadow(Vector2(HOME_POS.x + 6, hr.end.y - HOME_SIZE.y * 0.02), HOME_SIZE.x * 0.6)
	draw_texture_rect(_home_tex, hr, false)
	if not _home_open:
		_padlock(HOME_POS + Vector2(0, HOME_SIZE.y * 0.22))
	# Stops, smaller further away
	var font := get_theme_default_font()
	for i in _stops.size():
		var n := i + 1
		var c := _stops[i]
		var k := persp(c.y)
		var r := STOP_R * k
		var done := n < _reached
		var next := n == _reached and not _home_open
		var open := n <= _reached
		draw_circle(c + Vector2(0, 5 * k), r, Color(Palette.SHADOW, 0.5 if open else 0.25))
		if next:
			var pulse := 1.0 + 0.12 * sin(_glow * 3.0)
			draw_circle(c, r * 1.35 * pulse, Color(Palette.BUTTER, 0.45))
		var fill := Palette.CARD
		if done:
			fill = Color("#B8DCB0")
		elif next:
			fill = Palette.BUTTER
		elif not open:
			fill = Color(Palette.CARD, 0.6)
		draw_circle(c, r, fill)
		draw_arc(c, r, 0, TAU, 48, Color(Palette.TEXT, 0.25 if open else 0.12), 3.0 * k, true)
		var txt := str(n)
		var fs := int(34 * k)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-tw / 2.0, 12 * k), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(Palette.TEXT, 1.0 if open else 0.4))
		if done:
			var tick := c + Vector2(r * 0.75, -r * 0.75)
			draw_circle(tick, 16 * k, Color("#86C691"))
			draw_polyline(PackedVector2Array([tick + Vector2(-8, 0) * k, tick + Vector2(-2, 6) * k,
				tick + Vector2(8, -6) * k]), Color.WHITE, 4.0 * k, true)


## Soft contact shadow: stacked ellipses, faint and wide outside, darker in the middle.
func _ground_shadow(c: Vector2, half_w: float) -> void:
	var steps := 10
	for i in steps:
		var k := float(i) / float(steps - 1)          # 0 = outer edge, 1 = centre
		var r := Vector2(half_w * (1.0 - 0.6 * k), half_w * 0.16 * (1.0 - 0.55 * k))
		var pts := PackedVector2Array()
		for j in 40:
			var t := TAU * j / 40.0
			pts.append(c + Vector2(cos(t) * r.x, sin(t) * r.y))
		draw_colored_polygon(pts, Color(0.16, 0.2, 0.1, 0.11))


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
		if p.distance_to(_stops[i]) <= STOP_R * 1.5 * persp(_stops[i].y):
			if i + 1 <= _reached:
				accept_event()
				_open_card(i + 1)
			return
	if _home_rect().has_point(p) and _home_open:
		accept_event()
		_open_card(ColorBubbleLevels.HOME_LEVEL)


## The sandy path, drawn once: overlapping soft blobs along the line, wider
## close to us and narrower far away, with a slightly wobbly edge so it looks
## trodden rather than drawn with a ruler.
class _PathLayer extends Control:
	var curve := PackedVector2Array()
	var persp: Callable

	func _draw() -> void:
		var pts := PackedVector2Array()       # evenly spaced points every ~5 px
		var dist := PackedFloat32Array()
		var d := 0.0
		for i in curve.size() - 1:
			var a := curve[i]
			var b := curve[i + 1]
			var n := maxi(int(a.distance_to(b) / 5.0), 1)
			for j in n:
				pts.append(a.lerp(b, float(j) / n))
				dist.append(d + a.distance_to(b) * j / n)
			d += a.distance_to(b)
		var rims := PackedFloat32Array()
		for i in pts.size():
			var k: float = persp.call(pts[i].y)
			var wob := 1.0 + 0.13 * sin(dist[i] * 0.011) + 0.08 * sin(dist[i] * 0.037 + 1.7) \
				+ 0.05 * sin(dist[i] * 0.093 + 0.4)
			rims.append(36.0 * k * wob)
		for i in pts.size():                  # darker trodden edge
			draw_circle(pts[i] + Vector2(0, 3), rims[i] + 5.0, Color("#B3A077"))
		for i in pts.size():                  # the sandy top
			draw_circle(pts[i], rims[i], Color("#E2D3AA"))
		for i in pts.size():                  # lighter middle, a little off-centre
			draw_circle(pts[i] + Vector2(0, -rims[i] * 0.15), rims[i] * 0.55, Color("#EBDFBE"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in range(0, pts.size(), 9):     # a few pebbles
			var k: float = persp.call(pts[i].y)
			var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6)) * rims[i] * 0.8
			draw_circle(pts[i] + off, rng.randf_range(2.0, 4.5) * k, Color("#CDBB92"))
