extends Control
## "Poros" — match each picture in the top row with the same picture below.
## Tap a card (it is spoken), then tap its twin in the other row.
## Wrong choice = a tiny nudge only. No buzzer, no timer, no score.

const LEVELS_PATH := "res://data/levels/matching.json"

static var start_level := 1

var _level := {}
var _top: Array[PictureCard] = []
var _bottom: Array[PictureCard] = []
var _selected: PictureCard
var _matched := 0

@onready var _top_row: HBoxContainer = $Rows/Top
@onready var _bottom_row: HBoxContainer = $Rows/Bottom


func _ready() -> void:
	var home := RoundButton.new(RoundButton.Kind.HOME)
	home.position = Vector2(64, 56)
	home.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/games_menu.tscn"))
	add_child(home)
	var speak := RoundButton.new(RoundButton.Kind.SPEAKER)
	speak.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	speak.offset_left = -64 - RoundButton.SIZE
	speak.offset_right = -64
	speak.offset_top = 56
	speak.offset_bottom = 56 + RoundButton.SIZE
	speak.pressed.connect(_repeat)
	add_child(speak)
	_start(start_level)


static func load_level(id: int) -> Dictionary:
	var f := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var levels: Array = JSON.parse_string(f.get_as_text()).get("levels", []) if f else []
	for l in levels:
		if int(l.id) == id:
			return l
	return levels[0] if not levels.is_empty() else {"id": 1, "words": ["šuo", "katė", "karvė"], "show_word": true}


func _start(id: int) -> void:
	_level = load_level(id)
	for c in _top_row.get_children() + _bottom_row.get_children():
		c.queue_free()
	_top.clear()
	_bottom.clear()
	_selected = null
	_matched = 0
	var words: Array = _level.words
	var show_word: bool = _level.get("show_word", true)
	var shuffled := words.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Shuffle until no card sits directly under its twin (makes it a real match).
	for attempt in 20:
		_shuffle(shuffled, rng)
		var same := false
		for i in words.size():
			if shuffled[i] == words[i]:
				same = true
		if not same:
			break
	for i in words.size():
		_top.append(_add_card(_top_row, words[i], i, show_word))
	for w in shuffled:
		_bottom.append(_add_card(_bottom_row, w, words.find(w), show_word))


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _add_card(row: HBoxContainer, word: String, color_idx: int, show_word: bool) -> PictureCard:
	var c := PictureCard.new().setup(word, Palette.ACCENTS[(color_idx + 4) % Palette.ACCENTS.size()], show_word)
	c.pressed.connect(_on_card.bind(c))
	row.add_child(c)
	return c


func _on_card(c: PictureCard) -> void:
	if c.state == PictureCard.State.MATCHED:
		Sound.say(c.word)
		return
	Sound.say(c.word)
	if _selected == null or _same_row(_selected, c):
		if _selected:
			_selected.state = PictureCard.State.DEFAULT
		_selected = c
		c.state = PictureCard.State.SELECTED
		return
	if _selected.word == c.word:
		_selected.state = PictureCard.State.MATCHED
		c.state = PictureCard.State.MATCHED
		_selected.celebrate()
		c.celebrate()
		Sound.sfx("chime")
		_selected = null
		_matched += 1
		if _matched >= _top.size():
			_finish()
	else:
		c.nudge()


func _same_row(a: PictureCard, b: PictureCard) -> bool:
	return (a in _top) == (b in _top)


func _repeat() -> void:
	if _selected:
		Sound.say(_selected.word)
	else:
		Sound.say("surask porą")


func _finish() -> void:
	await get_tree().create_timer(0.9).timeout
	var w := WellDone.make(false)
	w.replay.connect(func(): w.queue_free(); _start(int(_level.id)))
	w.home.connect(func(): get_tree().change_scene_to_file("res://scenes/games_menu.tscn"))
	add_child(w)
