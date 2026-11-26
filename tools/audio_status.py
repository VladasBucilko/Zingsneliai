#!/usr/bin/env python3
"""Which words and phrases does the app say, and which ones still need a voice
clip (or a picture)?

Reads everything the app can speak:
  - data/levels/*.json (all games), data/planner.json
  - game and section names (scripts/games_menu.gd, scripts/main.gd)
  - fixed phrases in the code: Sound.say("...") / Sound.say_wait("...")
and checks assets/audio/words/<slug>.ogg|mp3|wav and assets/photos/<slug>.png|jpg|webp
(the same slug rule as scripts/word_bank.gd).

Usage (from the project folder):
  python3 tools/audio_status.py            # rewrite docs/voice_todo.md + print a summary
  python3 tools/audio_status.py --json     # print the status as JSON (for syncing Trello)
  python3 tools/audio_status.py --check    # exit code 1 if anything is missing
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AUDIO_DIR = ROOT / "assets/audio/words"
PHOTO_DIR = ROOT / "assets/photos"
OUT = ROOT / "docs/voice_todo.md"
AUDIO_EXT = ("ogg", "mp3", "wav")
PHOTO_EXT = ("png", "jpg", "webp")

TRANSLIT = str.maketrans("ąčęėįšųūž", "aceeisuuz")

# Groups, in the order they are listed.
WORDS, NAMES, PROMPTS, SOUNDS, GAMES_UI = (
    "Words", "Basket names", "Instructions and \"Surask …\" prompts",
    "\"… sako\" lines (Kartok)", "Game and section names, other phrases")
GROUPS = [WORDS, NAMES, PROMPTS, SOUNDS, GAMES_UI]


def slug(text: str) -> str:
    """Same as WordBank.slug(): lower case, transliterate, spaces -> _, drop the rest."""
    out = ""
    for ch in text.lower().strip().translate(TRANSLIT):
        if ch == " ":
            out += "_"
        elif ch.isascii() and (ch.isalnum() or ch == "_"):
            out += ch
    return out


class Collector:
    def __init__(self):
        self.items = {}  # slug -> dict

    def add(self, text, where, group, picture=False, say_text=None):
        text = str(text).strip()
        if not text:
            return
        s = slug(text)
        it = self.items.setdefault(s, {
            "slug": s, "text": text, "say": say_text or (text[0].upper() + text[1:]),
            "group": group, "where": set(), "picture": False})
        it["where"].add(where)
        it["picture"] = it["picture"] or picture
        # A word that has a picture somewhere is a "word", whatever else it is.
        if picture:
            it["group"] = WORDS
        if say_text and it["say"] == text[0].upper() + text[1:]:
            it["say"] = say_text


def load_levels(name):
    path = ROOT / "data/levels" / f"{name}.json"
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8")).get("levels", [])


def collect() -> Collector:
    c = Collector()

    for lv in load_levels("matching"):
        for w in lv.get("words", []):
            c.add(w, f"Poros L{lv['id']}", WORDS, picture=True)

    for lv in load_levels("sorting"):
        where = f"Rūšiuok L{lv['id']}"
        c.add(lv.get("instruction", ""), where, PROMPTS)
        for b in lv.get("baskets", []):
            c.add(b["name"], where, NAMES)
            c.add(b.get("icon", b["words"][0]), where, WORDS, picture=True)
            for w in b.get("words", []):
                c.add(w, where, WORDS, picture=True)

    for lv in load_levels("find"):
        where = f"Surask L{lv['id']}"
        for r in lv.get("rounds", []):
            c.add(r["prompt"], where, PROMPTS)
            for w in r.get("choices", []):
                c.add(w, where, WORDS, picture=True)

    for lv in load_levels("puzzle"):
        c.add(lv["word"], f"Dėlionė L{lv['id']}", WORDS, picture=True)

    for lv in load_levels("repeat"):
        where = f"Kartok L{lv['id']}"
        for it in lv.get("items", []):
            c.add(it["word"], where, WORDS, picture=True)
            say = it.get("say", it["word"])
            if slug(say) != slug(it["word"]):
                c.add(say, where, SOUNDS, say_text=it.get("text"))

    for lv in load_levels("letters"):
        where = f"Atspėk L{lv['id']}"
        c.add(lv.get("instruction", ""), where, PROMPTS)
        c.add(lv["answer"], where, WORDS, picture=True)
        for cl in lv.get("clues", []):
            c.add(cl["word"], where, WORDS, picture=True)

    planner = ROOT / "data/planner.json"
    if planner.exists():
        for card in json.loads(planner.read_text(encoding="utf-8")).get("cards", []):
            c.add(card["word"], "Mano planas", WORDS, picture=True)

    # Game names in the Žaidimukai menu, spoken when a game opens.
    menu = (ROOT / "scripts/games_menu.gd").read_text(encoding="utf-8")
    for name in re.findall(r'\[\s*"([^"]+)",\s*ActivityTile\.Icon', menu):
        c.add(name, "Žaidimukai menu", GAMES_UI)
    # Home screen sections: the spoken word is the last string of each row.
    main = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
    for spoken in re.findall(r'"res://[^"]+\.tscn",\s*"([^"]+)"\s*\]', main):
        c.add(spoken, "Home screen", GAMES_UI)

    # Fixed phrases in the code.
    for gd in sorted((ROOT / "scripts").rglob("*.gd")):
        src = gd.read_text(encoding="utf-8")
        where = gd.stem.replace("_", " ")
        for text in re.findall(r'say(?:_wait)?\(\s*"([^"]+)"\s*\)', src):
            c.add(text, f"code: {where}", GAMES_UI)
        for text in re.findall(r'\.get\(\s*"instruction",\s*"([^"]+)"\s*\)', src):
            c.add(text, f"code: {where}", PROMPTS)
        for text in re.findall(r'say_on_tap\s*:?=\s*"([^"]+)"', src):
            c.add(text, f"code: {where}", GAMES_UI)
    return c


def has_file(folder: Path, s: str, exts) -> bool:
    return any((folder / f"{s}.{e}").exists() for e in exts)


def status():
    c = collect()
    items = sorted(c.items.values(), key=lambda it: (GROUPS.index(it["group"]), it["slug"]))
    for it in items:
        it["where"] = sorted(it["where"])
        it["has_audio"] = has_file(AUDIO_DIR, it["slug"], AUDIO_EXT)
        it["has_photo"] = has_file(PHOTO_DIR, it["slug"], PHOTO_EXT) if it["picture"] else None
    return items


def short_where(where):
    """'Poros L1', 'Poros L3', 'Surask L2' -> 'Poros 1, 3 · Surask 2'."""
    games = {}
    for w in where:
        m = re.match(r"(.+) L(\d+)$", w)
        if m:
            games.setdefault(m.group(1), []).append(int(m.group(2)))
        else:
            games.setdefault(w, [])
    parts = []
    for g, lv in games.items():
        parts.append(g + (" " + ", ".join(map(str, sorted(lv))) if lv else ""))
    return " · ".join(parts)


def write_markdown(items):
    total = len(items)
    done = sum(it["has_audio"] for it in items)
    missing = [it for it in items if not it["has_audio"]]
    no_photo = [it for it in items if it["picture"] and not it["has_photo"]]
    lines = [
        "# Voice recording list",
        "",
        "_Generated by `python3 tools/audio_status.py`: do not edit by hand, run the script again instead._",
        "",
        f"**Voice clips: {done} / {total} done, {len(missing)} to record.**"
        + (f" Pictures missing: {len(no_photo)}." if no_photo else " Every word has a picture."),
        "",
        "Save each clip as `assets/audio/words/<file name>.ogg` (or `.mp3` / `.wav`), then run the",
        "script again. Words without a clip are simply silent in the app.",
        "",
    ]
    for g in GROUPS:
        group = [it for it in missing if it["group"] == g]
        if not group:
            continue
        lines += [f"## {g} ({len(group)})", "", "| Say this | File name | Used in |", "|---|---|---|"]
        for it in group:
            lines.append(f"| {it['say']} | `{it['slug']}` | {short_where(it['where'])} |")
        lines.append("")
    if no_photo:
        lines += [f"## Missing pictures ({len(no_photo)})", "",
                  "Save as `assets/photos/<file name>.png` (square, 512×512).", "",
                  "| Word | File name | Used in |", "|---|---|---|"]
        for it in no_photo:
            lines.append(f"| {it['say']} | `{it['slug']}` | {short_where(it['where'])} |")
        lines.append("")
    recorded = [it for it in items if it["has_audio"]]
    lines += [f"## Already recorded ({len(recorded)})", "",
              ", ".join(f"{it['say']}" for it in recorded) or "–", ""]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    return done, total, missing, no_photo


def main(argv):
    items = status()
    if "--json" in argv:
        print(json.dumps(items, ensure_ascii=False, indent=1))
        return 0
    done, total, missing, no_photo = write_markdown(items)
    print(f"Voice clips: {done}/{total} done, {len(missing)} missing. "
          f"Pictures missing: {len(no_photo)}. Wrote {OUT.relative_to(ROOT)}")
    for g in GROUPS:
        group = [it["slug"] for it in missing if it["group"] == g]
        if group:
            print(f"  {g}: {', '.join(group)}")
    if no_photo:
        print("  Missing pictures: " + ", ".join(it["slug"] for it in no_photo))
    if "--check" in argv and (missing or no_photo):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
