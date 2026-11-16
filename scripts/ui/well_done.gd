class_name WellDone
extends Control
## Calm end-of-level card: "Šaunu!" + replay / (next) / home. No scores.

signal replay
signal next
signal home


static func make(show_next: bool) -> WellDone:
	var w := WellDone.new()
	w._build(show_next)
	return w


func _build(show_next: bool) -> void:
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

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 48)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)

	var title := Label.new()
	title.text = "Šaunu!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Palette.TEXT)
	col.add_child(title)

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
	Sound.say("šaunu")
