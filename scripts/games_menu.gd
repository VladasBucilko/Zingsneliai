extends Control
## "Žaidimukai" — the six mini-games.

const GAMES := [
	# label, icon, accent, scene
	["Burbulai", ActivityTile.Icon.BUBBLES, Palette.SKY, "res://scenes/games/bubble_pop.tscn"],
	["Poros", ActivityTile.Icon.MATCHING, Palette.PEACH, "res://scenes/games/matching.tscn"],
	["Rūšiuok", ActivityTile.Icon.SORTING, Palette.SAGE, "res://scenes/games/sorting.tscn"],
	["Surask", ActivityTile.Icon.FIND, Palette.BUTTER, "res://scenes/games/find.tscn"],
	["Dėlionė", ActivityTile.Icon.PUZZLE, Palette.LAVENDER, "res://scenes/games/puzzle.tscn"],
	["Kartok", ActivityTile.Icon.SOUND, Palette.ROSE, "res://scenes/games/repeat.tscn"],
]

@onready var _grid: GridContainer = $Activities


func _ready() -> void:
	GameUI.add_home(self, GameUI.HOME)
	GameUI.add_title(self, "Žaidimukai")
	for g in GAMES:
		var t := ActivityTile.new().setup(g[0], g[1], g[2], true)
		t.pressed.connect(_open.bind(g[0], g[3]))
		_grid.add_child(t)


func _open(label: String, scene: String) -> void:
	Sound.say(label)
	get_tree().change_scene_to_file(scene)
