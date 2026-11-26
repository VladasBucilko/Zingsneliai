class_name Owl
extends Control
## Olis the owl, the child's companion. Sits on the left of a screen with a
## soft shadow, breathes gently, and reacts with short poses that return to
## his calm pose by themselves:
##   happy()  thumbs up   – a correct answer
##   oops()   thinking    – after a wrong try (never sad, never "no")
##   listen() wing at ear – while the game is speaking / showing
##   cheer()  wings up    – level done
##   wave()   waving      – hello; also when the child taps him
## Tapping Olis makes him wave and say hello.

const POSES := {
	"idle": "res://assets/characters/owl.png",
	"wave": "res://assets/characters/owl_wave.png",
	"happy": "res://assets/characters/owl_thumbs_up.png",
	"point": "res://assets/characters/owl_point.png",
	"cheer": "res://assets/characters/owl_cheer.png",
	"think": "res://assets/characters/owl_think.png",
	"listen": "res://assets/characters/owl_listen.png",
	"read": "res://assets/characters/owl_read.png",
	"sleepy": "res://assets/characters/owl_sleepy.png",
}
const SIDE_MARGIN := 24.0
const BOTTOM_MARGIN := 20.0

## The area Olis takes in the bottom-left corner at the in-game size; game
## layouts keep their content out of this rectangle.
static func corner_rect(screen_size: Vector2, height := 230.0) -> Rect2:
	var w := height * 0.86
	return Rect2(Vector2(SIDE_MARGIN, screen_size.y - BOTTOM_MARGIN - height), Vector2(w, height))

var pose := "idle"
var say_on_tap := "labas aš olis"
var _textures := {}
var _back: SceneTreeTimer
var _bob: Tween
var _sprite: TextureRect


## height = how tall Olis is drawn. Put him in place with position/anchors.
func setup(height := 230.0, start_pose := "idle") -> Owl:
	custom_minimum_size = Vector2(height * 0.86, height)
	size = custom_minimum_size
	pivot_offset = Vector2(size.x / 2.0, size.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_SHRINK_CENTER   # don't stretch inside rows
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sprite = TextureRect.new()
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite.offset_bottom = -height * 0.04   # room for the shadow
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	set_pose(start_pose)
	resized.connect(func(): pivot_offset = Vector2(size.x / 2.0, size.y))
	return self


## Bottom-left corner of a game screen, at the standard in-game size.
static func add_to_corner(screen: Control, height := 230.0) -> Owl:
	var o := Owl.new().setup(height)
	o.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	o.offset_left = SIDE_MARGIN
	o.offset_right = SIDE_MARGIN + o.size.x
	o.offset_top = -BOTTOM_MARGIN - height
	o.offset_bottom = -BOTTOM_MARGIN
	screen.add_child(o)
	return o


func _ready() -> void:
	if not Settings.reduce_motion:
		_bob = create_tween().set_loops()
		_bob.tween_property(_sprite, "position:y", -4.0, 1.6).set_trans(Tween.TRANS_SINE)
		_bob.tween_property(_sprite, "position:y", 0.0, 1.6).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	# Soft round shadow under his feet.
	var c := Vector2(size.x / 2.0, size.y - size.y * 0.035)
	for k in 3:
		var r := Vector2(size.x * (0.30 - k * 0.05), size.y * (0.03 - k * 0.006))
		_ellipse(c, r, Color(Palette.SHADOW, 0.10 + k * 0.05))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		pts.append(c + Vector2(cos(t) * r.x, sin(t) * r.y))
	draw_colored_polygon(pts, col)


func set_pose(p: String) -> void:
	if not POSES.has(p):
		p = "idle"
	pose = p
	if not _textures.has(p):
		_textures[p] = load(POSES[p])
	_sprite.texture = _textures[p]


## Show a pose, then go back to the calm pose after `secs` (0 = stay).
func react(p: String, secs := 1.6) -> void:
	set_pose(p)
	if not Settings.reduce_motion:
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(1.06, 0.95), 0.08)
		t.tween_property(self, "scale", Vector2(0.98, 1.03), 0.1)
		t.tween_property(self, "scale", Vector2.ONE, 0.12)
	if secs > 0.0:
		var timer := get_tree().create_timer(secs)
		_back = timer
		await timer.timeout
		if _back == timer and is_inside_tree():
			set_pose("idle")


func happy() -> void: react("happy")
func oops() -> void: react("think", 1.8)
func cheer() -> void: react("cheer", 0.0)
func wave() -> void: react("wave", 1.8)
func listen(on := true) -> void:
	if on:
		react("listen", 0.0)
	else:
		set_pose("idle")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		wave()
		if say_on_tap != "":
			Sound.say(say_on_tap)
