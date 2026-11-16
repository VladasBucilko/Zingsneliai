class_name ActivityTile
extends Button
## Home-screen activity tile (matches Figma "ActivityTile").

enum Icon { BUBBLES, MATCHING, SORTING, FIND, PUZZLE, SOUND, GAMES, PLAN }

var label_text := ""
var icon_kind: Icon = Icon.BUBBLES
var accent := Palette.SKY
var available := true


func setup(text_: String, icon_: Icon, accent_: Color, available_: bool, tile_size := Vector2(400, 360)) -> ActivityTile:
	label_text = text_
	icon_kind = icon_
	accent = accent_
	available = available_
	custom_minimum_size = tile_size
	flat = true
	focus_mode = Control.FOCUS_NONE
	disabled = not available
	modulate.a = 1.0 if available else 0.45
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	_round_rect(Rect2(r.position + Vector2(0, 10), r.size), 56, Palette.SHADOW)
	_round_rect(r, 56, Palette.CARD.darkened(0.03) if button_pressed else Palette.CARD)
	var k := size.y / 360.0  # scale everything with the tile height
	var c := Vector2(size.x / 2.0, 160.0 * k)
	draw_circle(c, 90.0 * k, accent)
	_draw_icon(c, 112.0 / 24.0 * k)
	var font := get_theme_default_font()
	var fs := int(44 * k)
	var tw := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, 318.0 * k), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)


func _round_rect(r: Rect2, radius: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func _draw_icon(c: Vector2, s: float) -> void:
	var o := c - Vector2(12, 12) * s
	var w := 1.8 * s
	var col := Palette.TEXT
	match icon_kind:
		Icon.BUBBLES:
			draw_arc(o + Vector2(9, 13) * s, 5.5 * s, 0, TAU, 48, col, w, true)
			draw_arc(o + Vector2(17, 8) * s, 3.5 * s, 0, TAU, 32, col, w, true)
			draw_arc(o + Vector2(17.5, 17) * s, 2.2 * s, 0, TAU, 24, col, w, true)
		Icon.MATCHING:
			draw_rect(Rect2(o + Vector2(3, 5) * s, Vector2(8, 11) * s), col, false, w)
			draw_rect(Rect2(o + Vector2(13, 8) * s, Vector2(8, 11) * s), col, false, w)
		Icon.SORTING:
			draw_rect(Rect2(o + Vector2(4, 14) * s, Vector2(7, 6) * s), col, false, w)
			draw_rect(Rect2(o + Vector2(13, 14) * s, Vector2(7, 6) * s), col, false, w)
			draw_arc(o + Vector2(7.5, 7) * s, 2.5 * s, 0, TAU, 24, col, w, true)
		Icon.FIND:
			draw_arc(o + Vector2(10.5, 10.5) * s, 6 * s, 0, TAU, 48, col, w, true)
			draw_line(o + Vector2(15, 15) * s, o + Vector2(20, 20) * s, col, w, true)
		Icon.PUZZLE:
			draw_rect(Rect2(o + Vector2(5, 5) * s, Vector2(14, 14) * s), col, false, w)
		Icon.GAMES:
			# Three toy shapes: circle, triangle, square ("play")
			draw_arc(o + Vector2(7.5, 8) * s, 4.5 * s, 0, TAU, 40, col, w, true)
			draw_polyline(PackedVector2Array([o + Vector2(16.5, 3.5) * s, o + Vector2(21.5, 12) * s,
				o + Vector2(11.5, 12) * s, o + Vector2(16.5, 3.5) * s]), col, w, true)
			draw_rect(Rect2(o + Vector2(8, 14.5) * s, Vector2(8, 7) * s), col, false, w)
		Icon.PLAN:
			# board with three cards in a row
			draw_rect(Rect2(o + Vector2(2, 5) * s, Vector2(20, 14) * s), col, false, w)
			for i in 3:
				draw_rect(Rect2(o + Vector2(4.5 + i * 5.5, 8.5) * s, Vector2(4, 7) * s), col, false, w * 0.8)
		Icon.SOUND:
			draw_rect(Rect2(o + Vector2(9, 3) * s, Vector2(6, 11) * s), col, false, w)
			draw_arc(o + Vector2(12, 11) * s, 6 * s, 0, PI, 24, col, w, true)
