class_name PlanCard
extends Control
## A picture "magnet" for the planner: small rounded card, picture, word,
## and a little magnet dot on top. Draws itself at any size.

var word := ""
var label := ""
var accent := Palette.PEACH
var _tex: Texture2D


func setup(word_: String, label_: String, accent_: Color, card_size: Vector2) -> PlanCard:
	word = word_
	label = label_
	accent = accent_
	_tex = WordBank.photo(word)
	size = card_size
	pivot_offset = card_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	return self


func _on_resized() -> void:
	pivot_offset = size / 2.0
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(clampf(size.x * 0.1, 10, 24))
	_box(Rect2(r.position + Vector2(0, 6), r.size), radius, Palette.SHADOW)
	_box(r, radius, Palette.CARD, Palette.LINE, 3)
	var pad := size.x * 0.07
	var font_size := int(clampf(size.y * 0.1, 18, 32))
	var label_h := font_size * 1.5
	var img := Rect2(Vector2(pad, pad + 8), Vector2(size.x - pad * 2, size.y - pad * 2 - label_h - 8))
	if _tex:
		var side := minf(img.size.x, img.size.y)
		var sq := Rect2(img.position + (img.size - Vector2(side, side)) / 2.0, Vector2(side, side))
		draw_texture_rect(_tex, sq, false)
	else:
		_box(img, 12, accent.lerp(Color.WHITE, 0.4))
	var font := get_theme_default_font()
	var fs := font_size
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	while tw > size.x - pad * 2 and fs > 14:  # long labels shrink to fit
		fs -= 1
		tw = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, size.y - pad - font_size * 0.35), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)
	# Magnet dot
	var m := Vector2(size.x / 2.0, 2)
	draw_circle(m + Vector2(0, 2), 11, Palette.SHADOW)
	draw_circle(m, 11, accent)
	draw_circle(m + Vector2(-3, -3), 3.5, Color(1, 1, 1, 0.7))


func _box(r: Rect2, radius: int, fill: Color, border := Color.TRANSPARENT, bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)
