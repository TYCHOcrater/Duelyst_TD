# Shardstorm TD

A roguelike co-op tower defense built in Godot 4.6, using [OpenDuelyst](https://github.com/openduelyst/duelyst) CC0 sprites.

## Status

Current iteration: **C0 — Player count plumbing** (Milestone C: Starbase Co-op architecture).

The single-player loop is feature-complete: 24 units across 6 factions, draft shop, traits/flaws/relics/pacts/evolution, 10 waves with splitter/silence/corruption special modifiers, run summary with failure coach, daily seed, mastery, procedural map generator, in-game map editor. Co-op architecture (`PlayerSlot` / `SessionController`) is now in place but multi-route gameplay lands in C1+.

See [`duelyst-td/docs/decisions.md`](duelyst-td/docs/decisions.md) for the full iteration log.

## Run it

1. Install Godot 4.6+ (Standard, not the C# build).
2. Open Godot → **Import** → point at `duelyst-td/project.godot`.
3. **Known quirk**: first import of a project with `class_name` scripts often needs two passes. If you see "Could not find type Command" on first F5, close Godot and reopen the project once.
4. F5 to play. Main menu → New Run.

## Design docs

The design is layered — read in this order:

1. [`co_op_roguelike_td_design_doc.md`](co_op_roguelike_td_design_doc.md) — the original §17 ten-iteration plan + MVP scope.
2. [`shardstorm_td_content_bible.md`](shardstorm_td_content_bible.md) — unit/enemy/trait/flaw/relic/pact reference.
3. [`shardstorm_td_research_engagement_addendum.md`](shardstorm_td_research_engagement_addendum.md) — engagement / replayability research.
4. [`shardstorm_td_next_roadmap_addendum.md`](shardstorm_td_next_roadmap_addendum.md) — post-MVP roadmap (Milestones A growth → C UI → B co-op → E maps; partially superseded by next doc).
5. [`shardstorm_td_coop_multiplayer_arena_addendum.md`](shardstorm_td_coop_multiplayer_arena_addendum.md) — current active roadmap: Starbase Co-op (C0-C12), Prism Clash arena (A0-A8).
6. [`duelyst-td/docs/decisions.md`](duelyst-td/docs/decisions.md) — every iteration's "what / why / impact / test" entry.
7. [`duelyst-td/docs/debug_guide.md`](duelyst-td/docs/debug_guide.md) — hotkeys + debug overlay + per-iteration manual test instructions.

## Repo layout

```
co_op_*.md, shardstorm_td_*.md   design docs
duelyst-td/                       Godot project (open this in the editor)
  ├── data/                       JSON content: units, enemies, waves, traits, flaws, relics, pacts, maps
  ├── scripts/                    GDScript
  ├── scenes/                     .tscn files
  ├── assets/                     sprites, audio, UI frames, fonts, cursor
  └── docs/                       decisions.md (iteration log) + debug_guide.md
tools/                            convert_units.py, package_iteration.ps1, etc.
```

`builds/` (excluded from git) holds per-iteration packaged `.exe` + source zip snapshots produced by `tools/package_iteration.ps1`. Playable builds are attached to GitHub Releases.

`duelyst-main/` (excluded from git) is the upstream OpenDuelyst source tree the asset converter reads from. Clone it from [openduelyst/duelyst](https://github.com/openduelyst/duelyst) at the same level as this repo if you want to re-run `tools/convert_units.py`.

## Credits

- **Sprites, audio, fonts**: [OpenDuelyst](https://github.com/openduelyst/duelyst) (CC0).
- **Cursor + UI frames**: OpenDuelyst.
- **Code, design, balance**: this repo.
