extends Control
## "Žaidimukai" — the mini-games.

const GAMES := [
	# label, icon, accent, scene
	["Burbulai", ActivityTile.Icon.BUBBLES, Palette.SKY, "res://scenes/games/bubble_pop.tscn"],
	["Poros", ActivityTile.Icon.MATCHING, Palette.PEACH, "res://scenes/games/matching.tscn"],
	["Rūšiuok", ActivityTile.Icon.SORTING, Palette.SAGE, "res://scenes/games/sorting.tscn"],
	["Surask", ActivityTile.Icon.FIND, Palette.BUTTER, "res://scenes/games/find.tscn"],
	["Dėlionė", ActivityTile.Icon.PUZZLE, Palette.LAVENDER, "res://scenes/games/puzzle.tscn"],
	["Kartok", ActivityTile.Icon.SOUND, Palette.ROSE, "res://scenes/games/repeat.tscn"],
	["Atspėk", ActivityTile.Icon.LETTERS, Palette.APRICOT, "res://scenes/games/letters.tscn"],
	["Sekos", ActivityTile.Icon.SEQUENCE, Palette.MINT, "res://scenes/games/sequence.tscn"],
	["Atmintis", ActivityTile.Icon.MEMORY, Palette.LAVENDER, "res://scenes/games/memory.tscn"],
]

const PER_ROW := 4   # up to 8 games; with more: rows of 5 and smaller tiles

@onready var _rows: VBoxContainer = $Activities


func _ready() -> void:
	GameUI.add_home(self, GameUI.HOME)
	GameUI.add_title(self, "Žaidimukai")
	Owl.add_to_corner(self)
	# Rows of tiles, each row centred (so a short last row stays centred).
	var per_row := PER_ROW if GAMES.size() <= 8 else 5
	var tile := Vector2(400, 360) if GAMES.size() <= 8 else Vector2(310, 280)
	var row: HBoxContainer
	for i in GAMES.size():
		if i % per_row == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 48 if GAMES.size() <= 8 else 36)
			_rows.add_child(row)
		var g: Array = GAMES[i]
		var t := ActivityTile.new().setup(g[0], g[1], g[2], true, tile)
		t.pressed.connect(_open.bind(g[0], g[3]))
		row.add_child(t)


func _open(label: String, scene: String) -> void:
	Sound.say(label)
	get_tree().change_scene_to_file(scene)
