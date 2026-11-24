#!/usr/bin/env python3
"""Make every voice clip equally loud, so no word is quieter than another.

For each clip in assets/audio/words it:
  - measures the loudness of the speech only (silence ignored), in LUFS,
  - trims long silence at the start/end (keeps 0.15 s),
  - applies one gain so the speech sits at TARGET_LUFS, without letting peaks
    go above MAX_PEAK,
  - writes the clip back under the same name and format (so Godot's .import
    files stay valid; open the project in Godot once to re-import).
Needs ffmpeg.

Usage (from the project folder):
  python3 tools/level_clips.py              # show levels, change nothing
  python3 tools/level_clips.py --apply      # level every clip that is off by more than 0.5 dB
  python3 tools/level_clips.py --apply suo kate   # only these
"""
import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORDS = ROOT / "assets/audio/words"
EXTS = (".ogg", ".mp3", ".wav")

TARGET_LUFS = -20.0   # speech loudness of every clip
MAX_PEAK = -1.5       # dB, sample peak after the gain
PAD = 0.15            # silence kept at each end, seconds
SILENCE_DB = -45      # quieter than this counts as silence
TOLERANCE = 0.5       # dB; closer than this = leave the clip alone

ENCODE = {
    ".ogg": ["-c:a", "libvorbis", "-q:a", "5"],
    ".mp3": ["-c:a", "libmp3lame", "-q:a", "2"],
    ".wav": ["-c:a", "pcm_s16le"],
}


def _ffmpeg_log(args):
    return subprocess.run(["ffmpeg", "-hide_banner", "-nostats", *args],
                          capture_output=True, text=True).stderr


def speech_bounds(src: Path):
    """(start, end) of the sound in the clip, in seconds."""
    dur = float(subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(src)],
        capture_output=True, text=True, check=True).stdout.strip())
    log = _ffmpeg_log(["-i", str(src), "-af", f"silencedetect=noise={SILENCE_DB}dB:d=0.1", "-f", "null", "-"])
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
    start, end = 0.0, dur
    if starts and starts[0] <= 0.01 and ends:          # leading silence
        start = ends[0]
    if starts and (len(ends) < len(starts) or ends[-1] >= dur - 0.01):  # trailing silence
        end = starts[-1]
    if end - start < 0.1:                               # nothing found: keep everything
        start, end = 0.0, dur
    return start, end, dur


def measure(src: Path, start=None, end=None):
    """(loudness LUFS of the speech, sample peak dB)."""
    cut = ["-ss", f"{start:.3f}", "-to", f"{end:.3f}"] if start is not None else []
    # Pad with silence: the loudness meter needs at least 0.4 s of audio.
    log = _ffmpeg_log(["-i", str(src), *cut, "-af", "apad=pad_dur=0.5,ebur128=peak=sample",
                       "-f", "null", "-"])
    lufs = re.findall(r"^\s+I:\s+([-\d.]+) LUFS", log, re.M)
    peak = re.findall(r"^\s+Peak:\s+([-\d.inf]+) dBFS", log, re.M)
    return float(lufs[-1]), float(peak[-1])


def level(src: Path, dest: Path, start: float, end: float, dur: float):
    """Write the trimmed, levelled clip to dest. Returns the gain used (dB)."""
    lufs, peak = measure(src, start, end)
    gain = min(TARGET_LUFS - lufs, MAX_PEAK - peak)
    a = max(0.0, start - PAD)
    b = min(dur, end + PAD)
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
         "-ss", f"{a:.3f}", "-to", f"{b:.3f}",
         "-af", f"volume={gain:.2f}dB,afade=t=in:d=0.02,areverse,afade=t=in:d=0.04,areverse",
         "-ac", "1", "-ar", "44100", *ENCODE[dest.suffix], str(dest)],
        check=True)
    return gain


def clips(names):
    files = sorted(p for p in WORDS.iterdir() if p.suffix in EXTS)
    if names:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from audio_status import slug
        wanted = {slug(n) for n in names}
        files = [p for p in files if p.stem in wanted]
    return files


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("names", nargs="*", help="only these clips (word or file name)")
    ap.add_argument("--apply", action="store_true", help="write the levelled clips")
    args = ap.parse_args(argv)

    changed = 0
    print(f"target {TARGET_LUFS} LUFS, peaks ≤ {MAX_PEAK} dB")
    for p in clips(args.names):
        start, end, dur = speech_bounds(p)
        lufs, peak = measure(p, start, end)
        gain = min(TARGET_LUFS - lufs, MAX_PEAK - peak)
        trim = (start - PAD) > 0.05 or (dur - end - PAD) > 0.05
        off = abs(gain) > TOLERANCE
        note = ("ok" if not (off or trim) else
                f"{gain:+.1f} dB" + (", trim silence" if trim else ""))
        print(f"  {p.name:26} {lufs:6.1f} LUFS  peak {peak:6.1f}  {dur:4.2f}s  {note}")
        if args.apply and (off or trim):
            with tempfile.TemporaryDirectory() as tmp:
                out = Path(tmp) / p.name
                level(p, out, start, end, dur)
                shutil.move(str(out), p)
            changed += 1
    if args.apply:
        print(f"Levelled {changed} clip(s). Open the project in Godot once so it re-imports them.")
    else:
        print("Nothing changed (add --apply to level them).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
