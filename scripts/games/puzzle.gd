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


var _owl: Owl


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_speaker(self, func(): Sound.say(_level.get("word", "")))
	_owl = Owl.add_to_corner(self)
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
	var spots := _waiting_spots(cols * rows, piece)
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


## Waiting spots: half the pieces left of the board, half right, each side in a
## small grid (one column if the pieces fit stacked, otherwise two).
func _waiting_spots(n: int, piece: Vector2) -> Array[Vector2]:
	const GAP := 24.0
	const MARGIN := 90.0       # space between the board and the pieces
	const MAX_H := 700.0       # pieces must stay on screen vertically
	var spots: Array[Vector2] = []
	var per_side := [ceili(n / 2.0), n / 2]
	for side in 2:
		var k: int = per_side[side]
		if k == 0:
			continue
		var cols := 1 if k * piece.y + (k - 1) * GAP <= MAX_H else 2
		var rows := ceili(float(k) / cols)
		var block := Vector2(cols * piece.x + (cols - 1) * GAP, rows * piece.y + (rows - 1) * GAP)
		var x0 := -MARGIN - block.x if side == 0 else BOARD + MARGIN
		var y0 := (BOARD - block.y) / 2.0
		if side == 0:
			# Keep the left pieces above Olis, who sits in the bottom-left corner.
			var owl_top := Owl.corner_rect(get_viewport_rect().size).position.y - _board.global_position.y
			y0 = minf(y0, owl_top - 30.0 - block.y)
		for j in k:
			var c := j % cols
			var r := j / cols
			spots.append(Vector2(x0 + c * (piece.x + GAP), y0 + r * (piece.y + GAP)))
	return spots


func _on_placed(_p: PuzzlePiece) -> void:
	_placed += 1
	if _placed < _pieces.size():
		_owl.happy()
		return
	_owl.cheer()
	await get_tree().create_timer(0.3).timeout
	create_tween().tween_property($Board/Ghost, "modulate:a", 1.0, 0.4)
	Sound.sfx("chime")
	await Sound.say_wait(_level.get("word", ""))
	await get_tree().create_timer(0.4).timeout
	GameUI.well_done(self, LEVELS, int(_level.get("id", 1)), _start)
