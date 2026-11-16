class_name WordBank
## Reads data/words.json and resolves the photo/audio file for a word.
## Files use an ASCII slug of the word: "katė" -> "kate", "šuo" -> "suo".

const DATA_PATH := "res://data/words.json"
const PHOTO_DIR := "res://assets/photos/"
const AUDIO_DIR := "res://assets/audio/words/"

const _TRANSLIT := {
	"ą": "a", "č": "c", "ę": "e", "ė": "e", "į": "i",
	"š": "s", "ų": "u", "ū": "u", "ž": "z",
}

static var _themes: Array = []


static func themes() -> Array:
	if _themes.is_empty():
		var f := FileAccess.open(DATA_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_themes = parsed.get("themes", [])
	return _themes


static func theme_words(theme_id: String) -> Array:
	for t in themes():
		if t.get("id") == theme_id:
			return t.get("words", [])
	return []


static func slug(word: String) -> String:
	# "Surask šunį." -> "surask_suni": transliterate, spaces -> _, drop punctuation.
	var out := ""
	for ch in word.to_lower().strip_edges():
		var c: String = _TRANSLIT.get(ch, ch)
		if c == " ":
			out += "_"
		elif (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_":
			out += c
	return out


static func photo(word: String) -> Texture2D:
	for ext in ["png", "jpg", "webp"]:
		var p: String = PHOTO_DIR + slug(word) + "." + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null


static func voice(word: String) -> AudioStream:
	for ext in ["ogg", "mp3", "wav"]:
		var p: String = AUDIO_DIR + slug(word) + "." + ext
		if ResourceLoader.exists(p):
			return load(p)
	return null
