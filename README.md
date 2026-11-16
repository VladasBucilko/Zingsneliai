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
- `scenes/main.tscn` – home screen with two sections + "Išeiti"
- **Mano planas** `scenes/planner.tscn` (`scripts/planner/`) – a magnetic board with 6 numbered spaces.
  Drag picture magnets from the tray onto the board to build a plan or story; tap a magnet to hear it;
  drag between spaces to swap, off the board to remove; the speaker reads the plan in order. Saved on
  the device (`user://plan.json`). Pictures and words in `data/planner.json`.
- **Žaidimukai** `scenes/games_menu.tscn` – the mini-games (`scenes/games/`, `scripts/games/`), one level each, levels in `data/levels/*.json`:
  - **Burbulai** `bubble_pop` – tap slowly rising bubbles; levels from `bubble_level_generator.gd` (deterministic; no fail)
  - **Poros** `matching` – tap a picture, then its twin in the other row
  - **Rūšiuok** `sorting` – drag (or tap, then tap a basket) each picture into Gyvūnai / Maistas
  - **Surask** `find` – hear "Surask šunį", tap the right picture (pictures only, no words)
  - **Dėlionė** `puzzle` – drag pieces into the faint picture; they snap in when close
  - **Kartok** `repeat` – hear "Šuo sako: au au!", say it back; any sound heard (or tapping the mic) counts. Nothing is recorded or stored.
- `scripts/ui/` – shared controls (RoundButton, PictureCard, Basket, MicButton, WellDone, GameUI helpers)
- `scripts/word_bank.gd` – finds a word's picture/voice by ASCII slug (`Surask šunį` → `surask_suni.mp3`)
- `scripts/sound.gd` (autoload `Sound`) – voice + soft effects, respects parent settings

## Tools
- `godot --headless -s tools/bubble_levels.gd` – print the bubble difficulty curve
- `godot --headless -s tools/bubble_levels.gd -- --export 20` – write 20 generated levels to `data/levels/bubbles_generated.json`
- `python3 tools/make_sfx.py` – regenerate the soft `pop`/`chime` sounds
- `python3 tools/square_picture.py in.png out.png` – square-crop a generated picture around its subject (512×512)

## Assets (prototype)
- Pictures: ElevenLabs image generation (calm pastel cartoon style), cropped to 512×512
- Voice: ElevenLabs `eleven_v4`, voice "Žilvinas – Lithuanian Male Voice" (pronunciation test)
- Font: Nunito ExtraBold (SIL Open Font License)

## Android build
- Export preset: **Android** in `export_presets.cfg` (no Gradle; arm64 + armv7; package `lt.zingsneliai.app`)
- In Godot: *Project → Export… → Android → Export Project*. Needs the Android export templates and an Android SDK path in *Editor Settings → Export → Android*.
- Latest test APK: `zingsneliai.apk` on the `apk` branch
