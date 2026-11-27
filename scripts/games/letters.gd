extends Control
## "Atspėk" — a word riddle. Above each empty letter box is a picture; its first
## letter goes into the box. Fill all boxes to discover the hidden word.
## Example: sala, traktorius, arklys, laivas, avilys, sūpynės → STALAS.
## - Tap a picture: hear its name (help for children who can't name it yet).
## - Drag a letter into a box, or tap a letter and then a box.
## - Right letter: snaps in, the picture's word is spoken. Wrong: slides back.
## - All boxes filled: the hidden word's picture appears and is spoken.

const LEVELS := "res://data/levels/letters.json"
const COL_W := 230.0
const COL_GAP := 26.0
const PIC := Vector2(210, 210)
const SLOT := Vector2(170, 170)
const TILE := Vector2(130, 130)
const TAP_DISTANCE := 20.0

static var start_level := 0   # > 0: open this level directly (tests); 0 = saved level / mode choice

var _level := {}
var _clues: Array = []
var _slots: Array[LetterSlot] = []
var _tiles: Array[LetterTile] = []
var _drag: LetterTile
var _selected: LetterTile
var _offset := Vector2.ZERO
var _press := Vector2.ZERO
var _filled := 0
var _busy := false


var _owl: Owl


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_title(self, "Atspėk žodį")
	GameUI.add_speaker(self, func(): Sound.say(_level.get("instruction", "atspėk žodį")))
	_owl = Owl.add_to_corner(self)
	var forced := start_level
	start_level = 0
	GameUI.open_game(self, "letters", forced, _start, _start_endless, _owl)


## A new "Begalinis" (unlimited) round.
func _start_endless() -> void:
	_start(-1)


func _start(id: int) -> void:
	for n in get_children():
		if n is PictureCard or n is LetterSlot or n is LetterTile or n.name == "Reveal":
			n.queue_free()
	_slots.clear()
	_tiles.clear()
	_filled = 0
	_selected = null
	_level = EndlessLevels.letters() if id < 0 else GameUI.load_level(LEVELS, id)
	_clues = _level.get("clues", [])
	var n := _clues.size()
	var x0 := (1920.0 - (n * COL_W + (n - 1) * COL_GAP)) / 2.0
	for i in n:
		var clue: Dictionary = _clues[i]
		var x := x0 + i * (COL_W + COL_GAP)
		# Picture only (no word): the child names it.
		var pic := PictureCard.new().setup(clue.word, Palette.ACCENTS[i % Palette.ACCENTS.size()], false)
		pic.custom_minimum_size = PIC
		pic.size = PIC
		pic.position = Vector2(x + (COL_W - PIC.x) / 2.0, 175)
		pic.pressed.connect(func(): Sound.say(clue.word))
		add_child(pic)
		var slot := LetterSlot.new().setup(String(clue.label).left(1), SLOT)
		slot.position = Vector2(x + (COL_W - SLOT.x) / 2.0, 420)
		slot.gui_input.connect(_on_slot_input.bind(slot))
		add_child(slot)
		_slots.append(slot)
	# Letter tray: the needed letters + a few extra, shuffled.
	var letters: Array = []
	for s in _slots:
		letters.append(s.expected)
	letters.append_array(_level.get("extra_letters", []))
	letters.shuffle()
	var gap := 26.0
	var tx0 := (1920.0 - (letters.size() * TILE.x + (letters.size() - 1) * gap)) / 2.0
	for i in letters.size():
		var t := LetterTile.new().setup(letters[i], Palette.ACCENTS[(i + 2) % Palette.ACCENTS.size()], TILE)
		t.home = Vector2(tx0 + i * (TILE.x + gap), 700)
		t.position = t.home
		t.gui_input.connect(_on_tile_input.bind(t))
		add_child(t)
		_tiles.append(t)
	Sound.say(_level.get("instruction", "atspėk žodį"))


# --- Input ------------------------------------------------------------------

func _on_tile_input(event: InputEvent, t: LetterTile) -> void:
	if _busy or t.locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag = t
			_press = event.global_position
			_offset = event.global_position - t.global_position
			t.z_index = 10
			if not Settings.reduce_motion:
				t.scale = Vector2(1.08, 1.08)
		elif _drag == t:
			_drag = null
			t.z_index = 0
			t.scale = Vector2.ONE
			_highlight(Vector2(-1, -1))
			if event.global_position.distance_to(_press) < TAP_DISTANCE:
				t.position = t.home
				_select(t)
			else:
				var s := _slot_at(event.global_position)
				if s:
					_try(t, s)
				else:
					_slide_home(t)
		t.accept_event()
	elif event is InputEventMouseMotion and _drag == t:
		t.global_position = event.global_position - _offset
		_highlight(event.global_position)
		t.accept_event()


func _on_slot_input(event: InputEvent, s: LetterSlot) -> void:
	if _busy or s.filled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _selected:
			_try(_selected, s)
		else:
			# No letter chosen yet: say the picture above, as a hint.
			Sound.say(_clues[_slots.find(s)].word)


func _select(t: LetterTile) -> void:
	if _selected and _selected != t:
		_selected.selected = false
	_selected = null if _selected == t else t
	t.selected = _selected == t


func _slot_at(p: Vector2) -> LetterSlot:
	for s in _slots:
		if not s.filled and s.get_global_rect().grow(20).has_point(p):
			return s
	return null


func _highlight(p: Vector2) -> void:
	for s in _slots:
		s.highlight = not s.filled and s.get_global_rect().grow(20).has_point(p)


# --- Game -------------------------------------------------------------------

func _try(t: LetterTile, s: LetterSlot) -> void:
	t.selected = false
	_selected = null
	if t.letter == s.expected:
		t.locked = true
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.filled = true
		_filled += 1
		var target := s.position + (s.size - t.size) / 2.0
		create_tween().tween_property(t, "position", target, 0.18).set_trans(Tween.TRANS_SINE)
		Sound.sfx("chime")
		_owl.happy()
		var word: String = _clues[_slots.find(s)].word
		if _filled >= _slots.size():
			_busy = true
			await Sound.say_wait(word)
			_reveal()
		else:
			Sound.say(word)
	else:
		_slide_home(t)
		_wiggle(t)
		_owl.oops()


func _slide_home(t: LetterTile) -> void:
	create_tween().tween_property(t, "position", t.home, 0.3).set_trans(Tween.TRANS_SINE)


func _wiggle(t: LetterTile) -> void:
	if Settings.reduce_motion:
		return
	var tw := create_tween()
	for d in [-5.0, 5.0, -3.0, 0.0]:
		tw.tween_property(t, "rotation_degrees", d, 0.07)


func _reveal() -> void:
	_owl.cheer()
	await get_tree().create_timer(0.4).timeout
	# Unused extra letters fade away; the hidden word's picture appears.
	for t in _tiles:
		if not t.locked:
			create_tween().tween_property(t, "modulate:a", 0.0, 0.3)
	var answer: String = _level.get("answer", "")
	var card := PictureCard.new().setup(answer, Palette.SAGE, true)
	card.name = "Reveal"
	card.custom_minimum_size = Vector2(300, 360)
	card.size = Vector2(300, 360)
	card.position = Vector2((1920 - 300) / 2.0, 640)
	card.modulate.a = 0.0
	card.state = PictureCard.State.MATCHED
	add_child(card)
	create_tween().tween_property(card, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.4).timeout
	await Sound.say_wait(answer)
	await get_tree().create_timer(0.8).timeout
	GameUI.well_done(self, LEVELS, int(_level.get("id", 1)), func(id: int): _busy = false; _start(id),
		func(): _busy = false; _start_endless())
