class_name Basket
extends Button
## Sorting basket: soft coloured box with a picture and a name.

var basket_name := ""
var words: Array = []
var accent := Palette.SAGE
var _icon: Texture2D
var _count := 0
var _highlight := false


func setup(name_: String, icon_word: String, words_: Array, accent_: Color) -> Basket:
	basket_name = name_
	words = words_
	accent = accent_
	_icon = WordBank.photo(icon_word)
	custom_minimum_size = Vector2(520, 360)
	flat = true
	focus_mode = Control.FOCUS_NONE
	return self


func accepts(word: String) -> bool:
	return word in words


func add_item() -> void:
	_count += 1
	queue_redraw()


func set_highlight(on: bool) -> void:
	_highlight = on
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	_box(Rect2(r.position + Vector2(0, 10), r.size), 56, Palette.SHADOW)
	var bg := accent.lerp(Color.WHITE, 0.55)
	_box(r, 56, bg, accent.darkened(0.1) if _highlight else accent, 10 if _highlight else 6)
	if _icon:
		var s := 150.0
		var ir := Rect2(Vector2((size.x - s) / 2.0, 36), Vector2(s, s))
		_box(ir.grow(8), 36, Palette.CARD)
		draw_texture_rect(_icon, ir, false)
	var font := get_theme_default_font()
	var fs := 48
	var tw := font.get_string_size(basket_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, 262), basket_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)
	# One small dot per sorted card.
	for i in _count:
		draw_circle(Vector2(size.x / 2.0 - (_count - 1) * 16 + i * 32, 312), 10, Palette.PEACH)


func _box(r: Rect2, radius: int, fill: Color, border := Color.TRANSPARENT, bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)
