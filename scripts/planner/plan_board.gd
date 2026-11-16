class_name PlanBoard
extends Control
## The magnetic board: soft slate surface, numbered dashed spaces with small
## arrows between them so the order (first → then) is clear.

const BOARD := Color("#E6EBE8")
const BOARD_EDGE := Color("#CFD8D3")

var slot_count := 6:
	set(v):
		slot_count = v
		queue_redraw()
var slot_size := Vector2(220, 300)
var gap := 40.0
var highlight := -1:
	set(v):
		highlight = v
		queue_redraw()


## Slot rectangles in this control's local coordinates.
func slot_rect(i: int) -> Rect2:
	var total := slot_count * slot_size.x + (slot_count - 1) * gap
	var x0 := (size.x - total) / 2.0
	return Rect2(Vector2(x0 + i * (slot_size.x + gap), 96), slot_size)


func slot_at(global_point: Vector2) -> int:
	var p := global_point - global_position
	for i in slot_count:
		if slot_rect(i).grow(gap * 0.5).has_point(p):
			return i
	return -1


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BOARD
	sb.border_color = BOARD_EDGE
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(40)
	sb.shadow_color = Palette.SHADOW
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	sb.anti_aliasing = true
	draw_style_box(sb, r)
	# Faint dot texture, like a magnetic whiteboard.
	var dot := Color(Palette.TEXT, 0.05)
	for y in range(30, int(size.y) - 20, 28):
		for x in range(30, int(size.x) - 20, 28):
			draw_circle(Vector2(x, y), 1.6, dot)
	var font := get_theme_default_font()
	for i in slot_count:
		var s := slot_rect(i)
		var on := i == highlight
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.75 if on else 0.35)
		box.set_corner_radius_all(22)
		box.anti_aliasing = true
		draw_style_box(box, s)
		_dashed_rect(s, Color(Palette.TEXT if on else Palette.TEXT_MUTED, 0.5), 3.0)
		# Number badge above the slot
		var c := Vector2(s.get_center().x, 50)
		draw_circle(c, 26, Palette.CARD)
		var n := str(i + 1)
		var tw := font.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, c + Vector2(-tw / 2.0, 11), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.TEXT)
		# Arrow to the next slot
		if i < slot_count - 1:
			var a := Vector2(s.end.x + gap * 0.5, s.get_center().y)
			draw_polyline(PackedVector2Array([a + Vector2(-7, -11), a + Vector2(5, 0), a + Vector2(-7, 11)]),
				Color(Palette.TEXT_MUTED, 0.7), 4.0, true)


func _dashed_rect(r: Rect2, col: Color, w: float) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		draw_dashed_line(pts[k], pts[(k + 1) % 4], col, w, 14.0, true)
