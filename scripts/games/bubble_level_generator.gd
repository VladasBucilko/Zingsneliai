class_name BubbleLevelGenerator
## Deterministic level generator for "Burbulai" (bubble pop).
##
## The same (level, seed, difficulty) always produces the same level, so a level
## can be replayed, tested, or saved to JSON. Levels never "fail": a bubble that
## floats off the top is simply queued again, so every level can be finished.
##
## Difficulty grows slowly across levels 1..10 and then plateaus:
##   more bubbles to pop, slightly smaller and faster bubbles, shorter gaps,
##   more bubbles on screen at once. Level 1 is deliberately very easy.
## On top of that every bubble rises faster (speed_boost): +20 % in level 1,
## rising evenly to +50 % in level 6, then +5 % more per level (capped at ×3).
## From level 5 bubbles also differ in speed: some are clearly faster than
## others (the spread widens up to level 10).

const MAX_CURVE_LEVEL := 10

## Tunables for the easiest (level 1) and hardest (level 10+) ends of the curve.
const EASY := {
	"goal": 6, "radius": 150.0, "speed": 60.0, "gap": 1.8, "max_on_screen": 3, "sway": 18.0, "colors": 2,
}
const HARD := {
	"goal": 20, "radius": 85.0, "speed": 150.0, "gap": 0.7, "max_on_screen": 7, "sway": 45.0, "colors": 6,
}


## Returns a Dictionary:
## {
##   level, seed, difficulty, goal, max_on_screen,
##   bubbles: [{ gap, x, radius, speed, color, sway, sway_hz, phase }, ...]
## }
## gap     = seconds after the previous spawn
## x       = horizontal position, 0..1 (the game maps it inside safe margins)
## radius  = px at 1080p; speed = px/s upward; color = index into Palette.ACCENTS
static func generate(level: int, seed: int = -1, difficulty: int = 1) -> Dictionary:
	level = maxi(level, 1)
	difficulty = clampi(difficulty, 1, 3)
	if seed < 0:
		seed = level * 7919 + difficulty * 104729
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var p := params(level, difficulty)
	var bubbles: Array = []
	var recent_x: Array[float] = []
	for i in p.goal:
		var radius: float = p.radius * rng.randf_range(0.85, 1.15)
		var spread := speed_spread(level)
		bubbles.append({
			"gap": 0.0 if i == 0 else p.gap * rng.randf_range(0.8, 1.25),
			"x": _spaced_x(rng, recent_x),
			"radius": snappedf(radius, 0.1),
			"speed": snappedf(p.speed * rng.randf_range(1.0 - spread, 1.0 + spread), 0.1),
			"color": rng.randi_range(0, p.colors - 1),
			"sway": snappedf(p.sway * rng.randf_range(0.6, 1.0), 0.1),
			"sway_hz": snappedf(rng.randf_range(0.15, 0.3), 0.001),
			"phase": snappedf(rng.randf_range(0.0, TAU), 0.001),
		})
	return {
		"level": level,
		"seed": seed,
		"difficulty": difficulty,
		"goal": p.goal,
		"max_on_screen": p.max_on_screen,
		"bubbles": bubbles,
	}


## The raw curve values for a level, before per-bubble randomisation.
static func params(level: int, difficulty: int = 1) -> Dictionary:
	var t := clampf(float(level - 1) / float(MAX_CURVE_LEVEL - 1), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t) # smoothstep: gentle start, gentle plateau
	t = clampf(t + (difficulty - 1) * 0.15, 0.0, 1.0)
	return {
		"goal": int(round(lerpf(EASY.goal, HARD.goal, t))),
		"radius": lerpf(EASY.radius, HARD.radius, t),
		"speed": lerpf(EASY.speed, HARD.speed, t) * speed_boost(level),
		"gap": lerpf(EASY.gap, HARD.gap, t),
		"max_on_screen": int(round(lerpf(EASY.max_on_screen, HARD.max_on_screen, t))),
		"sway": lerpf(EASY.sway, HARD.sway, t),
		"colors": int(round(lerpf(EASY.colors, HARD.colors, t))),
	}


## How much faster than the base curve bubbles rise in a level:
## ×1.2 at level 1 → ×1.5 at level 6 (evenly), then +0.05 per level, max ×3.
static func speed_boost(level: int) -> float:
	level = maxi(level, 1)
	if level <= 6:
		return lerpf(1.2, 1.5, (level - 1) / 5.0)
	return minf(1.5 + 0.05 * (level - 6), 3.0)


## Per-bubble speed variation (±): small up to level 4, then some bubbles are
## clearly faster or slower than others – ±30 % at level 5 up to ±45 % at 10+.
static func speed_spread(level: int) -> float:
	if level < 5:
		return 0.15
	return lerpf(0.30, 0.45, clampf((level - 5) / 5.0, 0.0, 1.0))


## Pick an x that is not too close to the last two spawns, so bubbles don't stack.
static func _spaced_x(rng: RandomNumberGenerator, recent: Array[float]) -> float:
	var x := 0.5
	for attempt in 12:
		x = rng.randf_range(0.0, 1.0)
		var ok := true
		for r in recent:
			if absf(r - x) < 0.22:
				ok = false
				break
		if ok:
			break
	recent.append(x)
	if recent.size() > 2:
		recent.pop_front()
	return snappedf(x, 0.001)


## A fresh x for a bubble that floated away and is queued again.
static func respawn_x(rng: RandomNumberGenerator) -> float:
	return snappedf(rng.randf_range(0.0, 1.0), 0.001)
