class_name LetterTile
extends Control
## A big, soft letter block the child can drag (or tap, then tap a box).

var letter := ""
var accent := Palette.SKY
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var locked := false
var home := Vector2.ZERO


func setup(letter_: String, accent_: Color, tile_size: Vector2) -> LetterTile:
	letter = letter_.to_upper()
	accent = accent_
	size = tile_size
	custom_minimum_size = tile_size
	pivot_offset = tile_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(size.x * 0.22)
	if not locked:
		_box(Rect2(r.position + Vector2(0, 7), r.size), radius, Palette.SHADOW)
	var fill := accent.lerp(Color.WHITE, 0.35)
	_box(r, radius, fill, Palette.TEXT if selected else accent.darkened(0.08), 8 if selected else 4)
	var font := get_theme_default_font()
	var fs := int(size.y * 0.62)
	var ts := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var asc := font.get_ascent(fs)
	draw_string(font, Vector2((size.x - ts.x) / 2.0, (size.y + asc * 0.72) / 2.0), letter,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)


func _box(r: Rect2, radius: int, fill: Color, border := Color.TRANSPARENT, bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)
