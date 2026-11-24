class_name MemorySquare
extends Control
## One big coloured square for "Atmintis". It lights up (brighter, a soft glow,
## slightly bigger) while its note plays.

signal pressed

var color := Palette.SKY
var index := 0
var lit := false:
	set(v):
		lit = v
		queue_redraw()


func setup(index_: int, color_: Color, side: float) -> MemorySquare:
	index = index_
	color = color_
	size = Vector2(side, side)
	custom_minimum_size = size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		pressed.emit()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(size.x * 0.18)
	if lit:
		# Soft halo around the lit square.
		for k in 4:
			_box(r.grow(8 + k * 10), radius + 10 + k * 10, Color(color.darkened(0.05), 0.42 - k * 0.1))
	else:
		_box(Rect2(r.position + Vector2(0, 10), r.size), radius, Palette.SHADOW)
	# Idle squares are muted; a lit square shows its full colour with a white rim.
	var fill := color.darkened(0.04) if lit else color.lerp(Palette.CANVAS, 0.5)
	_box(r, radius, fill, Color.WHITE if lit else color.lerp(Palette.CANVAS, 0.2), 12 if lit else 5)


func _box(r: Rect2, radius: int, fill: Color, border := Color.TRANSPARENT, bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)
