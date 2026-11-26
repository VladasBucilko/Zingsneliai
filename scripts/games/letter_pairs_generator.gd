class_name LetterPairsGenerator
## Levels for "Raidės": connect each capital letter with its small letter.
## 5 stages × 10 levels. Inside every stage the letters go through the whole
## Lithuanian alphabet in order: level 1 has 1 pair (A–a), level 2 has 2,
## level 3 has 3, levels 4–10 have 4 pairs (the last level adds review letters).
##
## Stage  layout     letters
##   1    columns    printed
##   2    columns    cursive
##   3    tangle     printed
##   4    tangle     cursive
##   5    tangle     mixed: each pair printed + cursive, either way round
## In the tangle stages from level 6 a few extra small letters without a partner
## join in (1 → 3), so the child really has to look. Deterministic per level.

const ALPHABET := ["A", "Ą", "B", "C", "Č", "D", "E", "Ę", "Ė", "F", "G", "H", "I", "Į", "Y", "J",
	"K", "L", "M", "N", "O", "P", "R", "S", "Š", "T", "U", "Ų", "Ū", "V", "Z", "Ž"]
const STAGES := 5
const LEVELS := 10
const STAGE_NAMES := ["Spausdintinės", "Rašytinės", "Raizgalynė", "Rašytinė raizgalynė", "Viskas kartu"]

enum Style { PRINT, CURSIVE }


static func pairs_in(level: int) -> int:
	return clampi(level, 1, 4)


static func is_tangle(stage: int) -> bool:
	return stage >= 3


## {stage, level, tangle: bool, pairs: [{letter, cap_style, small_style}],
##  extras: [{letter, style}]  (small letters without a partner)}
static func generate(stage: int, level: int) -> Dictionary:
	stage = clampi(stage, 1, STAGES)
	level = clampi(level, 1, LEVELS)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("raides-%d-%d" % [stage, level])

	# Letters: continue through the alphabet; the last level tops up with review letters.
	var start := 0
	for l in range(1, level):
		start += pairs_in(l)
	var letters: Array = []
	for i in pairs_in(level):
		if start + i < ALPHABET.size():
			letters.append(ALPHABET[start + i])
	while letters.size() < pairs_in(level):
		var l: String = ALPHABET[rng.randi_range(0, ALPHABET.size() - 1)]
		if not l in letters:
			letters.append(l)

	var pairs: Array = []
	for l in letters:
		var cap := Style.PRINT
		var small := Style.PRINT
		match stage:
			2, 4:
				cap = Style.CURSIVE
				small = Style.CURSIVE
			5:
				# One printed, one cursive: which one is random per pair.
				if rng.randf() < 0.5:
					small = Style.CURSIVE
				else:
					cap = Style.CURSIVE
		pairs.append({"letter": l, "cap_style": cap, "small_style": small})

	var extras: Array = []
	if is_tangle(stage) and level >= 6:
		var count := (level - 4) / 2          # L6–7: 1, L8–9: 2, L10: 3
		var pool := ALPHABET.filter(func(l): return not l in letters)
		for i in count:
			var l: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			var st := Style.PRINT
			if stage == 4 or (stage == 5 and rng.randf() < 0.5):
				st = Style.CURSIVE
			extras.append({"letter": l, "style": st})

	return {"stage": stage, "level": level, "tangle": is_tangle(stage), "pairs": pairs,
		"extras": extras, "seed": rng.seed}
