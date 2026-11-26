extends Control
## "Raidės" — connect each capital letter with its small letter by drawing a
## line with a finger (or tap one letter, then its partner).
## A correct pair: the line stays and both letters take the pair's colour.
## A wrong one: the line slides gently back. Sounds only, no voice.
## 5 stages × 10 levels (see LetterPairsGenerator). The game opens on a stage
## choice; a stage unlocks when the one before it is finished. Progress
## (unlocked stages, level reached in each) is saved on the device.

const SAVE := "user://raides.json"
const DIAMETER := 150.0
const TAP_DISTANCE := 20.0
const COL_GAP := 520.0                       # distance between the two columns
const AREA := Rect2(300, 215, 1320, 790)     # where tangle letters may sit (clear of Olis)
const STAGE_ACCENTS := [Palette.SKY, Palette.LAVENDER, Palette.PEACH, Palette.SAGE, Palette.BUTTER]

static var start := Vector2i.ZERO            # (stage, level) to open directly; zero = stage choice

var stage := 1
var level := 1
var _bubbles: Array[LetterBubble] = []
var _lines: Array = []                       # [{a: Vector2, b: Vector2, color}]
var _from: LetterBubble                      # bubble the finger started on
var _pending: LetterBubble                   # tapped bubble waiting for its partner
var _pointer := Vector2.ZERO
var _press := Vector2.ZERO
var _dragging := false
var _retract: Tween
var _matched := 0
var _pairs := 0
var _busy := false
var _owl: Owl
var _title: Label
var _layer: Control
var _dots: HBoxContainer
var _picker: Control
var _pair_colors := {}


func _ready() -> void:
	var home := RoundButton.new(RoundButton.Kind.HOME)
	home.position = Vector2(64, 56)
	home.pressed.connect(_on_home)
	add_child(home)
	_title = GameUI.add_title(self, "")
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_lines)
	add_child(_layer)
	_owl = Owl.add_to_corner(self)
	if start != Vector2i.ZERO:
		var s := start
		start = Vector2i.ZERO
		_load(s.x, s.y)
	else:
		_show_picker()


func _on_home() -> void:
	if _picker == null:
		_clear()
		_show_picker()
	else:
		get_tree().change_scene_to_file(GameUI.GAMES)


# --- Stage choice -------------------------------------------------------------------

func _show_picker() -> void:
	_title.text = "Raidės"
	var save := _saved()
	var unlocked := int(save.get("unlocked", 1))
	_picker = HBoxContainer.new()
	(_picker as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	_picker.add_theme_constant_override("separation", 32)
	_picker.set_anchors_preset(Control.PRESET_CENTER)
	_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_picker)
	for s in range(1, LetterPairsGenerator.STAGES + 1):
		var lvl := _saved_level(s)
		var done_all := s < unlocked or (s == LetterPairsGenerator.STAGES and bool(save.get("all_done", false)))
		var prog := "baigta ✓" if done_all else "lygis %d / %d" % [lvl, LetterPairsGenerator.LEVELS]
		var t := StageTile.new().setup(s, LetterPairsGenerator.STAGE_NAMES[s - 1], prog,
			s > unlocked, STAGE_ACCENTS[s - 1])
		t.pressed.connect(_choose.bind(s))
		_picker.add_child(t)
	_owl.react("point", 0.0)


func _choose(s: int) -> void:
	Sound.sfx("pop", 1.05)
	_load(s, _saved_level(s))


# --- A level ----------------------------------------------------------------------------

func _clear() -> void:
	for b in _bubbles:
		b.queue_free()
	_bubbles.clear()
	_lines.clear()
	_layer.queue_redraw()
	if _dots:
		_dots.queue_free()
		_dots = null
	if _picker:
		_picker.queue_free()
		_picker = null


func _load(s: int, l: int) -> void:
	_clear()
	stage = s
	level = l
	_set_level(stage, level)
	var data := LetterPairsGenerator.generate(stage, level)
	_title.text = "Sujunk raides"
	_owl.set_pose("idle")
	_matched = 0
	_busy = false
	_from = null
	_pending = null
	_pairs = data.pairs.size()
	_pair_colors.clear()
	var caps: Array[LetterBubble] = []
	var smalls: Array[LetterBubble] = []
	var i := 0
	for p in data.pairs:
		var L: String = p.letter
		_pair_colors[L] = Palette.ACCENTS[(i + stage) % Palette.ACCENTS.size()]
		caps.append(_make(L, L, true, p.cap_style == LetterPairsGenerator.Style.CURSIVE))
		smalls.append(_make(L.to_lower(), L, false, p.small_style == LetterPairsGenerator.Style.CURSIVE))
		i += 1
	var extras: Array[LetterBubble] = []
	for e in data.extras:
		extras.append(_make(String(e.letter).to_lower(), "", false, e.style == LetterPairsGenerator.Style.CURSIVE))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(data.seed) + 7
	if data.tangle:
		var all: Array[LetterBubble] = []
		all.append_array(caps)
		all.append_array(smalls)
		all.append_array(extras)
		_scatter(all, rng)
	else:
		_columns(caps, smalls, rng)
	_dots = GameUI.add_dots(self, _pairs)


func _make(text: String, key: String, capital: bool, cursive: bool) -> LetterBubble:
	var b := LetterBubble.new().setup(text, key, capital, cursive, DIAMETER)
	if key != "":
		b.accent = _pair_colors[key]
	b.gui_input.connect(_on_bubble_input.bind(b))
	add_child(b)
	_bubbles.append(b)
	return b


## Capitals in the left column (in order), small letters on the right (shuffled
## so no small letter sits straight across from its capital when avoidable).
func _columns(caps: Array[LetterBubble], smalls: Array[LetterBubble], rng: RandomNumberGenerator) -> void:
	var n := caps.size()
	var order := range(n)
	for attempt in 30:
		_shuffle(order, rng)
		var same := false
		for k in n:
			same = same or (order[k] == k and n > 1)
		if not same:
			break
	var step := minf(195.0, (AREA.size.y - DIAMETER) / maxf(n - 1, 1))
	var top := AREA.position.y + (AREA.size.y - (DIAMETER + step * (n - 1))) / 2.0
	var cx := size.x / 2.0
	for k in n:
		var y := top + k * step
		caps[k].position = Vector2(cx - COL_GAP / 2.0 - DIAMETER / 2.0, y)
		smalls[order[k]].position = Vector2(cx + COL_GAP / 2.0 - DIAMETER / 2.0, y)


## Letters scattered over the play area, not touching, slightly tilted.
func _scatter(all: Array[LetterBubble], rng: RandomNumberGenerator) -> void:
	_shuffle(all, rng)
	var placed: Array[Vector2] = []
	var min_d := DIAMETER * 1.3
	for b in all:
		var p := Vector2.ZERO
		for attempt in 400:
			p = Vector2(rng.randf_range(AREA.position.x, AREA.end.x - DIAMETER),
				rng.randf_range(AREA.position.y, AREA.end.y - DIAMETER))
			var ok := true
			for q in placed:
				if p.distance_to(q) < min_d:
					ok = false
					break
			if ok:
				break
			if attempt % 100 == 99:
				min_d *= 0.92   # crowded: allow a little closer
		placed.append(p)
		b.position = p
		b.rotation_degrees = rng.randf_range(-12.0, 12.0)


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for k in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, k)
		var t = a[k]
		a[k] = a[j]
		a[j] = t


# --- Drawing lines -------------------------------------------------------------------------

func _on_bubble_input(event: InputEvent, b: LetterBubble) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		b.accept_event()
		if event.pressed:
			if b.done:
				return
			_stop_retract()
			_from = b
			_dragging = true
			_press = event.global_position
			_pointer = event.global_position
			b.selected = true
			Sound.sfx("pop", 1.15)
		elif _dragging:
			_dragging = false
			var from := _from
			if event.global_position.distance_to(_press) < TAP_DISTANCE:
				_tap(from)
			else:
				var target := _bubble_at(event.global_position)
				if target and target != from and not target.done:
					_try(from, target)
				else:
					from.selected = false
					_retract_line(from, event.global_position)
	elif event is InputEventMouseMotion and _dragging:
		b.accept_event()
		_pointer = event.global_position
		_layer.queue_redraw()


## Tap one letter, then its partner (for children who find dragging hard).
func _tap(b: LetterBubble) -> void:
	_layer.queue_redraw()
	if _pending == null or _pending == b:
		_pending = b if _pending == null else null
		b.selected = _pending == b
		_from = null
		return
	var a := _pending
	_pending = null
	_try(a, b)


func _bubble_at(p: Vector2) -> LetterBubble:
	for b in _bubbles:
		if b.center_global().distance_to(p) <= DIAMETER / 2.0 + 10.0:
			return b
	return null


func _try(a: LetterBubble, b: LetterBubble) -> void:
	_from = null
	a.selected = false
	b.selected = false
	if a.key != "" and a.key == b.key and a.capital != b.capital:
		a.done = true
		b.done = true
		_lines.append({"a": a, "b": b, "color": _pair_colors[a.key]})
		_layer.queue_redraw()
		_bounce(a)
		_bounce(b)
		Sound.sfx("chime")
		GameUI.fill_dot(_dots, _matched)
		_matched += 1
		if _matched >= _pairs:
			_finish()
		else:
			_owl.happy()
	else:
		_wiggle(b)
		Sound.sfx("pop", 0.7)
		_owl.oops()
		_retract_line(a, b.center_global())


func _retract_line(from: LetterBubble, end: Vector2) -> void:
	# The loose line slides back into the letter it started from.
	_from = from
	_pointer = end
	if Settings.reduce_motion:
		_from = null
		_layer.queue_redraw()
		return
	_retract = create_tween()
	_retract.tween_method(func(t: float):
		_pointer = end.lerp(from.center_global(), t)
		_layer.queue_redraw(), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	_retract.tween_callback(func(): _from = null; _layer.queue_redraw())


func _stop_retract() -> void:
	if _retract:
		_retract.kill()
		_retract = null


func _draw_lines() -> void:
	for l in _lines:
		_thick(l.a.center_global(), l.b.center_global(), l.color.darkened(0.05), 14.0)
	if _from and (_dragging or _retract):
		_thick(_from.center_global(), _pointer, Color(Palette.TEXT_MUTED, 0.55), 10.0)


func _thick(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	_layer.draw_line(a, b, col, w, true)
	_layer.draw_circle(a, w / 2.0, col)
	_layer.draw_circle(b, w / 2.0, col)


# --- Level done -----------------------------------------------------------------------------

func _finish() -> void:
	_busy = true
	_owl.cheer()
	# Next: the following level, or level 1 of the next stage (which unlocks).
	var next := Vector2i(stage, level + 1)
	if level >= LetterPairsGenerator.LEVELS:
		next = Vector2i(stage + 1, 1)
		var save := _saved()
		if stage < LetterPairsGenerator.STAGES:
			save["unlocked"] = maxi(int(save.get("unlocked", 1)), stage + 1)
		else:
			save["all_done"] = true
		_write(save)
	if next.x <= LetterPairsGenerator.STAGES:
		_set_level(next.x, next.y)
	await get_tree().create_timer(0.8).timeout
	var has_next := next.x <= LetterPairsGenerator.STAGES
	var w := WellDone.make(has_next)
	w.replay.connect(func(): w.queue_free(); _load(stage, level))
	w.next.connect(func(): w.queue_free(); _load(next.x, next.y))
	w.home.connect(func(): get_tree().change_scene_to_file(GameUI.GAMES))
	add_child(w)


func _bounce(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(1.12, 1.12), 0.09)
	t.tween_property(n, "scale", Vector2.ONE, 0.15)


func _wiggle(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var base := n.rotation_degrees
	var t := create_tween()
	for d in [-7.0, 7.0, -4.0, 0.0]:
		t.tween_property(n, "rotation_degrees", base + d, 0.06)


# --- Saved progress: {"unlocked": n, "levels": {"1": n, …}, "all_done": bool} ----------

func _saved() -> Dictionary:
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _write(d: Dictionary) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func _saved_level(s: int) -> int:
	var levels: Dictionary = _saved().get("levels", {})
	return clampi(int(levels.get(str(s), 1)), 1, LetterPairsGenerator.LEVELS)


func _set_level(s: int, l: int) -> void:
	var d := _saved()
	var levels: Dictionary = d.get("levels", {})
	levels[str(s)] = l
	d["levels"] = levels
	_write(d)
