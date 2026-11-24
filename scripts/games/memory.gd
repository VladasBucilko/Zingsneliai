extends Control
## "Atmintis" — 5 coloured squares: one in the middle and four sitting at its
## corners (a small gap between them), each with its own soft note. The game shows a sequence
## (each square lights up for 0.5 s with its note), the child repeats it; every
## round adds one more square. A wrong press only wiggles that square, then the
## sequence is shown again calmly. No voice, no buzzer, no failing.
## Levels from MemoryGenerator, endless; the last level reached is remembered.

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

var level := 1
var _seq: Array = []
var _round := 1                # how many squares are shown this round
var _pos := 0                  # how far the child has repeated
var _showing := false
var _squares: Array[MemorySquare] = []
var _title: Label
var _dots: HBoxContainer


func _ready() -> void:
	GameUI.add_home(self)
	_title = GameUI.add_title(self, "")
	var origin := Vector2((size.x - AREA) / 2.0, 190.0)
	var free := AREA - SIDE
	for i in SPOTS.size():
		var sq := MemorySquare.new().setup(i, COLORS[i], SIDE)
		sq.position = origin + SPOTS[i] * free
		sq.pressed.connect(_on_press.bind(sq))
		add_child(sq)
		_squares.append(sq)
	_load_level(start_level if start_level > 0 else _saved_level())


func _load_level(n: int) -> void:
	level = maxi(n, 1)
	start_level = level
	_save(level)
	_seq = MemoryGenerator.generate(level).sequence
	_round = 1
	if _dots:
		_dots.queue_free()
	_dots = GameUI.add_dots(self, _seq.size())
	_show()


## Play the first _round squares of the sequence, then let the child repeat.
func _show() -> void:
	_showing = true
	_pos = 0
	_title.text = "Žiūrėk ir klausyk"
	await get_tree().create_timer(0.7).timeout
	for i in _round:
		if not is_inside_tree():
			return
		await _light(_squares[_seq[i]])
		await get_tree().create_timer(GAP).timeout
	_title.text = "Dabar tu!"
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
		GameUI.fill_dot(_dots, _round - 1)
		await get_tree().create_timer(0.5).timeout
		if _round >= _seq.size():
			_finish()
			return
		_round += 1
		_show()
	else:
		_showing = true
		_wiggle(sq)
		Sound.sfx("pop", 0.7)
		await get_tree().create_timer(0.8).timeout
		_show()  # calmly show the same round again


func _finish() -> void:
	Sound.sfx("chime")
	_title.text = ""
	_save(level + 1)
	await get_tree().create_timer(0.3).timeout
	var w := WellDone.make(true)
	w.replay.connect(func(): w.queue_free(); _load_level(level))
	w.next.connect(func(): w.queue_free(); _load_level(level + 1))
	w.home.connect(func(): get_tree().change_scene_to_file(GameUI.GAMES))
	add_child(w)


func _wiggle(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	for d in [-5.0, 5.0, -3.0, 0.0]:
		t.tween_property(n, "rotation_degrees", d, 0.06)


func _saved_level() -> int:
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return 1
	var d = JSON.parse_string(f.get_as_text())
	return maxi(int(d.get("level", 1)), 1) if d is Dictionary else 1


func _save(n: int) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"level": n}))
