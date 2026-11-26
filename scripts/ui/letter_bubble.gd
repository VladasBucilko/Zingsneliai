class_name LetterBubble
extends Control
## A round, soft letter piece for "Raidės": one capital or small letter,
## printed (Nunito) or cursive (Playwrite HR school script). The letter is
## scaled so tall cursive loops always fit inside the circle.

const CURSIVE_FONT := preload("res://assets/fonts/PlaywriteHR-Regular.ttf")

var letter := ""          # exactly as shown ("A" or "a")
var key := ""             # the pair it belongs to (upper case); "" = no partner
var capital := true
var cursive := false
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var done := false:
	set(v):
		done = v
		queue_redraw()
var accent := Palette.SKY  # colour once matched


func setup(letter_: String, key_: String, capital_: bool, cursive_: bool, diameter: float) -> LetterBubble:
	letter = letter_
	key = key_
	capital = capital_
	cursive = cursive_
	size = Vector2(diameter, diameter)
	custom_minimum_size = size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


func center_global() -> Vector2:
	return global_position + size / 2.0


func _draw() -> void:
	var c := size / 2.0
	var r := size.x / 2.0
	draw_circle(c + Vector2(0, 6), r, Palette.SHADOW)
	var fill := accent.lerp(Color.WHITE, 0.35) if done else Palette.CARD
	draw_circle(c, r, fill)
	var ring := Palette.TEXT if selected else (accent.darkened(0.1) if done else Palette.LINE)
	draw_arc(c, r - 3, 0, TAU, 64, ring, 8.0 if selected else 5.0, true)

	var font: Font = CURSIVE_FONT if cursive else get_theme_default_font()
	# Find a size where the drawn letter (ink, not the line box) fits ~62 % of the circle.
	var fs := int(size.y * (0.52 if cursive else 0.6))
	var box := _ink_size(font, fs)
	var limit := size.x * 0.62
	if box.x > limit or box.y > limit:
		fs = int(fs * minf(limit / maxf(box.x, 1.0), limit / maxf(box.y, 1.0)))
	var ts := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	# Centre the text line box vertically around the circle's centre.
	var base := c.y + (asc - desc) / 2.0
	draw_string(font, Vector2(c.x - ts.x / 2.0, base), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.TEXT)


## Rough ink size: width from the string, height from ascent+descent for
## cursive (loops reach far up and down), cap height otherwise.
func _ink_size(font: Font, fs: int) -> Vector2:
	var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h := (font.get_ascent(fs) + font.get_descent(fs)) * (0.8 if cursive else 0.75)
	return Vector2(w, h)
