# Žingsneliai

Lithuanian-language learning app for children with special needs (autism, speech delay), ages ~2–8.

- **Engine:** Godot 4.7, Android + iOS, GL Compatibility renderer, landscape (tablet-first)
- **Design:** https://www.figma.com/design/j6rsGrX3D9oCRPslNiDnAK
- **Tasks:** https://trello.com/b/jd5zb01H

## MVP
1. ~100 Lithuanian words in themes, each with a photo and a voice recording (`data/words.json`)
2. Mini-games: matching, sorting, "find the ___", puzzle, bubble pop, sound imitation
3. Picture board for talking (tap a card, it speaks)
4. Parent area: progress, sound/motion/difficulty settings, parent lock
5. Free start + subscription, no ads

## Design rules
Soft colours, no flashing, sound can be muted, no time pressure, no "wrong" buzzer, real photos and human voices.

## Project layout
- `scenes/main.tscn` – home screen with two sections + "Išeiti", and Olis waving on the left
- **Olis** the owl (`scripts/ui/owl.gd`, class `Owl`) – the child's companion, in the bottom-left corner of the games menu and every game (game content stays centred and clear of his corner). Reacts with short poses: thumbs up on a correct answer, thinking after a wrong try (never sad), listening while the game speaks/shows, cheering when a level is done; tap him and he waves and says hello. Also cheers on the "Šaunu!" card
- **Mano planas** `scenes/planner.tscn` (`scripts/planner/`) – a magnetic board with 6 numbered spaces.
  Drag picture magnets from the tray onto the board to build a plan or story; tap a magnet to hear it;
  drag between spaces to swap, off the board to remove; the speaker reads the plan in order. Saved on
  the device (`user://plan.json`). Pictures and words in `data/planner.json`.
- **Žaidimukai** `scenes/games_menu.tscn` – the mini-games (`scenes/games/`, `scripts/games/`), 6 levels each (Burbulai: generated), levels in `data/levels/*.json`. The "Šaunu!" card has a → button to the next level:
  - **Burbulai** `bubble_pop` – tap slowly rising bubbles; levels from `bubble_level_generator.gd` (deterministic; no fail)
  - **Poros** `matching` – tap a picture, then its twin in the other row
  - **Rūšiuok** `sorting` – drag (or tap, then tap a basket) each picture into baskets (Gyvūnai / Maistas / Transportas, Vaisiai / Daržovės; 2–3 baskets)
  - **Surask** `find` – hear "Surask šunį", tap the right picture (pictures only, no words; 2–4 pictures)
  - **Dėlionė** `puzzle` – drag pieces into the faint picture; they snap in when close (2 → 6 pieces)
  - **Kartok** `repeat` – hear "Šuo sako: au au!", say it back; any sound heard (or tapping the mic) counts. Nothing is recorded or stored.
  - **Sekos** `sequence` – a row of random capital letters stays on screen; press the buttons in the same order (the next letter is outlined; after 3 misses the right button pulses). Levels from `sequence_generator.gd`, endless: 2–4 letters (L1–10), +4 every 10 levels up to 16; the row's letters plus a few extra buttons, full alphabet keyboard from L21. Sounds only, no voice; the last level reached is remembered
  - **Atmintis** `memory` – 5 coloured squares (one in the middle, four at its corners), each with its own soft note; the game lights a sequence (0.5 s per square), the child repeats it, each round adds one random square. Two modes chosen on opening: **Lygiai** (levels from `memory_generator.gd`, level n builds up to n+2 squares; a wrong press only re-shows the round; last level remembered) and **Išbandymas** (endless random sequence until the first miss, then a calm card: how many were remembered + the best). No voice for the squares
  - **Raidės** `letter_pairs` – connect each capital letter with its small letter by drawing a line with a finger (or tap one, then its partner); a right pair keeps its line and colour, a wrong one slides back. 5 stages × 10 levels (`letter_pairs_generator.gd`): printed columns, cursive columns, printed tangle, cursive tangle, mixed printed+cursive; inside a stage the whole Lithuanian alphabet in order (1, 2, 3, then 4 pairs per level), tangle stages add a few letters without a partner from level 6. Opens on a stage choice; a stage unlocks when the previous one is finished; progress saved. Cursive font: Playwrite HR (OFL, `assets/fonts/`). Sounds only, no voice
  - **Atspėk** `letters` – word riddle: a picture above each empty box; put each picture's first letter in its box to find the hidden word (STALAS, SALA, LOVA, MORKA, DUONA, TORTAS). Drag a letter or tap letter then box; tap a picture to hear it.
- `assets/characters/` – the owl companion: `owl.png` plus poses `owl_wave`, `owl_thumbs_up`, `owl_point`, `owl_cheer`, `owl_think`, `owl_listen`, `owl_read`, `owl_sleepy` (transparent PNGs, cut from `owl_pose_sheet.png`)
- `scripts/ui/` – shared controls (RoundButton, PictureCard, Basket, MicButton, WellDone, GameUI helpers)
- `docs/credits_log.md` – ElevenLabs credits spent on this project (every generation, with running total)
- `docs/voice_todo.md` – words/phrases that still need a recorded voice clip (generated, see Tools)
- `scripts/word_bank.gd` – finds a word's picture/voice by ASCII slug (`Surask šunį` → `surask_suni.mp3`)
- `scripts/sound.gd` (autoload `Sound`) – voice + soft effects, respects parent settings

## Tools
- `godot --headless -s tools/bubble_levels.gd` – print the bubble difficulty curve
- `godot --headless -s tools/bubble_levels.gd -- --export 20` – write 20 generated levels to `data/levels/bubbles_generated.json`
- `python3 tools/audio_status.py` – check every word/phrase the app says against the clips and pictures; rewrites `docs/voice_todo.md` (`--json` for raw status, `--check` exits 1 if anything is missing)
- `python3 tools/split_clips.py take.mp3 --missing words` – cut a long recording (words with pauses) into one clip per word, levelled and saved as `assets/audio/words/<name>.ogg`; or give the names yourself: `… take.mp3 agurkas antis avis`
- `python3 tools/level_clips.py` – show every voice clip's loudness; `--apply` levels them all to the same loudness (−20 LUFS) and trims long silences (the splitter does this for new clips automatically)
- `python3 -I tools/cut_green_sheet.py sheet.png out_dir prefix name1 name2 …` – cut a green-screen sheet into separate transparent PNGs (keeps muted greens; used for the owl poses)
- `python3 tools/make_sfx.py` – regenerate the soft `pop`/`chime` sounds and the five Atmintis notes (`note1–5`, C D E G A)
- `python3 tools/square_picture.py in.png out.png` – square-crop a generated picture around its subject (512×512)

## Assets (prototype)
- Pictures: ElevenLabs image generation (calm pastel cartoon style), cropped to 512×512
- Voice: ElevenLabs `eleven_v4`, voice "Žilvinas – Lithuanian Male Voice" (pronunciation test)
- Font: Nunito ExtraBold (SIL Open Font License)

## Android build
- Export preset: **Android** in `export_presets.cfg` (no Gradle; arm64 + armv7; package `lt.zingsneliai.app`)
- In Godot: *Project → Export… → Android → Export Project*. Needs the Android export templates and an Android SDK path in *Editor Settings → Export → Android*.
- Latest test APK: `zingsneliai.apk` on the `apk` branch
