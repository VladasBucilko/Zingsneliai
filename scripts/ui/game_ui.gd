class_name GameUI
## Shared bits for game screens: home button, speaker button, title, progress dots.


static func add_home(screen: Control) -> RoundButton:
	var b := RoundButton.new(RoundButton.Kind.HOME)
	b.position = Vector2(64, 56)
	b.pressed.connect(func(): screen.get_tree().change_scene_to_file("res://scenes/main.tscn"))
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
