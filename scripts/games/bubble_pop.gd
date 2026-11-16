extends Control
## "Burbulai" — tap the slowly rising bubbles. No timer, no score, no failing.
## Levels come from BubbleLevelGenerator; bubbles that float away come back.

## Which level the scene opens with. Set before changing to this scene.
static var start_level := 1

const SIDE_MARGIN := 40.0

var level := 1
var _data := {}
var _queue: Array = []
var _active: Array[Bubble] = []
var _popped := 0
var _wait := 0.0
var _done := false
var _rng := RandomNumberGenerator.new()

@onready var _field: Node2D = $Field
@onready var _progress: HBoxContainer = $Progress


func _ready() -> void:
	var home := RoundButton.new(RoundButton.Kind.HOME)
	home.position = Vector2(64, 56)
	home.pressed.connect(_go_home)
	add_child(home)
	_load_level(start_level)


func _load_level(n: int) -> void:
	level = n
	start_level = n
	for b in _active:
		b.queue_free()
	_active.clear()
	_data = BubbleLevelGenerator.generate(level, -1, Settings.difficulty)
	_queue = _data.bubbles.duplicate(true)
	_rng.seed = int(_data.seed) + 1
	_popped = 0
	_wait = 0.4
	_done = false
	_build_progress()


func _process(delta: float) -> void:
	if _done or _queue.is_empty():
		return
	_wait -= delta
	if _wait <= 0.0 and _active.size() < int(_data.max_on_screen):
		_spawn(_queue.pop_front())
		if not _queue.is_empty():
			_wait = float(_queue[0].gap)


func _spawn(spec: Dictionary) -> void:
	var r := float(spec.radius)
	var w := size.x - 2.0 * (SIDE_MARGIN + r + float(spec.sway))
	var x := SIDE_MARGIN + r + float(spec.sway) + w * float(spec.x)
	var b := Bubble.new().setup(spec, x, size.y + r, Settings.reduce_motion)
	b.popped.connect(_on_popped)
	b.escaped.connect(_on_escaped)
	_field.add_child(b)
	_active.append(b)


func _unhandled_input(event: InputEvent) -> void:
	# Touch events (mouse is emulated as touch in project settings), so
	# several fingers can pop at once.
	if event is InputEventScreenTouch and event.pressed:
		_try_pop(event.position)


func _try_pop(p: Vector2) -> void:
	# Topmost (last added) bubble wins.
	for i in range(_active.size() - 1, -1, -1):
		var b := _active[i]
		if b.hit(p):
			b.pop()
			return


func _on_popped(b: Bubble) -> void:
	_active.erase(b)
	_popped += 1
	Sound.sfx("pop", _rng.randf_range(0.9, 1.12))
	_update_progress()
	if _popped >= int(_data.goal):
		_finish()


func _on_escaped(b: Bubble) -> void:
	_active.erase(b)
	if _done:
		return
	# Not a miss: the bubble just comes back later, somewhere else.
	var again: Dictionary = b.spec.duplicate()
	again.x = BubbleLevelGenerator.respawn_x(_rng)
	again.gap = 0.8
	_queue.append(again)
	if _queue.size() == 1:
		_wait = again.gap


func _finish() -> void:
	_done = true
	_queue.clear()
	await get_tree().create_timer(0.6).timeout
	var w := WellDone.make(true)
	w.replay.connect(func(): w.queue_free(); _load_level(level))
	w.next.connect(func(): w.queue_free(); _load_level(level + 1))
	w.home.connect(_go_home)
	add_child(w)


func _go_home() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# Quiet progress dots along the bottom: filled = popped. Purely informative.
func _build_progress() -> void:
	for c in _progress.get_children():
		c.queue_free()
	for i in int(_data.goal):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(18, 18)
		d.color = Color(Palette.TEXT, 0.12)
		_progress.add_child(d)


func _update_progress() -> void:
	var i := _popped - 1
	if i >= 0 and i < _progress.get_child_count():
		var d: ColorRect = _progress.get_child(i)
		d.color = Palette.PEACH
