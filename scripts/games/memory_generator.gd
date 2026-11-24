class_name MemoryGenerator
## Levels for "Atmintis": the sequence of squares to remember.
## Level n builds up to n + 2 squares, one more each round
## (level 1: 1 → 2 → 3, level 2: up to 4, …, capped at MAX_LEN).
## Any square can come next, also the same one again (red, red, blue…).
## Deterministic: the same level always gives the same sequence.

const SQUARES := 5
const MAX_LEN := 20


static func generate(level: int) -> Dictionary:
	level = maxi(level, 1)
	var length := mini(level + 2, MAX_LEN)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("atmintis-%d" % level)
	var seq: Array[int] = []
	for i in length:
		seq.append(rng.randi_range(0, SQUARES - 1))
	return {"level": level, "sequence": seq}
