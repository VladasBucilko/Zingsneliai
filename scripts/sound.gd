extends Node
## Autoload "Sound": voice + soft effects. Respects parent Settings.

var _voice := AudioStreamPlayer.new()
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_cache := {}


func _ready() -> void:
	_voice.volume_db = -2.0
	add_child(_voice)
	for i in 6: # a few players so quick pops can overlap
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_sfx.append(p)


## Speak a word if a recording exists. Returns true if something played.
func say(word: String) -> bool:
	if not Settings.voice_on:
		return false
	var s := WordBank.voice(word)
	if s == null:
		return false
	_voice.stream = s
	_voice.play()
	return true


## Speak and wait until the clip ends (returns at once if nothing played).
func say_wait(word: String) -> void:
	if say(word):
		await _voice.finished


func stop_voice() -> void:
	_voice.stop()


func sfx(name: String, pitch := 1.0) -> void:
	if not Settings.sound_on:
		return
	if not _sfx_cache.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_sfx_cache[name] = load(path) if ResourceLoader.exists(path) else null
	var s: AudioStream = _sfx_cache[name]
	if s == null:
		return
	for p in _sfx:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch
			p.play()
			return
