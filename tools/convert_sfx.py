"""Convert selected Duelyst .m4a sfx into .ogg files Godot can import.

Usage: py tools/convert_sfx.py
Edits SFX_MAP below to add/remove sounds.
"""
from __future__ import annotations
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "duelyst-main" / "duelyst-main" / "app" / "resources" / "sfx"
DEST = ROOT / "duelyst-td" / "assets" / "sfx"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

# Source-file -> output-name (without .ogg)
SFX_MAP = {
    "deploy_circle1.m4a": "place_tower",
    "select.m4a": "ui_select",
    "notification.m4a": "wave_start",
    "sfx_f1_silvermanevanguard_attack_swing.m4a": "tower_archer_shoot",
    "sfx_f1_grandmasterzir_attack_swing.m4a": "tower_caster_shoot",
    "sfx_f1_ironcliffeguardian_death.m4a": "enemy_death",
    "sfx_f1_general_hit.m4a": "base_hit",
}


def convert(src_name: str, out_name: str) -> bool:
    src = SRC / src_name
    out = DEST / f"{out_name}.ogg"
    if not src.exists():
        print(f"[miss] {src_name}")
        return False
    DEST.mkdir(parents=True, exist_ok=True)
    cmd = [
        FFMPEG, "-y", "-loglevel", "error",
        "-i", str(src), "-c:a", "libvorbis", "-q:a", "4", str(out),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[fail] {src_name}: {res.stderr.strip()}")
        return False
    print(f"[ok]   {src_name} -> {out.name}")
    return True


def main():
    ok = sum(convert(s, o) for s, o in SFX_MAP.items())
    print(f"\nConverted {ok}/{len(SFX_MAP)} sounds.")


if __name__ == "__main__":
    main()
