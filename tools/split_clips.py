#!/usr/bin/env python3
"""Cut one long recording (several words with pauses between them) into one
voice clip per word, ready for the app.

Each piece is trimmed, gets a little silence at both ends, is evened out in
loudness, and is saved as assets/audio/words/<file name>.ogg. Needs ffmpeg.

Usage (from the project folder):
  python3 tools/split_clips.py take.mp3 agurkas antis avis
      names given in the order they are spoken (file names or the words themselves)
  python3 tools/split_clips.py take.mp3 --missing "Words"
      use the next missing clips of that group from tools/audio_status.py, in list order
  python3 tools/split_clips.py take.mp3 --dry-run agurkas antis
      only show what was found, write nothing

If the number of pieces found doesn't match the number of names, nothing is
written and the pieces are listed so you can adjust (--min-silence, --threshold)
or re-record. Use --force to write anyway (extra pieces are dropped).
Existing clips are only replaced with --overwrite.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import audio_status  # noqa: E402  (same folder)

OUT_DIR = ROOT / "assets/audio/words"
PAD = 0.15          # seconds of silence kept before and after each word
MIN_WORD = 0.25     # shorter sounds are breaths/clicks, not words
TARGET_MEAN = -24.0 # dB, about the level of the app's other voice clips
MAX_PEAK = -3.0     # dB, never louder than this


def find_pieces(src: Path, threshold_db: float, min_silence: float):
    """Return [(start, end)] of the non-silent parts, in seconds."""
    dur = float(subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(src)],
        capture_output=True, text=True, check=True).stdout.strip())
    log = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(src), "-af",
         f"silencedetect=noise={threshold_db}dB:d={min_silence}", "-f", "null", "-"],
        capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
    # Sound runs from the end of one silence to the start of the next.
    edges_on = [0.0] + ends
    edges_off = starts + [dur]
    pieces = []
    for on, off in zip(edges_on, edges_off):
        if off - on >= MIN_WORD:
            pieces.append((on, off))
    return pieces, dur


def levels(src: Path, a: float, b: float):
    """(mean, peak) volume in dB of the word itself."""
    log = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(src), "-ss", f"{a:.3f}", "-to", f"{b:.3f}",
         "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True).stderr
    mean = float(re.search(r"mean_volume: ([-\d.]+) dB", log).group(1))
    peak = float(re.search(r"max_volume: ([-\d.]+) dB", log).group(1))
    return mean, peak


def export(src: Path, start: float, end: float, dur: float, dest: Path):
    a = max(0.0, start - PAD)
    b = min(dur, end + PAD)
    # One plain gain per clip so every word sits at the same level as the others
    # (loudness normalisers are unreliable on clips this short).
    mean, peak = levels(src, start, end)
    gain = min(TARGET_MEAN - mean, MAX_PEAK - peak)
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
         "-ss", f"{a:.3f}", "-to", f"{b:.3f}",
         "-af", f"volume={gain:.2f}dB,afade=t=in:d=0.02,areverse,afade=t=in:d=0.04,areverse",
         "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(dest)],
        check=True)


def existing_clip(slug: str):
    for ext in audio_status.AUDIO_EXT:
        p = OUT_DIR / f"{slug}.{ext}"
        if p.exists():
            return p
    return None


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("take", type=Path, help="the recording (mp3/wav/ogg/m4a)")
    ap.add_argument("names", nargs="*", help="what is said, in order (word or file name)")
    ap.add_argument("--missing", metavar="GROUP",
                    help='take names from the tracker: next missing clips of this group (e.g. "Words")')
    ap.add_argument("--threshold", type=float, default=-40.0, help="silence level in dB (default -40)")
    ap.add_argument("--min-silence", type=float, default=0.4, help="shortest pause between words, s (default 0.4)")
    ap.add_argument("--dry-run", action="store_true", help="show what was found, write nothing")
    ap.add_argument("--force", action="store_true", help="write even if the counts don't match")
    ap.add_argument("--overwrite", action="store_true", help="replace clips that already exist")
    args = ap.parse_args(argv)

    pieces, dur = find_pieces(args.take, args.threshold, args.min_silence)

    if args.missing:
        groups = {g.lower(): g for g in audio_status.GROUPS}
        group = next((g for k, g in groups.items() if k.startswith(args.missing.lower())), None)
        if group is None:
            sys.exit(f"Unknown group {args.missing!r}. Groups: " + "; ".join(audio_status.GROUPS))
        todo = [it for it in audio_status.status() if it["group"] == group and not it["has_audio"]]
        slugs = [it["slug"] for it in todo][:len(pieces)]
    else:
        slugs = [audio_status.slug(n) for n in args.names]
    if not slugs:
        sys.exit("No names: give them after the file, or use --missing GROUP.")

    print(f"{args.take.name}: {dur:.1f} s, found {len(pieces)} piece(s), expected {len(slugs)}")
    for i, (a, b) in enumerate(pieces):
        name = slugs[i] if i < len(slugs) else "(extra, dropped)"
        print(f"  {i + 1:2}. {a:6.2f}–{b:6.2f} s  ({b - a:.2f} s)  -> {name}")
    if len(pieces) != len(slugs):
        print("Counts don't match. Try --min-silence 0.3 (words merged) or 0.6 (a word split), "
              "or --threshold -35 (noisy room).")
        if not args.force:
            return 1
    if args.dry_run:
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    for (a, b), s in zip(pieces, slugs):
        old = existing_clip(s)
        if old and not args.overwrite:
            print(f"  skip {s}: {old.name} already exists (use --overwrite)")
            continue
        if old and old.suffix != ".ogg":
            old.unlink()  # don't leave two clips for the same word
        export(args.take, a, b, dur, OUT_DIR / f"{s}.ogg")
        written += 1
    print(f"Wrote {written} clip(s) to {OUT_DIR.relative_to(ROOT)}/. "
          "Run python3 tools/audio_status.py to update the list.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
