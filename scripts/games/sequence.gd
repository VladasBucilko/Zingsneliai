extends Control
## "Sekos" — a row of capital letters stays on screen; press the buttons in the
## same order. The next letter to find is outlined. Wrong button = it wiggles,
## nothing else (after a few misses the right button gently pulses as a hint).
## No voice: soft tap and success sounds only. Levels from SequenceGenerator,
## endless; the last level reached is remembered on the device.

const SAVE := "user://sekos.json"
const ROW_Y := 250.0
const ROW_MAX_W := 1720.0
const ROW_GAP := 16.0
const HINT_AFTER := 3          # misses before the right button pulses

static var start_level := 0    # 0 = continue from the saved level

var level := 1
var _data := {}
var _row_i := 0
var _pos := 0
var _misses := 0
var _busy := false
var _cells: Array[LetterTile] = []
var _buttons: Array[LetterTile] = []
var _dots: HBoxContainer
var _hint: Tween


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_title(self, "Spausk raides iš eilės")
	_load_level(start_level if start_level > 0 else _saved_level())


func _load_level(n: int) -> void:
	level = maxi(n, 1)
	start_level = level
	_save(level)
	_data = SequenceGenerator.generate(level)
	_row_i = 0
	if _dots:
		_dots.queue_free()
	_dots = GameUI.add_dots(self, _data.rows.size())
	_show_row()


func _show_row() -> void:
	for n in _cells + _buttons:
		n.queue_free()
	_cells.clear()
	_buttons.clear()
	_pos = 0
	_misses = 0
	_busy = false
	var row: Array = _data.rows[_row_i]

	# The row to copy, centred, cells shrink when the row is long.
	var n := row.size()
	var cell := minf(150.0, (ROW_MAX_W - (n - 1) * ROW_GAP) / n)
	var x0 := (size.x - (n * cell + (n - 1) * ROW_GAP)) / 2.0
	for i in n:
		var c := LetterTile.new().setup(row[i], Palette.LINE, Vector2(cell, cell))
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.position = Vector2(x0 + i * (cell + ROW_GAP), ROW_Y)
		add_child(c)
		_cells.append(c)

	# Buttons: one or two centred rows, or the whole alphabet as a keyboard.
	var letters := SequenceGenerator.buttons_for(_data, _row_i)
	var per_row: int = 8 if _data.keyboard else (letters.size() if letters.size() <= 7 else ceili(letters.size() / 2.0))
	var lines := ceili(float(letters.size()) / per_row)
	var tile := 112.0 if _data.keyboard else 160.0
	var gap := 14.0 if _data.keyboard else 28.0
	var top := 470.0 if _data.keyboard else (610.0 if lines == 1 else 520.0)
	for i in letters.size():
		var line := i / per_row
		var in_line := mini(per_row, letters.size() - line * per_row)
		var col := i % per_row
		var lx0 := (size.x - (in_line * tile + (in_line - 1) * gap)) / 2.0
		var accent: Color = Palette.ACCENTS[i % Palette.ACCENTS.size()]
		var b := LetterTile.new().setup(letters[i], accent, Vector2(tile, tile))
		b.position = Vector2(lx0 + col * (tile + gap), top + line * (tile + gap))
		b.gui_input.connect(_on_button_input.bind(b))
		add_child(b)
		_buttons.append(b)
	_mark_current()


func _mark_current() -> void:
	for i in _cells.size():
		_cells[i].selected = i == _pos


func _on_button_input(event: InputEvent, b: LetterTile) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	b.accept_event()
	if _busy or _pos >= _cells.size():
		return
	var want: String = _cells[_pos].letter
	if b.letter == want:
		_right(b)
	else:
		_wrong(b, want)


func _right(b: LetterTile) -> void:
	_stop_hint()
	_misses = 0
	Sound.sfx("pop", 1.0 + 0.04 * (_pos % 5))
	_bounce(b)
	var c := _cells[_pos]
	c.accent = Palette.SAGE
	c.locked = true
	c.selected = false
	c.queue_redraw()
	_bounce(c)
	_pos += 1
	if _pos < _cells.size():
		_mark_current()
		return
	# Row done.
	_busy = true
	GameUI.fill_dot(_dots, _row_i)
	Sound.sfx("chime")
	await get_tree().create_timer(0.8).timeout
	_row_i += 1
	if _row_i < _data.rows.size():
		_show_row()
	else:
		_finish()


func _wrong(b: LetterTile, want: String) -> void:
	Sound.sfx("pop", 0.7)
	_wiggle(b)
	_misses += 1
	if _misses >= HINT_AFTER:
		for other in _buttons:
			if other.letter == want:
				_pulse(other)
				break


func _finish() -> void:
	for n in _buttons:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(0.3).timeout
	_save(level + 1)
	var w := WellDone.make(true)
	w.replay.connect(func(): w.queue_free(); _load_level(level))
	w.next.connect(func(): w.queue_free(); _load_level(level + 1))
	w.home.connect(func(): get_tree().change_scene_to_file(GameUI.GAMES))
	add_child(w)


# --- Little animations (skipped with "reduce motion") ------------------------

func _bounce(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(1.12, 1.12), 0.08)
	t.tween_property(n, "scale", Vector2.ONE, 0.14)


func _wiggle(n: Control) -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	for d in [-7.0, 7.0, -4.0, 0.0]:
		t.tween_property(n, "rotation_degrees", d, 0.06)


func _pulse(n: Control) -> void:
	_stop_hint()
	if Settings.reduce_motion:
		(n as LetterTile).selected = true
		return
	_hint = create_tween().set_loops()
	_hint.tween_property(n, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_SINE)
	_hint.tween_property(n, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)


func _stop_hint() -> void:
	if _hint:
		_hint.kill()
		_hint = null
	for b in _buttons:
		b.scale = Vector2.ONE
		b.selected = false


# --- Remember the level -------------------------------------------------------

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
