extends Control
## Home screen: two big sections – "Žaidimukai" (games) and "Mano planas" (planner),
## with Olis the owl waving on the left.

const SECTIONS := [
	# label, icon, accent, scene, spoken
	["Žaidimukai", ActivityTile.Icon.GAMES, Palette.SKY, "res://scenes/games_menu.tscn", "žaidimukai"],
	["Mano planas", ActivityTile.Icon.PLAN, Palette.SAGE, "res://scenes/planner.tscn", "mano planas"],
]

const TILE := Vector2(500, 450)   # leaves room for Olis on the left, tiles stay centred

@onready var _grid: GridContainer = $Activities


func _ready() -> void:
	for a in SECTIONS:
		var t := ActivityTile.new().setup(a[0], a[1], a[2], true, TILE)
		t.pressed.connect(_open.bind(a[4], a[3]))
		_grid.add_child(t)
	# Olis greets the child (waves on arrival; tap him to hear hello).
	var olis := Owl.new().setup(432)
	olis.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	olis.offset_left = Owl.SIDE_MARGIN
	olis.offset_right = Owl.SIDE_MARGIN + olis.size.x
	olis.offset_top = -Owl.BOTTOM_MARGIN - olis.size.y
	olis.offset_bottom = -Owl.BOTTOM_MARGIN
	add_child(olis)
	olis.wave.call_deferred()

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
