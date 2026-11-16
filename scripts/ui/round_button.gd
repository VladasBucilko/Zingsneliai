class_name RoundButton
extends Button
## 112px round control with a drawn icon (matches Figma "IconButton").

enum Kind { HOME, SPEAKER, LOCK, REPLAY, NEXT, QUIT }

@export var kind: Kind = Kind.HOME

const SIZE := 112.0


func _init(k: Kind = Kind.HOME) -> void:
	kind = k
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _draw() -> void:
	var c := size / 2.0
	var r := SIZE / 2.0
	draw_circle(c + Vector2(0, 6), r, Palette.SHADOW)
	var fill := Palette.CARD.darkened(0.04) if is_pressed() or button_pressed else Palette.CARD
	draw_circle(c, r, fill)
	draw_arc(c, r - 1.5, 0, TAU, 64, Palette.LINE, 3.0, true)
	var s := 56.0 / 24.0 # icon drawn on a 24-unit grid, 56px on screen
	var o := c - Vector2(12, 12) * s
	var w := 2.2 * s
	var col := Palette.TEXT
	match kind:
		Kind.HOME:
			var pts := PackedVector2Array([Vector2(4, 11), Vector2(12, 4), Vector2(20, 11), Vector2(20, 20),
				Vector2(15, 20), Vector2(15, 14), Vector2(9, 14), Vector2(9, 20), Vector2(4, 20), Vector2(4, 11)])
			draw_polyline(_xf(pts, o, s), col, w, true)
		Kind.SPEAKER:
			var pts := PackedVector2Array([Vector2(4, 9), Vector2(8, 9), Vector2(13, 5), Vector2(13, 19),
				Vector2(8, 15), Vector2(4, 15), Vector2(4, 9)])
			draw_polyline(_xf(pts, o, s), col, w, true)
			draw_arc(o + Vector2(13, 12) * s, 4.0 * s, -0.9, 0.9, 16, col, w, true)
			draw_arc(o + Vector2(13, 12) * s, 7.5 * s, -0.9, 0.9, 20, col, w, true)
		Kind.LOCK:
			draw_rect(Rect2(o + Vector2(5, 10.5) * s, Vector2(14, 10) * s), col, false, w)
			draw_arc(o + Vector2(12, 8.5) * s, 4.0 * s, PI, TAU, 16, col, w, true)
		Kind.REPLAY:
			draw_arc(o + Vector2(12, 12) * s, 7.0 * s, -PI * 0.35, PI * 1.45, 32, col, w, true)
			var tip := o + Vector2(12, 12) * s + Vector2.from_angle(-PI * 0.35) * 7.0 * s
			draw_polyline(PackedVector2Array([tip + Vector2(-5, -6) * s * 0.6, tip, tip + Vector2(-7, 3) * s * 0.6]), col, w, true)
		Kind.QUIT:
			# Power symbol: open ring + vertical bar.
			draw_arc(o + Vector2(12, 13) * s, 7.0 * s, -PI * 0.3, PI * 1.3, 32, col, w, true)
			draw_line(o + Vector2(12, 3.5) * s, o + Vector2(12, 11) * s, col, w, true)
		Kind.NEXT:
			draw_polyline(_xf(PackedVector2Array([Vector2(5, 12), Vector2(19, 12)]), o, s), col, w, true)
			draw_polyline(_xf(PackedVector2Array([Vector2(13, 6), Vector2(19, 12), Vector2(13, 18)]), o, s), col, w, true)


func _xf(pts: PackedVector2Array, o: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(o + p * s)
	return out
