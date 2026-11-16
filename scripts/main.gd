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
	add_child(lock)

	# Quit (not on iOS: Apple doesn't allow apps to close themselves).
	var right := 80.0
	if OS.get_name() != "iOS":
		var quit := RoundButton.new(RoundButton.Kind.QUIT)
		quit.pressed.connect(func(): get_tree().quit())
		var caption := Label.new()
		caption.text = "Išeiti"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 26)
		caption.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		box.name = "Quit"
		box.add_theme_constant_override("separation", 6)
		box.add_child(quit)
		box.add_child(caption)
		add_child(box)
		_top_right(box, right)
		box.offset_bottom = 56 + RoundButton.SIZE + 40 # room for the caption
		right += RoundButton.SIZE + 32.0
	_top_right(lock, right)


func _top_right(c: Control, right: float) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	c.offset_left = -right - RoundButton.SIZE
	c.offset_right = -right
	c.offset_top = 56
	c.offset_bottom = 56 + RoundButton.SIZE


func _open(label: String, scene: String) -> void:
	Sound.say(label)
	get_tree().change_scene_to_file(scene)
