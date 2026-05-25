"""Convert Duelyst .plist+.png unit atlases into Godot SpriteFrames .tres resources.

Usage:
    py tools/convert_units.py <unit_prefix> [<unit_prefix> ...]
    py tools/convert_units.py --all

Outputs into duelyst-td/assets/units/<prefix>/:
    <prefix>.png        (copied spritesheet)
    <prefix>.tres       (Godot SpriteFrames resource)

The .tres references the .png via AtlasTexture sub-resources (no slicing on disk).
"""
from __future__ import annotations
import plistlib
import re
import shutil
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "duelyst-main" / "duelyst-main" / "app" / "resources" / "units"
DEST = ROOT / "duelyst-td" / "assets" / "units"

FRAME_RE = re.compile(r"^(?P<base>.+)_(?P<idx>\d{3})\.png$")
LOOPING = {"idle", "breathing", "run", "walk"}
DEFAULT_FPS = 15.0


def parse_rect(s: str) -> tuple[float, float, float, float]:
    nums = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", s)]
    return tuple(nums)  # x, y, w, h


def short_id() -> str:
    return uuid.uuid4().hex[:5]


def convert(prefix: str) -> bool:
    plist_path = SRC / f"{prefix}.plist"
    png_path = SRC / f"{prefix}.png"
    if not plist_path.exists() or not png_path.exists():
        print(f"[skip] {prefix}: missing .plist or .png")
        return False

    with plist_path.open("rb") as f:
        data = plistlib.load(f)

    frames = data["frames"]
    # Group by animation
    anims: dict[str, list[tuple[int, dict]]] = {}
    for frame_name, frame_data in frames.items():
        m = FRAME_RE.match(frame_name)
        if not m:
            continue
        base = m.group("base")
        idx = int(m.group("idx"))
        # Strip the unit prefix to get the animation name
        if base.startswith(prefix + "_"):
            anim = base[len(prefix) + 1 :]
        else:
            anim = base
        anims.setdefault(anim, []).append((idx, frame_data))

    if not anims:
        print(f"[skip] {prefix}: no frames")
        return False

    # Sort frames within each animation
    for anim_frames in anims.values():
        anim_frames.sort(key=lambda t: t[0])

    out_dir = DEST / prefix
    out_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(png_path, out_dir / f"{prefix}.png")

    # Build the .tres file
    ext_id = f"1_{short_id()}"
    lines: list[str] = []
    # Header — count sub_resources + ext_resources for load_steps
    sub_atlas: list[tuple[str, tuple[float, float, float, float]]] = []
    anim_blocks: list[str] = []

    for anim_name in sorted(anims.keys()):
        frame_items = anims[anim_name]
        frame_tex_ids: list[str] = []
        for _idx, fd in frame_items:
            rect = parse_rect(fd["frame"])
            sid = f"AtlasTexture_{short_id()}"
            sub_atlas.append((sid, rect))
            frame_tex_ids.append(sid)
        loop = "true" if anim_name.lower() in LOOPING else "false"
        # Build frames array
        frame_entries = ", ".join(
            f'{{"duration": 1.0, "texture": SubResource("{sid}")}}'
            for sid in frame_tex_ids
        )
        anim_blocks.append(
            "{\n"
            f'"frames": [{frame_entries}],\n'
            f'"loop": {loop},\n'
            f'"name": &"{anim_name}",\n'
            f'"speed": {DEFAULT_FPS}\n'
            "}"
        )

    load_steps = len(sub_atlas) + 2  # +1 for ext_resource, +1 for [resource]
    lines.append(
        f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]\n'
    )
    lines.append(
        f'[ext_resource type="Texture2D" path="res://assets/units/{prefix}/{prefix}.png" id="{ext_id}"]\n'
    )
    for sid, rect in sub_atlas:
        x, y, w, h = rect
        lines.append(f'[sub_resource type="AtlasTexture" id="{sid}"]')
        lines.append(f'atlas = ExtResource("{ext_id}")')
        lines.append(f"region = Rect2({x}, {y}, {w}, {h})\n")
    lines.append("[resource]")
    lines.append("animations = [" + ", ".join(anim_blocks) + "]")

    tres_path = out_dir / f"{prefix}.tres"
    tres_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[ok]   {prefix}: {len(anims)} animations, {sum(len(a) for a in anims.values())} frames")
    return True


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    if args == ["--all"]:
        prefixes = sorted({p.stem for p in SRC.glob("*.plist")})
    else:
        prefixes = args
    ok = sum(convert(p) for p in prefixes)
    print(f"\nDone. Converted {ok}/{len(prefixes)} units.")


if __name__ == "__main__":
    main()
