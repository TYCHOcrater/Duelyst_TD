# Debug Guide

One-stop reference for testing what's been built. Updated each iteration.

If you can't tell whether a feature works, look here first.

---

## Hotkeys (during a run)

| Key | Function |
|---|---|
| **F1** | Toggle Run Stats overlay (gold/kills/leaks/damage/etc.) |
| **F2** | Toggle Last Commands overlay (with ✓/✗ marks + rejection reasons) |
| **F3** | Reload current map JSON (tiles + path re-derive; existing enemies/towers stay) |
| **Space** | Pause / resume |
| **Enter** | Start wave (planning phase only) |
| **R** | Reroll shop (planning phase only) |
| **1 / 2 / 3** | Quick-pick draft offer #1, #2, #3 |
| **Esc** | Cancel current selection / tower pick |
| **Right-click** | Cancel selection / deselect picked tower |

## Mouse

| Action | Effect |
|---|---|
| Click draft offer card | Toggles preview placement of that unit |
| Left-click while previewing | Place tower (dispatches `PlaceUnitCommand`) |
| Left-click on placed tower | Open tower panel (upgrade/sell) |
| Right-click anywhere | Cancel |

---

## Scenes

| Scene | How to access | What's there |
|---|---|---|
| `scenes/main_menu.tscn` | Project default — F5 from editor | "Project Loaded" splash, seed input, randomize, **Run Determinism Test**, New Run, Quit |
| `scenes/main.tscn` | "New Run" from menu, or F5 with main.tscn open | The actual game — planning/combat phases, HUD, debug overlay |
| `scenes/board.tscn` | Instanced by `main.tscn` | Tile grid renderer + hover indicator + enemy Path2D. Hover any tile to see `(col, row) TYPE`. |
| `scenes/debug_overlay.tscn` | Auto-instantiated by main.gd; toggle via F1/F2 | Live stats + command history overlays |

## Autoloads (always-on singletons)

| Name | Role |
|---|---|
| `GameState` | Gold/lives/wave state. Signals: `gold_changed`, `lives_changed`, `wave_changed`, `game_over` |
| `AudioManager` | Pool of `AudioStreamPlayer`s; call `play("name", pitch_variance)` |
| `SessionRng` | Seeded RNG. All gameplay randomness goes through this |
| `UnitFactory` | Loads `data/units/*.json` at startup. `make_tower(id)` builds a tower node |
| `EnemyFactory` | Loads `data/enemies/*.json` + `data/waves/*.json`. `make_enemy(id)` builds an enemy. `get_wave_set(id)` returns a wave-set dict. |
| `PactManager` | Loads `data/pacts/*.json`. Tracks `active_ids`. Pact-specific data only — for effect totals, query `ModifierTotals`. |
| `RelicManager` | Loads `data/relics/*.json`. Same shape as PactManager. |
| `Daily` | Owns today's seed, score formula, persisted scoreboard at `user://daily_scores.json`, share-text generator. |
| `ModifierTotals` (class, not autoload) | `ModifierTotals.sum_int(type)` / `product_float(type)` / `has_flag(type)` — sums across all modifier sources (pacts + relics). Use this everywhere effects are consumed. |
| `MapLoader` (class, not autoload) | `MapLoader.load_path(res_path)` → `{ok, map}` or `{ok:false, error}`. Validates spawn/core/path connectivity. |
| `GridController` (class, not autoload) | Tile data + `grid_to_world` / `world_to_grid` / `is_buildable` / `is_path` / `build_path_curve`. Owned by Board. |
| `RunConfig` | Holds current run's seed/max_waves/etc. Set by main menu, read by `main.gd` |
| `RunLog` | Records every event during a run; dumps JSON at end |
| `CommandBus` | Dispatches `Command` objects; logs every attempt |

---

## Where stuff is saved

| What | Where (Windows) |
|---|---|
| End-of-run JSON log | `%APPDATA%\Godot\app_userdata\Duelyst_TD\run_log_*.json` |
| Iteration package zips | `builds/iter-*.zip` and `.exe` |
| Decisions ledger | `docs/decisions.md` |
| Build index | `builds/INDEX.md` |

To open the user directory quickly: run from PowerShell:
```powershell
explorer "$env:APPDATA\Godot\app_userdata\Duelyst_TD"
```

---

## Per-iteration test checklists

### Iter 0.1 — Project skeleton
- [ ] Godot opens the project without script errors.
- [ ] Main menu (project default) shows "Shardstorm TD — Project Loaded".
- [ ] `docs/decisions.md` exists.
- [ ] These dirs exist: `scenes/ scripts/ scripts/commands/ data/units/ data/enemies/ data/waves/ data/maps/ data/traits/ data/relics/ docs/ debug/`.
- [ ] At least 12 JSON files in `data/units/`.

### Iter 0.2 — Run config + seeded RNG
- [ ] Main menu shows current seed (e.g. `SHARD-3A7F910C`).
- [ ] **↻** (Randomize) button generates a new seed.
- [ ] Seed field accepts: `SHARD-0000007B`, `7B`, `123` — all map to seed 123.
- [ ] **Run Determinism Test** → green "PASS" line.
- [ ] Type seed `123` → New Run, abort, type `123` again → New Run. First 3 draft offers match exactly.
- [ ] HUD top bar shows seed during the run.

### Iter 0.3 — Command-based player actions
- [ ] Click any offer → F2 panel shows `BuyOfferCommand #N` with ✓.
- [ ] Click on map with preview active → F2 shows `PlaceUnitCommand` with ✓ or ✗ + reason.
- [ ] Click on path → ✗ "invalid placement (on path / too close to tower / off-screen)".
- [ ] Click with insufficient gold → ✗ "insufficient gold (have X, need Y)".
- [ ] Click Reroll → ✗ "insufficient gold" if broke; else ✓.
- [ ] Click Start Wave → ✓ `StartWaveCommand`.
- [ ] Click a placed tower → tower panel opens. Click Sell → ✓ `SellUnitCommand`. Click Upgrade → ✓ or ✗ + reason.

### Iter 0.4 — Run logger
- [ ] Press F1 → stats panel shows seed/wave/result + all counters at 0 on run start.
- [ ] Place a tower → `units_bought` increments, `gold_spent` adds the cost.
- [ ] Start wave → enemies appear; killing them increments `enemies_killed` + `gold_earned`.
- [ ] An enemy reaching the base → `leaks` increments + `core_damage_taken`.
- [ ] Damage dealt counter goes up as your towers fire.
- [ ] **Export log JSON** button in F1 panel → writes file. Path shown in the panel. Check `%APPDATA%\Godot\app_userdata\Duelyst_TD\`.
- [ ] End a run (win or lose) → another JSON file auto-written.

### Iter 13.3 — Songhai Burst content pack
- [ ] 4 new units: Chakri Avatar (STRIKE 2.6/s), Geomancer (ARCANE splash), Onyx Jaguar (STRIKE strongest-target), Lantern Fox (AURA +28%).
- [ ] Wave 8 spawns Clad Juggernaut at delay 12s (A8 + P50 + M20 chips).
- [ ] Strike-only build struggles vs Clad Juggernaut; arcane (Geomancer/Pyromancer) cuts through.
- [ ] Duelist's Bet pact (+5 gold/kill) noticeably boosts economy when Chakri Avatar clears swarms.

### Iter 8.4 — Unit mastery
- [ ] Main menu "Unit Mastery" button opens a panel.
- [ ] First open: "No runs recorded yet."
- [ ] After one run, units appear with their stats.
- [ ] Cross-run accumulation: kills add up over multiple runs.
- [ ] Tier names appear when thresholds cross (Initiate / Adept / Master / Champion / Legend).
- [ ] `user://mastery.json` persists.

### Iter 6.2c — Corruption waves
- [ ] Wave 8 preview shows purple "Corruption" tag with hint.
- [ ] Each leak during wave 8 turns a buildable tile near the core purple with a swirl marker.
- [ ] Towers on corrupted tiles fire at 70% rate (visibly slower than clean-tile towers).
- [ ] Corrupted tile count caps at 6 per wave.
- [ ] All corruption clears when wave 8 ends; wave 9 starts clean.
- [ ] Selling a tower off a corrupted tile + placing it on a clean tile restores full fire rate.

### Iter 6.2b — Silence waves
- [ ] Wave 6 preview shows cyan "Silence" tag.
- [ ] 5 s in, all towers pause; pulsing "⚠ SILENCE" banner appears top-center.
- [ ] After 1.5 s, banner clears + all ready towers fire in a synced volley.
- [ ] Repeats every 9 s.
- [ ] Other waves: no silence banner.

### Iter 6.2 — Splitter enemies
- [ ] Wave 9 preview shows the green "Splitter" tag.
- [ ] Silithar Broodmother (greenish, scale 1.4×) spawns 2 s into wave 9.
- [ ] On her death, 3 Younglets appear at her path position.
- [ ] Each younglet has its own HP bar / kill reward.
- [ ] Splash on the Broodmother can hit the brood that just spawned.
- [ ] Single-target kill on Broodmother → 3 more enemies to deal with.
- [ ] No recursive infinite splits (younglets don't split further).

### Iter 13.2 — Vanar Frost Control content pack
- [ ] 4 new units in pool: Hearth-Sister (AURA chip), Gravity Well, Frostiva, Kindred Hunter — all FROST chip.
- [ ] Gravity Well: longest slow (1.8s @ 40%).
- [ ] Kindred Hunter: 260px range, longest in the roster.
- [ ] Heart of Winter pact + Vanar Banner relic + Spreading Frost relic stack to ~2.9× base slow duration.
- [ ] Wave 7 spawns 1 Sun-Priest 7s in (gold-tinted, fast, 60% magic resist visible as M60 chip).
- [ ] Frost damage minimal vs Sun-Priest; physical (Archer/Kaido) cuts through.
- [ ] Challenge seed `F8051CE0` leans Vanar in early draft.

### Iter 9.1 — Combat readability
- [ ] Wave 10 banner reads "⚠ Wave 10 · BOSS ⚠" in red. Other waves white.
- [ ] Hover any placed tower (without clicking): gold line draws from tower to its current target.
- [ ] Hover off: line disappears.
- [ ] Hits ≥15 damage spawn a floating "+N" popup colored by damage type; smaller hits don't.

### Iter 5.5 — Unit evolution
- [ ] Place a tower early. Tower panel shows "0 / 15 kills to Tempered" line.
- [ ] At 15 kills, gold star appears above the sprite; damage jumps; panel reads "★1 Tempered (15 kills)".
- [ ] At 40 kills, two stars + larger range circle (Veteran).
- [ ] At 80 kills, three stars + faster fire rate (Legendary).
- [ ] Pyromancer/Firebreather splash kills credit the source tower correctly.
- [ ] Selling an evolved tower mid-run is safe (no crash from projectiles in flight).
- [ ] End-of-run JSON has `evolutions_by_tier` dict.

### Iter 4.5 — Unit flaws
- [ ] Some trait-bearing offers also show "FLAW · X" in the same chip, red-tinted.
- [ ] No offer ever shows a flaw without a trait.
- [ ] Heavy + Brittle Archer deals less damage than pure Heavy Archer.
- [ ] Veteran + Costly stacks cost mults correctly (×1.5 × 1.4 ≈ 2.1× base).
- [ ] Tower panel shows "Unit (Lvl N) · Trait / Flaw".
- [ ] End-of-run JSON has `flaws_taken` dict.

### Iter 4.4 — Unit traits + HUD pass
- [ ] Some draft offers show TRAIT chip below the damage-type chip; rarity-colored (gray/green/blue).
- [ ] Trait chance ramps with wave (more frequent late game).
- [ ] Heavy/Swift/Long-Eyed/Glass visibly change tower stats.
- [ ] Veteran offer: cost shown as "Ng (was Mg)", places at Lvl 2.
- [ ] Frostbound trait grants slow even to non-slow units.
- [ ] Buff-only towers never get traits.
- [ ] Tower panel shows trait name next to level.
- [ ] End-of-run JSON has `traits_taken` dict.
- [ ] End panel fits entirely on screen (no buttons cut off).
- [ ] F1/F2 debug panels clear the bottom bar.
- [ ] IncomeFloater appears top-center, doesn't overlap pacts ribbon.

### Iter 13.1 — Abyssian Choir content pack
- [ ] 4 new units in draft pool: Gloomchaser, Shadowdancer, Aphotic Devourer, Black Solus. All show SPIRIT chip (Black Solus shows AURA).
- [ ] Soul Auction pact appears after wave 3/6/9 rolls.
- [ ] Echo Reliquary relic appears after wave 5.
- [ ] Wave 8 spawns a Sanctified Bulwark mid-wave (gold-tinted, chips show A5/P25/M65).
- [ ] Wave 10 spawns a Sanctified Bulwark 10 s into the boss wave.
- [ ] Spirit-only build deals minimal damage to the Bulwark; physical/frost cuts through it.
- [ ] Aphotic Devourer locks onto highest-HP enemy (visible by kill order).
- [ ] Black Solus aura grants +35% damage to nearby towers (verify via tower panel comparison).
- [ ] Challenge seed `AB551A4E` produces an Abyssian-heavy first draft.

### Iter 8.5 — Daily seed
- [ ] Main menu shows "Daily Storm" section with today's seed + ISO date.
- [ ] "Play Daily" starts a run; HUD seed matches.
- [ ] End panel shows DAILY STORM badge + big Score + rank line.
- [ ] "Copy Share Text" copies a 6-line summary to clipboard.
- [ ] After run, main menu shows updated "Best today" + recent dailies list.
- [ ] `user://daily_scores.json` contains today's entries with score, run_name, pacts/relics.
- [ ] "New Run (new seed)" exits daily mode (no badge on next end).
- [ ] "Replay (same seed)" preserves daily mode.

### Iter 5.1 — Relics
- [ ] Beat wave 5. "Choose a Relic" modal appears with 3 sky-blue cards showing Boon only.
- [ ] Pick one; top-left ribbon adds a "Relics:" line.
- [ ] Each relic's effect visibly fires (Coin Engine +1 per kill, Loadbearer Banner half-price upgrades, Sun Aegis first-leak free, Treasury Doctrine +3 planning gold, Spreading Frost longer SLO chip, Mercy Sigil shorter HP bars).
- [ ] After wave 6, pact modal returns with gold header — relic flow doesn't corrupt pact flow.
- [ ] End-of-run summary shows "Relics: <name>" line under "Pacts:" line.
- [ ] Add a new file to `data/relics/`. Restart run; it appears in rotation.

### Iter 2.2 — Economy loop polish (interest)
- [ ] Hoard 20+ gold into planning. Income floater shows "+N base · +M interest" in gold color next to gold counter.
- [ ] Sit on 100+ gold: interest caps at +5 (not 10).
- [ ] Spend everything: next planning shows only "+N base" with no interest line.
- [ ] Pact bonus from Greedy Horizon shows as purple "+4 pact" component.
- [ ] End-of-run stats grid shows "Interest earned · max gold floated" row.
- [ ] `user://run_log_*.json` contains `planning_income` events per wave with breakdown fields.

### Iter 4.1 — Status icons + damage type chips
- [ ] Each draft offer card shows a colored chip (STRIKE/ARCANE/FROST/SPIRIT/SIEGE/AURA) below the button.
- [ ] Wave 4 Iron Squires show A4 + P30 chips above their HP bar.
- [ ] Wave 5 Silithar Younglets show R5 chip.
- [ ] Wave 6 Crystal Wisps show S60 + M50 chips; S value drops live as shield absorbs damage; S chip disappears when shield breaks.
- [ ] Snowchaser/Frost Dryad hits cause a SLO chip on the target while slow is active.
- [ ] Wave 10 boss has chips correctly positioned at the higher HP bar offset.
- [ ] Wraithlings/Storm Kages (no defenses) show zero chips — no clutter.

### Iter 8.2 — Failure coach
- [ ] Lose to wave 4 (armored) with strike-only towers → coach shows red "Armor blunted your damage" + gold "Damage too one-sided".
- [ ] Lose to wave 1 (swarm) with no placement → coach shows red "Swarm overran you".
- [ ] 6+ rerolls during a run → blue "Lots of rerolls" insight.
- [ ] Lose with 40+ unspent gold → "Sat on gold" insight.
- [ ] Lose with ≤2 units placed → "Too few units placed" insight.
- [ ] Clean victory → coach section hidden or only minor (sev 1/2) observations.
- [ ] At most 3 insights, sorted by severity descending.
- [ ] All insight hints name actual units from `data/units/`.

### Iter 8.1 — Run summary
- [ ] At end of run (win or lose), the panel shows a generated **Run Name** in gold (format: "<Adj> <Faction> <Theme>").
- [ ] Seed + wave-reached line correct.
- [ ] Stats grid (gold/kills/damage/leaks/units) matches what F1 was showing live.
- [ ] Highlights block names actual units/enemies (e.g. "Top damage  Pyromancer - 1243").
- [ ] Pacts row lists pacts in chosen order, or "No pacts taken".
- [ ] Replay (same seed) → first draft offers match the just-played run.
- [ ] New Run (new seed) → first draft offers differ.
- [ ] Main Menu button returns cleanly.
- [ ] JSON log dump contains the new fields: `damage_by_unit`, `kills_by_enemy`, `leaks_by_enemy`, `leaks_by_wave`, `placements_by_faction`, `placements_by_unit`, `pacts`.

### Iter 5.2 — Pacts
- [ ] After clearing wave 3, pact modal appears with 3 cards (name + Boon + Curse).
- [ ] Clicking a card hides the modal and starts planning for wave 4.
- [ ] "Pacts: <name>" label appears top-left below the top bar.
- [ ] Effects visibly apply (e.g. Greedy Horizon → shop 2 offers + extra gold on planning; Iron Vow → +HP enemies).
- [ ] After waves 6 and 9, two more pact picks (different from prior choices).
- [ ] F2 shows `ChoosePactCommand <id>` ✓ on click; ✗ "not in pact choice phase" if dispatched outside the modal.
- [ ] Add a new file to `data/pacts/` (copy an existing one, change `id`/`display_name`/`effects`). Restart run; the new pact appears in rotation.

### Iter 6.1 — Wave tags + preview
- [ ] Wave Preview card visible in bottom-left of bottom bar.
- [ ] Card shows wave number + name + colored chips per tag (e.g. purple Swarm, gold Armored).
- [ ] 1-2 hint lines below the chips name the counter (e.g. "Splash damage shreds groups").
- [ ] During planning: "Wave N: name". During combat: "Wave N (active): name".
- [ ] All 10 waves show distinct previews matching their tags.
- [ ] Edit `data/counters.json` (change a hint), restart, hint updates.
- [ ] Add a new tag to a wave in `data/waves/act1.json` for which no `counters.json` entry exists - preview falls back to the tag string capitalized, no crash.

### Iter 2.4 — Six enemy archetypes
- [ ] Wave 1 spawns small purple wraiths (swarm).
- [ ] Wave 3 has fast red Storm Kages mixed with wraiths.
- [ ] Wave 4 has gold-tinted Iron Squires (armored — strike damage visibly reduced).
- [ ] Wave 5 has green Silithar Younglets that regen HP while alive.
- [ ] Wave 6 has Crystal Wisps with shields (their HP bar stays full while the shield absorbs).
- [ ] Wave 7 has slow Diamond Golems behind a Storm Kage stampede.
- [ ] Wave 10 is boss Andromeda + adds.
- [ ] Edit any file in `data/enemies/` → restart run → behavior changes (e.g. bump wraithling HP to 200).
- [ ] Edit `data/waves/act1.json` → restart run → wave composition changes.

### Iter 1.1 + 1.2 — Grid board + MapDef loader
- [ ] On boot, no red error label visible.
- [ ] The grid is visible: 20 columns × 8 rows of 64 px tiles.
- [ ] Tile colors are distinct: amber (path), greenish (buildable), gray (blocked, if any), red-orange (spawn), blue (core).
- [ ] Hover any tile → highlighted with white outline + coords like `(8, 3) B` shown beside it.
- [ ] Enemies spawn from the S tile and walk along the P chain to the C tile.
- [ ] Tower preview snaps to tile centers (not free mouse position).
- [ ] Try to place on a path tile → ✗ in F2 with reason "tile is not buildable...".
- [ ] Try to place on same tile as existing tower → same ✗ reason.
- [ ] **Map edit + F3 reload:**
  - Open `data/maps/starter_neutral.json`, change one `B` to `P` somewhere not adjacent to the path. Save.
  - In-game press **F3** → red error label appears: "Orphan path tile at (X,Y)...".
  - Revert that change. Press F3 again → error clears, tiles update.
  - Now change one `B` to `X`. F3 → that tile turns dark gray.
- [ ] **Invalid map errors:**
  - Delete the `"S"` line entirely (replace with `B`). F3 → "No spawn tile ('S') found".
  - Add a second `"S"` somewhere. F3 → "More than one 'S' (spawn) found".
  - Mismatch row length (delete a char from one row). F3 → "Row N has X chars, expected Y".

---

## Iter Polish.1 — Duelyst HUD skin (cursor + fonts + portraits)

What changed visually:
- OS arrow → Duelyst selection arrow (`assets/ui/cursor.png`, hotspot `(8, 6)`).
- Default font → Lato; display titles → Trump Gothic Pro Bold.
- Each of the 3 draft offer cards has a unit portrait above the buy button (idle sprite frame, faction-tinted).

Where to look in the project:
- `assets/fonts/` — Lato + TrumpGothicPro TTFs.
- `assets/ui/duelyst_theme.tres` — wired as global GUI theme via `project.godot [gui] theme/custom`.
- `assets/ui/cursor.png` — wired via `project.godot [display] mouse_cursor/custom_image`.
- `scenes/hud.tscn` — `BottomBar/VBox/DraftRow/OfferBoxN/OfferPortraitN` nodes added.
- `scripts/hud.gd::_portrait_for(unit_id)` — returns the idle frame texture from `UnitFactory.sprite_frames_for(id)`.

Quick sanity check:
1. Open project in Godot 4.6 — main menu title uses Trump Gothic Pro and the cursor is the Duelyst arrow.
2. F5 → New Run → 3 draft cards each show a portrait above the name.
3. Press R to reroll a few times — every offered unit gets a visible portrait, never blank.
4. Press F1 + F2 — debug panels float above the bottom bar without clipping the offer cards.

Common breakage:
- Blank portrait on a card = the unit's `asset_profile_id` doesn't resolve to a `.tres` SpriteFrames, or that SpriteFrames has no `idle`/`breathing` animation. Helper falls back to first non-empty animation, but a fully empty SpriteFrames returns `null`.
- Trump Gothic Pro silently falling back to Lato = the FontFile resource didn't import. Re-open the project once so Godot generates the `.import` files for TTFs.

---

## Iter Polish.2 — panel frames + button styleboxes

What changed visually:
- Every `Panel` and `PanelContainer` now has a dark navy background, thin gold border, and rounded corners (all via `assets/ui/duelyst_theme.tres`).
- Every `Button` uses a textured stylebox (Duelyst's `button_confirm` for normal, `button_confirm_glow` for hover, `button_cancel` for pressed).
- Draft offer cards each sit inside their own PanelContainer frame; unaffordable cards dim to ~85% brightness.

Where to look:
- `assets/ui/duelyst_theme.tres` — single source of truth for 8 styleboxes. Edit there to tune colors / margins everywhere.
- `assets/ui/frames/` — texture sources for the button states.
- `scenes/hud.tscn::OfferBox{1,2,3}` — now `PanelContainer` with child `Inner` VBoxContainer holding the original portrait/button/chips/desc.

Quick sanity check:
1. Open project → main menu shows framed Mastery button + framed Quit button.
2. F5 → New Run → bottom bar + offer cards + top bar all share the same gold-bordered navy look.
3. Spend gold below an offer's cost → that card dims; affording it again restores brightness.
4. Hover any button → glow texture appears.

Common breakage:
- All panels rendering as flat gray = theme didn't load. Confirm `[gui] theme/custom = "res://assets/ui/duelyst_theme.tres"` in `project.godot`.
- Offer cards missing their frame = check `OfferBox{N}` is `PanelContainer` (not `VBoxContainer`) in the .tscn.
- Buttons look stretched = the 174×58 source button image needs the texture_margin values defined in the theme (currently 30/14/30/14). Tweak in the theme resource if a new button shape needs different margins.

---

## Iter 7 + 10 — Procgen + map editor

What landed:
- `MapGenerator` (random-walk procgen) selectable from the main menu Map dropdown.
- `MapEditor` scene reachable via the "Editor" button on the main menu.
- Custom maps save to `user://maps/<id>.json` (on Windows: `%APPDATA%\Godot\app_userdata\Duelyst_TD\maps\`).

How to exercise it:
1. **Procgen.** Main menu → Map dropdown → "Random (procgen)" → seed `0xCAFEBABE` → New Run. A randomized 20×8 board appears. Same seed twice = same map.
2. **Editor → Save.** Main menu → Editor → paint cells → Save with a name → New Blank → Load dropdown lists your save → Load it back.
3. **Editor → Test Play.** Editor → paint a valid map → Test Play. Game launches on the playtest map.
4. **Editor → Save → Play.** Save with a real name. Return to main menu. Map dropdown now lists "Custom: \<your-name\>" → New Run plays it.

Headless verification:
- `godot.exe --headless --path . res://scenes/main_menu.tscn --test-generator` prints PASS/FAIL across a dozen seeds and a determinism check.
- `godot.exe --headless --path . res://scenes/main.tscn --use-generated --quit-after 1800` forces procgen for a smoke run.

Common breakage:
- Generator's "no valid map after N attempts" error = the quality gate is too tight or the seed is unlucky. `generate_forgiving` walks 10 cluster seeds — that's the public entry point.
- "Load failed: This map is WxH; editor is fixed 20x8" = trying to load a non-20×8 custom file in the editor. Editor MVP is fixed-size; gameplay can run any size that the loader accepts.
- Daily seed always loads starter, never procgen — that's intentional: daily scores must be comparable.

Where to look:
- Procgen: [scripts/map_generator.gd](duelyst-td/scripts/map_generator.gd) — algorithm + quality gate.
- Editor: [scripts/map_editor.gd](duelyst-td/scripts/map_editor.gd) — paint/save/load/test-play.
- Glue: [scripts/main.gd](duelyst-td/scripts/main.gd) — `_load_configured_map` dispatch on `RunConfig.map_source`.
- Validation: [scripts/map_loader.gd](duelyst-td/scripts/map_loader.gd) — single source of MapDef truth (loads, generates, and editor all funnel through `validate()`).

---

## How to test a packaged iteration later

Each iteration is snapshot to `builds/iter-X.X-NAME-source.zip` (and `.exe` if available).

**Easiest — `.exe` (recommended for play):**
1. Run `builds/iter-X.X-NAME-win64.exe`. No setup, no Godot needed.

**Source zip (for editing/poking at code):**
1. Extract the zip to a fresh folder.
2. Open Godot 4.6+ → **Import** → point at `project.godot`.
3. **Known quirk:** Godot 4.6's first import of a project with `class_name` scripts (we have several: `Command`, `PlaceUnitCommand`, etc.) often needs **two** import passes before the class cache is correct. If you see "Could not find type Command" errors on first run, just **close Godot and reopen the project once**, then F5. The build's pre-baked `.godot/` cache is excluded from the zip on purpose (it's editor-machine-specific).
4. F5 to play. Use the test checklist above for that iteration.

To re-package after an iteration:
```powershell
.\tools\package_iteration.ps1 -Id "X.X" -Name "short-slug" -Description "What landed in this iteration."
```

---

## Adding new debug surfaces

When introducing a new debug feature in a future iteration:
1. Add a row to the Hotkeys / Scenes / Autoloads tables above.
2. Add a "Iter X.X — <name>" test checklist section.
3. Note it in `docs/decisions.md` for that iteration.
4. Re-run `tools/package_iteration.ps1` so the build snapshot reflects the docs.

This file is the running glossary — keep entries terse, link to code paths sparingly.
