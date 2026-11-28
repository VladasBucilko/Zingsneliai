class_name ColorBubbleLevels
## Settings for "Spalvos" (Burbulai colour mode): pop only the bubbles of the
## colour shown in the square. Levels 1–19 on the forest path; level 20 is
## Olis's home = unlimited (it keeps getting harder while the child plays).
##
## Per level: more colours come in (2 → 6), bubbles rise faster (+7 % a level
## from a start 20 % faster than classic level 1), from level 9 their speeds
## differ more and more, and a few more target bubbles are needed.

const HOME_LEVEL := 20
const LAST_PATH_LEVEL := 19
## Clear but calm colours (easy to tell apart) and their Lithuanian names.
const COLORS := [Color("#7DB2DF"), Color("#F0CB55"), Color("#EC97AC"), Color("#86C691"),
	Color("#AD95DD"), Color("#F2A563")]
const NAMES := ["mėlyna", "geltona", "rožinė", "žalia", "violetinė", "oranžinė"]
## Speaks the names: Sound.say("mėlyna") Sound.say("geltona") Sound.say("rožinė")
## Sound.say("žalia") Sound.say("violetinė") Sound.say("oranžinė")


static func params(level: int) -> Dictionary:
	level = maxi(level, 1)
	var t := clampf((level - 1) / 18.0, 0.0, 1.0)     # 0 at level 1, 1 at level 19
	var spread := 0.1
	if level >= 9:
		spread = lerpf(0.25, 0.45, clampf((level - 9) / 6.0, 0.0, 1.0))
	return {
		"colors": clampi(2 + (level - 1) / 3, 2, COLORS.size()),
		"speed": 90.0 * minf(1.0 + 0.07 * (level - 1), 2.8),
		"spread": spread,
		"goal": 6 + mini(level, LAST_PATH_LEVEL),
		"max_on_screen": mini(3 + level / 4, 7),
		"gap": lerpf(1.5, 0.7, t),
		"radius": lerpf(130.0, 95.0, t),
		"target_share": lerpf(0.5, 0.35, t),   # how often a new bubble has the target colour
	}
