class_name StageTile
extends Button
## A stage card on the "Raidės" stage-choice screen: number, a big "Aa" sample
## in the stage's letter style, the stage name and progress. Locked stages are
## faded with a small padlock.

const CURSIVE_FONT := preload("res://assets/fonts/PlaywriteHR-Regular.ttf")

var stage := 1
var title := ""
var progress := ""
var locked := false
var accent := Palette.SKY


func setup(stage_: int, title_: String, progress_: String, locked_: bool, accent_: Color,
		tile_size := Vector2(300, 430)) -> StageTile:
	stage = stage_
	title = title_
	progress = progress_
	locked = locked_
	accent = accent_
	custom_minimum_size = tile_size
	flat = true
	focus_mode = Control.FOCUS_NONE
	disabled = locked
	modulate.a = 0.5 if locked else 1.0
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	_box(Rect2(r.position + Vector2(0, 10), r.size), 48, Palette.SHADOW)
	_box(r, 48, Palette.CARD.darkened(0.03) if button_pressed else Palette.CARD)
	var printed := get_theme_default_font()
	# Stage number badge
	var b := Vector2(46, 46)
	draw_circle(b, 26, accent)
	_text(printed, str(stage), b + Vector2(0, 11), 30)
	# "Aa" sample in the stage's style
	var c := Vector2(size.x / 2.0, 150)
	draw_circle(c, 84, accent.lerp(Color.WHITE, 0.45))
	match stage:
		1:
			_text(printed, "Aa", c + Vector2(0, 26), 76)
		2:
			_text(CURSIVE_FONT, "Aa", c + Vector2(0, 20), 58)
		3:
			_text(printed, "A", c + Vector2(-30, 4), 56)
			_text(printed, "a", c + Vector2(32, 44), 56)
		4:
			_text(CURSIVE_FONT, "A", c + Vector2(-30, 0), 46)
			_text(CURSIVE_FONT, "a", c + Vector2(32, 40), 46)
		5:
			_text(printed, "A", c + Vector2(-26, 24), 70)
			_text(CURSIVE_FONT, "a", c + Vector2(30, 22), 50)
	# Name (may wrap to two lines) and progress
	draw_multiline_string(printed, Vector2(16, 290), title, HORIZONTAL_ALIGNMENT_CENTER,
		size.x - 32, 32, 2, Palette.TEXT)   # up to two lines: ~290–370
	if locked:
		_padlock(Vector2(size.x / 2.0, size.y - 30))
	elif progress != "":
		_text(printed, progress, Vector2(size.x / 2.0, size.y - 20), 26, Palette.TEXT_MUTED)


func _text(font: Font, s: String, center_baseline: Vector2, fs: int, col := Palette.TEXT) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, center_baseline - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _padlock(c: Vector2) -> void:
	var col := Palette.TEXT_MUTED
	draw_arc(c + Vector2(0, -6), 10, PI, TAU, 16, col, 4.0, true)
	draw_rect(Rect2(c + Vector2(-15, -6), Vector2(30, 22)), col)


func _box(r: Rect2, radius: int, fill: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	draw_style_box(sb, r)
