class_name GameUI
## Shared bits for game screens: home button, speaker button, title, progress dots.


const HOME := "res://scenes/main.tscn"
const GAMES := "res://scenes/games_menu.tscn"


static func add_home(screen: Control, target := GAMES) -> RoundButton:
	var b := RoundButton.new(RoundButton.Kind.HOME)
	b.position = Vector2(64, 56)
	b.pressed.connect(func(): screen.get_tree().change_scene_to_file(target))
	screen.add_child(b)
	return b


static func add_speaker(screen: Control, on_press: Callable) -> RoundButton:
	var b := RoundButton.new(RoundButton.Kind.SPEAKER)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -64 - RoundButton.SIZE
	b.offset_right = -64
	b.offset_top = 56
	b.offset_bottom = 56 + RoundButton.SIZE
	b.pressed.connect(on_press)
	screen.add_child(b)
	return b


static func add_title(screen: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 56)
	l.add_theme_color_override("font_color", Palette.TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = 70
	l.offset_bottom = 150
	screen.add_child(l)
	return l


## Row of quiet dots along the bottom. Call fill(i) as the child progresses.
static func add_dots(screen: Control, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -64
	row.offset_bottom = -46
	for i in count:
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(18, 18)
		d.color = Color(Palette.TEXT, 0.12)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(d)
	screen.add_child(row)
	return row


static func fill_dot(row: HBoxContainer, i: int) -> void:
	if i >= 0 and i < row.get_child_count():
		(row.get_child(i) as ColorRect).color = Palette.PEACH


static func load_level(path: String, id: int) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	var levels: Array = parsed.get("levels", []) if parsed is Dictionary else []
	for l in levels:
		if int(l.get("id", 0)) == id:
			return l
	return levels[0] if not levels.is_empty() else {}


static func has_level(path: String, id: int) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return false
	for l in parsed.get("levels", []):
		if int(l.get("id", 0)) == id:
			return true
	return false


## "Šaunu!" card with replay, next and home.
## restart(id) starts the given level again on the same screen; endless() starts
## a new "Begalinis" round. id < 0 means the round just played was endless.
## After the last level the game is marked as finished and → leads to Begalinis.
static func well_done(screen: Control, path: String, id: int, restart: Callable,
		endless := Callable()) -> WellDone:
	var game := path.get_file().get_basename()
	var has_next := id < 0 or has_level(path, id + 1) or endless.is_valid()
	if id > 0:
		if has_level(path, id + 1):
			set_progress(game, {"level": id + 1})
		else:
			set_progress(game, {"done": true})
	var w := WellDone.make(has_next)
	w.replay.connect(func():
		w.queue_free()
		if id < 0: endless.call()
		else: restart.call(id))
	w.next.connect(func():
		w.queue_free()
		if id < 0 or not has_level(path, id + 1): endless.call()
		else: restart.call(id + 1))
	w.home.connect(func(): screen.get_tree().change_scene_to_file(GAMES))
	screen.add_child(w)
	return w


# --- Progress per game (user://progress.json): {game: {"level": n, "done": bool, …}} ---

const PROGRESS := "user://progress.json"


static func _all_progress() -> Dictionary:
	var f := FileAccess.open(PROGRESS, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func progress(game: String) -> Dictionary:
	var g = _all_progress().get(game, {})
	return g if g is Dictionary else {}


static func set_progress(game: String, changes: Dictionary) -> void:
	var all := _all_progress()
	var g: Dictionary = all.get(game, {}) if all.get(game) is Dictionary else {}
	g.merge(changes, true)
	all[game] = g
	var f := FileAccess.open(PROGRESS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(all))


static func saved_level(game: String) -> int:
	return maxi(int(progress(game).get("level", 1)), 1)


## How a game opens: a level given directly (forced > 0, e.g. tests) → that
## level; game finished before → the Lygiai / Begalinis choice; otherwise the
## level reached last time. on_level(id) and on_endless() start the game.
static func open_game(screen: Control, game: String, forced: int, on_level: Callable,
		on_endless: Callable, owl: Owl = null) -> void:
	if forced > 0:
		on_level.call(forced)
	elif bool(progress(game).get("done", false)):
		mode_picker(screen, "lygis %d" % saved_level(game), func(): on_level.call(saved_level(game)),
			on_endless, owl)
	else:
		on_level.call(saved_level(game))


## Two big tiles: "Lygiai" and "Begalinis" (unlimited rounds). Removes itself.
## Speaks the chosen mode: Sound.say("lygiai") / Sound.say("begalinis").
static func mode_picker(screen: Control, levels_note: String, on_levels: Callable,
		on_endless: Callable, owl: Owl = null) -> Control:
	var row := HBoxContainer.new()
	row.name = "ModePicker"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 96)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	# A soft cover so the (empty) game screen behind doesn't show through.
	var cover := ColorRect.new()
	cover.color = Palette.CANVAS
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(cover)
	screen.add_child(row)
	for m in [["Lygiai", Palette.LAVENDER, levels_note, on_levels, "lygiai"],
			["Begalinis", Palette.BUTTER, "be pabaigos", on_endless, "begalinis"]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 18)
		var t := ActivityTile.new().setup(m[0], ActivityTile.Icon.GAMES, m[1], true, Vector2(460, 414))
		var start: Callable = m[3]
		var spoken: String = m[4]
		t.pressed.connect(func():
			Sound.say(spoken)
			row.queue_free()
			cover.queue_free()
			if owl: owl.set_pose("idle")
			start.call())
		col.add_child(t)
		var note := Label.new()
		note.text = m[2]
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 34)
		note.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		col.add_child(note)
		row.add_child(col)
	# Keep the home button and Olis above the cover.
	for c in screen.get_children():
		if c is RoundButton or c is Owl:
			screen.move_child(c, -1)
	if owl:
		owl.react("point", 0.0)
	return row
