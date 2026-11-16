extends Control
## "Dėlionė" — drag the pieces into the faint picture. Pieces snap in when close;
## dropped far away they slide back. When complete the word is spoken.

const LEVELS := "res://data/levels/puzzle.json"
const BOARD := 560.0

static var start_level := 1

var _level := {}
var _pieces: Array[PuzzlePiece] = []
var _placed := 0
var _tex: Texture2D

@onready var _board: Control = $Board


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_speaker(self, func(): Sound.say(_level.get("word", "")))
	_start(start_level)


func _start(id: int) -> void:
	_level = GameUI.load_level(LEVELS, id)
	for p in _pieces:
		p.queue_free()
	_pieces.clear()
	_placed = 0
	var word: String = _level.get("word", "katė")
	_tex = WordBank.photo(word)
	$Board/Ghost.texture = _tex
	$Board/Ghost.modulate.a = 0.22
	var cols := int(_level.get("cols", 2))
	var rows := int(_level.get("rows", 1))
	var tex_size := _tex.get_size()
	var piece := Vector2(BOARD / cols, BOARD / rows)
	var src := Vector2(tex_size.x / cols, tex_size.y / rows)
	# Waiting spots: left and right of the board, alternating.
	var spots: Array[Vector2] = []
	for i in cols * rows:
		var left := i % 2 == 0
		var x := -piece.x - 120.0 if left else BOARD + 120.0
		var y := (BOARD - piece.y) / 2.0 + (i / 2) * 40.0 - 20.0 * ((cols * rows - 1) / 2)
		spots.append(Vector2(x, y))
	spots.shuffle()
	var idx := 0
	for r in rows:
		for c in cols:
			var p := PuzzlePiece.new().setup(_tex, Rect2(Vector2(c, r) * src, src), piece,
				Vector2(c, r) * piece, spots[idx])
			p.placed.connect(_on_placed)
			_board.add_child(p)
			_pieces.append(p)
			idx += 1
	Sound.say("sudėk dėlionę")


func _on_placed(_p: PuzzlePiece) -> void:
	_placed += 1
	if _placed < _pieces.size():
		return
	await get_tree().create_timer(0.3).timeout
	create_tween().tween_property($Board/Ghost, "modulate:a", 1.0, 0.4)
	Sound.sfx("chime")
	await Sound.say_wait(_level.get("word", ""))
	await get_tree().create_timer(0.4).timeout
	var w := WellDone.make(false)
	w.replay.connect(func(): w.queue_free(); _start(int(_level.get("id", 1))))
	w.home.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	add_child(w)
