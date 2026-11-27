class_name EndlessLevels
## "Begalinis" (unlimited) rounds for the level-based games. Each call makes a
## fresh random round in the same format as that game's level JSON, built
## from the words and pictures the levels already use, so nothing new is needed.
## A round has id = -1 (GameUI.well_done then offers another endless round).

const LEVELS := "res://data/levels/"
## Words that share a picture with another word: left out of the picture pool.
const SAME_PICTURE := ["miegoti"]

static var _rng := RandomNumberGenerator.new()
static var _seeded := false


static func _r() -> RandomNumberGenerator:
	if not _seeded:
		_rng.randomize()
		_seeded = true
	return _rng


static func _levels(game: String) -> Array:
	var f := FileAccess.open(LEVELS + game + ".json", FileAccess.READ)
	if f == null:
		return []
	var d = JSON.parse_string(f.get_as_text())
	return d.get("levels", []) if d is Dictionary else []


static func _pick(a: Array, n: int) -> Array:
	var pool := a.duplicate()
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(_r().randi_range(0, pool.size() - 1)))
	return out


## Every word with a picture that some level uses (with its proper spelling).
static func picture_words() -> Array:
	var words := {}
	for l in _levels("matching"):
		for w in l.get("words", []): words[w] = true
	for l in _levels("find"):
		for r in l.get("rounds", []):
			for w in r.get("choices", []): words[w] = true
	for l in _levels("sorting"):
		for b in l.get("baskets", []):
			for w in b.get("words", []): words[w] = true
	for l in _levels("puzzle"):
		words[l.word] = true
	for l in _levels("letters"):
		words[l.answer] = true
		for c in l.get("clues", []): words[c.word] = true
	var out: Array = []
	for w in words:
		if not w in SAME_PICTURE and WordBank.photo(w) != null:
			out.append(w)
	return out


static func matching() -> Dictionary:
	var n := _r().randi_range(4, 6)
	return {"id": -1, "words": _pick(picture_words(), n), "show_word": _r().randf() < 0.5}


## Targets need a spoken prompt ("Surask avį"), so they come from find.json.
static func find() -> Dictionary:
	var prompts := {}
	for l in _levels("find"):
		for r in l.get("rounds", []):
			prompts[r.target] = r.prompt
	var pool := picture_words()
	var rounds: Array = []
	var targets := _pick(prompts.keys(), 4)
	for t in targets:
		var n := _r().randi_range(4, 6)
		var others := _pick(pool.filter(func(w): return w != t), n - 1)
		var choices := others + [t]
		choices.shuffle()
		rounds.append({"target": t, "prompt": prompts[t], "choices": choices})
	return {"id": -1, "rounds": rounds}


## Reuses one of the levels' basket sets (so the categories never overlap) and
## fills each basket with 3–4 words seen in that basket anywhere in the levels.
static func sorting() -> Dictionary:
	var levels := _levels("sorting")
	var cats := {}   # name -> {icon, words{}}
	for l in levels:
		for b in l.baskets:
			if not cats.has(b.name):
				cats[b.name] = {"icon": b.get("icon", b.words[0]), "words": {}}
			for w in b.words: cats[b.name].words[w] = true
	var tpl: Dictionary = levels[_r().randi_range(0, levels.size() - 1)]
	var names: Array = tpl.baskets.map(func(b): return b.name)
	var baskets: Array = []
	for nm in names:
		var mine: Array = cats[nm].words.keys()
		# Leave out words that also belong to another basket in this set.
		mine = mine.filter(func(w):
			for other in names:
				if other != nm and cats[other].words.has(w): return false
			return true)
		baskets.append({"name": nm, "icon": cats[nm].icon, "words": _pick(mine, _r().randi_range(3, 4))})
	return {"id": -1, "instruction": tpl.get("instruction", "sudėk į krepšelius"), "baskets": baskets}


static func puzzle() -> Dictionary:
	var grids := [[3, 2], [3, 3], [4, 3], [4, 3], [4, 4]]
	var g: Array = grids[_r().randi_range(0, grids.size() - 1)]
	var pool := picture_words()
	return {"id": -1, "word": pool[_r().randi_range(0, pool.size() - 1)], "cols": g[0], "rows": g[1]}


static func repeat() -> Dictionary:
	var items := {}
	for l in _levels("repeat"):
		for it in l.items: items[it.say] = it
	return {"id": -1, "items": _pick(items.values(), 4)}


## One of the hidden words, with a fresh picture for each letter every time
## (S from sala, stalas or sūpynės…) and new extra letters.
static func letters() -> Dictionary:
	var levels := _levels("letters")
	var tpl: Dictionary = levels[_r().randi_range(0, levels.size() - 1)].duplicate(true)
	var by_letter := {}
	for w in picture_words():
		var first := String(w).left(1).to_upper()
		if not by_letter.has(first): by_letter[first] = []
		by_letter[first].append(w)
	var clues: Array = []
	for i in String(tpl.answer).length():
		var ch := String(tpl.answer)[i].to_upper()
		var options: Array = by_letter.get(ch, [])
		var used: Array = clues.map(func(c): return c.word)
		options = options.filter(func(w): return w != tpl.answer and not w in used)
		if options.is_empty():
			clues.append(tpl.clues[i])     # keep the level's own picture
		else:
			var w: String = options[_r().randi_range(0, options.size() - 1)]
			clues.append({"word": w, "label": w.left(1).to_upper() + w.substr(1)})
	tpl.clues = clues
	var abc := LetterPairsGenerator.ALPHABET.filter(func(l): return not l in String(tpl.answer).to_upper())
	tpl.extra_letters = _pick(abc, 3)
	tpl.id = -1
	return tpl
