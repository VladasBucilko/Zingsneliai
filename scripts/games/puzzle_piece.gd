class_name PuzzlePiece
extends Control
## One rectangular piece of a picture. Drag it near its place and it snaps in.

signal placed(piece: PuzzlePiece)

const SNAP_DISTANCE := 110.0

var texture: Texture2D
var region := Rect2()        # part of the texture this piece shows
var target := Vector2.ZERO   # local position (in parent) where it belongs
var home := Vector2.ZERO     # where it waits
var locked := false

var _dragging := false
var _offset := Vector2.ZERO


func setup(tex: Texture2D, region_: Rect2, piece_size: Vector2, target_: Vector2, home_: Vector2) -> PuzzlePiece:
	texture = tex
	region = region_
	size = piece_size
	custom_minimum_size = piece_size
	target = target_
	home = home_
	position = home_
	pivot_offset = piece_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_offset = event.global_position - global_position
			z_index = 10
			scale = Vector2(1.04, 1.04)
		elif _dragging:
			_dragging = false
			z_index = 0
			scale = Vector2.ONE
			_drop()
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		global_position = event.global_position - _offset
		accept_event()


func _drop() -> void:
	if position.distance_to(target) <= SNAP_DISTANCE:
		locked = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		create_tween().tween_property(self, "position", target, 0.18).set_trans(Tween.TRANS_SINE)
		Sound.sfx("pop", 0.8)
		placed.emit(self)
	else:
		create_tween().tween_property(self, "position", home, 0.3).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if not locked:
		draw_rect(Rect2(r.position + Vector2(0, 8), r.size), Palette.SHADOW)
	draw_texture_rect_region(texture, r, region)
	draw_rect(r, Palette.CARD, false, 4.0)
