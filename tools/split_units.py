"""One-shot: split data/units.json into one file per unit in data/units/."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "duelyst-td"
SRC = ROOT / "data" / "units.json"
DEST = ROOT / "data" / "units"

with SRC.open(encoding="utf-8") as f:
    units = json.load(f)

DEST.mkdir(parents=True, exist_ok=True)
for uid, def_ in units.items():
    out = DEST / f"{uid}.json"
    out.write_text(json.dumps(def_, indent=2), encoding="utf-8")
    print(f"wrote {out.name}")

SRC.unlink()
print(f"\nSplit {len(units)} units; removed {SRC.name}")
