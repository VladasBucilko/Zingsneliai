extends Control
## "Surask" — hear a word, tap its picture.
## Wrong tap = the picture wiggles and says its own name, then the question repeats.

const LEVELS := "res://data/levels/find.json"

static var start_level := 1

var _level := {}
var _round := 0
var _rounds: Array = []
var _cards: Array[PictureCard] = []
var _busy := false
var _dots: HBoxContainer

@onready var _prompt: Label = $Prompt
@onready var _row: HBoxContainer = $Choices


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_speaker(self, _ask)
	_start(start_level)


func _start(id: int) -> void:
	_level = GameUI.load_level(LEVELS, id)
	_rounds = _level.get("rounds", [])
	_round = 0
	if _dots:
		_dots.queue_free()
	_dots = GameUI.add_dots(self, _rounds.size())
	_show_round()


func _show_round() -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()
	if _round >= _rounds.size():
		await get_tree().create_timer(0.5).timeout
		var w := WellDone.make(false)
		w.replay.connect(func(): w.queue_free(); _start(int(_level.get("id", 1))))
		w.home.connect(func(): get_tree().change_scene_to_file("res://scenes/games_menu.tscn"))
		add_child(w)
		return
	var r: Dictionary = _rounds[_round]
	_prompt.text = r.prompt
	var i := 0
	for word in r.choices:
		# Pictures only: the child finds it by listening, not by reading.
		var c := PictureCard.new().setup(word, Palette.ACCENTS[i % Palette.ACCENTS.size()], false)
		c.custom_minimum_size = Vector2(360, 360)
		c.pivot_offset = Vector2(180, 180)
		c.pressed.connect(_on_pick.bind(c))
		_row.add_child(c)
		_cards.append(c)
		i += 1
	_ask()


func _ask() -> void:
	if _round < _rounds.size():
		Sound.say(_rounds[_round].prompt)


func _on_pick(c: PictureCard) -> void:
	if _busy:
		return
	var r: Dictionary = _rounds[_round]
	if c.word == r.target:
		_busy = true
		c.state = PictureCard.State.MATCHED
		c.celebrate()
		Sound.sfx("chime")
		GameUI.fill_dot(_dots, _round)
		await Sound.say_wait(c.word)
		await get_tree().create_timer(0.5).timeout
		_round += 1
		_busy = false
		_show_round()
	else:
		_busy = true
		c.nudge()
		await Sound.say_wait(c.word)
		await get_tree().create_timer(0.3).timeout
		_busy = false
		_ask()
