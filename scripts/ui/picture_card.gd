class_name PictureCard
extends Button
## Photo + word card (matches Figma "PictureCard"). Tap = select + speak.

enum State { DEFAULT, SELECTED, MATCHED }

const CARD_SIZE := Vector2(300, 360)
const RADIUS := 40
const PHOTO_RADIUS := 28
const PAD := 20.0

var word := ""
var show_word := true
var state: State = State.DEFAULT:
	set(v):
		state = v
		queue_redraw()

var _tex: Texture2D
var _fallback := Palette.BUTTER
var _photo: TextureRect


func setup(word_: String, fallback_: Color, show_word_ := true) -> PictureCard:
	word = word_
	show_word = show_word_
	_fallback = fallback_
	_tex = WordBank.photo(word)
	custom_minimum_size = CARD_SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	pivot_offset = CARD_SIZE / 2.0
	if _tex:
		_photo = TextureRect.new()
		_photo.texture = _tex
		_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/rounded.gdshader")
		mat.set_shader_parameter("radius_px", float(PHOTO_RADIUS))
		_photo.material = mat
		add_child(_photo)
	return self


func _photo_rect() -> Rect2:
	var h := size.y - PAD * 2.0 - (64.0 if show_word else 0.0)
	return Rect2(Vector2(PAD, PAD), Vector2(size.x - PAD * 2.0, h))


func _process(_d: float) -> void:
	if _photo:
		var r := _photo_rect()
		_photo.position = r.position
		_photo.size = r.size
		(_photo.material as ShaderMaterial).set_shader_parameter("size_px", r.size)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	_box(Rect2(r.position + Vector2(0, 8), r.size), RADIUS, Palette.SHADOW)
	var border := Palette.LINE
	var bw := 4
	match state:
		State.SELECTED:
			border = Palette.SKY
			bw = 10
		State.MATCHED:
			border = Palette.SUCCESS.darkened(0.05)
			bw = 10
	_box(r, RADIUS, Palette.CARD, border, bw)
	if _tex == null:
		_box(_photo_rect(), PHOTO_RADIUS, _fallback)
	if show_word:
		var font := get_theme_default_font()
		var fs := 44
		var tw := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((size.x - tw) / 2.0, size.y - PAD - 12), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)


func _box(r: Rect2, radius: int, fill: Color, border := Color.TRANSPARENT, bw := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)


## Gentle "not this one" nudge. No sound, no red.
func nudge() -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	for dx in [-10.0, 10.0, -6.0, 0.0]:
		t.tween_property(self, "rotation_degrees", dx * 0.3, 0.07)


func celebrate() -> void:
	if Settings.reduce_motion:
		return
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.06, 1.06), 0.18).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_SINE)
