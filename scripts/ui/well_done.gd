class_name WellDone
extends Control
## Calm end-of-level card: Olis cheering, "Šaunu!" + replay / (next) / home. No scores.

signal replay
signal next
signal home


## note: an optional calm line under "Šaunu!" (e.g. how many squares were remembered).
## title / pose / spoken: for the calm "try again" card in Spalvos
## ("Beveik!", Olis thinking, Sound.say("beveik")). Normally Sound.say("šaunu").
static func make(show_next: bool, note := "", title_text := "Šaunu!", pose := "cheer",
		spoken := "šaunu") -> WellDone:
	var w := WellDone.new()
	w._build(show_next, note, title_text, pose, spoken)
	return w


func _build(show_next: bool, note := "", title_text := "Šaunu!", pose := "cheer",
		spoken := "šaunu") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Palette.CANVAS, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.CARD
	sb.set_corner_radius_all(56)
	sb.shadow_color = Palette.SHADOW
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 10)
	sb.content_margin_left = 96
	sb.content_margin_right = 96
	sb.content_margin_top = 64
	sb.content_margin_bottom = 64
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(card)

	# Olis cheers next to "Šaunu!".
	var row_all := HBoxContainer.new()
	row_all.add_theme_constant_override("separation", 56)
	row_all.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row_all)
	var olis := Owl.new().setup(330, pose)
	olis.say_on_tap = ""
	row_all.add_child(olis)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 48)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row_all.add_child(col)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Palette.TEXT)
	col.add_child(title)
	if note != "":
		var sub := Label.new()
		sub.text = note
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 44)
		sub.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		col.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	col.add_child(row)
	var b_replay := RoundButton.new(RoundButton.Kind.REPLAY)
	b_replay.pressed.connect(func(): replay.emit())
	row.add_child(b_replay)
	if show_next:
		var b_next := RoundButton.new(RoundButton.Kind.NEXT)
		b_next.pressed.connect(func(): next.emit())
		row.add_child(b_next)
	var b_home := RoundButton.new(RoundButton.Kind.HOME)
	b_home.pressed.connect(func(): home.emit())
	row.add_child(b_home)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)
	Sound.sfx("chime")
	Sound.say(spoken)
