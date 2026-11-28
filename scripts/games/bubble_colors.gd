class_name BubbleColors
extends Control
## "Spalvos" — Burbulai colour mode. The square at the top shows a colour:
## pop a bubble of that colour and the square changes at once to a new colour
## (it can be the same one again), picked from the bubbles on screen. Three
## hearts: a heart goes only when a bubble of the square's colour floats away.
## Tapping another colour just makes that bubble wiggle. Out of hearts → a calm
## "Beveik!" card. Finishing a level goes back to the map, where Olis walks to
## the next stop and a Play card opens. Levels 1–19 are stops on the forest
## path (BubbleMap); 20 = Olis's home, unlimited and slowly getting harder.

const MAP := "res://scenes/games/bubble_map.tscn"
const SCENE := "res://scenes/games/bubble_colors.tscn"
const GAME := "bubble_colors"         # progress key: {"level": next stop to play}
const LIVES := 3
const HOME_STEP := 8                  # pops per difficulty step at Olis's home
const SIDE_MARGIN := 40.0
const LEFT_MARGIN := 290.0            # Olis sits on the left
const TOP_ZONE := 230.0               # square + hearts live above this
const STUCK_TIME := 2.5               # colour not on screen this long → square changes anyway

## Level to open (set by the map before changing scene).
static var start_level := 1
## Set when a level was just finished: the map shows Olis walking on from it.
static var walk_from := 0

var level := 1
var _p := {}
var _home := false
var _active: Array[Bubble] = []
var _target := 0
var _lives := LIVES
var _popped := 0
var _wait := 0.0
var _missing_t := 0.0
var _done := false
var _rng := RandomNumberGenerator.new()
var _owl: Owl
var _square: ColorSquare
var _hearts: Hearts
var _dots: HBoxContainer
var _counter: Label

@onready var _field: Node2D = $Field


## Static helpers for the map and the game.
static func reached() -> int:
	return clampi(int(GameUI.progress(GAME).get("level", 1)), 1, ColorBubbleLevels.HOME_LEVEL)


static func open_level(tree: SceneTree, n: int) -> void:
	start_level = n
	tree.change_scene_to_file(SCENE)


func _ready() -> void:
	_rng.randomize()
	var back := RoundButton.new(RoundButton.Kind.HOME)
	back.position = Vector2(64, 56)
	back.pressed.connect(_go_map)
	add_child(back)
	_owl = Owl.add_to_corner(self)
	_square = ColorSquare.new()
	_square.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_square.offset_left = -ColorSquare.SIDE / 2.0
	_square.offset_right = ColorSquare.SIDE / 2.0
	_square.offset_top = 40
	_square.offset_bottom = 40 + ColorSquare.SIDE
	add_child(_square)
	_hearts = Hearts.new()
	_hearts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hearts.offset_left = -64 - Hearts.WIDTH
	_hearts.offset_right = -64
	_hearts.offset_top = 64
	_hearts.offset_bottom = 64 + Hearts.HEIGHT
	add_child(_hearts)
	_start(start_level)


func _start(n: int) -> void:
	level = n
	_home = n >= ColorBubbleLevels.HOME_LEVEL
	_p = ColorBubbleLevels.params(mini(level, ColorBubbleLevels.LAST_PATH_LEVEL) if not _home else level)
	for b in _active:
		b.queue_free()
	_active.clear()
	_lives = LIVES
	_hearts.set_lives(_lives)
	_popped = 0
	_wait = 0.3
	_missing_t = 0.0
	_done = false
	if _dots:
		_dots.queue_free()
		_dots = null
	if _home:
		if _counter == null:
			_counter = Label.new()
			_counter.add_theme_font_size_override("font_size", 56)
			_counter.add_theme_color_override("font_color", Palette.TEXT)
			_counter.set_anchors_preset(Control.PRESET_CENTER_TOP)
			_counter.offset_left = ColorSquare.SIDE / 2.0 + 30
			_counter.offset_right = ColorSquare.SIDE / 2.0 + 230
			_counter.offset_top = 70
			_counter.offset_bottom = 150
			_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(_counter)
		_counter.text = "0"
	else:
		if _counter:
			_counter.text = ""
		_dots = GameUI.add_dots(self, int(_p.goal))
		_dots.offset_left = LEFT_MARGIN
	_set_target(_rng.randi_range(0, int(_p.colors) - 1), false)
	Sound.say(ColorBubbleLevels.NAMES[_target])


func _process(delta: float) -> void:
	if _done:
		return
	_wait -= delta
	if _wait <= 0.0 and _active.size() < int(_p.max_on_screen):
		_spawn()
		_wait = float(_p.gap) * _rng.randf_range(0.8, 1.2)
	# Safety net: if the square's colour is nowhere on screen for a while,
	# change it to one that is (normally it changes on every pop).
	if _present().has(_target) or _active.is_empty():
		_missing_t = 0.0
	else:
		_missing_t += delta
		if _missing_t >= STUCK_TIME:
			_new_target()


## Colours of the bubbles on screen (not popping), one entry per bubble.
func _present() -> Array:
	var out: Array = []
	for b in _active:
		if not b.is_popping():
			out.append(b.color_id)
	return out


## A new colour for the square straight away: one of the bubbles on screen
## (the same colour may come again); a random level colour if none are there.
func _new_target() -> void:
	_missing_t = 0.0
	var options := _present()
	var c := _rng.randi_range(0, int(_p.colors) - 1)
	if not options.is_empty():
		c = options[_rng.randi_range(0, options.size() - 1)]
	_set_target(c, true)


func _set_target(c: int, speak: bool) -> void:
	_target = c
	_square.show_color(ColorBubbleLevels.COLORS[c])
	if speak:
		Sound.say(ColorBubbleLevels.NAMES[c])


func _spawn() -> void:
	var n := int(_p.colors)
	var c := _target
	if _rng.randf() >= float(_p.target_share) and n > 1:
		c = (_target + _rng.randi_range(1, n - 1)) % n
	var r := float(_p.radius) * _rng.randf_range(0.9, 1.1)
	var spread := float(_p.spread)
	var spec := {
		"radius": r,
		"speed": float(_p.speed) * _rng.randf_range(1.0 - spread, 1.0 + spread),
		"color": c,
		"tint": ColorBubbleLevels.COLORS[c],
		"whiten": 0.45,
		"sway": _rng.randf_range(8.0, 22.0),
		"sway_hz": _rng.randf_range(0.12, 0.25),
		"phase": _rng.randf() * TAU,
	}
	var w := size.x - LEFT_MARGIN - SIDE_MARGIN - 2.0 * (r + 22.0)
	var x := LEFT_MARGIN + r + 22.0 + w * _free_x(r, w)
	var b := Bubble.new().setup(spec, x, size.y + r, Settings.reduce_motion)
	b.popped.connect(_on_popped)
	b.escaped.connect(_on_escaped)
	_field.add_child(b)
	_active.append(b)


## A spot (0–1 across) not right on top of a bubble that just came up.
func _free_x(r: float, w: float) -> float:
	var best := _rng.randf()
	var best_d := -1.0
	for i in 6:
		var t := _rng.randf()
		var x := LEFT_MARGIN + r + 22.0 + w * t
		var d := INF
		for b in _active:
			if b.position.y > size.y - 3.0 * b.radius:
				d = minf(d, absf(b.position.x - x))
		if d > best_d:
			best_d = d
			best = t
	return best


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_try_pop(event.position)


func _try_pop(p: Vector2) -> void:
	if _done:
		return
	for i in range(_active.size() - 1, -1, -1):
		var b := _active[i]
		if b.hit(p):
			if b.color_id == _target:
				b.pop()
			else:
				b.nudge()
				_owl.oops()
			return


func _on_popped(b: Bubble) -> void:
	_active.erase(b)
	_popped += 1
	Sound.sfx("pop", _rng.randf_range(0.9, 1.12))
	_new_target()
	if _home:
		_counter.text = str(_popped)
		if _popped % HOME_STEP == 0:
			level += 1
			_p = ColorBubbleLevels.params(level)
			if _popped % (HOME_STEP * 3) == 0:
				_owl.happy()
		return
	GameUI.fill_dot(_dots, _popped - 1)
	if _popped >= int(_p.goal):
		_finish()


func _on_escaped(b: Bubble) -> void:
	_active.erase(b)
	if _done or b.color_id != _target:
		return              # other colours may float away
	_lives -= 1
	_hearts.set_lives(_lives)
	_owl.oops()
	if _lives <= 0:
		_out_of_lives()


func _stop_field() -> void:
	_done = true
	for b in _active:
		b.queue_free()
	_active.clear()


func _finish() -> void:
	_stop_field()
	_owl.cheer()
	Sound.sfx("chime")
	Sound.say("šaunu")
	if level + 1 > reached():
		GameUI.set_progress(GAME, {"level": level + 1})
	await get_tree().create_timer(1.2).timeout
	# On the map Olis walks from this stop to the next one, then "Play" opens.
	walk_from = level
	_go_map()


func _out_of_lives() -> void:
	_stop_field()
	await get_tree().create_timer(0.6).timeout
	var w: WellDone
	if _home:
		var best := maxi(int(GameUI.progress(GAME).get("home_best", 0)), _popped)
		GameUI.set_progress(GAME, {"home_best": best})
		_owl.cheer()
		w = WellDone.make(false, "%d  (geriausias: %d)" % [_popped, best])
	else:
		w = WellDone.make(false, "Pabandyk dar kartą", "Beveik!", "think", "beveik")
	var again := ColorBubbleLevels.HOME_LEVEL if _home else level
	w.replay.connect(func(): w.queue_free(); _owl.set_pose("idle"); _start(again))
	w.home.connect(_go_map)
	add_child(w)


func _go_map() -> void:
	get_tree().change_scene_to_file(MAP)


## The colour to pop: a big soft rounded square that gently pulses when it changes.
class ColorSquare extends Control:
	const SIDE := 150.0
	var col := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(SIDE, SIDE)

	func show_color(c: Color) -> void:
		col = c
		pivot_offset = Vector2(SIDE, SIDE) / 2.0
		queue_redraw()
		if is_inside_tree() and not Settings.reduce_motion:
			var t := create_tween()
			t.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
			t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(40)
		sb.anti_aliasing = true
		sb.bg_color = Palette.SHADOW
		draw_style_box(sb, Rect2(Vector2(0, 8), size))
		sb.bg_color = Palette.CARD
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		sb.set_corner_radius_all(28)
		sb.bg_color = col
		draw_style_box(sb, Rect2(Vector2(16, 16), size - Vector2(32, 32)))


## Three soft hearts; a lost one turns into a pale outline.
class Hearts extends Control:
	const WIDTH := 3 * 70.0
	const HEIGHT := 64.0
	var lives := 3

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(WIDTH, HEIGHT)

	func set_lives(n: int) -> void:
		lives = n
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var c := Vector2(35 + i * 70, 32)
			var full := i < lives
			var pts := _heart(c, 26.0)
			if full:
				draw_colored_polygon(pts, Color("#EC97AC"))
			else:
				draw_colored_polygon(pts, Color(Palette.TEXT, 0.08))
			pts.append(pts[0])
			draw_polyline(pts, Color(Palette.TEXT, 0.35 if full else 0.2), 2.5, true)

	func _heart(c: Vector2, s: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in 48:
			var t := TAU * k / 48.0
			var x := 16.0 * pow(sin(t), 3)
			var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
			pts.append(c + Vector2(x, -y) * s / 16.0)
		return pts
