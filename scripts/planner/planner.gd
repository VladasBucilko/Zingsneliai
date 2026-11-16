extends Control
## "Mano planas" — a magnetic board with 6 spaces. Drag picture magnets from the
## tray onto the board to make a plan or a story (first … then …).
## - Tap any magnet: it says its word.
## - Drag a magnet on the board to another space to swap them; drag it off the
##   board to take it away.
## - Speaker: reads the whole plan in order. ✕: clears the board.
## The plan is saved on the device.

const DATA := "res://data/planner.json"
const SAVE := "user://plan.json"
const TRAY_CARD := Vector2(176, 216)
const TAP_DISTANCE := 20.0

var _cards: Array = []            # [{word, label}]
var _slots: Array = []            # PlanCard or null per space
var _drag: PlanCard
var _drag_from := -1              # slot index, or -1 = from the tray
var _drag_offset := Vector2.ZERO
var _press := Vector2.ZERO
var _reading := false

@onready var _board: PlanBoard = $Board
@onready var _tray: Control = $Tray
@onready var _layer: Control = $DragLayer


func _ready() -> void:
	GameUI.add_home(self, GameUI.HOME)
	GameUI.add_title(self, "Mano planas")
	GameUI.add_speaker(self, _read_plan)
	var clear := RoundButton.new(RoundButton.Kind.CLEAR)
	clear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	clear.offset_left = -64 - RoundButton.SIZE * 2 - 32
	clear.offset_right = -64 - RoundButton.SIZE - 32
	clear.offset_top = 56
	clear.offset_bottom = 56 + RoundButton.SIZE
	clear.pressed.connect(_clear)
	add_child(clear)

	var data := _load_json(DATA)
	_cards = data.get("cards", [])
	_board.slot_count = int(data.get("slots", 6))
	_slots.resize(_board.slot_count)
	_slots.fill(null)
	await get_tree().process_frame  # containers have their final size now
	_build_tray()
	_restore()


func _build_tray() -> void:
	var gap := 20.0
	var total := _cards.size() * TRAY_CARD.x + (_cards.size() - 1) * gap
	var x0 := (_tray.size.x - total) / 2.0
	for i in _cards.size():
		var c: Dictionary = _cards[i]
		var card := PlanCard.new().setup(c.word, c.label, _accent(i), TRAY_CARD)
		card.position = Vector2(x0 + i * (TRAY_CARD.x + gap), 0)
		card.gui_input.connect(_on_tray_input.bind(card))
		_tray.add_child(card)


func _accent(i: int) -> Color:
	return Palette.ACCENTS[i % Palette.ACCENTS.size()]


# --- Dragging ---------------------------------------------------------------

func _on_tray_input(event: InputEvent, source: PlanCard) -> void:
	if _reading:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.global_position
			# Pick up a copy; the tray keeps its magnet, so a picture can be used twice.
			_drag = PlanCard.new().setup(source.word, source.label, source.accent, source.size)
			_layer.add_child(_drag)
			_drag.global_position = source.global_position
			_drag_offset = event.global_position - source.global_position
			_drag_from = -1
			_lift(_drag)
		elif _drag:
			_release(event.global_position)
		source.accept_event()
	elif event is InputEventMouseMotion and _drag:
		_move(event.global_position)
		source.accept_event()


func _on_board_card_input(event: InputEvent, card: PlanCard) -> void:
	if _reading:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.global_position
			_drag = card
			_drag_from = _slots.find(card)
			_drag_offset = event.global_position - card.global_position
			# Stay on the board (moving it to another parent mid-touch would drop
			# the touch); z_index lifts it above the other magnets instead.
			_lift(card)
		elif _drag:
			_release(event.global_position)
		card.accept_event()
	elif event is InputEventMouseMotion and _drag:
		_move(event.global_position)
		card.accept_event()


func _move(p: Vector2) -> void:
	_drag.global_position = p - _drag_offset
	_board.highlight = _board.slot_at(p) if p.distance_to(_press) > TAP_DISTANCE else -1


func _release(p: Vector2) -> void:
	var card := _drag
	_drag = null
	_board.highlight = -1
	card.scale = Vector2.ONE
	card.z_index = 0
	var is_tap := p.distance_to(_press) < TAP_DISTANCE
	var target := -1 if is_tap else _board.slot_at(p)

	if _drag_from == -1:
		# From the tray
		if is_tap:
			Sound.say(card.word)
		if is_tap or target == -1:
			_fade_out(card)
			return
		_put(card, target)
		Sound.sfx("pop", 0.9)
		Sound.say(card.word)
		return

	# From the board
	var from := _drag_from
	if is_tap:
		_put(card, from)
		Sound.say(card.word)
		return
	if target == -1:
		if _board.get_global_rect().has_point(p):
			_put(card, from)          # dropped on the board, but not on a space
		else:
			_slots[from] = null       # taken off the board
			_fade_out(card)
			_save()
		return
	if target != from:
		var other: PlanCard = _slots[target]
		_slots[from] = null
		if other != null:
			_slots[target] = null
			_put(other, from)         # swap places
	_put(card, target)
	Sound.sfx("pop", 0.9)


## Place a card into a space (replacing whatever is there) with a soft snap.
func _put(card: PlanCard, i: int) -> void:
	var old: PlanCard = _slots[i]
	if old != null and old != card:
		_fade_out(old)
	_slots[i] = card
	if card.get_parent() != _board:
		card.reparent(_board)
	if not card.gui_input.is_connected(_on_board_card_input):
		card.gui_input.connect(_on_board_card_input.bind(card))
	var r := _board.slot_rect(i)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(card, "position", r.position, 0.18)
	t.tween_property(card, "size", r.size, 0.18)
	_save()


func _lift(card: PlanCard) -> void:
	card.z_index = 10
	if not Settings.reduce_motion:
		card.scale = Vector2(1.06, 1.06)


func _fade_out(card: PlanCard) -> void:
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(card, "modulate:a", 0.0, 0.2)
	t.tween_callback(card.queue_free)


# --- Read, clear, save ------------------------------------------------------

func _read_plan() -> void:
	if _reading:
		return
	_reading = true
	var any := false
	for i in _slots.size():
		var card: PlanCard = _slots[i]
		if card == null:
			continue
		any = true
		_board.highlight = i
		if not Settings.reduce_motion:
			var t := create_tween()
			t.tween_property(card, "scale", Vector2(1.08, 1.08), 0.15)
			t.tween_property(card, "scale", Vector2.ONE, 0.25)
		await Sound.say_wait(card.word)
		await get_tree().create_timer(0.35).timeout
	_board.highlight = -1
	if not any:
		Sound.say("mano planas")
	_reading = false


func _clear() -> void:
	if _reading:
		return
	for i in _slots.size():
		if _slots[i] != null:
			_fade_out(_slots[i])
			_slots[i] = null
	_save()


func plan_words() -> Array:
	var words := []
	for c in _slots:
		words.append(c.word if c != null else "")
	return words


func _save() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"slots": plan_words()}))


func _restore() -> void:
	var saved := _load_json(SAVE)
	var words: Array = saved.get("slots", [])
	for i in mini(words.size(), _slots.size()):
		var w: String = words[i]
		if w == "":
			continue
		for j in _cards.size():
			if _cards[j].word == w:
				var card := PlanCard.new().setup(w, _cards[j].label, _accent(j), _board.slot_size)
				_board.add_child(card)
				card.position = _board.slot_rect(i).position
				card.gui_input.connect(_on_board_card_input.bind(card))
				_slots[i] = card
				break


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
