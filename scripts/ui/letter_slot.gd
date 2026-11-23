class_name LetterSlot
extends Control
## An empty letter box ("_") under a clue picture. Glows softly when filled.

var expected := ""
var filled := false:
	set(v):
		filled = v
		queue_redraw()
var highlight := false:
	set(v):
		highlight = v
		queue_redraw()


func setup(expected_: String, slot_size: Vector2) -> LetterSlot:
	expected = expected_.to_upper()
	size = slot_size
	custom_minimum_size = slot_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.SUCCESS if filled else Color(1, 1, 1, 0.75 if highlight else 0.45)
	sb.set_corner_radius_all(int(size.x * 0.2))
	sb.anti_aliasing = true
	draw_style_box(sb, r)
	if not filled:
		var col := Color(Palette.TEXT if highlight else Palette.TEXT_MUTED, 0.6)
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for k in 4:
			draw_dashed_line(pts[k], pts[(k + 1) % 4], col, 3.0, 12.0, true)
		# The "_" line the letter goes on
		var y := size.y * 0.78
		draw_line(Vector2(size.x * 0.25, y), Vector2(size.x * 0.75, y), Color(Palette.TEXT, 0.35), 6.0, true)
