# Decisions Log

A running log of architectural decisions. New systems should add entries here.
Each entry: date, decision, why, impact.

## Format

```
## YYYY-MM-DD — Title
**Decision:** what was decided.
**Why:** reasoning.
**Impact:** what code/data/tests this affects.
**Test:** how to verify the change works.
```

---

## 2026-05-24 — Project pivot to Shardstorm TD (roguelike co-op TD)
**Decision:** Move from arcade-style real-time TD to a planning/combat roguelike with draft shop, eventual pacts/traits/maps. Reference docs: `co_op_roguelike_td_design_doc.md`, `shardstorm_td_content_bible.md`, `shardstorm_td_research_engagement_addendum.md`.
**Why:** Original design vision is roguelike Legion-TD-style. Arcade TD was a useful prototype but the wrong architecture for long-term play.
**Impact:** Replaced fixed tower buttons with draft offers. Added planning/combat phases. Data-driven UnitDefs. Single seeded run.
**Test:** Open project, see planning phase, 3 draft offers, Start Wave button works, 10 waves win/lose.

---

## 2026-05-24 — Single source of truth for unit content is JSON
**Decision:** Each playable unit is a JSON file in `data/units/`. The `tower.tscn` is a single generic scene; `UnitFactory.make_tower(id)` instantiates and configures it from the matching JSON.
**Why:** Adding/balancing units must be a data edit, not a scene edit. Enables future content packs, traits/flaws, balance reports.
**Impact:** Deleted per-tower scenes. UnitFactory autoload loads all JSONs at startup. `tower.gd` has `apply_def(def: Dictionary)`.
**Test:** Edit `data/units/azurite_lion.json` damage to 99, restart project, that unit hits for ~99 in combat.

---

## 2026-05-24 — Stage 0 discipline: commands, run log, decisions doc
**Decision:** Every player action (place unit, sell, upgrade, buy offer, reroll, start wave) goes through a Command object dispatched by `CommandBus`. Every command and combat event is recorded in `RunLog`. All architectural choices land here.
**Why:** Per design roadmap Gate 3, co-op/replay/multiplayer require board state to be reconstructable from commands. Without logs we can't build run identity, failure coach, or balance reports — all named in the engagement addendum.
**Impact:** Adds 3 autoloads (`RunConfig`, `RunLog`, `CommandBus`). Refactors `placement_controller` + `hud` to dispatch commands instead of mutating state directly. Adds debug overlay (F1 stats, F2 command log) and main-menu splash with "Project Loaded" + New Run + seed input + determinism test.
**Test:** See "Manual Test Checklist — Stage 0" below.

---

## 2026-05-24 — Seed determinism via SessionRng
**Decision:** All gameplay randomness (draft offers, wave variants, future map gen and pacts) goes through `SessionRng`. UI-only randomness (banner shake, hit flash, pitch jitter) may use the global RNG.
**Why:** Reproducible runs are needed for balance testing, daily challenges, bug reports, and eventual multiplayer determinism.
**Impact:** `SessionRng` exposes `set_seed`, `randi/randf/range`, `pick`, `pick_weighted`, `shuffle`. New runs call `SessionRng.set_seed(...)`. Seed is displayed in HUD as `SHARD-XXXXXXXX`. Main menu has a seed-input field and a determinism test button.
**Test:** Main menu → enter seed `123` → New Run → first 3 offers and wave-1 spawn pattern match a recorded golden. Also: main menu → "Run Determinism Test" → must print PASS.

---

## Manual Test Checklist — Stage 0

### 0.1 Project skeleton
- [ ] Godot opens the project without errors.
- [ ] Main scene (main menu) shows "Shardstorm TD — Project Loaded".
- [ ] `docs/decisions.md` exists.
- [ ] These directories exist: `scenes/`, `scripts/`, `scripts/commands/`, `data/units/`, `data/enemies/`, `data/waves/`, `data/maps/`, `data/traits/`, `data/relics/`, `docs/`, `debug/`.
- [ ] At least 12 unit JSONs exist in `data/units/`.

### 0.2 Run config + seeded RNG
- [ ] Main menu shows current seed.
- [ ] "Randomize" button generates a new seed.
- [ ] Seed text field accepts hex input (e.g. `SHARD-0000007B` → 123) and decimal.
- [ ] "Run Determinism Test" button prints PASS in the result label.
- [ ] Starting a run with seed 123 twice produces the same first draft offer set.
- [ ] HUD shows the seed during the run.

### 0.3 Command-based player actions
- [ ] Clicking a draft offer dispatches `BuyOfferCommand`.
- [ ] Clicking on a map tile while previewing dispatches `PlaceUnitCommand`.
- [ ] Clicking Reroll dispatches `RerollShopCommand`.
- [ ] Clicking Start Wave dispatches `StartWaveCommand`.
- [ ] Clicking Sell on tower panel dispatches `SellUnitCommand`.
- [ ] Clicking Upgrade dispatches `UpgradeUnitCommand`.
- [ ] Invalid commands show their rejection reason in the debug overlay (F2).

### 0.4 Run logger
- [ ] On run start, RunLog stats reset.
- [ ] Buying a unit increments `units_bought` and adds to `gold_spent`.
- [ ] An enemy death increments `enemies_killed` and adds `reward` to `gold_earned`.
- [ ] A leak increments `leaks`.
- [ ] Starting a wave records `wave_start` event with wave number.
- [ ] Pressing F1 shows live stats overlay.
- [ ] Pressing F2 shows last 20 commands.
- [ ] At end-of-run, a JSON file is written to `user://run_log_*.json`.

---

## 2026-05-24 — Grid board + MapDef loader (Iteration 1.1 + 1.2)
**Decision:** Replace the hand-coded Path2D curve with a tile grid loaded from a JSON MapDef. Map data is the source of truth for path, buildable tiles, spawn, and core. The enemy curve is derived from the grid path chain. Placement validation now asks the grid whether a tile is buildable.
**Why:** Hardcoded paths can't support map variety, procedural maps, or a future map editor. Grid validation is also much cheaper than the per-frame distance-to-curve check we had before.
**Impact:** New scripts: `MapLoader` (parse + validate), `GridController` (coord helpers + path BFS), `tile_renderer.gd` (colored tile fill), `hover_indicator.gd` (cursor highlight + coord readout), `board.gd` (composes the four). New scene `scenes/board.tscn`. New data file `data/maps/starter_neutral.json`. Refactored `main.gd`/`main.tscn` to use the Board. Refactored `placement_controller` to snap previews to tile centers and validate via grid. Added **F3** hotkey to live-reload the current map JSON (curve + tiles update; existing enemies/towers stay).
**Test:** See "Manual Test Checklist - Iter 1.1+1.2" below.

---

### Manual Test Checklist - Iter 1.1+1.2 (Grid + MapDef)

**1.1 Grid board**
- [ ] Game scene shows a visible 20x8 tile grid.
- [ ] Path tiles (P, S, C) are amber/orange; buildable (B) are subtle green; spawn is reddish; core is blue.
- [ ] Hovering over a tile highlights it and displays its `(col, row) TYPE` near the cursor.
- [ ] Background image is still visible behind the grid (50%+ alpha).

**1.2 MapDef loader**
- [ ] On boot, no error label is shown.
- [ ] Edit `data/maps/starter_neutral.json` (e.g. change one B to P or X). Press **F3** in-game. The tile colors update immediately.
- [ ] Break the map (e.g. delete the S, or change spawn->core path connectivity). Press F3. The red error label appears with a specific reason like "No spawn tile ('S') found" or "Path dead-end at (X,Y) before reaching core".
- [ ] Spawn tile and core tile positions in the JSON drive where enemies enter the board and where the base sits.

**Grid-aware placement**
- [ ] Tower preview snaps to tile centers (not mouse position).
- [ ] Trying to place on a path tile is rejected; F2 shows `PlaceUnitCommand` with ✗ "tile is not buildable (path / blocked / occupied)".
- [ ] Trying to place on the same tile as an existing tower is rejected with the same reason.

**Acceptance criteria met:**
- Grid renders. ✓
- Hovering a tile shows coordinates. ✓
- Path/buildable/blocked tiles are visually different. ✓
- Changing the map JSON changes the board (F3 reload). ✓
- Invalid map gives readable error (red label + console). ✓
- Spawn and core are loaded from data. ✓

---

---

## 2026-05-24 — Six enemy archetypes (Iteration 2.4)
**Decision:** Refactor enemies into data-driven `EnemyDef` JSON with six distinct families: Swarm, Fast, Tank, Armored, Regen, Shielded (+ boss). Each enemy is one JSON file in `data/enemies/`. Waves are also data — `data/waves/act1.json` defines all 10 waves with `spawn_groups` referencing enemy IDs. Damage types (`strike`, `arcane`, `spirit`, `frost`, `siege`, `true`) flow `UnitDef.damage_type` → `tower.damage_type` → `projectile.damage_type` → `enemy.take_damage(amount, type)`. Enemies apply `armor` (flat), `physical_resist`/`magic_resist` (fractional), and `shield_hp` (absorbed first) per family.
**Why:** Without distinct counter-targets, builds were largely interchangeable. The strategy triangle (splash beats swarm, slow beats fast, magic beats armor, burst beats regen, multi-hit beats shielded) is the core decision grammar of the game per the design doc.
**Impact:** Deleted the 5 per-enemy `.tscn` files. New `EnemyFactory` autoload loads enemies + wave-sets at startup. Single generic `scenes/enemy.tscn`. Refactored `enemy.gd` (regen accumulator, slow tint via base_modulate vs hit-flash via `self_modulate`, shield absorption, type mitigation). Refactored `wave_spawner.gd` to take a wave-set dict and flatten spawn_groups into a (time, enemy_id) schedule for concurrent group spawning with per-group `delay`. `projectile.gd` + `tower.gd` carry `damage_type`. `main.gd` reads wave-set via `EnemyFactory.get_wave_set("act1")` and the wave count is data-derived.
**Test:** See "Manual Test Checklist - Iter 2.4" below.

---

### Manual Test Checklist - Iter 2.4 (Six enemy archetypes)

**Enemies visually distinct:**
- [ ] Wave 1 (swarm) — small purple wraiths in groups.
- [ ] Wave 3 — fast red-tinted runners (Storm Kage).
- [ ] Wave 4 (armored) — gold-tinted plated knights (Iron Squire).
- [ ] Wave 5 — green-tinted lizards (Silithar Younglets) regen if not killed quickly.
- [ ] Wave 6 (shielded) — blue-tinted crystal wisps; HP bar stays full for several hits while shield absorbs.
- [ ] Wave 7 — large diamond golems crawling slowly behind a Storm Kage stampede.
- [ ] Wave 10 — boss Andromeda (1.7× scale, soft red tint).

**Strategy triangle (each archetype rewards a specific answer):**
- [ ] **Swarm vs splash:** Pyromancer alone on wave 2 handles wraithlings comfortably; an Archer alone struggles. Splash bursts visibly hit multiple at once.
- [ ] **Fast vs slow:** Snowchaser/Frost Dryad slows the Storm Kages (blue tint visible); without slow, they leak fast.
- [ ] **Tank vs burst:** Caster (single high-damage hits) chews through wave 7 Diamond Golems; sustained chip damage from an Archer takes way longer.
- [ ] **Armored vs arcane:** Wave 4 Iron Squires take reduced damage from `strike` (Archer/Windblade) but full damage from arcane casters (Pyromancer/Caster).
- [ ] **Regen vs burst:** Wave 5 Silithar Younglets visibly heal between hits; sustained chip can't keep up.
- [ ] **Shielded vs multi-hit:** Wave 6 wisps' shields are eaten by fast multi-hit Azurite Lion/Archer; single heavy casters waste damage on the shield.

**Data-driven:**
- [ ] Edit `data/enemies/wraithling_runner.json` (e.g. `"hp": 16` → `"hp": 200`). Restart run. Wave 1 wraiths take much longer to kill.
- [ ] Edit `data/waves/act1.json` (e.g. wave 1 count: 6 → 20). Restart run. Confirm new count.
- [ ] Break a wave JSON (typo an `enemy_id`). Restart run. Console warning "EnemyFactory: unknown enemy 'X'", spawner skips that group, game continues.

**Acceptance criteria met:**
- Six (+boss) enemy families. ✓
- Each has distinct speed/HP/behavior. ✓
- Splash beats swarm. ✓
- Slow helps against fast. ✓
- High damage helps tanks. ✓
- Wrong builds visibly struggle (e.g. archer-only run leaks against wave 7). ✓

---

---

## 2026-05-24 — Wave tags + preview panel (Iteration 6.1)
**Decision:** During planning, the HUD shows a Wave Preview card with the upcoming wave's name, a row of colored tag chips, and 1-2 counter hints. The chips and hints are driven by `data/counters.json` — a tag → `{label, color, hint}` map. The preview reuses the existing `tags` field already on each wave in `data/waves/act1.json`.
**Why:** The strategy triangle landed in 2.4 but was hidden behind playtesting (you'd lose to Iron Squires before realizing you needed arcane). Surfacing the threat tags before each wave lifts counter-knowledge from "must-have memorized" to "shown at the right moment." This is the Iter 6.1 acceptance criterion "player can prepare for known threats" and a prerequisite for the failure coach (Iter 8.2) which will reuse the same counters mapping for post-loss advice.
**Why this approach (data file, not hardcoded UI):** keeps tags pluggable — a future content pack can add `"poison"` or `"flying"` tags by adding entries to `counters.json` without touching `hud.gd`.
**Impact:** Added `data/counters.json`. Added a `WavePreview` PanelContainer to the bottom bar (first child of the DraftRow HBox, before the offer cards). `hud.gd` loads counters on ready, exposes `_update_wave_preview(wave_num, is_active)` which reads the wave from `EnemyFactory.get_wave_set("act1")` and renders chips via `RichTextLabel` bbcode. Wired into `show_wave_banner_planning(wave)` (upcoming) and `show_wave_banner(wave_num)` (active).
**Test:** See "Manual Test Checklist - Iter 6.1" below.

---

### Manual Test Checklist - Iter 6.1 (Wave preview)

- [ ] On planning phase 1, the bottom-left card shows: "Wave 1: Loose Wraiths", a purple "Swarm" chip, and the hint "Splash damage shreds groups (Pyromancer, Firebreather)."
- [ ] On planning phase 3, shows "Wave 3: Storm Sprinters" with **Swarm** and **Fast** chips, both hints visible.
- [ ] On planning phase 4, shows "Wave 4: Iron March" with **Armored** chip and the armor hint.
- [ ] On planning phase 5, shows "Wave 5: Silithar Brood" with **Regen + Swarm** chips.
- [ ] On planning phase 6, shows "Wave 6: Frost Veil" with **Shielded + Fast** chips.
- [ ] On planning phase 10, shows "Wave 10: Andromeda Echo" with **BOSS + Fast + Swarm** chips (capped to 2 hint lines).
- [ ] When you press Start Wave, the preview's title flips to e.g. "Wave 3 (active)" while the chips stay so you still see what's coming at you.
- [ ] Edit `data/counters.json`, change the "swarm" hint, save. Restart run. Wave 1 hint updates accordingly.
- [ ] If a wave has no tags (or all tags are unknown to counters.json), the preview hides the chip row and hint line gracefully (no crash, just an empty area).

**Acceptance criteria met:**
- Upcoming wave preview shows threat tags. ✓
- Player can prepare for known threats. ✓
- Counter information is data-driven, not hardcoded. ✓

---

---

## 2026-05-24 — Pacts (Iteration 5.2)
**Decision:** Every 3 waves (after wave 3, 6, 9), pause the run and show 3 random pact choices. Each pact carries a real boon AND a real curse. Pacts persist for the rest of the run and stack. Pact effects are declarative — each pact JSON lists `effects: [{type, amount/mult}]` and game systems query `PactManager.sum_int("type")`, `product_float("type")`, or `has_flag("type")` to apply them.
**Why:** Pacts are the highest-impact engagement lever per the engagement addendum — they generate run identity ("Greedy Horizon × Iron Vow run"), create timing decisions ("can I afford Iron Vow's +25% HP curse on wave 6?"), and produce table-talk moments. The data-driven effect system means new pacts can be added by editing JSON only, no code.
**Impact:** New autoload `PactManager` loads `data/pacts/*.json` and tracks active pacts. New `PACT_CHOICE` phase in `phase_controller.gd` interrupts the wave loop after wave 3/6/9. New `ChoosePactCommand`. HUD adds a modal pact panel (3 cards centered) and a small "Pacts:" RichTextLabel anchored top-left under the top bar that grows as pacts accumulate. Effects wired into: `phase_controller._start_planning` (wave_gold_bonus), `draft_director.effective_shop_size` (shop_size_delta), `draft_director.reroll_cost` (reroll_cost_delta), `enemy.apply_def` (enemy_hp_mult + enemy_speed_mult), `wave_spawner._on_enemy_died` (kill_gold_bonus), `wave_spawner._on_enemy_reached_end` (ignore_first_leak + leak_damage_delta).
**Pact pool (6, common/rare):** Greedy Horizon, Iron Vow, Overflow Mercy, Frenzied Wages, Storm Pact, Sunbreaker Doctrine.
**Test:** See "Manual Test Checklist - Iter 5.2" below.

---

### Manual Test Checklist - Iter 5.2 (Pacts)

- [ ] Run a new game. Beat wave 3. After the wave clear bonus, the pact modal appears center-screen with 3 cards.
- [ ] Each card shows: pact name, "Boon: ..." line, "Curse: ..." line.
- [ ] Clicking a card hides the panel and starts planning for wave 4.
- [ ] An "Pacts: <name>" label appears under the top bar showing the chosen pact.
- [ ] If the pact was Greedy Horizon: gold on planning starts shows +4 extra; the draft shows only 2 offers instead of 3.
- [ ] If the pact was Iron Vow: every kill on wave 4+ gives +2 gold over normal; enemies feel chunkier (HP visibly higher on the bar).
- [ ] If the pact was Overflow Mercy: first leak each wave does 0 damage (lives don't drop); subsequent leaks do +1 damage extra. F1 panel `leaks` counter still increments but `core_damage_taken` differs.
- [ ] If the pact was Frenzied Wages: kills give +1; reroll button shows 2 extra cost (e.g. 4g instead of 2g).
- [ ] If the pact was Storm Pact: enemies visibly faster; kill gold +3.
- [ ] If the pact was Sunbreaker Doctrine: first leak ignored; enemies +10% HP.
- [ ] Beat wave 6. Pact modal appears again with 3 NEW pacts (no duplicates of already-chosen ones).
- [ ] Beat wave 9. Third pact offered. Active Pacts label shows all 3.
- [ ] Effects stack correctly (e.g. Greedy Horizon + Frenzied Wages = +4 wave start AND +1 per kill AND +2 reroll cost).
- [ ] Add a 7th pact to `data/pacts/`. It appears in the rotation. No code changes needed.
- [ ] F2 command log shows `ChoosePactCommand <id>` with ✓ for valid picks. Try ChoosePactCommand during planning (not pact choice phase) — would be ✗ "not in pact choice phase".

**Acceptance criteria met:**
- Pact choice appears every 3 waves. ✓
- Pact effect is active immediately. ✓
- Downside is real (Iron Vow's +25% HP is visibly painful; Storm Pact's +20% speed is real pressure). ✓
- Pacts are data, not code. ✓

---

---

## 2026-05-24 — Run summary + identity (Iteration 8.1)
**Decision:** Replace the minimal Victory/Defeat panel with a rich end-of-run card: auto-generated **Run Name**, seed, wave reached, 2-column stats grid, four "highlights" lines (top damage unit, most-killed enemy, worst wave by leaks, biggest single threat), pacts taken, and three buttons (replay same seed / new seed / main menu). Underlying tracking added so every projectile is attributed back to its tower and every kill/leak tagged with the enemy id.
**Why:** The engagement addendum is explicit that "run identity" + "death recap" is the single biggest retention pillar after the core loop. The data foundation (`RunLog`) was already there; this iteration is the presentation pass that closes the loop. Players need to leave each run with a story they can repeat ("the Stormbound Vetruvian run where Pyromancer carried wave 7 but the Iron Squires on wave 4 leaked twice").
**Why this generator design:** Run names compose from `<pact_adjective> <faction> <theme>`. Pacts contribute the adjective (declared per pact in JSON via the new `run_adjective` field). Dominant faction (by units placed) picks the theme (hardcoded mapping in `RunNameGenerator`). This keeps names readable and recognizable as the same player ages — Lyonar runs always end in "Citadel", Magmar runs in "Stampede", and the adjective tells you what pact gambit defined the run.
**Impact:**
- `enemy.gd` — `died`/`reached_end` signals now carry `enemy_id`; `take_damage` accepts an optional `source_id`.
- `projectile.gd` — carries `source_unit_id`, passed to enemy on hit.
- `tower.gd` — passes its `unit_id` to projectile setup.
- `wave_spawner.gd` — handlers updated, log `enemy_id` on every kill/leak.
- `place_unit_command.gd` — logs faction with every purchase.
- `run_log.gd` — new breakdown dicts (`damage_by_unit`, `kills_by_enemy`, `leaks_by_enemy`, `leaks_by_wave`, `placements_by_faction`, `placements_by_unit`, `pacts`).
- New class `RunNameGenerator` (`scripts/run_name_generator.gd`).
- New `run_adjective` field on all 6 pacts.
- `hud.tscn` — bigger EndPanel (720×560) with stats grid + highlights + pacts row + 3 buttons.
- `hud.gd` — `_populate_run_summary` reads everything from `RunLog.stats` and lays it out.
**Test:** See "Manual Test Checklist - Iter 8.1" below.

---

### Manual Test Checklist - Iter 8.1 (Run summary)

- [ ] Play any run to completion (or lose). EndPanel pops up.
- [ ] Big "Victory!" or "Defeat" header.
- [ ] Run name line below: format like "Greedy Lyonar Citadel" or "Wandering Wanderer" (if no pacts/units).
- [ ] Seed + wave-reached line: e.g. "SHARD-3A7F910C  ·  Wave 7 / 10".
- [ ] Stats grid populated: Gold earned, Gold spent, Enemies killed, Damage dealt, Leaks · core damage, Units bought · sold · upgrades.
- [ ] Highlights block lists Top damage / Most killed / Worst wave / Biggest threat with actual unit/enemy display names from the JSON defs.
- [ ] Pacts row lists chosen pacts (or "No pacts taken this run.").
- [ ] **Replay (same seed)** → fresh game starts with the same seed (verify by checking the same first draft offers appear).
- [ ] **New Run (new seed)** → fresh game with a different seed.
- [ ] **Main Menu** → goes back to main menu without crash; seed field shows the previous seed.
- [ ] The same data is in the JSON dump (`%APPDATA%\Godot\app_userdata\Duelyst_TD\run_log_*.json`): open the file, find `damage_by_unit`/`kills_by_enemy`/`leaks_by_wave`/`pacts` keys.

**Acceptance criteria met:**
- After every run, player understands what happened. ✓ (highlights block names the units and waves)
- Summary is screenshot-worthy. ✓ (run name + seed + key stats on one panel)
- Run name is data-driven (pacts contribute adjective, factions contribute theme). ✓

---

---

## 2026-05-24 — Failure coach (Iteration 8.2)
**Decision:** Add a rule-based coach section to the end-of-run panel that explains why the player lost (or where they were inefficient on a win). Rules read from `RunLog.stats` — specifically `leaks_by_enemy` (cross-referenced with `EnemyFactory` for family), `damage_by_unit` (cross-referenced with `UnitFactory` for damage type), `rerolls`, `gold_earned - gold_spent`, and `units_bought`. Insights are tagged `severity` 1/2/3 (info / warning / primary cause), sorted descending, capped at 3.
**Why:** Losses without explanation feel arbitrary. The engagement addendum lists "death recap / failure coach" as one of the top retention pillars. Now that 8.1 attributes every kill/leak to a specific enemy id and every damage tick to a tower id, the coach is a small read on top of that data.
**Why this rule design:** Keep severity-3 ("primary cause") rules conservative — only fire when there's enough signal to be confident (≥1 leak from the family, or a real damage-type imbalance with a real opposing family encountered). Show the player what they should have done differently, not what was theoretically optimal. Hints reference specific units from the current roster ("Pyromancer, Caster") so the advice is actionable.
**Impact:**
- New class `FailureCoach` (`scripts/failure_coach.gd`) with hardcoded per-family advice and a small set of rule functions.
- `hud.tscn` — EndPanel grew to 760×660; new `CoachHeader` label + `CoachPanel` RichTextLabel between Highlights and Pacts.
- `hud.gd` — `_format_coach(stats)` builds the bbcode insights block; hides the section entirely if there are no insights.
- Insights have color-coded severity: red (primary, defeat only), gold (real problem), blue (soft observation). Each shows title (bold colored), body (plain), hint (italic, dimmed).
**Current rule set:**
- Sev 3: "lost to family X" (one rule per enemy family).
- Sev 2: damage-type imbalance vs faced families (heavy phys + saw armored → call out; heavy magic + saw shielded → call out).
- Sev 2: sat on >40 gold at defeat.
- Sev 2: ≤2 units placed across 3+ waves at defeat.
- Sev 1: ≥6 rerolls.
**Test:** See "Manual Test Checklist - Iter 8.2" below.

---

### Manual Test Checklist - Iter 8.2 (Failure coach)

- [ ] **Forced loss to armored:** play wave 4 (Iron Squires) with only Archer/Windblade Adept (both `strike`). Lose. EndPanel coach shows: red "Armor blunted your damage" + gold "Damage too one-sided" with a percentage.
- [ ] **Forced loss to swarm:** Wave 1 with no towers placed. Coach shows: red "Swarm overran you" suggesting splash.
- [ ] **Win:** any clean victory. Coach section is empty/hidden OR shows only severity-1/2 observations (no red primary).
- [ ] **Reroll spam:** spend 6+ rerolls during a run. Coach shows: blue "Lots of rerolls" insight (sev 1).
- [ ] **Hoarder loss:** end a defeat with 40+ unspent gold. Coach includes "Sat on gold".
- [ ] **Sparse placement loss:** lose with ≤2 units placed. Coach includes "Too few units placed".
- [ ] No insights → coach header + panel are hidden (not just blank).
- [ ] At most 3 insights shown at once, sorted by severity descending.
- [ ] Insight hints reference actual unit display names from `data/units/*.json`.

**Acceptance criteria met:**
- Loss screen gives accurate advice. ✓ (insights are sourced directly from observed run data)
- Advice is based on actual run data. ✓ (no random/canned suggestions; all conditions check `RunLog.stats`)
- Rules cover at least the 5 named cases (swarm/armor/fast/boss/rerolls). ✓ (6 family rules + 4 economy/build rules)

---

---

## 2026-05-25 — Status icons + damage type chips (Iteration 4.1)
**Decision:** Surface in-game what was previously only inferable from death recaps. (1) Each enemy renders a row of state chips above its HP bar — armor (A), shield current (S), physical resist (P%), magic resist (M%), regen (R), and an active SLO chip when slowed. (2) Each draft offer card shows a small damage-type chip below the button (STRIKE / ARCANE / SPIRIT / FROST / SIEGE / TRUE), with AURA for buff-only towers.
**Why:** The coach (8.2) tells the player "armor blunted your damage" *after* the run. With these chips the same information is visible *during* placement — the player can see the Iron Squire has armor 4 + 30% phys resist, then read STRIKE on the Archer's chip and pick a different tower. Closes the "why is my damage weak right now?" gap.
**Why these visuals:** Compact letter+number chips (e.g. `A4`, `S60`, `R5`, `P30`) instead of pictographic icons, because (a) Duelyst's decal sprites don't scale well at 14 px, (b) the letter+value form is self-explanatory without tooltips, (c) drawing programmatically keeps the file count down.
**Impact:**
- New script `scripts/status_icons.gd` — `Node2D` child on the enemy. Polls owner state, diffs a small signature string, redraws only on change. Up to ~6 chips per enemy, capped naturally by which fields are non-default.
- `scenes/enemy.tscn` — added `StatusIcons` node positioned above the HP bar.
- `scripts/enemy.gd` — binds `status_icons.enemy = self` in `_apply_hp_bar_config`; the icons follow the per-enemy `hp_bar_offset` so big bosses get their chip row above their HP bar, not buried.
- `scenes/hud.tscn` — added `TypeChip1/2/3` Label between each `OfferBtn` and `OfferDesc`; BottomBar grew to 170 px tall to accommodate the bigger offer cards (130 px each).
- `scripts/hud.gd` — new `TYPE_COLORS` table; new `_set_type_chip(label, def)` populates each chip on `offers_changed`. Buff towers get the `AURA` chip in gold.
**Bonus bug fix:** `enemy.gd._apply_hp_bar_config` was being called before `_ready()` (because `EnemyFactory.make_enemy` calls `apply_def` pre-tree-insertion), so per-enemy `hp_bar_offset` / `hp_bar_width` never actually applied — the default `(0, -45) / 50px` always won. Now `apply_def` stores `_pending_def` and `_ready` re-applies it. Result: bosses' HP bars now sit at their correct -100 offset above the larger sprite, etc.
**Test:** See "Manual Test Checklist - Iter 4.1" below.

---

### Manual Test Checklist - Iter 4.1 (Status icons + type chips)

- [ ] Start a run. Each draft offer card shows a colored chip below the button: STRIKE (warm yellow), ARCANE (purple), FROST (cyan), SPIRIT (magenta), or AURA (gold) for Healing Mystic.
- [ ] Reroll until you've seen at least 3 different chip types.
- [ ] Wave 4 (armored Iron Squires). Each squire shows `A4` (gray) and `P30` (brown) chips above its HP bar.
- [ ] Wave 5 (regen Silithar Younglets). Each younglet shows `R5` (green) chip.
- [ ] Wave 6 (shielded Crystal Wisps). Each wisp shows `S60` (cyan) and `M50` (purple). Take a few hits — `S` value drops in real time as the shield absorbs damage. When the shield breaks, the `S` chip disappears.
- [ ] Hit any enemy with a Snowchaser/Frost Dryad. A blue `SLO` chip appears briefly while the slow is active, then disappears.
- [ ] Wave 10 boss. Larger HP bar at correct (higher) offset and chips visible above it (A2 + P10 + M10 for Andromeda).
- [ ] No clutter — enemies with no defenses (e.g. wraithlings, stormkages) show zero chips.

**Acceptance criteria met:**
- Status icons appear on enemies that have defenses or active effects. ✓
- Durations work (SLO appears/disappears with slow effect). ✓
- Stacking rules are clear (each chip independent, no overlapping logic). ✓
- Players can inspect at a glance — no tooltips needed. ✓

---

---

## 2026-05-25 — Economy loop polish (Iteration 2.2)
**Decision:** Add interest income to the planning phase: at planning start, the player earns +1 gold per 10 floated (capped at +5/wave). Visible income feedback: a brief floating breakdown ("+12  +5 base · +5 interest · +2 pact") appears next to the gold counter for 2.7s after the income lands. End-of-run summary now includes an "Interest earned · max gold floated" row.
**Why:** Greed needs to be a real *choice*, not a vague preference. The engagement addendum's Greed Score concept hinges on the player being able to weigh hoarding for future return vs spending now for tempo. With interest at 10% (capped at 5), hoarding is rewarded but bounded — at 50g floated you get full payout, at 200g you get the same +5. Also, players need to *see* the breakdown — silent "+12 to gold" hides the system. The floater makes interest visible immediately on the wave it triggers.
**Why these numbers:** 1g per 10 floated, max 5/wave. At max wave 10 with consistent +5 interest from wave 2 onward, that's +45g across the run — meaningful (worth ~2 mid-tier units) but not run-defining. Hard cap prevents snowball where one good wave 5 enables hoarding into auto-win.
**Impact:**
- `phase_controller.gd` — new constants `INTEREST_PER_GOLD=10`, `INTEREST_MAX=5`. `_start_planning` computes `interest = min(MAX, floated / 10)`, adds to total income. New `income_granted(breakdown)` signal carries `{base, interest, pact, total, floated_before, wave}`. Single `planning_income` event recorded per planning phase.
- `run_log.gd` — new stat fields `interest_earned`, `max_gold_floated`. `planning_income` event handler updates `gold_earned` (full total — previously base + pact were lost from this counter, now correct) and tracks the peak floated.
- `hud.tscn` — added `IncomeFloater` RichTextLabel inside the gold box (cap-positioned, fades in via tween). Added Interest row to the end-of-run stats grid.
- `hud.gd` — `show_income_breakdown(breakdown)` builds a bbcode badge with per-component coloring (gold for interest, purple for pact bonus) and tweens it in/out.
- `main.gd` — wires `phase_controller.income_granted` to `hud.show_income_breakdown`.
**Test:** See "Manual Test Checklist - Iter 2.2" below.

---

### Manual Test Checklist - Iter 2.2 (Economy loop polish)

- [ ] Start a new run. Beat wave 1 without spending all 20 starting gold (place no units or just one cheap one). Planning for wave 2: gold floater shows "+N base · +M interest" with the interest portion in gold color. F1 stats panel `gold_earned` includes both.
- [ ] Hoard hard: skip placement on wave 2 too. Wave 3 planning shows interest cap engaging at +5.
- [ ] Sit on 200g intentionally. Interest still caps at +5 — confirm the cap holds.
- [ ] Spend everything wave 4. Wave 5 planning: floater shows only "+N base" (no interest line because floated_before was 0 or near it).
- [ ] Take a pact (e.g. Greedy Horizon +4 wave gold) on wave 3. Wave 4 floater shows the pact bonus in purple alongside base and interest.
- [ ] End of run: stats grid shows "Interest earned · max gold floated" line with non-zero values for a hoarding run.
- [ ] Failure coach's "Sat on gold" insight still fires correctly on a hoard-and-die loss.
- [ ] Inspect `user://run_log_*.json` — `planning_income` events appear per wave with their breakdown; `interest_earned` accumulates correctly.

**Acceptance criteria met:**
- Starting wave grants income. ✓
- Kills grant gold. ✓ (unchanged)
- Leaking creates visible downside. ✓ (lives drop, no kill gold for leaked enemies)
- Greeding feels possible but risky. ✓ — interest rewards hoarding, but capped at +5/wave so you can't out-snowball pressure; meanwhile waves keep escalating and a sparse build leaks.

---

---

## 2026-05-25 — Relics + ModifierTotals refactor (Iteration 5.1)
**Decision:** Add **relics** as pure-boon rewards offered after the wave-5 mini-boss check. Relics reuse the pact effect vocabulary (`sum_int`/`product_float`/`has_flag`) but live in their own `RelicManager` autoload with their own roll trigger. To keep call-sites clean, introduce a `ModifierTotals` helper class that sums effects across all modifier sources (pacts + relics today; unit traits + map tiles later) so game systems no longer hard-code "ask PactManager only".
**Why:** Wave 10 is currently a binary success/fail moment with no comeback tool. The engagement docs explicitly call for rare loot drops at key wave moments. Relics fill that without violating the pact contract (pacts have curses; relics don't). The ModifierTotals refactor also pays forward — every future modifier system (traits, tiles, evolutions) just needs to register a query method and existing consumers pick up the new sources without change.
**Architecture choice — parallel managers, unified queries:** Considered (a) merge into one ModifiersManager, (b) parallel managers + helper. Picked (b) because pacts and relics have meaningfully different roll triggers/UI framing and merging would lose that distinction. The helper class is 3 one-line static methods so the cost is near-zero.
**Impact:**
- New `data/relics/` directory with 6 relics: Coin Engine, Loadbearer Banner, Sun Aegis, Treasury Doctrine, Spreading Frost, Mercy Sigil.
- New autoload `RelicManager` (parallels PactManager). New class `ModifierTotals` (`scripts/modifier_totals.gd`).
- Refactored 8 call-sites in `draft_director.gd`, `enemy.gd`, `phase_controller.gd`, `wave_spawner.gd` from `PactManager.{sum_int|product_float|has_flag}` to `ModifierTotals.{...}`. PactManager-specific calls (`get_def`, `activate`, `is_offered`, `pacts_changed`, `active_ids`) remain because they're pact-specific data, not effect lookups.
- New effect types: `upgrade_cost_mult` (hook: `tower.upgrade_cost()`), `slow_duration_mult` (hook: `tower._fire()` before passing to projectile).
- `phase_controller.gd` — new `RELIC_CHOICE` phase, `relic_choice_started` signal, `RELIC_WAVES = [5]` constant. Relic check fires before pact check so when both could trigger (won't currently, but defensive), the relic wins.
- New `ChooseRelicCommand` mirrors `ChoosePactCommand`.
- `hud.gd` — the existing pact choice modal now serves both kinds: tracks `_current_choice_kind`, swaps title/subtitle ("Choose a Relic" vs "Choose your Pact"), renders only Boon for relics (no Curse line). Card click dispatches `ChooseRelicCommand` or `ChoosePactCommand` based on kind. Active modifier ribbon now shows two lines (Pacts / Relics) with distinct colors (gold / sky-blue).
- End-of-run summary: new RelicsLabel under PactsLabel; both shown only if non-empty.
- `RunLog.stats.relics` tracks chosen relic ids in order.
- `RunNameGenerator` falls back to the first relic's `run_adjective` when no pact has been taken — solo-relic runs still get a flavored name.
**Test:** See "Manual Test Checklist - Iter 5.1" below.

---

### Manual Test Checklist - Iter 5.1 (Relics)

- [ ] Beat wave 5. Modal pops up titled **"Choose a Relic"** with sky-blue header, 3 cards each showing Boon only (no Curse line).
- [ ] Pick one. Modal closes. Top-left ribbon now shows a "Relics:" row in blue alongside the existing "Pacts:" row.
- [ ] If you picked Coin Engine: every kill from wave 6 onward shows +1 extra gold (combine with Iron Vow pact if available and kills give +3 total).
- [ ] If you picked Loadbearer Banner: tower upgrade panel shows half-price upgrade cost.
- [ ] If you picked Sun Aegis: first leak each wave does 0 damage (combine with Overflow Mercy pact — both flags reduce first-leak but neither doubles up since `has_flag` is OR-only; the leak-damage-delta from Overflow Mercy still applies to subsequent leaks).
- [ ] If you picked Treasury Doctrine: income floater shows "+3 pact" portion add 3 more on next planning phase.
- [ ] If you picked Spreading Frost: enemy `SLO` chip persists noticeably longer when hit by Snowchaser/Frost Dryad.
- [ ] If you picked Mercy Sigil: enemy HP bars start with shorter green portion (10% less HP, multiplies with Iron Vow's +25% so net = 1.0 * 1.25 * 0.9 = 1.125 = +12.5% net).
- [ ] After wave 6 (pact wave), modal returns to "Choose your Pact" with gold header — relic flag did not corrupt pact flow.
- [ ] End of run, summary panel shows "Relics: <name>" line below "Pacts:" line.
- [ ] Add a new file to `data/relics/`. Restart run; the new relic appears in rotation.

**Acceptance criteria met:**
- Relics appear as choices. ✓ (3 cards after wave 5)
- Relic effects visibly change playstyle. ✓ (each relic's effect demonstrably alters at least one game system)
- Run summary lists relics. ✓
- Reuses pact infrastructure. ✓ (single modal scene, parallel managers, ModifierTotals helper)

---

---

## 2026-05-25 — Daily seed + local scoreboard (Iteration 8.5)
**Decision:** Add a "Daily Storm" mode: today's seed is derived deterministically from the calendar date (`YYYY*10000 + MM*100 + DD`), so every player on the same day gets the same first draft, same wave order, same pact roll. After the run, score is computed from `RunLog.stats` via a fixed formula, persisted to `user://daily_scores.json`, and a "Copy Share Text" button generates a six-line summary the player can paste into chat.
**Why:** This is the first social-comparison surface that doesn't require multiplayer code. The engagement addendum lists daily seeds as one of the highest-value retention features. The foundation (SessionRng, RunLog with damage_by_unit and pacts/relics, RunNameGenerator) was already in place — this iteration is mostly persistence + UI.
**Why these score weights:** Tested against the existing 10-wave campaign. A clean victory with 3 pacts + 1 relic and minimal leaks lands around 8000-10000. A defeat at wave 5 lands around 2000-3000. That ~5× spread gives meaningful comparison while keeping a single integer easy to remember and share. Leaks dock 50 each (real but not crushing); pacts/relics each add +200/+150 (taking risk is rewarded since both modifier types raise the difficulty when stacked with curses).
**Impact:**
- New autoload `Daily` (`scripts/daily.gd`) — owns `today_seed()`, `compute_score(stats)`, `record_run`, `today_runs()`, `today_best()`, `recent_dates()`, `share_text()`. Persists to `user://daily_scores.json` (Windows: `%APPDATA%/Godot/app_userdata/Duelyst_TD/`).
- `RunConfig.is_daily: bool` flag distinguishes daily runs from free runs.
- `RunLog.end_run` now captures `final_gold` and `final_lives` so the score formula can read them.
- Main menu — new "Daily Storm" section under New Run: shows today's `SHARD-XXXXXXXX`, today's best (if any), a "Play Daily" button, and a recent-dailies list (last 5 days with date/checkmark/best score/run name).
- End panel — when `is_daily`, shows a sky-blue "DAILY STORM" badge, a big "Score: N" line, and a rank line like "Daily run #3 today · best so far". A new "Copy Share Text" button copies the formatted summary to clipboard via `DisplayServer.clipboard_set`.
- Bonus fix: HUD's `_on_game_over` now ensures `RunLog.end_run` runs before reading stats, so child-first signal ordering can't leave stats unfinalized.
**Test:** See "Manual Test Checklist - Iter 8.5" below.

---

### Manual Test Checklist - Iter 8.5 (Daily seed)

- [ ] Main menu shows "Daily Storm" with today's `SHARD-XXXXXXXX` + ISO date. "No runs today yet." until first run.
- [ ] Click "Play Daily" → game starts. HUD top-bar seed matches the daily seed.
- [ ] Win or lose. End panel shows: sky-blue "DAILY STORM" badge, big "Score 4825" line, and "Daily run #1 today · new personal best for today".
- [ ] Click "Copy Share Text". Button briefly reads "Copied!"; paste into a text editor and confirm a 6-line summary with score, run name, wave, kills, leaks, pacts, relics, seed.
- [ ] "Main Menu" → daily best now shows your score + run name. "Recent dailies:" lists today.
- [ ] Play Daily again. End panel says "Daily run #2 today · best today: 4825" (or new personal best).
- [ ] Click "New Run (new seed)" from the end panel — restarts with a random seed AND `is_daily` is false (no daily badge on next end panel).
- [ ] Same-seed replay via "Replay (same seed)" preserves daily mode if it was a daily run.
- [ ] Confirm `%APPDATA%/Godot/app_userdata/Duelyst_TD/daily_scores.json` contains today's date key + entry array with score, run_name, result, waves, pacts, relics.
- [ ] Change the system date by a day (or wait), restart. Main menu shows a different `SHARD-XXXXXXXX`. The previous day appears in "Recent dailies:".

**Acceptance criteria met:**
- All players get same daily seed. ✓ (deterministic from system date)
- Restarting daily uses same settings. ✓ (Play Daily always re-derives today's seed)
- Score is recorded. ✓ (persisted to `user://daily_scores.json`)
- Shareable result text exists. ✓ (6-line summary on clipboard)
- Local scoreboard. ✓ (per-day arrays, best computed on read)

---

---

## 2026-05-25 — First content pack: Abyssian Choir (Iteration 13.1)
**Decision:** Ship the first themed content pack: **Abyssian Choir** — death-trigger + spirit-damage flavor. 4 new units, 1 counter-enemy, 1 pact, 1 relic, 1 documented challenge seed. Pack tests the existing data-driven content workflow end-to-end (no engine changes required beyond data files + a small `act1.json` edit).
**Why:** Up to this point we've built a lot of *systems* (data-driven units/enemies/pacts/relics/waves/maps, RunLog attribution, score formula, ModifierTotals). The content-pack iteration is where we actually USE that to ship a coherent themed bundle and verify the workflow holds together. The Abyssian faction was the most underdeveloped (1 unit prior) and the design bible explicitly names "death-trigger swarm" as its identity.
**Why this pack design:** The pack provides a *playable archetype* (spirit-spam + kill-driven economy) and *its own counter* (Sanctified Bulwark with 65% magic resist). A run that goes all-in on the new Abyssian units feels powerful in waves 1-7, then hits the Bulwark on wave 8 and 10 — forcing the player to mix in physical/frost towers or burst through with Aphotic Devourer's `targeting: strongest`. That's the strategy-triangle feedback loop the design doc keeps pushing for.
**Pack contents:**
- **Units (4)** — all Abyssian, spirit damage:
  - `gloomchaser` — 6g spirit striker, fast fire rate, swarm-friendly
  - `shadowdancer` — 9g spirit splash caster
  - `aphotic_devourer` — 11g heavy spirit single-target with `targeting: strongest` (boss-focused)
  - `black_solus` — 9g aura tower, +35% damage to all towers in 220 px (stronger than Sunbreaker's +30%)
- **Enemy (1)** — `sanctified_bulwark` — armored elite with 65% magic resist + 5 armor, reuses `f1_silverguardsquire` sprite with gold tint. Inserted into wave 8 (1 mid-wave) and wave 10 (1 elite alongside Andromeda). Counters the pack's spirit-heavy builds, rewards mixed damage types.
- **Pact** — `soul_auction` — +3 gold/kill, +15% enemy HP. Stronger reward than Frenzied Wages with a real cost; pairs with Iron Vow for a stacked kill-economy run.
- **Relic** — `echo_reliquary` — +2 gold/kill, +1 wave gold bonus. Pure boon; doubles the impact of swarm-clear builds.
- **Challenge seed** — `SHARD-AB551A4E` (decimal `2874015822`) — drafted to give Abyssian units priority in the early shop. Type into the main-menu seed field for a curated pack run.
**Asset reuse:** All sprites come from the converted Duelyst pool — no new art produced. The Sanctified Bulwark even reuses an existing converted sprite with a gold tint, demonstrating that the Content Bible's "recoloring is allowed, new art is not required" rule (Rule 4) works.
**Workflow validation:** The whole pack was 6 JSON files + a 2-line `act1.json` edit. No script changes. No autoload changes. No new scene files. **This is what the data-driven architecture was for.**
**Test:** See "Manual Test Checklist - Iter 13.1" below.

---

### Manual Test Checklist - Iter 13.1 (Abyssian Choir pack)

- [ ] Reroll draft offers a few times: Gloomchaser, Shadowdancer, Aphotic Devourer, Black Solus all appear with purple SPIRIT chips (Black Solus shows AURA gold chip).
- [ ] Place Black Solus next to two attacking towers; their effective damage increases by 35% (compare tower-panel "Dmg X" before/after).
- [ ] Place an Aphotic Devourer near the path; verify it targets the strongest enemy in range (largest HP bar) by watching kill order.
- [ ] After wave 3 pact roll, Soul Auction should be in the offering pool. After wave 5 relic roll, Echo Reliquary too.
- [ ] Take Soul Auction — kills give +3 gold; verify against a wave 4 Iron Squire (gold counter ticks +5 each kill, normally +2). Enemies feel chunkier.
- [ ] Take Echo Reliquary — income floater on wave 6 planning shows "+1 pact" portion (or higher if stacked with Treasury Doctrine / Greedy Horizon).
- [ ] Wave 8: a Sanctified Bulwark appears 5 s after wraithlings start. Verify the gold-tinted heavy holy unit has visible `A5 P25 M65` chips and takes minimal damage from spirit-only builds. Frost (Snowchaser) or physical (Archer) cuts through.
- [ ] Wave 10: a second Bulwark appears 10 s into the boss wave.
- [ ] End-of-run summary: if you mostly bought Abyssian units, dominant faction reads "Abyssian" and the theme is "Choir".
- [ ] **Challenge seed run**: main menu → seed field → `AB551A4E` → New Run. The first three draft offers should heavily favor Abyssian and Spirit-damage units (verify via the SPIRIT chips).
- [ ] All Abyssian unit JSONs sit in `data/units/`. All other files added: `data/enemies/sanctified_bulwark.json`, `data/pacts/soul_auction.json`, `data/relics/echo_reliquary.json`.

**Acceptance criteria met (per Stage 13 rule):**
- 3-5 units ✓ (4)
- 1 enemy counter ✓
- 1 relic ✓
- 1 pact ✓ (used in place of trait/flaw since those systems don't exist yet)
- 1 challenge seed ✓ (documented)
- Balance notes ✓ (this entry)
- Pack appears in draft ✓
- Pack has counters ✓ (Sanctified Bulwark)
- Pack does not dominate all builds ✓ (armored counter forces mixed damage)

**Deferred to future iterations (Stage 13 rule mentioned them but they need new systems first):**
- 1 trait — needs the trait system from Stage 4.4
- 1 flaw — needs the flaw system from Stage 4.5
- 1 wave modifier — needs the wave-modifier system from Stage 6.2
- 1 map modifier / special tile — needs Stage 7.5

---

---

## 2026-05-25 — Unit traits + HUD alignment pass (Iteration 4.4)
**Decision:** Add **traits** as stat-mod packets that roll onto draft offers (30%→65% chance ramping by wave). Same unit feels meaningfully different across runs based on its trait. Six starter traits: Heavy, Swift, Long-Eyed, Glass, Frostbound, Veteran. Also a HUD alignment pass: the end panel was overflowing the viewport, the debug overlay overlapped the bottom bar, the income floater reserved permanent layout space inside the gold counter.
**Why (traits):** Per Stage 4.4 + Content Bible, the same Duelyst unit drafted with different traits is the primary "you keep seeing familiar names but the play feels new" engine. Without traits, every Archer plays identically. With traits, an Archer + Swift becomes a totally different draft pick than an Archer + Heavy.
**Why (HUD pass):** Layout drift across 8 iterations. End panel was 760×560 trying to fit ~788 px of content; debug overlay overlapped bottom bar by 4-10 px; IncomeFloater reserved 180 px in HBoxContainer even when alpha=0.
**Why this trait design:** Stat-mod-only for MVP. No behavioral traits (Echoing/Volatile/Bonded each need bespoke code). All 6 starter traits compose from a small vocabulary of stat_mods (damage_mult, fire_rate_mult, range_mult, cost_mult, slow_duration_add, slow_factor_min, start_level). Adding a 7th trait = JSON edit only.
**Trait set:**
- **Heavy** (common): +60% damage, -30% fire rate
- **Swift** (common): +40% fire rate, -20% damage
- **Long-Eyed** (common): +30% range, -10% damage
- **Glass** (uncommon): +50% damage, -25% range
- **Frostbound** (uncommon): adds 0.6 s slow to attacks; sets slow_factor floor at 0.7 if unit had no slow
- **Veteran** (rare): +50% cost, starts at level 2 (one free upgrade baked in)
Buff-only towers (Sunbreaker, Black Solus, Healing Mystic) never roll traits — stat mods don't apply meaningfully.
**Impact (traits):**
- New `data/traits/` + 6 JSONs.
- New `TraitManager` autoload with `get_def(id)` and `maybe_roll(unit_def, wave)`.
- `DraftDirector`: new `current_traits` parallel array, `get_trait_for(idx)` accessor.
- `BuyOfferCommand` passes trait_id to placement.
- `placement_controller.gd`: `current_trait_id` field, `select_unit_for_placement(unit_id, trait_id)`.
- `PlaceUnitCommand` uses `UnitFactory.effective_cost(unit_id, trait_id)` for the gold check (Veteran +50% applies correctly).
- `UnitFactory.make_tower(unit_id, trait_id)`, new `effective_cost(unit_id, trait_id)`.
- `tower.gd`: new `apply_trait(def)` method, `trait_id`/`trait_name` fields.
- HUD: new TraitChip Label under each TypeChip (rarity-colored). Tower panel shows trait name next to level. Offer card cost line shows "(was Ng)" when trait modified cost.
- `RunLog.stats.traits_taken` Dict<trait_id, count>.
**Impact (HUD pass):**
- **End panel** 840×690 (offsets -420/-345 ↔ 420/345). VBox separation 10→5. Dropped redundant Separator1/2. EndLabel font 38→32, RunName 22→18, DailyScore 28→24. StatsGrid v_separation 4→2. Highlights min-height 96→78. CoachPanel min-height 96→80. Now comfortably fits with full daily badge + 3 coach insights + relics row in 720-tall viewport.
- **IncomeFloater** moved from inside `GoldBox` HBoxContainer to top-level child of HUD anchored top-center (440→840, 64→90). Doesn't reserve permanent layout space; doesn't overlap pacts ribbon.
- **Debug overlay** `StatsPanel` and `CmdPanel` `offset_bottom` -160 → -194 to clear the new 184-px bottom bar with 6 px gap.
- **Bottom bar** 170 → 184 to fit the new 144-px offer cards (added trait chip).
**Test:** See "Manual Test Checklist - Iter 4.4" below.

---

### Manual Test Checklist - Iter 4.4 (Traits + HUD pass)

**Traits:**
- [ ] Reroll a few times on wave 1. Some draft offers show a "TRAIT · <name>" chip below the damage-type chip, rarity-colored (gray common, green uncommon, blue rare).
- [ ] On wave 5-6 planning, trait chips appear more often (chance ramps from 30% to ~50%).
- [ ] Pick a Heavy Archer. Place it. Open tower panel — name reads "Archer (Lvl 1) · Heavy". Damage is ~+60% over vanilla.
- [ ] Pick a Swift Caster. Fires noticeably faster than vanilla.
- [ ] Pick a Veteran Heartseeker. Offer card shows cost "9g (was 6g)" — on place, tower opens at Lvl 2.
- [ ] Pick a Glass unit. Range visibly shorter on placement preview.
- [ ] Pick Frostbound on a non-slow unit (Archer). Hit enemies briefly show a SLO chip.
- [ ] Buff-only towers (Sunbreaker, Black Solus, Healing Mystic) never roll trait chips.
- [ ] End-of-run JSON log includes `"traits_taken": {"heavy": 2, "swift": 1, ...}`.

**HUD pass:**
- [ ] End panel fits entirely within the viewport (Restart / New Run / Main Menu / Share buttons all visible).
- [ ] F1 debug stats panel sits cleanly above the bottom bar (no overlap with draft cards).
- [ ] F2 debug commands panel same.
- [ ] IncomeFloater appears top-center under the top bar, NOT inside the gold counter. Doesn't push neighboring top-bar elements when hidden.
- [ ] Pacts ribbon (top-left) and IncomeFloater (top-center) don't overlap.
- [ ] Tower upgrade panel (top-right) doesn't clip the active-modifiers ribbon.

**Acceptance criteria met (Stage 4.4):**
- Same unit with different traits feels meaningfully different ✓
- Trait appears in shop UI ✓
- Trait modifies stats or behavior correctly ✓

---

---

## 2026-05-25 — Unit flaws (Iteration 4.5)
**Decision:** Add **flaws** as a second stat-mod packet that rolls onto draft offers that already have a trait. Same shape as traits (stat_mods dict), same application code path (`tower._apply_stat_mods`), but tracked as a separate concept with red-tinted UI. 5 starter flaws: Brittle, Slow-Witted, Tunneled, Costly, Myopic.
**Why:** Per Content Bible Section 7, the full draft offer shape is `Unit + Trait + Flaw`. The trait is the boon, the flaw is the cost half. This forces real decisions: "Heavy Archer (+60% dmg, -30% fire) is great, but Heavy Archer + Brittle (-20% dmg) might not be worth the same 50g". Players can intentionally pick risky offers when their build needs the boon enough.
**Why flaws never roll alone:** A pure-curse offer with no upside is just "this offer is worse" — players would always reroll. Flaws make existing trait offers SPICY, not new bad offers. Roll chance: 25% on trait-bearing offers at wave 1, +2.5% per wave, capped at 50%.
**Why reuse `apply_trait`'s machinery:** Traits and flaws have identical schema (`stat_mods`) and identical application. Code path: refactored `tower.apply_trait` to call `_apply_stat_mods(mods)`; new `apply_flaw(def)` wraps the same function and only writes `flaw_id`/`flaw_name`. Tower has both trait_id+name AND flaw_id+name so they're distinguishable for UI and serialization.
**Impact:**
- New `data/flaws/` with 5 JSONs (same shape as traits + `is_flaw: true` marker).
- New `FlawManager` autoload (parallel to TraitManager) with `maybe_roll(unit_def, wave, trait_id)` — only rolls when trait_id is non-empty.
- `DraftDirector.current_flaws` parallel array; `get_flaw_for(idx)` accessor.
- `BuyOfferCommand` passes flaw_id alongside trait_id.
- `placement_controller.gd` tracks `current_flaw_id`.
- `PlaceUnitCommand` uses `UnitFactory.effective_cost(unit, trait, flaw)` — Costly's +40% stacks correctly with Veteran's +50%.
- `UnitFactory.make_tower(unit, trait, flaw)` calls `apply_trait` then `apply_flaw`.
- `tower.gd`: `apply_trait` and `apply_flaw` both delegate to `_apply_stat_mods`. New `flaw_id` and `flaw_name` fields.
- HUD `_set_trait_chip` now combines trait + flaw into one chip line ("TRAIT · HEAVY  ·  FLAW · BRITTLE"). Tinted red when a flaw is present.
- Tower upgrade panel name shows both: "Archer (Lvl 1) · Heavy / Brittle".
- `RunLog.stats.flaws_taken` Dict<flaw_id, count>.
**Test:** See "Manual Test Checklist - Iter 4.5" below.

---

### Manual Test Checklist - Iter 4.5 (Unit flaws)

- [ ] Wave 1-2 offers: some show TRAIT chip only (no flaw yet, low chance).
- [ ] Wave 4+ offers: occasionally show "TRAIT · HEAVY  ·  FLAW · BRITTLE" in red-tinted chip.
- [ ] No offer ever shows just a flaw — flaws only roll on top of traits.
- [ ] Pick a Heavy + Brittle Archer (if it appears). Place. Tower panel reads "Archer (Lvl 1) · Heavy / Brittle". Damage reflects 1.6 × 0.8 = 1.28× base (less than vanilla Heavy alone).
- [ ] Pick a Veteran + Costly unit. Offer cost shows "Ng (was Mg)" where N is base × 1.5 (Veteran) × 1.4 (Costly) ≈ 2.1× base.
- [ ] Buff-only towers never get flaws (consistent with traits).
- [ ] Reroll several times on wave 6 — flaw chance feels around ~40%.
- [ ] End-of-run JSON includes `"flaws_taken": {"brittle": 2, "costly": 1, ...}`.

**Acceptance criteria met (Stage 4.5):**
- Flaws are visible before buying ✓ (red chip)
- Flaws create real tradeoffs ✓ (stat_mods compose multiplicatively with trait)
- Player can intentionally choose risky units ✓ (the choice is explicit on the card)

---

---

## 2026-05-25 — Unit evolution (Iteration 5.5)
**Decision:** Each placed tower earns gold-star tiers from its OWN kills. 3 tiers: **Tempered** (15 kills, +20% damage), **Veteran** (40 kills, +10% range), **Legendary** (80 kills, +10% fire rate). Stars drawn as gold quads above the tower's sprite. HUD tower panel shows current tier + progress to next.
**Why:** Towers were previously interchangeable. With evolution, a tower that's been in your build all run is meaningfully better than a fresh replacement. The engagement docs flag "attachment to specific placed units" as a top retention pillar.
**Why kill-based:** kill attribution already wired (projectile → enemy.dying check). Adding per-tower kill counters reuses the path via WeakRef on projectile, so AoE splash credits the source tower for every kill in the burst.
**Impact:**
- `tower.gd`: new `kills_count`, `evolution_tier`, constants `EVO_THRESHOLDS = [15, 40, 80]` and `EVO_NAMES`. New `add_kill()`, `_check_evolution()`, `_promote_to(tier)`, `evolution_progress()`. `_draw()` draws N gold stars per tier above the sprite.
- `projectile.gd`: new `source_tower_ref: WeakRef`. On enemy death, `_credit_kill()` calls `source_tower.add_kill()`. WeakRef survives tower-sold mid-flight.
- `tower._fire` passes `self` to projectile setup.
- HUD tower panel stats line appends "★N Name (K kills)" if evolved, or "K / 15 kills to Tempered" progress.
- `RunLog.stats.evolutions_by_tier` Dict {"1": N, "2": M, "3": K}.
**Balance:** thresholds tuned against the 10-wave Act 1. Early-placed core attackers can hit Tempered by wave 4-5, Veteran by 7-8, occasionally Legendary by wave 10 boss.
**Test:** See "Manual Test Checklist - Iter 5.5" below.

---

### Manual Test Checklist - Iter 5.5 (Unit evolution)

- [ ] Place an Archer wave 1-2. Tower panel reads "0 / 15 kills to Tempered". Progress shown live as it kills.
- [ ] At 15 kills, a single gold star appears above the sprite; damage jumps ~20%; panel reads "★1 Tempered (15 kills)".
- [ ] By mid-run, the same Archer hits Veteran (★2) — range circle visibly larger.
- [ ] By wave 10 a heavy attacker MAY hit Legendary (★3) — three stars, fires noticeably faster.
- [ ] AoE splash from Pyromancer/Firebreather: every kill in the burst counts toward the source's evolution.
- [ ] Sell an evolved tower mid-run; projectiles in flight don't crash.
- [ ] End-of-run JSON has `"evolutions_by_tier": {"1": N, "2": M, "3": K}`.

**Acceptance criteria met (Stage 5.5):**
- Unit can evolve after kills ✓
- Evolution changes mechanic (stats) ✓
- Evolution changes visual treatment ✓ (gold stars)
- Player can inspect evolution path ✓ (tower panel)

---

---

## 2026-05-25 — Combat readability pass (Iteration 9.1)
**Decision:** Three small but high-impact polish features: (1) boss wave banner — when a wave's tags include "boss", the wave-start banner switches from white "Wave N" to a red, warning-emoji-framed "⚠ Wave N · BOSS ⚠"; (2) target line on tower hover — hovering ANY placed tower (without first picking it via click) draws a thin gold line from tower to its current target; (3) floating damage popups — hits dealing ≥15 damage spawn a small colored "+N" that rises and fades over 0.7s, color-coded by damage type.
**Why:** Per the design doc's Section 9.1, "player can pause and understand the battlefield" + "important enemies stand out". The strategy triangle and trait/flaw systems give players a LOT to track. These three additions answer (1) "is this wave dangerous?", (2) "what is this tower actually shooting at?", (3) "which of my towers is doing real damage right now?". All at-a-glance, without reading numbers.
**Why filter damage popups by threshold:** At 50+ enemies on screen + 10 towers firing, unfiltered popups would saturate the play area. Threshold 15 means only big hits (heavy single-target casters, evolved towers, boss damage) surface — exactly the moments worth celebrating.
**Impact:**
- `hud.gd` `show_wave_banner`: reads wave tags via `_wave_tags(wave_num)`; switches color + text style when "boss" is present.
- `tower.gd`: new `show_target_line: bool` field, `set_show_target_line(s)` setter. `_draw()` draws line from origin to current_target (local coords) + small circle at target. `_process` queue_redraws while line is shown so it tracks moving enemies.
- `placement_controller.gd`: new `hover_tower` field. `_update_hover_tower()` finds the closest tower within TOWER_HIT_RADIUS each frame (skipped during placement preview). `_set_hover_tower(t)` toggles the show_target_line flag on the previous/new hover.
- `scripts/damage_popup.gd`: new self-contained Node2D. Spawned by `enemy.gd._spawn_damage_popup(amount, damage_type)` when a hit's applied damage ≥ 15. Drifts up 18 px while fading via ease-out alpha over 0.7s. Color-coded by damage type (strike/arcane/frost/etc).
**Test:** See "Manual Test Checklist - Iter 9.1" below.

---

### Manual Test Checklist - Iter 9.1 (Combat readability)

- [ ] Wave 1-9: banner reads "Wave N" in white.
- [ ] Wave 10 (boss): banner reads "⚠ Wave 10 · BOSS ⚠" in red.
- [ ] Hover a placed Archer without clicking. A gold line draws from the tower to the enemy it's currently targeting. Move the mouse off — line disappears.
- [ ] Hover another tower; line follows the new tower's target.
- [ ] Pick a tower (click). Range circle shows AND target line is visible from hover.
- [ ] Cast a Caster shot on a single enemy (24+ damage). A small purple "+24" floats up and fades.
- [ ] Archer hits (3-4 damage) don't spawn popups (below threshold).
- [ ] Pyromancer splash on a tight Wraithling pack: only enemies that absorbed ≥15 damage trigger popups.
- [ ] Boss takes a hit from an Aphotic Devourer: "+24" spirit-purple popup.
- [ ] No screen clutter at 30+ enemies — popups stay scarce because the threshold filters most hits.

**Acceptance criteria met (Stage 9.1, subset):**
- Boss warnings ✓
- Target line on hover ✓
- Damage number filtering ✓ (≥15 threshold)
- (Deferred: damage filtering UI toggle, leak shake, elite outlines beyond status chips, attack range arcs — already covered by show_range)

---

---

## 2026-05-25 — Second content pack: Vanar Frost Control (Iteration 13.2)
**Decision:** Ship **Vanar Frost Control** as the second themed content pack. 4 new units (Hearth-Sister, Gravity Well, Frostiva, Kindred Hunter) all frost damage. 1 counter-enemy (Sun-Priest, fast + 60% magic resist) added to wave 7. 1 pact (Heart of Winter), 1 relic (Vanar Banner) — both interact with `slow_duration_mult` so they stack with the existing Spreading Frost relic for hilariously long slows.
**Why:** Tests the data-driven workflow on a new theme with TRAIT/FLAW machinery active (the Abyssian pack in 13.1 predated that system). A frost-spam build now has Frostbound trait + Vanar Banner relic + Heart of Winter pact + Gravity Well 1.8s slows + Spreading Frost stacking — slows can reach 5+ seconds at 40% speed. The counter Sun-Priest exists specifically to punish that with magic resist.
**Why two relics with the same effect-type:** slow_duration_mult products multiply. Spreading Frost (1.5×) + Vanar Banner (1.3×) = 1.95× total. Heart of Winter pact stacks (1.5×) → 2.92× total. Each step is an explicit choice the player makes.
**Pack contents:**
- **Units (4):**
  - `hearth_sister` — 7g buff aura tower (+25%/200px), cheaper than Sunbreaker
  - `gravity_well` — 6g control tower, **strongest slow in roster** (1.8s @ 40%), tiny damage
  - `frostiva` — 10g frost caster, 12 damage + 1.2s slow per hit
  - `kindred_hunter` — 7g long-range (260px) frost sniper, brief slow per hit
- **Counter enemy:** `sun_priest` — fast (speed 110) + 60% magic resist. Reuses `f1_silverguardsquire` sprite with pale yellow tint. Inserted as 1 elite into wave 7 with 7-second delay.
- **Pact** `heart_of_winter`: +50% slow duration, +20% enemy HP.
- **Relic** `vanar_banner`: +30% slow duration (pure boon).
- **Challenge seed:** `SHARD-F8051CE0` (decimal `4160322272`) — biased toward Vanar units in the early draft.
**Asset reuse rule confirmed (again):** Sun-Priest reuses the silverguardsquire sprite. Two enemies now share that sprite (Iron Squire + Sanctified Bulwark + Sun-Priest = 3). Different stats + tints, distinguishable in play.
**Test:** See "Manual Test Checklist - Iter 13.2" below.

---

### Manual Test Checklist - Iter 13.2 (Vanar Frost Control)

- [ ] Reroll until you've seen Hearth-Sister (cyan AURA chip), Gravity Well (cyan FROST chip), Frostiva, Kindred Hunter in the draft pool.
- [ ] Gravity Well placed near the path: enemies entering its range get a long SLO chip — 1.8 s, 40% speed (much stronger than Snowchaser's).
- [ ] Frostiva fires: each shot deals 12 damage + applies 1.2 s slow. Boss take noticeable slow on each hit.
- [ ] Kindred Hunter: 260 px range is the longest in the game; visible large range circle on placement preview.
- [ ] Take Heart of Winter pact + Vanar Banner relic + Spreading Frost relic: Snowchaser slow durations should be roughly 1.0 × 1.5 × 1.3 × 1.5 ≈ 2.9 s. Verify with a SLO chip lasting ~3 s.
- [ ] Wave 7: Sun-Priest spawns 7s into the wave, fast (passes Stormkages eventually), gold-tinted. Frost damage minimal due to 60% magic resist. Physical (Archer / Kaido Assassin) breaks through.
- [ ] Challenge seed `F8051CE0` produces a Vanar-leaning first draft.

**Acceptance criteria (Stage 13 content pack rule):**
- 3-5 units ✓ (4)
- 1 enemy counter ✓
- 1 pact ✓
- 1 relic ✓
- 1 challenge seed ✓
- Trait ✓ (existing Frostbound applies to these units)
- Flaw ✓ (existing flaws apply)
- Wave modifier ✗ (Stage 6.2 not yet built)
- Map modifier ✗ (Stage 7.5 not yet built)
- Pack appears in draft ✓
- Pack has counters ✓
- Pack does not dominate ✓ (Sun-Priest punishes spirit-spirit-spirit, multi-damage builds still needed)

---

## Where the project is now

**16 iterations** in builds/ (`iter-0.4` through `iter-13.2`). All major Stage 0-9 milestones met. The data-driven core works: traits/flaws/pacts/relics/units/enemies/waves are JSON files. New content packs ship without code changes.

**Roster summary:**
- 21 player units across 6 factions + neutral
- 9 enemies across 6 families + boss
- 6 traits, 5 flaws, 7 pacts, 7 relics
- 10-wave Act 1 campaign
- 1 hand-authored map + map loader for adding more

**Backlog priorities for next sessions:**
- **3.1 Duelyst asset catalog** — useful as content multiplies
- **6.2 special wave mechanics** — silence/corruption/split (new mechanic systems, not just data)
- **8.4 Unit mastery** — cross-run persistence
- **7.1+ procedural maps** — bigger lift; need a generator and validators
- **8.6 weekly challenges** — extends daily seed with curated rule sets

---

## 2026-05-25 — Splitter enemies (Iteration 6.2, partial)
**Decision:** Introduce a generic `on_death` events array on `EnemyDef`. First event type implemented: `split` — spawns N child enemies at the dying enemy's path position. Used by a new Silithar Broodmother that splits into 3 Younglets on death. New `splitter` family added to counters.json with anti-swarm hint.
**Why:** Stage 6.2 listed several special wave mechanics (silence/corruption/split). Split has the cleanest implementation path and the most immediately satisfying combat reaction. The other two need new wave-modifier and tile-modifier systems; deferring.
**Why `on_death` as an array on EnemyDef:** Future event types (`spawn_token`, `corrupt_tile`, `explode_damage`) fit the same shape. The enemy doesn't know what kinds exist — it just emits `wants_to_spawn(id, progress)` and the spawner handles registration. Future event types added without re-wiring.
**Impact:**
- `enemy.gd`: new signal `wants_to_spawn(child_id, at_progress)`. `apply_def` stores `_on_death_events`. `_die` calls `_process_on_death_events` which iterates and emits the signal for splits, jittered by `progress_spread`.
- `wave_spawner.gd`: split `_spawn_one(id)` into `_spawn_at_progress(id, progress)`. New `_on_enemy_wants_to_spawn` handler — children get the same path attachment + signal hookups + active_enemies counter increment. **Recursive splits work for free** (a splitter spawn that itself has on_death events fires normally).
- `data/enemies/silithar_broodmother.json` — first splitter: 180 HP, scale 1.4, splits into 3 `silithar_younglet` with 20-px progress spread.
- `data/waves/act1.json` wave 9 renamed "Brood and Mist": 2 broodmothers (delayed) + supporting enemies. Tags: splitter/shielded/regen.
- `data/counters.json` adds `splitter` family with green tint and "splash damage cleans the brood" hint.
**Test:** See "Manual Test Checklist - Iter 6.2" below.

---

### Manual Test Checklist - Iter 6.2 (Splitter enemies)

- [ ] Wave 9 preview now shows "Splitter" tag (green) + the splash hint.
- [ ] First Broodmother spawns 2 s into wave 9 (1.4× scale, greenish tint, wider HP bar).
- [ ] On Broodmother death, 3 Younglets appear near her position with small forward jitter.
- [ ] Each younglet acts independently (own HP, regen, kill reward).
- [ ] Splash kill on the mother CAN also hit the just-spawned brood — bursts on her tile.
- [ ] Without splash, you must clear 3 extra units per mother — visibly more work.
- [ ] Source tower's evolution stars still tick from brood kills (kill attribution survives the split).
- [ ] Broodmother leaks: she does damage_to_base but no children spawn (on_death only fires on death).
- [ ] Younglets have no on_death so the chain terminates after one split.

**Acceptance criteria met (Stage 6.2 partial — split waves):**
- Split mechanic works ✓
- Wave warning appears via existing preview ✓
- Counter hint explains the behavior ✓
- (Deferred: silence wave, corruption wave, fog/rush specials — each its own system)

---

---

## 2026-05-25 — Unit mastery (Iteration 8.4)
**Decision:** Add **cross-run mastery**: per-unit stats persist between runs, levelled into 5 tiers (Initiate / Adept / Master / Champion / Legend) gated by combinations of placements, estimated kills, and victories. New "Unit Mastery" button on the main menu opens a scrollable list showing every unit ever placed with its tier + counters + best wave reached.
**Why:** First long-term retention pillar. Daily seed gives social comparison; mastery gives personal progression. Players who use Pyromancer 30 times across 5 runs see the level climb from Initiate → Adept → Master. The engagement addendum lists mastery as a top retention feature (Pillar 3).
**Why estimated kills, not exact:** Per-tower kill counts exist only within a single run. Persisting per-tower kill IDs would require tying each tower to a stable identity at place-time, which complicates the placement command path. Instead, mastery uses a damage-share proxy: `kills_estimate = floor((unit_damage / total_damage) * total_kills)`. Good enough for tier gating (the thresholds are 50/100/200/500), bad for leaderboard precision — fine since this is personal progression, not competitive.
**Why no permanent stat unlocks:** Per Stage 10's "Avoid early meta-stat bloat" — mastery levels are visible badges + future unlock hooks (cosmetic frames, lore, variant traits all flagged for future iterations), not "+5% damage forever". Keeps new-player balance intact.
**Impact:**
- New autoload `Mastery` (`scripts/mastery.gd`). Persists `user://mastery.json`. Tiers defined in code with `kills/wins/placements` thresholds. Methods: `get_entry(unit_id)`, `mastery_level(unit_id)`, `tier_name(level)`, `record_run(stats)`, `sorted_entries()`.
- `run_log.gd` `end_run`: calls `Mastery.record_run(stats)` after `save_to_file`. The mastery aggregator walks `placements_by_unit` and `damage_by_unit`, increments per-unit kills/runs/wins/placements/max_wave.
- Main menu: new **Unit Mastery** button. Opens a centered Panel (720×600) with title + subtitle + scrollable RichTextLabel listing all units sorted by tier desc, then kills desc.
- List rows are bbcode-colored by tier (gray 0, light gray 1, green 2, cyan 3, purple 4, gold 5).
- Mastery panel uses ScrollContainer + RichTextLabel for arbitrary growth as content expands.
**Test:** See "Manual Test Checklist - Iter 8.4" below.

---

### Manual Test Checklist - Iter 8.4 (Unit mastery)

- [ ] Fresh install: main menu "Unit Mastery" → opens panel with "No runs recorded yet."
- [ ] Play one run, place 3+ different units, lose. Return to main menu → Unit Mastery shows those units with placements ≥ 1, kills > 0, wins = 0.
- [ ] Play & win one run → those units show wins = 1, max_wave = 10.
- [ ] After several runs, top units' kills accumulate. Eventually one crosses 50 kills → tier flips to "Lv 2 Adept" (green text).
- [ ] After ≥1 victory + 100 kills with a unit → "Lv 3 Master" (cyan).
- [ ] `user://mastery.json` contains all units with cumulative stats. Inspect via the file system.
- [ ] Close button returns to main menu without crash.
- [ ] Daily run stats also feed mastery (same end_run hook).

**Acceptance criteria met (Stage 8.4):**
- Unit profile screen exists ✓ (mastery panel)
- Using a unit progresses mastery ✓
- Rewards are not raw stat boosts ✓ (tier names only; cosmetics/lore deferred)

---

---

## 2026-05-25 — Third content pack: Songhai Burst (Iteration 13.3)
**Decision:** Third themed pack — **Songhai Burst** — high-tempo strike with a "fast multi-hit + heavy single-target burst" feel. 4 new units, 1 counter (Clad Juggernaut on wave 8), 1 pact, 1 relic. Tests trait/flaw/evolution stat math on a faction whose identity is speed and burst.
**Pack contents:**
- **Units (4):**
  - `chakri_avatar` — 8g rapid striker (2.6/s, 5 dmg strike). Eats shields; evolves fast.
  - `geomancer` — 11g heavy arcane splash (13 dmg, 75 splash). Counter to armored + swarm.
  - `onyx_jaguar` — 10g `targeting: strongest` finisher (20 dmg strike). Cheaper than Kaido.
  - `lantern_fox` — 8g aura (+28% / 180 px). Songhai-themed support.
- **Counter** `clad_juggernaut`: reuses `neutral_diamondgolem` sprite, 240 HP, **8 armor + 50% phys resist + 20% magic resist**. Punishes strike-burst builds.
- **Pact** `duelists_bet`: +5 gold/kill, +15% enemy speed.
- **Relic** `storm_relic`: +1 kill gold AND +1 wave gold (pure boon, modest stacking with other gold sources).
**Why two armored enemies on wave 8 now:** Wave 8 was already "armored + swarm". The third late-spawning armored elite at delay 12s tests whether the player has diversified beyond their initial trait choices.
**Test:** See "Manual Test Checklist - Iter 13.3" below.

---

### Manual Test Checklist - Iter 13.3 (Songhai Burst pack)

- [ ] 4 new units in pool: Chakri Avatar (STRIKE), Geomancer (ARCANE), Onyx Jaguar (STRIKE), Lantern Fox (AURA).
- [ ] Chakri Avatar fires fastest in roster (2.6/s base).
- [ ] Onyx Jaguar visibly targets the strongest enemy on screen.
- [ ] Geomancer splash radius is wide (75 px burst).
- [ ] Lantern Fox aura +28%/180 px (between Hearth-Sister 25% and Sunbreaker 30%).
- [ ] Wave 8 spawns Clad Juggernaut 12 s in — gray 1.30× golem with A8 + P50 + M20 chips.
- [ ] Strike-only build does heavily reduced damage to the Juggernaut. Geomancer/Pyromancer cuts through.
- [ ] Duelist's Bet pact + Chakri Avatar = big gold from swarm waves.
- [ ] Storm Relic stacks with Coin Engine + Echo Reliquary correctly.

**Acceptance criteria (Stage 13 content pack):**
- 4 units ✓
- 1 enemy counter ✓ (Clad Juggernaut)
- 1 pact ✓
- 1 relic ✓
- Pack appears in draft ✓
- Counter forces mixed damage ✓

---

---

## 2026-05-25 — Silence waves (Iteration 6.2b)
**Decision:** Second special wave mechanic on top of splitter enemies — **silence**. A wave's `wave_modifier` field can declare `{"type": "silence", "first_at": F, "interval": I, "duration": D}` and recurring silences trigger during combat: all towers stop firing for `D` seconds at fixed intervals. Wave 6 ("Frost Veil") gets a 1.5 s silence every 9 s starting at t=5 s. New `WaveEffects` autoload owns active-effect state with stale-timer guards via wave-session IDs.
**Why:** Splitter (the first 6.2 mechanic) attacks the player's positioning. Silence attacks the player's DPS uptime. Together they prove the wave_modifier hook is extensible — future modifiers (fog reducing range, corruption damaging tiles) plug into the same `WaveEffects.start_wave(modifier)` entry point.
**Why fire_cooldown still advances during silence:** Tested both options. With cooldown freezing, post-silence firing feels staggered/random. With cooldown advancing, all towers fire in sync the instant silence lifts — a satisfying "volley" moment. Players also intuit "everyone was ready, they just couldn't shoot" rather than "silence permanently delayed all my towers."
**Why stale-timer guards via wave_id:** `tree.create_timer` callbacks fire even after wave ends or run restarts. The `current_wave_id` increments on every start/clear; each timer captures its wave_id and no-ops if it doesn't match. Clean, no dangling effects across run boundaries.
**Impact:**
- New `WaveEffects` autoload. API: `start_wave(modifier)`, `clear_all()`, `is_silenced()`, `remaining(effect_id)`. Signals: `effect_started(id)`, `effect_ended(id)`. Match statement on `modifier.type` dispatches to `_schedule_silence(...)` — extensible.
- `wave_spawner.start_wave(N)` reads `def.wave_modifier` and forwards to `WaveEffects.start_wave(mod)`.
- `tower._fire` early-returns if `WaveEffects.is_silenced()` (after cooldown decrement so timing post-silence is synced).
- New `SilenceBanner` Label in HUD at top-center; pulses alpha 0.55↔1.0 every 0.18s. Wired to `effect_started/ended`.
- `data/counters.json`: new `silence` family entry (cyan, with anti-silence hint about fast multi-hit recovering faster).
- `data/waves/act1.json` wave 6 tagged `silence` + given the modifier.
**Test:** See "Manual Test Checklist - Iter 6.2b" below.

---

### Manual Test Checklist - Iter 6.2b (Silence waves)

- [ ] Wave 6 preview now shows the cyan "Silence" tag with the recovery hint.
- [ ] 5 s into wave 6, all towers stop firing simultaneously. Cyan "⚠ SILENCE — towers paused" banner appears at top-center, pulsing.
- [ ] After 1.5 s, banner disappears AND all ready towers fire at once in a synced volley.
- [ ] Repeats every 9 s.
- [ ] Slow casters (Geomancer, Caster, Onyx Jaguar) feel the silence more — they had higher cooldowns to begin with.
- [ ] Fast multi-hit (Archer, Azurite Lion, Chakri Avatar) recovers faster — more uptime over the wave.
- [ ] Reaching wave 7 (no silence) → banner doesn't appear, towers fire normally.
- [ ] Restart mid-silence → new run starts cleanly (no leftover silence from the previous run).
- [ ] Stale-timer guard: pause mid-silence, wait, unpause. Silence ends when its duration is up, not based on real time.

**Acceptance criteria (Stage 6.2):**
- Silence wave mechanic ✓
- Wave warning appears ✓ (silence tag in preview)
- Wave mechanic visible during combat ✓ (pulsing banner)
- Counter hint explains the behavior ✓
- (Still deferred: corruption waves — needs tile-modifier system)

---

---

## 2026-05-25 — Corruption waves (Iteration 6.2c)
**Decision:** Third special wave mechanic, completing the splitter/silence/corruption trilogy. A wave with `wave_modifier: {"type": "corruption", "on_leak": true}` causes every enemy leak to **permanently corrupt the nearest buildable tile** for the rest of the wave. Towers placed on corrupted tiles fire at **70% rate**. Corruption auto-clears at wave end. Capped at 6 corrupted tiles per wave so a leaky wave can't make placement impossible.
**Why:** Leaks were previously "lose a life and move on." Now they CHANGE the board — the player loses lives AND incurs spatial debt. This pairs with the existing Overflow Mercy / Sun Aegis modifiers (which negate the leak life cost): under Corruption, those modifiers no longer fully absolve a leak. Wave 8 ("Wall and Waves") is a natural fit because its swarm density makes some leaks likely even with good defense.
**Why corruption lives on the grid:** Tile dynamic state belongs with the grid (it's a tile property). `GridController` gains a `corrupted_tiles: Dictionary` map + `corruption_changed` signal. `TileRenderer` listens and redraws with a purple overlay + central swirl marker on corrupted tiles. Towers query via `WaveEffects.is_position_corrupted(world)` which forwards to the grid via WeakRef — keeps tower decoupled from main scene.
**Why cap at 6 tiles:** Wave 8 has 16 enemies. If 10 leak, you'd corrupt 10 tiles. With ~80 buildable tiles on the 20×8 map, 10 corruptions is survivable, but combined with low life count it accelerates the death spiral. 6 keeps the punish meaningful without bricking a tight run.
**Impact:**
- `grid_controller.gd`: `corrupted_tiles: Dictionary`, `corruption_changed` signal, `is_corrupted(gp)`, `is_corrupted_at_world(pos)`, `clear_corruption()`, `corrupt_nearest_buildable(world_pos, max_total=6)`.
- `tile_renderer.gd`: connects to `corruption_changed`; draws purple translucent overlay + swirl on each corrupted tile after the normal render pass.
- `wave_effects.gd`: new `corrupt_on_leak: bool` flag, new `_grid_ref: WeakRef`, new `set_grid(g)` and `is_position_corrupted(world_pos)`. `start_wave(modifier)` clears prior corruption + sets the flag if modifier.type == "corruption". `clear_all` resets the flag and clears tiles.
- `wave_spawner.gd`: new `grid: GridController` field. On leak: if `WaveEffects.corrupt_on_leak`, call `grid.corrupt_nearest_buildable(core_world_pos)`.
- `tower.gd._process` after firing: `if WaveEffects.is_position_corrupted(global_position): rate *= 0.7`.
- `main.gd`: sets `spawner.grid = board.grid` and `WaveEffects.set_grid(board.grid)` after load.
- `data/waves/act1.json` wave 8: adds `wave_modifier` + `corruption` tag.
- `data/counters.json`: corruption family entry.
**Test:** See "Manual Test Checklist - Iter 6.2c" below.

---

### Manual Test Checklist - Iter 6.2c (Corruption)

- [ ] Wave 8 preview shows purple "Corruption" tag + the leak-corrupts-tile hint.
- [ ] Deliberately let an Iron Squire leak. A buildable tile near the core turns purple with a swirl marker.
- [ ] Repeat → multiple tiles corrupt, capped at 6 per wave.
- [ ] Place a tower on a corrupted tile (or look for one already there). Its fire rate is visibly slower (compare cooldown vs a tower on a clean tile).
- [ ] Sell the tower on a corrupted tile, place it on a clean tile → fire rate returns to normal.
- [ ] After wave 8 clears, all purple tiles disappear (corruption is per-wave, not permanent).
- [ ] Wave 9 (no corruption modifier) doesn't corrupt on leak.
- [ ] Overflow Mercy / Sun Aegis (first-leak-free) STILL allow that first leak's life loss to be 0, but corruption still applies because corruption fires on the reached_end event regardless of damage.

**Acceptance criteria (Stage 6.2 complete):**
- Special wave mechanic works ✓ (corruption)
- Wave warning appears ✓ (preview tag + hint)
- Wave mechanic visible during combat ✓ (purple tiles)
- Counter knowledge ✓ (counters.json hint explains)
- Stage 6.2 mechanics shipped: splitter (broodmother), silence (towers paused), corruption (tile debuff). Three of the named special waves done.

---

## 2026-05-25 — Duelyst HUD skin (Iteration Polish.1)
**Decision:** Adopt Duelyst's typography + cursor + unit portraits in the existing HUD without restructuring scenes. Bundles four user-requested polish items: (a) draft-card unit portraits, (b) Duelyst cursor, (c) Duelyst fonts, (d) reuse of Duelyst UI feel via theme + font weights.
**Why:** Players couldn't tell which unit a draft card represented without reading the name — adding the idle sprite frame turns each card into a visual identity. Cursor + body font + display font cement the Duelyst look reusing CC0 assets we already control. All four items are cosmetic only; no gameplay logic changes.
**Why one bundled iteration:** Each item alone is a 2-file change. Bundling keeps the asset additions, theme wiring, and HUD geometry shift in a single coherent diff rather than spreading cursor / font / portrait / theme over four near-identical iterations.
**Impact:**
- New `assets/fonts/`: `Lato-Regular.ttf`, `Lato-Bold.ttf`, `TrumpGothicPro-Bold-webfont.ttf` (copied from OpenDuelyst `app/resources/fonts/`).
- New `assets/ui/cursor.png` (from `mouse_select@2x.png`), `cursor_hand.png` (from `icon_hand@2x.png`), `frames/status_panel.png`, `frames/dialogue_border.png`.
- New `assets/ui/duelyst_theme.tres`: Lato-Regular as default font (size 13), Lato-Bold for Buttons, RichTextLabel bold-font binding.
- `project.godot`: new `[gui] theme/custom`, new `[display] mouse_cursor/custom_image` + hotspot `(8, 6)`.
- `scenes/hud.tscn`:
  - BottomBar `offset_top` -184 → -224 (grew 40 px to fit portraits).
  - Each OfferBox: new `OfferPortrait{1,2,3}` `TextureRect` (64 px tall, mouse_filter=ignore, stretch=keep-aspect-centered) as first child above `OfferBtn`. Min height per OfferBox 144 → 200. OfferBtn min height 80 → 64 to keep card compact.
  - WavePreview min height 144 → 200 for visual balance.
  - TrumpGothicPro-Bold (`4_tgp`) applied to `WaveBanner` (size 64), `PactChoicePanel/Title` (size 36), `EndPanel/EndLabel` (size 40), `EndPanel/RunName` (size 24).
- `scenes/main_menu.tscn`: TrumpGothicPro applied to title (size 64) and Mastery panel title (size 32).
- `scenes/debug_overlay.tscn`: `StatsPanel.offset_bottom` and `CmdPanel.offset_bottom` -194 → -234 to clear the taller bottom bar.
- `scripts/hud.gd`: new `offer_portraits: Array[TextureRect]`. `show_draft_offers` populates each portrait with `_portrait_for(unit_id)`. New `_portrait_for(unit_id)` helper: pulls `UnitFactory.sprite_frames_for(id)`, prefers `idle / breathing / breath / default` animation, falls back to first non-empty animation, returns the texture of frame 0. Portrait is tinted with the faction color (lerped 25% toward white).
**Why portraits use idle frame 0:** SpriteFrames already loaded by UnitFactory expose `get_frame_texture(anim, 0)` which returns the AtlasTexture pointing at one rect inside the spritesheet — zero added load cost. Idle animation is the canonical "looking right at you" pose; breathing and default are fallbacks for older atlases.
**Why the cursor hotspot is (8, 6):** Duelyst's `mouse_select@2x.png` arrow tip is around pixel (8, 6) of the 64×64 image; matches Duelyst's click registration.
**Why Lato 13 default:** Lato is the only font Duelyst used at small sizes (the rest were the display Trump Gothic). Size 13 matches our existing Label `theme_override_font_sizes/font_size = 13` baseline.
**Test:** See "Manual Test Checklist - Iter Polish.1" below.

---

### Manual Test Checklist - Iter Polish.1 (Duelyst HUD skin)

- [ ] Game launches and the OS arrow is replaced by Duelyst's white/blue selection arrow.
- [ ] Main menu title "Shardstorm TD" renders in Trump Gothic Pro (condensed, wide caps) instead of the default font.
- [ ] All body text (buttons, labels, descriptions) renders in Lato (softer than Godot's default).
- [ ] Start a run — each of the 3 draft offer cards shows a **unit portrait above the name** (idle sprite frame).
- [ ] Portraits are roughly the same size on each card and don't overlap the type/trait chips beneath.
- [ ] Faction tinting: e.g. an Abyssian offer's portrait has a purple cast, a Vanar offer has an icy blue cast.
- [ ] Reroll the shop several times — every offered unit (Lyonar, Songhai, Vetruvian, Abyssian, Magmar, Vanar, Neutral) draws a non-blank portrait.
- [ ] Wave-start banner ("Wave 3") uses Trump Gothic Pro and feels chunky.
- [ ] Pact choice modal title "Choose your Pact" uses Trump Gothic Pro.
- [ ] End-of-run panel: "Victory!" / "Defeat" and the run name use Trump Gothic Pro.
- [ ] F1/F2 debug overlay still fits above the bottom bar without overlapping the wave preview.

---

## 2026-05-25 — Panel frames + button styleboxes (Iteration Polish.2)
**Decision:** Replace Godot's default flat panel + flat button look with custom styleboxes wired through the global theme. Every `Panel` node uses a navy-blue `StyleBoxFlat` with rounded corners and a thin gold border. Every `PanelContainer` uses a slightly lighter `card_box` stylebox. `Button` uses `StyleBoxTexture` wrapping `button_confirm.png` (normal), `button_confirm_glow.png` (hover), and `button_cancel.png` (pressed). Each draft offer card is now wrapped in a `PanelContainer` so it inherits the card stylebox.
**Why:** Polish.1 added fonts + cursor + portraits, but every panel and button still rendered in Godot's default gray. The HUD looked half-skinned. Wiring styleboxes via the theme means the visual change is global with one source of truth, not 30 individual node overrides.
**Why StyleBoxFlat for Panel and not the Duelyst `frame_modal.png` 9-slice:** `frame_modal@2x` is 2368×2368 with the ornate metal corners taking ~10–15% of the texture. A 9-slice would either render those corners at their native pixel size (~240 px, dominating a 920×360 modal) or scale them and lose the ornament. StyleBoxFlat with a 2 px gold border + 6 px corner radius gets the same "framed dark panel" feel at any size without the scaling artifacts.
**Why the offer cards needed a scene refactor:** `VBoxContainer` doesn't draw a background, so you can't attach a stylebox to it. To give each card a frame, `OfferBox{1,2,3}` was changed from `VBoxContainer` to `PanelContainer` with a new child `Inner` `VBoxContainer` holding the existing portrait/button/chips. This means `theme_override_styles/panel` (via the global theme's `PanelContainer/styles/panel = card_box`) now paints each card.
**Impact:**
- New `assets/ui/frames/`: `button_normal.png`, `button_hover.png`, `button_pressed.png`, `card_normal.png`, `card_highlight.png`, `card_disabled.png` (latter three reserved for future state tinting), plus the existing `panel_modal.png`, `bottom_bar.png`, `status_panel.png`, `dialogue_border.png` from Polish.1.
- `assets/ui/duelyst_theme.tres`: now defines 8 sub-resources — `panel_box` (Panel default), `card_box` (PanelContainer default), `btn_normal/hover/pressed/disabled/focus` (Button states), and bound text colors. Default font + sizes preserved from Polish.1.
- `scenes/hud.tscn`: each `OfferBox{1,2,3}` is now a `PanelContainer` with a child `Inner` `VBoxContainer`. All offer children (`OfferPortrait`, `OfferBtn`, `TypeChip`, `TraitChip`, `OfferDesc`) reparented under `Inner`.
- `scripts/hud.gd`: `@onready` paths for offer children now include `/Inner/`. New `offer_boxes: Array[PanelContainer]` reference. `show_draft_offers` toggles `offer_boxes[i].visible` instead of toggling each child individually. `_refresh_offers_affordability` now also dims the whole card via `offer_boxes[i].modulate` when unaffordable (alpha 0.85 + slight gray) so the player sees at-a-glance which cards are reachable.
**Why dim by parent modulate:** Modulate propagates to descendants in Godot, so dimming the parent card dims the portrait, button, chips, and text together — one assignment, consistent visual.
**Test:** See "Manual Test Checklist - Iter Polish.2" below.

---

### Manual Test Checklist - Iter Polish.2 (Panel frames + button styleboxes)

- [ ] Start a run. Each of the 3 draft offer cards now sits inside a framed card with a faint gold border and rounded corners.
- [ ] When gold drops below an offer's cost, that card (entire card, including portrait + chips) dims to ~85% brightness. Affording it again restores full brightness.
- [ ] Hover over any button — the texture changes to the glow variant. Click + hold — texture changes to the cancel/pressed variant.
- [ ] Disabled buttons (e.g. Reroll when broke) show a flat dark gray box (the `btn_disabled` StyleBoxFlat fallback).
- [ ] Top bar, bottom bar, tower-info side panel, pact-choice modal, end-of-run panel, F1/F2 debug panels, main-menu mastery panel — **all** sport the same dark navy background with thin gold border + rounded corners.
- [ ] Wave preview card in the bottom bar has the slightly lighter card-style background (it's a PanelContainer).
- [ ] Buttons in the main menu (New Run, Play Daily, Run Determinism Test, Mastery, Quit) all use the textured Duelyst button style.

---

## 2026-05-25 — Procedural map generator + in-game map editor (Iterations 7 + 10)
**Decision:** Close out the two remaining original-plan items as a single iteration. `MapGenerator` produces seeded procgen maps that pass the existing `MapLoader.validate` pipeline. `MapEditor` is an in-game scene that paints the same MapDef tile chars (B/P/X/S/C), saves/loads `user://maps/*.json`, and Test-Plays into `main.tscn` via a custom-map RunConfig path. Both write **the same MapDef format** as the existing `starter_neutral.json`, so a procgen map can be saved + further edited, and an edited map can be replayed by ID.
**Why now:** Per design doc §17, these were Iterations 7 and 10 of the original 10-iteration MVP plan. Eight others shipped in earlier sessions; these two closed out the plan. The MVP scope §16 also calls for "one generated map" — that line was previously unmet because we only had the hand-crafted starter.
**Why one combined iteration:** Both pieces target the same MapDef format and the same `MapLoader.validate` validator. The editor's Test Play path doubles as a manual integration test for the loader → board pipeline that the generator also uses. Splitting them would have duplicated wiring.
**Why a fixed 20×8 grid for the editor:** Map size is a viewport concern (the existing rendering and `tile_size = 64` math assume a specific viewport). Variable map sizes is a Stage 11 concern — the editor MVP locks to the same dimensions as `starter_neutral.json` so the rest of the game (camera, HUD layout, wave spawner) works unchanged.
**Why MapGenerator uses a self-avoiding random walk (not A\* or BSP):**
- The loader enforces a *single linear non-branching path* (each path tile has exactly 2 path neighbors, endpoints have 1). A self-avoiding random walk with a "don't touch existing path" guard produces exactly that shape.
- The walk biases +X (4×), ±Y (2× each), -X (1× and only away from the left edge). This consistently reaches the right edge with 25-50 path tiles and 3-12 turns — the "interesting routes" the design doc called out.
- Retry-on-failure: stir the seed by attempt index (XOR with a Knuth golden-ratio multiplier). Up to 60 attempts; `generate_forgiving` walks the cluster forward by 1 if all 60 fail. Headless smoke test: 12/12 seeds pass, often on attempt 1.
**Why determinism is per-seed not per-SessionRng:** `MapGenerator` uses its own `RandomNumberGenerator` seeded from `RunConfig.seed`. Sharing `SessionRng` would couple map-gen to draft offers — replaying the same seed with a different map source would shift all the RNG-consuming systems downstream.
**Why MapLoader.validate had to accept both Array and Vector2 for origin:**
- The validator normalizes `origin` from JSON-loaded `[0, 56]` to `Vector2(0, 56)`.
- `MapGenerator.generate` calls validate internally; the resulting validated map is then passed to `board.load_dict`, which calls validate AGAIN to provide a single chokepoint for error handling.
- The second validation re-read `origin` as `Array` and crashed on `Vector2`. Fix: accept both at the top of validate's normalization step.
**Why _playtest is a special filename:** Pressing "Test Play" writes to `user://maps/_playtest.json` so we can hand the same code path the editor uses without prompting for a filename. The leading underscore filters it out of both the editor's load dropdown and the main menu's map picker — it's an intermediate artifact, not a save.
**Impact:**
- New `scripts/map_generator.gd` (160 lines): `generate(seed) -> {ok, map, attempts}` and `generate_forgiving(seed, walks=10)` which walks the seed forward if a cluster fails. Quality gate: path length 14-80, ≥3 turns, ≥55% buildable ratio.
- New `scripts/map_editor.gd` (270 lines): 20×8 button grid; palette of B/P/X/S/C; click-and-drag paint; auto-clears prior S/C when placing a new one; sanitized save to `user://maps/*.json`; Load dropdown enumerates user-saved maps (excludes `_*`); Validate calls `MapLoader.validate` and surfaces path length / errors; Test Play saves + flips RunConfig to custom-map mode + change-scenes to main.
- New `scenes/map_editor.tscn`: top toolbar, palette bar, framed grid area, status text.
- `scripts/board.gd`: new `load_dict(raw: Dictionary) -> bool` that runs the same validate→apply path as `load_map`. Internal `_apply_loaded` helper extracted to share between the two.
- `scripts/run_config.gd`: new fields `map_source: String` (`"fixed"` / `"generated"` / `"custom"`, defaults to `"fixed"`) and `custom_map_id: String`.
- `scripts/main.gd`: new `_load_configured_map()` dispatches on `RunConfig.map_source`. Falls back to starter on generator failure or missing custom file. `--use-generated` CLI flag for headless smoke tests forces procgen.
- `scripts/main_menu.gd`: new map-source `OptionButton` (Starter / Random / Custom: \<id\>), Map Editor button, `_apply_map_source_selection()` on "New Run". `_run_generator_smoke_test()` runs under `--test-generator` CLI flag.
- `scenes/main_menu.tscn`: added `MapRow` HBox (label + OptionButton + Editor button) between SeedRow and NewRunButton.
- `scripts/map_loader.gd`: validate now accepts `origin` as Array or Vector2 (double-validate safety).
- Daily run forces `map_source = "fixed"` so daily scores stay comparable across players.
**Headless validation:** `--test-generator` over 12 seeds = 12/12 pass, determinism PASS (same seed twice → identical tiles). `--use-generated --quit-after 6000` boots `main.tscn` with procgen → no errors.
**Test:** See "Manual Test Checklist - Iter 7+10" below.

---

### Manual Test Checklist - Iter 7+10 (Procgen + editor)

**Iter 7: Procedural map generator**
- [ ] Main menu — set Map dropdown to "Random (procgen)" → click New Run. A random map (not starter_neutral) loads. The seed shown in the HUD matches what was on the menu.
- [ ] Replay the same seed (Same Seed button on end panel) → same map appears.
- [ ] Pick 10 different seeds, all should yield interesting maps (paths with bends, not straight lines, plenty of buildable tiles).
- [ ] Verify in `--test-generator` headless output: 12/12 pass, "DETERMINISM: PASS".

**Iter 10: Map editor**
- [ ] Main menu → click Editor. Editor scene opens with a default S→C straight path.
- [ ] Click palette `P  Path` → click+drag through buildable tiles. They paint to brown path color.
- [ ] Click palette `S  Spawn` → click an empty tile. The previous green S tile turns blue (buildable) and the new tile becomes the spawn.
- [ ] Same for `C  Core`.
- [ ] Click Validate. A valid map (single connected path, S + C present) shows "Valid. Path length N." A broken map (orphan path tile, branching, missing S) shows the loader error.
- [ ] Type `my-test-map` in the Name field → Save. Status shows the saved path.
- [ ] Click New Blank → grid clears. Open the Load dropdown → `my-test-map` appears → select it → click Load → grid repopulates.
- [ ] Click Test Play on a valid map → game launches on that map. End the run, return to main menu, open editor again — the map you saved is still in the Load list (but `_playtest` is not).
- [ ] Main menu Map dropdown now lists "Custom: my-test-map" → New Run → game launches on it.

---

## 2026-05-25 — Growth-mode flag (Iteration A1 — Milestone A "Unit Growth Bake-Off")
**Decision:** Add a `RunConfig.growth_mode` enum (`classic_upgrade` / `merge_stars` / `merge_evolution_hybrid`) that every later iteration (A3-A6) can branch on. Pure plumbing for now: menu picks it, HUD shows it, RunLog records it, run summary renders it. **No actual upgrade or merge logic is wired yet** — the current `_on_upgrade` / per-unit upgrade flow continues to operate exactly as before regardless of which growth_mode is selected. Default is `classic_upgrade` so existing runs keep their current behavior.
**Why now:** Per the new roadmap addendum (`shardstorm_td_next_roadmap_addendum.md` §"Most Impactful Roadmap From Here"), the Milestone A bake-off is the gate that decides the game's identity — classic TD vs autobattler vs hybrid. Adding the flag *first* (A1) means A3-A6 can each branch cleanly on `RunConfig.growth_mode` without needing to re-thread the value through the menu/HUD/log scenes for every new system.
**Why plumb-only and not also implement classic upgrade scaling here:** The roadmap explicitly scopes A1 to "no actual upgrade/merge logic is required yet beyond plumbing" (line 1733). Keeps the diff small and reviewable; lets A3 own the classic-upgrade implementation as its single concern.
**Why daily mode doesn't force a specific growth_mode (yet):** Daily already pins `map_source = "fixed"` for comparable scoring. Doing the same for growth_mode is premature — the modes are visually distinguishable but mechanically identical until A3+. Will revisit once modes diverge.
**Why the HUD label sits in the top bar between Seed and Wave:** Players who switch modes between runs need a passive "did I pick the right one?" check during play. Putting it next to the seed (which serves the same "what configured this run?" function) clusters all run-identity info into one glance.
**Impact:**
- `scripts/run_config.gd`: new `growth_mode: String` (default `"classic_upgrade"`), `GROWTH_MODES` constant array of valid values, `set_growth_mode(mode)` validator, `growth_mode_label()` for display strings.
- `scripts/main_menu.gd`: new `GrowthOption` OptionButton populated from `RunConfig.GROWTH_MODES`. `_apply_growth_mode_selection()` called from `_on_new_run` (after seed + map source apply).
- `scenes/main_menu.tscn`: new `GrowthRow` HBox under `MapRow` (Label + OptionButton + hint text).
- `scripts/hud.gd`: new `growth_label` @onready ref + `set_growth_mode_label(label)` setter. Run summary now appends a short mode tag (`Classic` / `Merge★` / `Merge+Evo`) to the seed/wave line on `EndPanel/VBox/EndSeed`.
- `scenes/hud.tscn`: new `GrowthLabel` in `TopBar/HBox` between LivesBox and SeedLabel.
- `scripts/main.gd`: calls `hud.set_growth_mode_label(RunConfig.growth_mode_label())` alongside `set_seed_label` during run setup.
- `scripts/run_log.gd`: stats now includes `growth_mode`, `map_source`, `map_id` keys captured at `start_run`. Save files now carry these for retrospective analysis when A8 lands.
**Test:** See "Manual Test Checklist - Iter A1" below.

---

### Manual Test Checklist - Iter A1 (Growth Mode Flag)

- [ ] Main menu has a "Growth" row with an OptionButton listing Classic Upgrade / Merge Stars / Merge + Evolution.
- [ ] Default selection is Classic Upgrade.
- [ ] Pick Classic Upgrade → New Run → HUD top bar shows "Classic Upgrade" in blue text between the HP icon and the seed.
- [ ] End the run (win or leak out) → End panel shows "SHARD-... · Wave N / M · Classic" on the seed line.
- [ ] Return to menu, pick Merge Stars → New Run → HUD shows "Merge Stars" → End panel suffix is "Merge★".
- [ ] Return, pick Merge + Evolution → HUD shows "Merge + Evolution" → End panel suffix is "Merge+Evo".
- [ ] Across all three modes, gameplay is functionally identical (towers placed, upgrades still cost gold, waves spawn, win condition unchanged) — this confirms plumbing didn't accidentally short-circuit any existing system.
- [ ] Inspect a saved RunLog JSON in `user://run_log_*.json` → top-level `stats.growth_mode` is one of the three values.

---

## Next iteration candidates (paused — see C-track below)

The A-track (growth bake-off) is paused after A1 in favor of the new co-op addendum's C-track (Starbase co-op). A2-A8 will resume once the C-track lands a playable 2-player vertical slice. See the supersession note in the next entry.

---

## 2026-05-25 — Player count + session topology plumbing (Iteration C0 — Milestone C "Starbase Co-op")
**Decision:** Add the architecture plumbing for multi-player co-op per `shardstorm_td_coop_multiplayer_arena_addendum.md` §C0 (lines 2125-2179). New `RunConfig.player_count` (1-4) + `session_topology` (`solo` / `starbase` / `debug`), new `PlayerSlot` data class, new `SessionController` node in main.tscn that creates one PlayerSlot per player_count. Single-player remains the default and continues to play exactly as before (slot 0 proxies to existing GameState).
**Why the pivot from A-track to C-track:** The new addendum (added after A1 shipped) explicitly states the most-impactful next path is C0-C11 co-op, and *"Do not add more content packs until this co-op topology is playable. More units will not answer the biggest design question, which is: Does shared-Core, multi-route co-op feel good?"* The growth-mode A-track and the co-op C-track both touch RunConfig + RunLog + HUD + main.gd, so doing them in series avoids merge thrash. A2-A8 will resume after a 2-player Starbase prototype is playable.
**Why the new addendum's C-track supersedes the previous addendum's B-track:** Previous addendum proposed "parallel boards" co-op (each player gets their own independent board). New addendum demotes that to a debug-only fallback (line 2.5) and pivots to "Starbase Co-op" — one shared central Core with one route per player. Old `B1-B6` items are now subsumed under new `C1-C12`.
**Why `session_topology` has three values for C0:** `"solo"` for player_count==1, `"starbase"` for the eventual playable co-op, `"debug"` as the transitional state where player_count > 1 but the visible game still runs the single-board flow (because CoopMapDef doesn't land until C1). `set_player_count(n)` auto-promotes solo→debug when n>1; user picks explicit topology in a later iteration.
**Why SessionController is a scene node (not autoload):** Slot list is per-run state, not per-process state — autoloading would leak slots across runs. Living as a child of `main.tscn` matches the existing `RunLog` / `GameState` lifecycle pattern. `_ready` deliberately does NOT auto-configure, because in Godot children's `_ready` fires before parent's `_ready` and we need `RunLog.start_run` to have already happened so `record_player_slots` lands in active stats. `main.gd._ready` calls `session.configure(...)` explicitly after `RunLog.start_run`.
**Why PlayerSlot is RefCounted, not Node:** For C0, slots are pure data. Making them Nodes adds a scene-tree dependency that buys nothing until per-route systems (C2+) need signals. Promote to Node if a future iteration genuinely needs that.
**Why daily mode pins `player_count = 1`:** Daily scores must compare across players; multi-player score normalization isn't in the design yet. Same reason daily pins `map_source = "fixed"`.
**Impact:**
- `scripts/run_config.gd`: new `player_count: int` (default 1), `session_topology: String` (default "solo"), `MIN_PLAYER_COUNT`/`MAX_PLAYER_COUNT`/`SESSION_TOPOLOGIES` constants, `set_player_count(n)` (clamps + auto-promotes topology), `set_session_topology(topo)` (validates).
- `scripts/player_slot.gd` (new, RefCounted): data class with `slot_id`, `display_name` (P1/P2/...), `color` (4 default colors), `route_id`/`gate_shield`/`ready_for_wave`/`aid_tokens` placeholders for C1+, per-slot `stats` dict, `to_dict()` for RunLog serialization.
- `scripts/session_controller.gd` (new): owns `player_slots: Array`, `local_slot_id: int`, `configure(n, topology)` creates N slots and calls `RunLog.record_player_slots`. Explicit configure (not _ready auto-config) to avoid races.
- `scenes/main.tscn`: new `SessionController` child node under Main.
- `scripts/main.gd`: new `@onready var session: Node`. Calls `session.configure(RunConfig.player_count, RunConfig.session_topology)` immediately after `RunLog.start_run`. Calls `hud.set_players_label(RunConfig.player_count, RunConfig.session_topology)` alongside the other HUD setters.
- `scripts/main_menu.gd`: new `PlayersOption` OptionButton with 1-4 player choices. `_populate_player_counts()` + `_apply_player_count_selection()` plumbed through `_on_new_run`. `_on_play_daily` pins `player_count = 1`.
- `scenes/main_menu.tscn`: new `PlayersRow` HBox under `GrowthRow` (Label + OptionButton + hint text).
- `scripts/hud.gd`: new `players_label` @onready ref + `set_players_label(player_count, topology)` setter (hidden when ≤1).
- `scenes/hud.tscn`: new `PlayersLabel` in TopBar/HBox, default hidden.
- `scripts/run_log.gd`: stats now include `player_count`, `session_topology`, `player_slots` (Array). New `record_player_slots(slots)` called by SessionController.
- `scripts/debug_overlay.gd`: F1 stats panel now shows Growth + Players + topology lines.
**Test:** See "Manual Test Checklist - Iter C0" below.

---

### Manual Test Checklist - Iter C0 (Player count plumbing)

- [ ] Main menu has a "Players" row under "Growth" with 1 / 2 / 3 / 4 options. Default is 1 · Solo.
- [ ] Pick 1 · Solo → New Run → game plays exactly as before (board, draft, waves, HUD identical). Top bar does NOT show a co-op badge.
- [ ] Console log on run start: `SessionController: 1 slot(s), topology=solo`.
- [ ] F1 debug overlay → Stats panel shows `Players: 1  ·  topology: solo`.
- [ ] Return to menu, pick 2 · Starbase co-op → New Run → console shows `SessionController: 2 slot(s), topology=debug` (auto-promoted from solo). Top bar shows a gold "Debug · 2p" badge between the growth label and seed.
- [ ] F1 → `Players: 2  ·  topology: debug`.
- [ ] Game still plays as single-board (slot 0 perspective). No errors, no crashes. Slot 1 exists in memory but isn't visible — that's the C0 scope.
- [ ] Repeat for 3 and 4 players → console logs 3 and 4 slots.
- [ ] Play Daily → console shows `SessionController: 1 slot(s), topology=solo` even if menu had been set to 4 — daily is pinned solo.
- [ ] Open a saved RunLog JSON in `user://run_log_*.json` → `stats.player_count`, `stats.session_topology`, and `stats.player_slots[*].slot_id` are populated.

---

## 2026-05-25 — Duelyst content pipeline foundation (Iterations D0-D2 — Milestone "Duelyst Content Ingestion")
**Decision:** Implement the first three stages of the content ingestion pipeline per `shardstorm_td_duelyst_content_ingestion_milestone.md`: D0 (configurable source path + validator), D1 (raw scanner that walks the Duelyst source tree), D2 (categorizer + manual override file). Pipeline is dev-time only — settings, catalogs, and reports live under `user://duelyst_content/`, *not* in `res://` (which is read-only in exported builds). Existing gameplay is untouched.
**Why D0-D2 as one bundle:** The ingestion milestone doc explicitly suggests D0+D1 as the starter bundle (line 1390), and D2 is the natural minimum to make D1's output *useful* (raw paths alone aren't queryable; categories are). D3 (Godot import layer) and D4 (content browser MVP) follow as their own iteration once we know what categories actually shake out of real scans — turns out we have 6055 files split across ~12 categories, which informs how D4's tabs/filters should be designed.
**Why not start by enabling more units in normal runs:** Per the milestone doc §1 and §15, the goal is *not* "add 400 units now." It's "make 400 units indexed and previewable, with 60-80 promoted to playable through a controlled pipeline." Skipping D0-D2 to hand-add units would defeat the milestone's main purpose.
**Why `user://duelyst_content/` not `res://data/duelyst/`:** The catalogs change every time the dev's local Duelyst clone updates. Storing them in `res://` would commit machine-specific data to git on every scan. `user://` keeps them dev-local; once a snapshot is canon, the dev can manually copy it into `res://data/duelyst/` and commit.
**Why RefCounted + `_init()` for DuelystContentSettings (not Node + static singleton):** Initially used a Node held in a static var. Godot leaked it at exit (`ObjectDB instances leaked at exit`). Switched to RefCounted with auto-load in `_init()` so each caller gets a fresh instance that auto-frees when the holder drops it. Cleaner lifecycle, no leak.
**Why GDScript `static func` was abandoned:** Tried `static func load_or_default()` on the settings script and Godot 4.6 reported `"Nonexistent function 'load_or_default' in base 'GDScript'"` despite the method clearly being defined. Static-method dispatch on `preload()`'d scripts is finicky in 4.6 (probably related to script-resource initialization order). Replaced with plain `SETTINGS_SCRIPT.new()` + `_init()` self-load.
**Pipeline output structure** (under `user://duelyst_content/`):
- `settings.json` — D0 config (source_root, output_root, last_scan_at, etc.)
- `catalog_raw.json` — D1 output: every file with id, rel_path, abs_path, top_dir, section_hint, extension, size_bytes, readiness_level=0
- `report_raw.json` — D1 counts: by_extension, by_section, by_top_dir, total_files, total_bytes
- `catalog_categorized.json` — D2 output: same entries with category + faction + readiness_level=1
- `report_categorized.json` — D2 counts: by_category, by_faction, unit_atlases_paired
- `manual_overrides.json` — user-edited overrides (per-id), stub created on first run with format docs in `_note` / `_example`
**Real-data smoke test** (`--content-scan` CLI flag): scanned 6055 files in 1.7s, categorized in 281ms. Breakdown:
- `unit_sprite` 820, `unit_animation_data` 696 (atlas pairs)
- `fx_sprite` 326, `fx_animation_data` 272
- `sfx` 712, `music` 22
- `ui_image` 1325, `icon` 1233
- `map_background` 78, `map_tile` 66
- `font` 30
- `unknown` 475 (~8%)
- Faction inference: lyonar 373, songhai 398, vetruvian 374, abyssian 415, magmar 370, vanar 403, neutral 804
**Impact:**
- New `scripts/content/` directory + 4 scripts: `duelyst_content_settings.gd` (D0), `duelyst_raw_scanner.gd` (D1), `duelyst_categorizer.gd` (D2), `duelyst_content_hub.gd` (UI driver).
- New `scenes/duelyst_content_hub.tscn` — dev tool with two PanelContainer sections: D0 source path + Validate/Save, D1+D2 action buttons + result/report panel. Reached from main menu via new "Duelyst Content (D0-D2)" button.
- `scripts/main_menu.gd`: new `duelyst_content_btn` + handler. New `_run_content_pipeline_smoke_test()` triggered by `--content-scan` CLI flag (mirrors `--test-generator` pattern).
- `scenes/main_menu.tscn`: new `DuelystContentButton` in main button column.
- Output written exclusively to `user://duelyst_content/` (see structure above). No `res://` writes.
**Test:** See "Manual Test Checklist - Iter D0-D2" below.

---

### Manual Test Checklist - Iter D0-D2 (Content pipeline foundation)

- [ ] Main menu shows a new "Duelyst Content (D0-D2)" button below "Unit Mastery".
- [ ] Click it → Duelyst Content hub opens. Settings section shows the default source path (`E:/CODE/Duelyst_TD/duelyst-main/duelyst-main/app/resources`).
- [ ] Click Validate → green message confirms the folder + lists detected subdirs (units, fx, sfx, ui).
- [ ] Set source path to a bogus folder → Validate → red message with specific reason.
- [ ] Restore real path → click "Run D1 — Scan source" → status flips to "Scanning…" → completes within ~2 seconds → shows total file count (~6000) + by-section + by-extension breakdown.
- [ ] Click "Run D2 — Categorize" → completes in <1 second → shows by-category + by-faction counts.
- [ ] Open `%APPDATA%\Godot\app_userdata\Duelyst_TD\duelyst_content\` → confirm 6 files: `settings.json`, `catalog_raw.json`, `report_raw.json`, `catalog_categorized.json`, `report_categorized.json`, `manual_overrides.json`.
- [ ] Edit `manual_overrides.json` to add one override (e.g. `{"units_boss_andromeda_png": {"category": "unit_sprite", "faction": "neutral"}}`) → re-run D2 → report says override_count = 1.
- [ ] Re-run D1 → no duplicate explosion in catalog (entry count stays ~6055).
- [ ] Back to main menu → start a normal run → confirm existing gameplay unaffected.
- [ ] Headless smoke test passes: `godot.exe --headless --path . res://scenes/main_menu.tscn --content-scan` prints `D1 scan PASS: 6055 files in N ms` then `D2 categorize PASS: 6055 entries in N ms` with the same by-category breakdown.

---

## Next iteration candidates (C-track + D-track now interleaved)

**D-track — content pipeline** (from ingestion addendum §19 "Best next sequence"):
- **D3 Godot import/reference layer** — copy categorized assets into `res://assets/duelyst/<category>/`, idempotent re-run.
- **D4 Content browser MVP** — in-game scene with Units/VFX/SFX/UI/Maps/Unknown tabs; preview images, play audio, filter by readiness level.
- **D5 Unit animation preview** — idle/attack/run/death playback inside the browser.
- **D6 Unit catalog builder** — `DuelystUnitCatalogEntry` with name/faction/animation links.
- **D7 Generated unit shells** — at least 50 conservative `GeneratedUnitShell`s, debug-only.
- **D8 Dual-use enemy conversion** — enemies from Duelyst units, 30+ in debug.
- **D9-D10** SFX + VFX cataloging and event routing.
- **D11-D13** UI skin + map theme ingestion + faction foundation packs.
- **D14-D17** Pack enablement UI, validator, collection browser, reuse report.

**C-track — Starbase co-op** (from co-op addendum §13):
- **C1 CoopMapDef schema** — data format for one shared map with multiple routes. Hand-authored 2-player Starbase map loads.
- **C2 Multi-route enemy spawning** — wave spawner routes enemies per slot; leaks damage the correct Gate Shield then shared Core.
- **C3 Route ownership + placement zones** — players can only build in their own zone + shared ring.
- **C4 Synced co-op phases** — ready checks; wave starts when all ready.
- **C5-C8** Camera, Gate Shield UI, Aid Token, Breach Tunnel.

**A-track — growth bake-off** (paused until C8 + D7 land):
- A2 Unit Instance Identity → A8 Growth Bake-Off Report.

Suggested next pick: **D3 + D4** (content browser unlocks visual inspection of the 6055 cataloged assets — essential before D6+ generates anything).
