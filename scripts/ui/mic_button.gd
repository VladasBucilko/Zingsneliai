class_name MicButton
extends Button
## Big round microphone button. A soft ring grows with the child's voice.

const SIZE := 200.0

var level := 0.0:  # 0..1, how loud the microphone hears right now
	set(v):
		level = clampf(v, 0.0, 1.0)
		queue_redraw()
var listening := false:
	set(v):
		listening = v
		queue_redraw()

var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE) + Vector2(80, 80)
	flat = true
	focus_mode = Control.FOCUS_NONE


func _process(delta: float) -> void:
	if listening and not Settings.reduce_motion:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := SIZE / 2.0
	if listening:
		var breathe := 0.0 if Settings.reduce_motion else (sin(_t * 2.0) * 0.5 + 0.5) * 6.0
		var ring := Palette.ROSE
		ring.a = 0.45
		draw_circle(c, r + 10.0 + breathe + level * 36.0, ring)
	draw_circle(c + Vector2(0, 8), r, Palette.SHADOW)
	draw_circle(c, r, Palette.CARD if not listening else Palette.ROSE.lerp(Color.WHITE, 0.4))
	draw_arc(c, r - 2.0, 0, TAU, 72, Palette.LINE, 4.0, true)
	# Microphone icon on a 24-unit grid.
	var s := 96.0 / 24.0
	var o := c - Vector2(12, 12) * s
	var w := 2.0 * s
	var col := Palette.TEXT
	var body := Rect2(o + Vector2(9, 3) * s, Vector2(6, 11) * s)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = col
	sb.set_border_width_all(int(w))
	sb.set_corner_radius_all(int(3 * s))
	sb.anti_aliasing = true
	draw_style_box(sb, body)
	draw_arc(o + Vector2(12, 11) * s, 6.0 * s, 0.0, PI, 24, col, w, true)
	draw_line(o + Vector2(12, 17) * s, o + Vector2(12, 21) * s, col, w, true)
