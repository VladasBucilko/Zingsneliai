class_name SequenceGenerator
## Levels for "Sekos": rows of random capital letters to copy by pressing buttons.
## Deterministic: the same level number always gives the same rows.
##
## Every 10 levels the rows get up to 4 letters longer:
##   levels 1–10: 2–4 letters, 11–20: 5–8, 21–30: 9–12, 31+: 13–16 (the cap).
## Buttons: the row's letters plus a few extra ones up to level 20, then the
## full alphabet as a keyboard. Levels 1–10 use only letters without accents.

const ALPHABET := ["A", "Ą", "B", "C", "Č", "D", "E", "Ę", "Ė", "F", "G", "H", "I", "Į", "Y", "J",
	"K", "L", "M", "N", "O", "P", "R", "S", "Š", "T", "U", "Ų", "Ū", "V", "Z", "Ž"]
const PLAIN := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "Y", "J", "K", "L", "M", "N", "O",
	"P", "R", "S", "T", "U", "V", "Z"]
const STEP := 4            # letters added every 10 levels
const MAX_LEN := 16        # rows never get longer than this
const KEYBOARD_FROM := 21  # full alphabet buttons from this level


static func generate(level: int) -> Dictionary:
	level = maxi(level, 1)
	var block := (level - 1) / 10          # 0 for levels 1–10, 1 for 11–20, …
	var step := (level - 1) % 10           # 0..9 inside the block
	var max_len := mini(STEP + STEP * block, MAX_LEN)
	var min_len := 2 if block == 0 else max_len - STEP + 1
	var pool: Array = PLAIN if block == 0 else ALPHABET
	var rows_count := 4 if max_len <= 4 else (3 if max_len <= 8 else 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sekos-%d" % level)
	var rows: Array = []
	for r in rows_count:
		# Rows grow from min to max length across the block, and within the level.
		var t := (float(step) + float(r) / rows_count) / 10.0
		var length := clampi(int(round(lerpf(min_len, max_len, t))), min_len, max_len)
		rows.append(_row(rng, pool, length))

	var keyboard := level >= KEYBOARD_FROM
	var extras := 0 if keyboard else 1 + step / 3 + block   # 1..4 (L1–10), 2..5 (L11–20)
	return {
		"level": level,
		"rows": rows,
		"keyboard": keyboard,
		"extras": extras,
		"pool": pool,
	}


## Buttons for one row: the full alphabet, or the row's own letters plus a few
## others, in shuffled order (the same shuffle every time for that row).
static func buttons_for(data: Dictionary, row_index: int) -> Array:
	if data.keyboard:
		return ALPHABET.duplicate()
	var row: Array = data.rows[row_index]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sekos-buttons-%d-%d" % [data.level, row_index])
	var letters: Array = []
	for l in row:
		if not l in letters:
			letters.append(l)
	var others: Array = (data.pool as Array).filter(func(l): return not l in letters)
	for i in mini(int(data.extras), others.size()):
		letters.append(others.pop_at(rng.randi_range(0, others.size() - 1)))
	_shuffle(letters, rng)
	return letters


static func _row(rng: RandomNumberGenerator, pool: Array, length: int) -> Array:
	var row: Array = []
	while row.size() < length:
		var l: String = pool[rng.randi_range(0, pool.size() - 1)]
		# No letter twice in a row: easier to follow, and it never looks like a word typo.
		if not row.is_empty() and row[-1] == l:
			continue
		row.append(l)
	return row


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
