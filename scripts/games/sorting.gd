extends Control
## "Rūšiuok" — put each picture into the right basket.
## Drag the card, or tap the card and then tap a basket.
## Wrong basket = the card slides gently back. No buzzer, no timer.

const LEVELS := "res://data/levels/sorting.json"
const CARD_HOME := Vector2(960 - 150, 170)

static var start_level := 1

var _level := {}
var _baskets: Array[Basket] = []
var _queue: Array = []
var _card: PictureCard
var _selected := false
var _dragging := false
var _drag_offset := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _done := 0
var _total := 0
var _busy := false


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_speaker(self, _repeat)
	_start(start_level)


func _start(id: int) -> void:
	for b in _baskets:
		b.queue_free()
	_baskets.clear()
	if _card:
		_card.queue_free()
		_card = null
	_level = GameUI.load_level(LEVELS, id)
	var accents := [Palette.SAGE, Palette.PEACH, Palette.SKY]
	var row := $Baskets as HBoxContainer
	_queue.clear()
	var i := 0
	for bd in _level.get("baskets", []):
		var b := Basket.new().setup(bd.name, bd.get("icon", bd.words[0]), bd.words, accents[i % accents.size()])
		b.pressed.connect(_on_basket_pressed.bind(b))
		row.add_child(b)
		_baskets.append(b)
		_queue.append_array(bd.words)
		i += 1
	_queue.shuffle()
	_total = _queue.size()
	_done = 0
	_intro()


func _intro() -> void:
	_busy = true
	await Sound.say_wait(_level.get("instruction", "sudėk į krepšelius"))
	_busy = false
	_next_card()


func _next_card() -> void:
	if _queue.is_empty():
		await get_tree().create_timer(0.6).timeout
		var w := WellDone.make(false)
		w.replay.connect(func(): w.queue_free(); _start(int(_level.get("id", 1))))
		w.home.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
		add_child(w)
		return
	var word: String = _queue.pop_front()
	_card = PictureCard.new().setup(word, Palette.BUTTER)
	_card.position = CARD_HOME
	_card.gui_input.connect(_on_card_input)
	_card.modulate.a = 0.0
	add_child(_card)
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.3)
	_selected = false
	Sound.say(word)


func _on_card_input(event: InputEvent) -> void:
	var card := _card  # _card may be replaced while handling the drop
	if _busy or card == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_press_pos = event.global_position
			_drag_offset = event.global_position - _card.global_position
			_card.z_index = 10
		elif _dragging:
			_dragging = false
			_card.z_index = 0
			if event.global_position.distance_to(_press_pos) < 24.0:
				_tap_card()
			else:
				_drop(event.global_position)
		card.accept_event()
	elif event is InputEventMouseMotion and _dragging:
		card.global_position = event.global_position - _drag_offset
		_highlight_under(event.global_position)
		card.accept_event()


func _tap_card() -> void:
	_card.position = CARD_HOME
	_selected = not _selected
	_card.state = PictureCard.State.SELECTED if _selected else PictureCard.State.DEFAULT
	Sound.say(_card.word)


func _on_basket_pressed(b: Basket) -> void:
	if _busy or _card == null:
		return
	if _selected:
		_try(b)
	else:
		Sound.say(b.basket_name)


func _drop(p: Vector2) -> void:
	_highlight_under(Vector2(-1, -1))
	for b in _baskets:
		if b.get_global_rect().has_point(p):
			_try(b)
			return
	_slide_home()


func _try(b: Basket) -> void:
	if b.accepts(_card.word):
		_busy = true
		var card := _card
		_card = null
		card.state = PictureCard.State.MATCHED
		Sound.sfx("chime")
		var target := b.global_position + b.size / 2.0 - card.size * 0.2
		var t := create_tween().set_parallel(true)
		t.tween_property(card, "global_position", target, 0.35).set_trans(Tween.TRANS_SINE)
		t.tween_property(card, "scale", Vector2(0.4, 0.4), 0.35)
		t.tween_property(card, "modulate:a", 0.0, 0.45)
		await t.finished
		card.queue_free()
		b.add_item()
		await Sound.say_wait(b.basket_name)
		_done += 1
		_busy = false
		_next_card()
	else:
		_card.state = PictureCard.State.DEFAULT
		_selected = false
		_slide_home()
		_card.nudge()


func _slide_home() -> void:
	if _card:
		create_tween().tween_property(_card, "position", CARD_HOME, 0.3).set_trans(Tween.TRANS_SINE)


func _highlight_under(p: Vector2) -> void:
	for b in _baskets:
		b.set_highlight(b.get_global_rect().has_point(p))


func _repeat() -> void:
	if _card:
		Sound.say(_card.word)
	else:
		Sound.say(_level.get("instruction", "sudėk į krepšelius"))
