extends Control
## Home screen: big, calm tiles for each activity (matches Figma "01 Home").

const ACTIVITIES := [
	# label, icon, accent, scene (empty = coming soon)
	["Burbulai", ActivityTile.Icon.BUBBLES, Palette.SKY, "res://scenes/games/bubble_pop.tscn"],
	["Poros", ActivityTile.Icon.MATCHING, Palette.PEACH, "res://scenes/games/matching.tscn"],
	["Rūšiuok", ActivityTile.Icon.SORTING, Palette.SAGE, ""],
	["Surask", ActivityTile.Icon.FIND, Palette.BUTTER, ""],
	["Dėlionė", ActivityTile.Icon.PUZZLE, Palette.LAVENDER, ""],
	["Kartok", ActivityTile.Icon.SOUND, Palette.ROSE, ""],
]

@onready var _grid: GridContainer = $Activities


func _ready() -> void:
	for a in ACTIVITIES:
		var t := ActivityTile.new().setup(a[0], a[1], a[2], a[3] != "")
		if a[3] != "":
			t.pressed.connect(_open.bind(a[0], a[3]))
		_grid.add_child(t)
	var lock := RoundButton.new(RoundButton.Kind.LOCK)
	lock.modulate.a = 0.6
	lock.disabled = true # parent area comes later
	lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lock.offset_left = -80 - RoundButton.SIZE
	lock.offset_right = -80
	lock.offset_top = 56
	lock.offset_bottom = 56 + RoundButton.SIZE
	add_child(lock)


func _open(label: String, scene: String) -> void:
	Sound.say(label)
	get_tree().change_scene_to_file(scene)
