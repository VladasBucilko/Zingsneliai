extends Node
## Parent-controlled settings. Calm defaults: quiet sound, gentle motion.

const PATH := "user://settings.cfg"

var sound_on := true
var voice_on := true
var reduce_motion := false
var difficulty := 1 # 1 = easiest

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sound_on = cfg.get_value("s", "sound_on", sound_on)
		voice_on = cfg.get_value("s", "voice_on", voice_on)
		reduce_motion = cfg.get_value("s", "reduce_motion", reduce_motion)
		difficulty = cfg.get_value("s", "difficulty", difficulty)

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("s", "sound_on", sound_on)
	cfg.set_value("s", "voice_on", voice_on)
	cfg.set_value("s", "reduce_motion", reduce_motion)
	cfg.set_value("s", "difficulty", difficulty)
	cfg.save(PATH)
