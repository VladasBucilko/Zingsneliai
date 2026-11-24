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
]

const PER_ROW := 4

@onready var _rows: VBoxContainer = $Activities


func _ready() -> void:
	GameUI.add_home(self, GameUI.HOME)
	GameUI.add_title(self, "Žaidimukai")
	# Rows of up to 4 tiles, each row centred (so a short last row stays centred).
	var row: HBoxContainer
	for i in GAMES.size():
		if i % PER_ROW == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 48)
			_rows.add_child(row)
		var g: Array = GAMES[i]
		var t := ActivityTile.new().setup(g[0], g[1], g[2], true)
		t.pressed.connect(_open.bind(g[0], g[3]))
		row.add_child(t)


func _open(label: String, scene: String) -> void:
	Sound.say(label)
	get_tree().change_scene_to_file(scene)
