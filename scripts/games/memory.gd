extends Control
## "Atmintis" — 5 coloured squares: one in the middle and four sitting at its
## corners (a small gap between them), each with its own soft note. The game
## shows a sequence (each square lights up for 0.5 s with its note), the child
## repeats it; every round adds one more square.
## Two modes, chosen when the game opens:
##   Lygiai      – levels from MemoryGenerator (level n builds up to n + 2
##                 squares). A wrong press only wiggles the square and the same
##                 round is shown again. The last level reached is remembered.
##   Išbandymas  – a challenge: an endless random sequence that keeps growing
##                 until the first wrong press. Then a calm card shows how many
##                 squares were remembered and the best so far.
## No voice for the squares, no buzzer. Olis watches with the child.

enum Mode { LEVELS, CHALLENGE }

const SAVE := "user://atmintis.json"
const LIT := 0.5               # seconds a square stays lit
const GAP := 0.25              # pause between squares when showing
const SIDE := 250.0
const CORNER_GAP := 18.0       # space between the middle square and the corner ones
const AREA := SIDE * 3 + CORNER_GAP * 2
const COLORS := [Palette.PEACH, Palette.SKY, Palette.LAVENDER, Palette.SAGE, Palette.ROSE]
## Square positions inside AREA (fraction of the free space): the middle square,
## and one at each of its corners.
const SPOTS := [Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 0.5), Vector2(0, 1), Vector2(1, 1)]

static var start_level := 0    # 0 = continue from the saved level

var mode := Mode.LEVELS
var level := 1
var _seq: Array = []
var _round := 1                # how many squares are shown this round
var _pos := 0                  # how far the child has repeated
var _showing := true
var _squares: Array[MemorySquare] = []
var _title: Label
var _dots: HBoxContainer
var _owl: Owl
var _picker: Control
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	GameUI.add_home(self)
	_title = GameUI.add_title(self, "")
	_owl = Owl.add_to_corner(self)
	var origin := Vector2((size.x - AREA) / 2.0, 190.0)
	var free := AREA - SIDE
	for i in SPOTS.size():
		var sq := MemorySquare.new().setup(i, COLORS[i], SIDE)
		sq.position = origin + SPOTS[i] * free
		sq.pressed.connect(_on_press.bind(sq))
		add_child(sq)
		_squares.append(sq)
	if start_level > 0:
		var n := start_level
		start_level = 0            # only this once (used by tests / direct links)
		_load_level(n)
	else:
		_show_picker()


# --- Choosing the mode ----------------------------------------------------------

func _show_picker() -> void:
	_showing = true
	_title.text = "Atmintis"
	for sq in _squares:
		sq.visible = false
	_picker = HBoxContainer.new()
	(_picker as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	_picker.add_theme_constant_override("separation", 96)
	_picker.set_anchors_preset(Control.PRESET_CENTER)
	_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_picker)
	var best := int(_saved().get("best", 0))
	for m in [[Mode.LEVELS, "Lygiai", Palette.LAVENDER, "lygis %d" % _saved_level()],
			[Mode.CHALLENGE, "Išbandymas", Palette.BUTTER, ("geriausias: %d" % best) if best > 0 else ""]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 18)
		var t := ActivityTile.new().setup(m[1], ActivityTile.Icon.MEMORY, m[2], true, Vector2(460, 414))
		t.pressed.connect(_choose.bind(m[0], m[1]))
		col.add_child(t)
		var note := Label.new()
		note.text = m[3]
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 34)
		note.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		col.add_child(note)
		_picker.add_child(col)
	_owl.react("point", 0.0)


func _choose(m: Mode, _label: String) -> void:
	if m == Mode.LEVELS:
		Sound.say("lygiai")
	else:
		Sound.say("išbandymas")
	_picker.queue_free()
	_picker = null
	for sq in _squares:
		sq.visible = true
	_owl.set_pose("idle")
	mode = m
	if mode == Mode.LEVELS:
		_load_level(_saved_level())
	else:
		_start_challenge()


# --- Levels -----------------------------------------------------------------------

func _load_level(n: int) -> void:
	mode = Mode.LEVELS
	level = maxi(n, 1)
	_save({"level": level})
	_seq = MemoryGenerator.generate(level).sequence
	_round = 1
	_set_dots(_seq.size())
	_show()


# --- Challenge --------------------------------------------------------------------

func _start_challenge() -> void:
	mode = Mode.CHALLENGE
	_rng.randomize()
	_seq = [_rng.randi_range(0, MemoryGenerator.SQUARES - 1)]
	_round = 1
	_set_dots(0)
	_show()


func _set_dots(n: int) -> void:
	if _dots:
		_dots.queue_free()
		_dots = null
	if n > 0:
		_dots = GameUI.add_dots(self, n)


# --- Showing and repeating ----------------------------------------------------------

## Play the first _round squares of the sequence, then let the child repeat.
func _show() -> void:
	_showing = true
	_pos = 0
	_title.text = "Žiūrėk ir klausyk"
	_owl.listen()
	await get_tree().create_timer(0.7).timeout
	for i in _round:
		if not is_inside_tree():
			return
		await _light(_squares[_seq[i]])
		await get_tree().create_timer(GAP).timeout
	_title.text = "Dabar tu!" if mode == Mode.LEVELS else "Dabar tu! (%d)" % _round
	_owl.listen(false)
	_showing = false


func _light(sq: MemorySquare, secs := LIT) -> void:
	sq.lit = true
	Sound.sfx("note%d" % (sq.index + 1))
	if not Settings.reduce_motion:
		create_tween().tween_property(sq, "scale", Vector2(1.06, 1.06), 0.1)
	await get_tree().create_timer(secs).timeout
	sq.lit = false
	if not Settings.reduce_motion:
		create_tween().tween_property(sq, "scale", Vector2.ONE, 0.12)


func _on_press(sq: MemorySquare) -> void:
	if _showing:
		return
	if sq.index == _seq[_pos]:
		_light(sq, 0.3)
		_pos += 1
		if _pos < _round:
			return
		# The whole round repeated correctly.
		_showing = true
		_owl.happy()
		if _dots:
			GameUI.fill_dot(_dots, _round - 1)
		await get_tree().create_timer(0.6).timeout
		if mode == Mode.LEVELS:
			if _round >= _seq.size():
				_finish_level()
				return
		else:
			_seq.append(_rng.randi_range(0, MemoryGenerator.SQUARES - 1))
		_round += 1
		_show()
	else:
		_showing = true
		_wiggle(sq)
		Sound.sfx("pop", 0.7)
		_owl.oops()
		await get_tree().create_timer(0.9).timeout
		if mode == Mode.LEVELS:
			_show()  # calmly show the same round again
		else:
			_finish_challenge(_round - 1)


func _finish_level() -> void:
	Sound.sfx("chime")
	_owl.cheer()
	_title.text = ""
	_save({"level": level + 1})
	await get_tree().create_timer(0.3).timeout
	var w := WellDone.make(true)
	w.replay.connect(func(): w.queue_free(); _load_level(level))
	w.next.connect(func(): w.queue_free(); _load_level(level + 1))
	w.home.connect(func(): get_tree().change_scene_to_file(GameUI.GAMES))
	add_child(w)


## remembered = how many squares the child repeated correctly in a row.
func _finish_challenge(remembered: int) -> void:
	_title.text = ""
	var best := int(_saved().get("best", 0))
	var note := "Prisiminei: %d" % remembered
	if remembered > best:
		_save({"best": remembered})
		if best > 0:
			note += "\nNaujas geriausias!"
	else:
		note += "\nGeriausias: %d" % best
	Sound.sfx("chime")
	_owl.cheer()
	await get_tree().create_timer(0.3).timeout
	var w := WellDone.make(false, note)
	w.replay.connect(func(): w.queue_free(); _start_challenge())
	w.home.connect(func(): get_tree().change_scene_to_file(GameUI.GAMES))
	add_child(w)


func _wiggle(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	for d in [-5.0, 5.0, -3.0, 0.0]:
		t.tween_property(n, "rotation_degrees", d, 0.06)


# --- Saved progress: {"level": n, "best": n} ------------------------------------------

func _saved() -> Dictionary:
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _saved_level() -> int:
	return maxi(int(_saved().get("level", 1)), 1)


func _save(changes: Dictionary) -> void:
	var d := _saved()
	d.merge(changes, true)
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
