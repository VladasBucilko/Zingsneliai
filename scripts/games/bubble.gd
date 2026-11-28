class_name Bubble
extends Node2D
## One floating bubble. Rises slowly, sways gently, pops softly when tapped.

signal escaped(bubble: Bubble)
signal popped(bubble: Bubble)

const POP_TIME := 0.35

var radius := 120.0
var speed := 60.0
var tint := Palette.SKY
var sway := 20.0
var sway_hz := 0.2
var phase := 0.0
var spec := {}
var whiten := 0.85          # how pale the centre gets (colour mode keeps more colour)
var color_id := 0

var _base_x := 0.0
var _t := 0.0
var _pop_t := -1.0
var _spawn_t := 0.0
var _reduce_motion := false
var _shake := 0.0


func setup(spec_: Dictionary, x_px: float, y_px: float, reduce_motion: bool) -> Bubble:
	spec = spec_
	radius = spec.radius
	speed = spec.speed * (0.7 if reduce_motion else 1.0)
	color_id = int(spec.color)
	tint = spec.get("tint", Palette.ACCENTS[color_id % Palette.ACCENTS.size()])
	whiten = spec.get("whiten", 0.85)
	sway = 0.0 if reduce_motion else spec.sway
	sway_hz = spec.sway_hz
	phase = spec.phase
	_reduce_motion = reduce_motion
	_base_x = x_px
	position = Vector2(x_px, y_px)
	return self


func is_popping() -> bool:
	return _pop_t >= 0.0


## Generous hit area: small fingers miss a little.
func hit(p: Vector2) -> bool:
	return not is_popping() and p.distance_to(position) <= radius * 1.15


## A small side-to-side shake: "not this one".
func nudge() -> void:
	if not _reduce_motion:
		_shake = 1.0


func pop() -> void:
	if is_popping():
		return
	_pop_t = 0.0
	popped.emit(self)


func _process(delta: float) -> void:
	if is_popping():
		_pop_t += delta
		if _pop_t >= POP_TIME:
			queue_free()
		queue_redraw()
		return
	_t += delta
	_spawn_t = minf(_spawn_t + delta * 3.0, 1.0)
	position.y -= speed * delta
	position.x = _base_x + sin(_t * TAU * sway_hz + phase) * sway
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 3.0, 0.0)
		position.x += sin(_shake * 40.0) * 14.0 * _shake
	if position.y < -radius * 1.2:
		escaped.emit(self)
		queue_free()
	queue_redraw()


func _draw() -> void:
	if is_popping():
		_draw_pop(_pop_t / POP_TIME)
		return
	var r := radius * (0.6 + 0.4 * _ease_out(_spawn_t))
	# Soft body: stacked circles from rim colour to a pale centre.
	var steps := 14
	for i in steps:
		var k := float(i) / float(steps - 1) # 0 = outer, 1 = inner
		var col := tint.lerp(Color.WHITE, k * whiten)
		col.a = lerpf(0.85, 0.95, k)
		draw_circle(Vector2(-r * 0.12, -r * 0.12) * k, r * (1.0 - k * 0.85), col)
	draw_arc(Vector2.ZERO, r - 2.0, 0, TAU, 72, Color(1, 1, 1, 0.9), 4.0, true)
	# Shine
	draw_set_transform(Vector2(-r * 0.42, -r * 0.5), -0.5, Vector2(1.0, 0.62))
	draw_circle(Vector2.ZERO, r * 0.16, Color(1, 1, 1, 0.85))
	draw_set_transform(Vector2.ZERO)


func _draw_pop(k: float) -> void:
	var fade := 1.0 - k
	if _reduce_motion:
		var col := tint.lerp(Color.WHITE, 0.5)
		col.a = fade * 0.8
		draw_circle(Vector2.ZERO, radius, col)
		return
	var e := _ease_out(k)
	var ring := tint
	ring.a = fade * 0.8
	draw_arc(Vector2.ZERO, radius * (1.0 + 0.25 * e), 0, TAU, 72, ring, 6.0 * fade + 1.0, true)
	var dot := Palette.PEACH
	dot.a = fade
	for i in 8:
		var a := TAU * i / 8.0 + phase
		draw_circle(Vector2.from_angle(a) * radius * (0.9 + 0.6 * e), 9.0 * fade + 2.0, dot)


func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)
