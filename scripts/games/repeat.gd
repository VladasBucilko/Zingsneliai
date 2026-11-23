extends Control
## "Kartok" — the voice says a word or animal sound, the child says it back.
## Any sound the microphone hears counts as a try: the game never judges
## pronunciation and never says "wrong". Tapping the mic button also counts,
## so the game works without a microphone (or without permission).
## Nothing is recorded or stored.

const LEVELS := "res://data/levels/repeat.json"
const HEARD_SECONDS := 0.3   # this much voice = a try
const REPEAT_AFTER := 8.0    # nothing heard -> say the word again

static var start_level := 1

var _level := {}
var _items: Array = []
var _i := 0
var _card: PictureCard
var _listening := false
var _heard := 0.0
var _quiet := 0.0
var _floor := 0.01
var _dots: HBoxContainer

var _mic_player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _mic_bus := -1
var _sink_bus := -1

@onready var _title: Label = $Title
@onready var _mic: MicButton = $Mic
@onready var _card_slot: Control = $CardSlot


func _ready() -> void:
	GameUI.add_home(self)
	GameUI.add_speaker(self, _say_current)
	_mic.pressed.connect(_success)  # tap = "I said it"
	$Next.pressed.connect(_skip)
	_setup_mic()
	_start(start_level)


func _start(id: int) -> void:
	_level = GameUI.load_level(LEVELS, id)
	_items = _level.get("items", [])
	_i = 0
	if _dots:
		_dots.queue_free()
	_dots = GameUI.add_dots(self, _items.size())
	_present(true)


func _present(first := false) -> void:
	_listening = false
	_mic.listening = false
	if _card:
		_card.queue_free()
		_card = null
	if _i >= _items.size():
		GameUI.well_done(self, LEVELS, int(_level.get("id", 1)), _start)
		return
	var item: Dictionary = _items[_i]
	_title.text = item.get("text", item.word)
	_card = PictureCard.new().setup(item.word, Palette.BUTTER)
	_card.custom_minimum_size = Vector2(420, 480)
	_card.size = Vector2(420, 480)
	_card.pivot_offset = _card.size / 2.0
	_card.pressed.connect(_say_current)
	_card_slot.add_child(_card)
	if first:
		await Sound.say_wait("pakartok")
	await _say_and_listen()


func _say_current() -> void:
	if _i < _items.size():
		Sound.say(_items[_i].say)


func _say_and_listen() -> void:
	_listening = false
	_mic.listening = false
	await Sound.say_wait(_items[_i].say)
	# Short pause so the app's own voice isn't picked up as the child's.
	await get_tree().create_timer(0.4).timeout
	_drain_mic()
	_heard = 0.0
	_quiet = 0.0
	_listening = true
	_mic.listening = true


func _process(delta: float) -> void:
	var lvl := _mic_level()
	if not _listening:
		return
	_mic.level = lvl * 6.0
	if lvl > maxf(0.03, _floor * 3.0):
		_heard += delta
		if _heard >= HEARD_SECONDS:
			_success()
			return
	else:
		_heard = maxf(0.0, _heard - delta * 0.5)
		_floor = lerpf(_floor, lvl, 0.02)  # learn the room's background noise
		_quiet += delta
		if _quiet >= REPEAT_AFTER:
			_say_and_listen()


func _success() -> void:
	if not _listening:
		return
	_listening = false
	_mic.listening = false
	_mic.level = 0.0
	if _card:
		_card.state = PictureCard.State.MATCHED
		_card.celebrate()
	Sound.sfx("chime")
	GameUI.fill_dot(_dots, _i)
	await Sound.say_wait("šaunu")
	await get_tree().create_timer(0.5).timeout
	_i += 1
	_present()


func _skip() -> void:
	Sound.stop_voice()
	_i += 1
	_present()


# --- Microphone -------------------------------------------------------------

func _setup_mic() -> void:
	if OS.get_name() == "Android":
		OS.request_permissions()
	_sink_bus = AudioServer.bus_count
	AudioServer.add_bus(_sink_bus)
	AudioServer.set_bus_name(_sink_bus, "MicSink")
	AudioServer.set_bus_mute(_sink_bus, true)  # never play the mic back
	_mic_bus = AudioServer.bus_count
	AudioServer.add_bus(_mic_bus)
	AudioServer.set_bus_name(_mic_bus, "Mic")
	AudioServer.set_bus_send(_mic_bus, "MicSink")
	_capture = AudioEffectCapture.new()
	AudioServer.add_bus_effect(_mic_bus, _capture)
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "Mic"
	add_child(_mic_player)
	_mic_player.play()


func _mic_level() -> float:
	if _capture == null:
		return 0.0
	var n := _capture.get_frames_available()
	if n <= 0:
		return 0.0
	var buf := _capture.get_buffer(n)
	var sum := 0.0
	for f in buf:
		sum += (f.x * f.x + f.y * f.y) * 0.5
	return sqrt(sum / buf.size())


func _drain_mic() -> void:
	if _capture:
		_capture.clear_buffer()


func _exit_tree() -> void:
	if _mic_player:
		_mic_player.stop()
	# Remove our buses (highest index first).
	for idx in [_mic_bus, _sink_bus]:
		if idx >= 0 and idx < AudioServer.bus_count:
			AudioServer.remove_bus(idx)
