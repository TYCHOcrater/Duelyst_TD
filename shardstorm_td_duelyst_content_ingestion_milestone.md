# Shardstorm TD - Duelyst Content Ingestion Milestone

Version: 1.0
Purpose: Give Claude a concrete, testable roadmap for bringing Duelyst content into the Godot project at scale without turning the game into an unbalanced asset dump.

This document assumes the project already has:

- Core tower defense loop.
- Draft shop.
- Combat.
- Traits.
- Flaws.
- Pacts.
- Relics.
- Evolution.
- Mastery.
- Daily seed.
- Failure coach.
- Several content packs.
- Some UI and polish work.

The next milestone is not simply "add more units." The next milestone is:

> Build a reusable Duelyst content pipeline so most or all Duelyst assets can exist inside the project, be previewed, classified, searched, and gradually promoted into real gameplay.

The goal is to make the project feel like it already contains a huge world, while still allowing playable content to be balanced in controlled waves.

---

# 1. Main recommendation

Do this next:

```text
Duelyst Content Ingestion Milestone
```

But split content into two concepts:

```text
Imported content
  Assets are inside the project, cataloged, previewable, and valid.

Playable content
  Assets are mapped to gameplay, balanced, and allowed in real runs.
```

Claude should not try to balance 600+ units at once. Claude should first make them visible and usable by the tools.

Recommended target:

```text
Milestone target A:
50%+ of Duelyst unit/FX/SFX/UI/map assets are indexed and previewable.

Milestone target B:
60-100 Duelyst units are gameplay-enabled as defenders/enemies/summons.

Milestone target C:
A content promotion pipeline exists so new Duelyst units can be enabled in batches of 10-25.
```

This gives you the feeling that the project has all the Duelyst content, but does not force all of it into balance at once.

---

# 2. Core principle: Content readiness levels

Every Duelyst asset or unit should have a readiness level.

```text
Level 0 - Discovered
Asset exists in local Duelyst source folder and has an id/path.

Level 1 - Imported
Asset is inside Godot or referenced by a stable import path.

Level 2 - Previewable
Asset can be viewed/heard in an in-game debug browser.

Level 3 - Classified
Asset has faction, role, category, animation set, and tags.

Level 4 - Gameplay shell
Asset has a simple generated UnitDef, EnemyDef, VfxDef, SfxDef, HudDef, or MapThemeDef.

Level 5 - Playtest enabled
Asset can appear in debug runs or controlled challenge runs.

Level 6 - Run enabled
Asset can appear in normal survival runs.

Level 7 - Balanced/shipped
Asset has telemetry, failure-coach support, counterplay notes, and balance review.
```

This prevents a common failure mode:

```text
"We added 400 units, now the game is impossible to balance."
```

Instead, the pipeline becomes:

```text
Discover -> Import -> Preview -> Classify -> Generate shell -> Playtest -> Enable -> Balance
```

---

# 3. Required folder structure

Claude should adapt names to the existing Godot project, but the project should end up with a clear structure similar to this:

```text
res://external/duelyst_raw/
  original downloaded Duelyst asset folders, or symlinks/path config if used

res://assets/duelyst/
  units/
  enemies/
  fx/
  sfx/
  music/
  ui/
  maps/
  icons/
  tiles/
  portraits/

res://data/duelyst/
  duelyst_asset_catalog.json
  duelyst_unit_catalog.json
  duelyst_sfx_catalog.json
  duelyst_vfx_catalog.json
  duelyst_ui_catalog.json
  duelyst_map_catalog.json
  duelyst_import_report.json

res://data/units/generated/
  generated unit shells, not all enabled by default

res://data/enemies/generated/
  generated enemy shells, not all enabled by default

res://data/content_packs/duelyst/
  faction packs
  enemy packs
  boss packs
  ui packs
  arena packs

res://tools/content/
  import scripts
  validators
  catalog builders
  preview scene scripts

res://scenes/debug/content_browser/
  DuelystContentBrowser.tscn
  UnitPreviewPanel.tscn
  SfxPreviewPanel.tscn
  VfxPreviewPanel.tscn
  HudPreviewPanel.tscn
  MapThemePreviewPanel.tscn
```

Important rule:

```text
Do not mix raw assets, imported assets, generated data, and manually balanced data in the same folder.
```

---

# 4. Content types to ingest

The milestone should include these categories.

## 4.1 Units

Use Duelyst units as:

```text
Defenders
Enemy skins
Summons
Boss skins
Arena sendables
Evolution forms
Shop cards
Mastery collection entries
```

A single Duelyst unit can support multiple game roles.

Example:

```text
Silverguard Knight
  Defender role: blocker / armor aura
  Enemy role: armored knight
  Arena sendable role: medium frontline unit
  Evolution role: stronger Lyonar guard form
```

Do not assume every Duelyst unit is only a player tower.

## 4.2 Enemies

Many Duelyst units should become enemy units too.

Enemy conversion should use:

```text
faction
visual size
animation set
weapon style
name keywords
manual tags
balance tier
```

Enemy families can be made from Duelyst factions:

```text
Lyonar enemy set:
armored, shields, formation, healers

Songhai enemy set:
fast, blink, dodge, burst

Vetruvian enemy set:
constructs, obelisks, shields, sand swarms

Abyssian enemy set:
swarms, sacrifice, ghosts, death triggers

Magmar enemy set:
large bodies, eggs, regen, impact

Vanar enemy set:
slow, ice, ranged, crystals

Neutral enemy set:
beasts, golems, mercenaries, generic wave filler
```

## 4.3 HUD and UI

Reuse Duelyst UI as the basis for:

```text
shop cards
unit inspect panel
wave preview panel
relic panel
pact selection
mastery screen
collection browser
arena round screen
core health frame
faction frames
buttons
icons
status icons
currency indicators
```

The goal is not to copy Duelyst's UI 1:1. The goal is to build a Shardstorm TD UI skin from Duelyst UI pieces.

## 4.4 VFX

Ingest all useful Duelyst FX into categories:

```text
projectile
impact
slash
explosion
aura
buff
debuff
shield
heal
summon
death
teleport
frost
fire
void
sand
holy
poison
lightning
warning
core damage
```

Then map VFX by gameplay event:

```text
unit_attack_started
projectile_spawned
enemy_hit
enemy_death
status_applied
status_expired
unit_evolved
pact_triggered
relic_triggered
boss_spawned
leak_occurred
core_damaged
wave_started
wave_completed
```

## 4.5 SFX

Ingest Duelyst sounds into categories:

```text
ui_click
ui_confirm
ui_cancel
shop_reroll
unit_place
unit_sell
unit_merge
unit_evolve
attack_light
attack_heavy
attack_magic
impact_physical
impact_magic
impact_shield
impact_fire
impact_ice
impact_void
heal
buff
debuff
death_small
death_large
leak
core_damage
boss_warning
victory
defeat
round_start
round_end
arena_send
```

Important: SFX should use throttling and priority. Do not play every hit sound in a huge wave.

## 4.6 Music and ambience

Use Duelyst music/ambience if available and appropriate.

Categories:

```text
main_menu
planning_phase
combat_phase
boss_wave
victory
defeat
arena_match
faction_theme_lyonar
faction_theme_songhai
faction_theme_vetruvian
faction_theme_abyssian
faction_theme_magmar
faction_theme_vanar
```

## 4.7 Maps, boards, tiles, arenas

Reuse Duelyst map/board-style assets as:

```text
survival map themes
co-op Starbase themes
arena mode maps
backgrounds
path tiles
buildable tiles
blocked props
core/base visuals
spawn portals
round start backgrounds
```

Map content should be treated as theme data, not just images.

A MapThemeDef should describe:

```text
visual theme
path visuals
buildable visuals
blocked visuals
core visuals
spawn visuals
ambient SFX
combat music
special tile visuals
recommended enemy family
recommended faction packs
```

---

# 5. What "use 50% of Duelyst" should mean

Do not define this only by number of playable units.

Use this scoring model:

```text
Duelyst reuse score =
  unit assets indexed and previewable
+ unit assets gameplay-enabled
+ SFX indexed and used
+ VFX indexed and used
+ HUD/UI pieces used
+ map/board assets used
+ icons/portraits used
+ faction identity reused
```

A healthy first milestone could be:

```text
Unit sprites:
50%+ indexed and previewable
15% gameplay-enabled

SFX:
50%+ indexed
25% used in events

VFX:
50%+ indexed
25% mapped to gameplay events

HUD/UI:
50%+ relevant pieces cataloged
core run UI partially skinned

Map assets:
all obvious map/board/arena assets cataloged
1-3 map themes implemented

Icons/portraits:
50%+ cataloged
used in shop, inspect, collection, mastery
```

This is much more realistic than:

```text
Add all units to the shop now.
```

---

# 6. Data schemas

## 6.1 DuelystAssetEntry

```json
{
  "id": "duelyst_asset_001",
  "source_path": "res://external/duelyst_raw/app/resources/...",
  "import_path": "res://assets/duelyst/units/...",
  "asset_type": "unit_sprite",
  "duelyst_name": "Silverguard Knight",
  "faction": "lyonar",
  "readiness_level": 2,
  "tags": ["unit", "lyonar", "humanoid", "melee"],
  "notes": "Auto-discovered. Needs manual gameplay mapping."
}
```

## 6.2 DuelystUnitCatalogEntry

```json
{
  "id": "silverguard_knight",
  "duelyst_name": "Silverguard Knight",
  "faction": "lyonar",
  "source_asset_ids": ["duelyst_asset_001"],
  "animation_set": {
    "idle": "res://assets/duelyst/units/silverguard_knight/idle.tres",
    "attack": "res://assets/duelyst/units/silverguard_knight/attack.tres",
    "run": "res://assets/duelyst/units/silverguard_knight/run.tres",
    "death": "res://assets/duelyst/units/silverguard_knight/death.tres"
  },
  "visual_tags": ["humanoid", "armor", "shield", "melee"],
  "suggested_gameplay_tags": ["blocker", "armor", "frontline", "physical"],
  "allowed_roles": ["defender", "enemy", "arena_sendable"],
  "readiness_level": 3,
  "enabled_in_normal_runs": false,
  "enabled_in_debug": true
}
```

## 6.3 GeneratedUnitShell

Generated shells should be simple and conservative.

```json
{
  "id": "silverguard_knight_shell",
  "display_name": "Silverguard Knight",
  "source_duelyst_unit_id": "silverguard_knight",
  "faction": "lyonar",
  "role": "blocker",
  "rarity": "common",
  "cost": 8,
  "range": 1,
  "damage": 6,
  "attack_cooldown": 1.1,
  "damage_type": "physical",
  "tags": ["lyonar", "blocker", "armor", "frontline"],
  "ability_package": "basic_melee_blocker",
  "balance_state": "generated_unbalanced",
  "enabled_in_normal_runs": false,
  "enabled_in_debug": true
}
```

## 6.4 SfxDef

```json
{
  "id": "lyonar_shield_impact_01",
  "source_path": "res://assets/duelyst/sfx/...",
  "category": "impact_shield",
  "priority": 80,
  "cooldown_ms": 120,
  "max_simultaneous": 2,
  "volume_db": -4,
  "tags": ["lyonar", "shield", "impact"],
  "readiness_level": 3
}
```

## 6.5 VfxDef

```json
{
  "id": "holy_impact_small_01",
  "source_path": "res://assets/duelyst/fx/...",
  "category": "impact",
  "duration_sec": 0.45,
  "priority": 60,
  "scale": 1.0,
  "tags": ["lyonar", "holy", "impact"],
  "readiness_level": 3
}
```

## 6.6 ContentPackDef

```json
{
  "id": "duelyst_lyonar_foundation_pack",
  "display_name": "Lyonar Foundation Pack",
  "type": "faction_pack",
  "units": [
    "silverguard_knight_shell",
    "windblade_adept_shell",
    "ironcliffe_guardian_shell"
  ],
  "enemies": [
    "lyonar_shieldguard_enemy",
    "lyonar_banner_knight_enemy"
  ],
  "vfx": ["holy_impact_small_01", "shield_flash_01"],
  "sfx": ["lyonar_shield_impact_01"],
  "ui_skin_parts": ["lyonar_card_frame", "gold_button"],
  "map_themes": ["lyonar_citadel_theme"],
  "enabled_in_debug": true,
  "enabled_in_normal_runs": false,
  "balance_state": "needs_playtest"
}
```

---

# 7. Milestone stages for Claude

This milestone should be implemented as a sequence of small, testable iterations.

## D0 - Asset source path setup

Goal:
Tell the project where the Duelyst source assets live.

Build:

```text
DuelystContentSettings
source_root_path
import_output_path
catalog_output_path
```

Acceptance criteria:

```text
There is a UI or config file where the local Duelyst source path can be set.
The game can detect whether the source path exists.
The game shows a readable error if the path is missing.
Existing gameplay is not affected.
```

Manual test:

```text
1. Launch Godot.
2. Open content/debug settings.
3. Set Duelyst source path.
4. Press Validate Source.
5. Confirm success or clear error message.
```

Claude prompt:

```text
Implement D0: Asset source path setup.
Add a data/config object that stores the local Duelyst source root and output paths. Add a small debug UI to validate whether the source root exists. Do not import assets yet. Existing gameplay must remain unchanged.
```

---

## D1 - Raw asset scanner

Goal:
Scan the local Duelyst folder and create a raw catalog.

Build:

```text
DuelystRawScanner
DuelystAssetEntry schema
raw file count report
extension/category grouping
```

Acceptance criteria:

```text
Scanner walks the Duelyst source folder.
Scanner records image/audio/json/xml/plist/atlas-like files.
Scanner writes duelyst_asset_catalog_raw.json.
Report shows counts by extension and guessed category.
Invalid/unreadable files are reported, not fatal.
```

Manual test:

```text
1. Press Scan Duelyst Assets.
2. Wait for report.
3. Open generated catalog.
4. Confirm assets are listed with paths and categories.
```

Notes:

```text
This stage should not copy or import assets yet.
This is inventory only.
```

---

## D2 - Asset categorizer

Goal:
Classify raw assets into useful game categories.

Categories:

```text
unit_sprite
unit_animation_data
fx_sprite
fx_animation_data
sfx
music
ui_image
icon
portrait
map_tile
map_background
unknown
```

Acceptance criteria:

```text
Each scanned asset receives a guessed category.
Unknown assets remain in catalog instead of being discarded.
Report shows category counts.
A manual override file can fix bad guesses.
```

Manual test:

```text
1. Run categorizer.
2. Inspect category counts.
3. Add one manual override.
4. Re-run categorizer and confirm override persists.
```

---

## D3 - Godot import/reference layer

Goal:
Make categorized assets accessible from the Godot project.

Two acceptable approaches:

```text
Option A: Copy selected assets into res://assets/duelyst/.
Option B: Keep source assets in a stable external folder and generate references/import metadata.
```

Recommended for simplicity:

```text
Copy imported assets into res://assets/duelyst/.
```

Acceptance criteria:

```text
Importer can copy selected categories into res://assets/duelyst/.
Importer avoids duplicate copies.
Importer writes stable import paths.
Importer can be safely re-run.
Importer creates an import report.
```

Manual test:

```text
1. Import only UI and SFX categories first.
2. Confirm files appear under res://assets/duelyst/.
3. Re-run import.
4. Confirm no duplicate explosion occurs.
```

Important:

```text
Claude should not import everything blindly before scanner reports are sane.
```

---

## D4 - Content browser MVP

Goal:
Create an in-game/debug content browser.

Browser tabs:

```text
Units
VFX
SFX
UI
Maps
Unknown
```

Acceptance criteria:

```text
Browser loads the catalog.
User can filter by category.
User can search by filename/id/name.
Image assets show previews.
Audio assets can be played.
Unknown assets can be inspected.
Readiness level is visible.
```

Manual test:

```text
1. Open Duelyst Content Browser.
2. Search for a known unit or asset name.
3. Preview an image.
4. Play an SFX.
5. Filter by unknown assets.
```

This is a major milestone. It means the assets are no longer invisible.

---

## D5 - Unit animation preview

Goal:
Preview Duelyst unit animations in Godot.

Build:

```text
UnitPreviewPanel
animation selection dropdown
idle/attack/run/death preview
speed slider
background toggle
scale slider
```

Acceptance criteria:

```text
At least 20 unit assets can be previewed.
Preview supports idle and attack if data exists.
Missing animations produce clear warnings.
Animation playback does not crash the editor/game.
```

Manual test:

```text
1. Open Unit tab.
2. Select 5 units from different factions.
3. Play idle/attack/death where available.
4. Confirm missing animations are handled.
```

If the project already uses the Godot SpriteFrames package, Claude should integrate that path rather than re-parsing everything from scratch.

---

## D6 - Unit catalog builder

Goal:
Convert raw unit assets into a Duelyst unit catalog.

Build:

```text
DuelystUnitCatalogEntry
name normalization
faction guesser
animation set linker
visual tag guesser
manual override file
```

Acceptance criteria:

```text
Catalog contains unit-like entries, not just raw files.
Units have ids, display names, faction guesses, and asset references.
Manual overrides can correct name/faction/tags.
Report shows total unit entries by faction and readiness level.
```

Manual test:

```text
1. Build unit catalog.
2. Open browser by faction.
3. Confirm units appear grouped by faction.
4. Correct one unit manually.
5. Rebuild and confirm correction persists.
```

---

## D7 - Generated unit shells

Goal:
Generate conservative gameplay shells for many Duelyst units without enabling them in normal runs.

Build:

```text
GeneratedUnitShell
role templates
stat templates
ability package templates
balance_state field
enabled_in_debug field
enabled_in_normal_runs field
```

Role templates:

```text
basic_ranged
basic_melee
blocker
splash_mage
support_aura
economy_unit
summoner
control_unit
assassin
artillery
boss_body
```

Acceptance criteria:

```text
At least 50 unit shells are generated.
Generated units are disabled in normal runs by default.
Generated units can be spawned/placed in debug sandbox.
Every generated shell has a balance_state.
Every generated shell links back to source Duelyst unit id.
```

Manual test:

```text
1. Generate unit shells.
2. Open debug unit sandbox.
3. Spawn/place 10 generated units.
4. Confirm visuals and basic attacks work.
5. Confirm they do not appear in normal survival unless enabled.
```

---

## D8 - Defender and enemy dual-use conversion

Goal:
Allow Duelyst units to become either player defenders or enemy wave units.

Build:

```text
UnitToEnemyConverter
EnemyDef shells
faction enemy families
role-based enemy stats
```

Acceptance criteria:

```text
At least 30 Duelyst units can be spawned as enemies in debug.
Enemy shells use movement, health, defenses, and attack/leak data.
Enemy visuals come from Duelyst unit assets.
Enemies are grouped into family packs.
Normal waves are not flooded yet.
```

Manual test:

```text
1. Open enemy sandbox.
2. Spawn a Lyonar armored enemy.
3. Spawn a Songhai fast enemy.
4. Spawn an Abyssian swarm enemy.
5. Confirm they move, take damage, die, and log correctly.
```

---

## D9 - SFX catalog and event mapping

Goal:
Make Duelyst audio reusable through an event-driven SFX system.

Build:

```text
SfxDef catalog
SfxRouter
priority/cooldown/max_simultaneous handling
category mapping UI
```

Events to support first:

```text
ui_click
shop_reroll
unit_place
unit_sell
unit_merge
unit_evolve
wave_start
enemy_death
leak
core_damage
boss_spawn
victory
defeat
```

Acceptance criteria:

```text
At least 50 SFX assets are cataloged.
At least 15 gameplay/UI events use mapped SFX.
SFX spam is throttled.
Debug panel can test each mapped event.
```

Manual test:

```text
1. Open SFX tab.
2. Play sounds manually.
3. Trigger each mapped event in a test scene.
4. Spawn a big wave and confirm audio does not become unbearable.
```

---

## D10 - VFX catalog and event mapping

Goal:
Make Duelyst FX reusable through a VFX router.

Build:

```text
VfxDef catalog
VfxRouter
attachment rules
scale rules
priority rules
fallback VFX
```

Events to support first:

```text
attack_projectile
hit_impact
enemy_death
slow_applied
burn_applied
poison_applied
shield_hit
heal
unit_evolve
boss_warning
leak
core_damage
```

Acceptance criteria:

```text
At least 50 VFX assets are cataloged.
At least 12 combat events use mapped VFX.
VFX can be previewed in browser.
VFX priority rules prevent visual soup.
```

Manual test:

```text
1. Preview VFX in browser.
2. Run a combat test with several VFX categories.
3. Confirm the path/enemies remain readable.
4. Confirm missing VFX uses fallback instead of crashing.
```

---

## D11 - HUD and UI skin ingestion

Goal:
Start using Duelyst UI content for the game's actual UI.

Build:

```text
DuelystUiCatalog
ShardstormTheme resource
shop card skin
unit inspect skin
wave preview skin
relic/pact card skin
button skin
currency icon mapping
```

Acceptance criteria:

```text
UI catalog indexes relevant Duelyst UI images/icons.
Shop cards use Duelyst-inspired frames.
Unit inspect panel uses cataloged frames/icons.
Relic/pact choice cards use skinned panels.
Core health and currency indicators use imported UI pieces.
UI remains readable at target resolution.
```

Manual test:

```text
1. Start a run.
2. Open shop.
3. Inspect unit.
4. Choose pact/relic.
5. Confirm visual style is more Duelyst-like but still clear.
```

Important:

```text
UI skin should never reduce clarity.
If Duelyst UI art conflicts with readability, use it as ornament/frame, not as core text/background.
```

---

## D12 - Map and arena asset ingestion

Goal:
Catalog and use Duelyst map/board/arena-like assets.

Build:

```text
DuelystMapCatalog
MapThemeDef
ArenaThemeDef
path/build/core/spawn visual mapping
background preview
```

Acceptance criteria:

```text
Map/board/arena assets are cataloged.
At least 1 survival map theme uses Duelyst visuals.
At least 1 arena mockup background/theme exists.
Theme can be selected from debug/new-run UI.
Gameplay readability remains intact.
```

Manual test:

```text
1. Open map theme browser.
2. Preview available map assets.
3. Start a survival run with Duelyst map theme.
4. Confirm path/build/core/spawn remain readable.
```

---

## D13 - Faction foundation packs

Goal:
Create one content pack per Duelyst faction plus neutral.

Packs:

```text
Lyonar Foundation Pack
Songhai Foundation Pack
Vetruvian Foundation Pack
Abyssian Foundation Pack
Magmar Foundation Pack
Vanar Foundation Pack
Neutral Foundation Pack
```

Each pack should include:

```text
8-12 defenders
8-12 enemies
2-4 VFX mappings
4-8 SFX mappings
1 relic
1 trait
1 flaw
1 pact hook or wave modifier
1 faction UI/card frame style
1 challenge seed
```

Acceptance criteria:

```text
Each faction pack exists as data.
Each pack can be enabled in debug runs.
Each pack has units and enemies.
Each pack has at least one unique identity mechanic.
Packs are disabled from normal runs until reviewed.
```

Manual test:

```text
1. Enable only Lyonar Foundation Pack.
2. Start debug run.
3. Confirm only Lyonar/neutral relevant content appears.
4. Repeat for each faction pack.
5. Confirm no pack crashes the run.
```

---

## D14 - Content pack enablement UI

Goal:
Let you test content safely.

Build:

```text
Content Pack Manager screen
pack enable/disable toggles
normal-run allowed flag
debug-run allowed flag
pack dependency display
pack validation display
```

Acceptance criteria:

```text
You can enable/disable content packs from debug UI.
Normal runs only use approved packs.
Debug runs can use experimental packs.
Validation errors are visible before starting a run.
```

Manual test:

```text
1. Enable one faction pack.
2. Start run.
3. Confirm shop/waves use that pack.
4. Disable it.
5. Confirm it no longer appears.
```

---

## D15 - Content validation pass

Goal:
Prevent bad generated content from breaking the project.

Validate:

```text
asset paths exist
sprite/animation exists or fallback exists
SFX files load
VFX files load
unit has role/cost/tags
unit has source Duelyst id
enemy has health/speed/reward/wave tags
content pack references valid ids
normal-run content has balance_state not generated_unbalanced
readiness levels are consistent
```

Acceptance criteria:

```text
Validator can run from debug UI.
Validator can run from command line if possible.
Validation report is written to file.
Broken content is disabled automatically or flagged clearly.
```

Manual test:

```text
1. Intentionally break one asset path.
2. Run validator.
3. Confirm clear error.
4. Fix path.
5. Confirm validation passes.
```

---

## D16 - Duelyst collection browser

Goal:
Make the imported content visible to the player eventually, not just developers.

Build:

```text
Collection screen
faction filters
unit cards
readiness/locked/seen state
mastery links
source identity display
```

Acceptance criteria:

```text
Player-facing collection can show enabled units.
Debug mode can show all indexed Duelyst units.
Units display art/name/faction/role.
Mastery screen can link to unit catalog entry.
```

Manual test:

```text
1. Open collection.
2. Filter by faction.
3. Select a unit.
4. View role, tags, and mastery info.
```

---

## D17 - 50% reuse report

Goal:
Make progress measurable.

Build a report with:

```text
total assets scanned
assets imported
assets previewable
assets classified
unit entries discovered
unit entries gameplay shell generated
unit entries enabled in debug
unit entries enabled in normal runs
SFX cataloged
SFX mapped to events
VFX cataloged
VFX mapped to events
UI assets cataloged
UI assets used in current UI
map assets cataloged
map themes implemented
```

Acceptance criteria:

```text
Report is generated from actual project data.
Report shows percentages.
Report distinguishes imported vs playable.
Report can be saved to docs/reports/duelyst_content_reuse_report.md.
```

Manual test:

```text
1. Run content reuse report.
2. Open generated markdown.
3. Confirm it shows exact counts and percentages.
4. Use it to decide next pack priority.
```

---

# 8. Recommended immediate Claude task

Start with D0-D4 before adding any more units manually.

Best next task:

```text
Implement D0 and D1 together if small enough:
Duelyst asset source setup + raw scanner.
```

Claude prompt:

```text
Read:
- docs/co_op_roguelike_td_design_doc.md
- docs/shardstorm_td_content_bible.md
- docs/shardstorm_td_research_engagement_addendum.md
- docs/shardstorm_td_next_roadmap_addendum.md
- docs/shardstorm_td_coop_multiplayer_arena_addendum.md
- docs/shardstorm_td_duelyst_content_ingestion_milestone.md
- docs/decisions.md

Implement milestone D0-D1: Duelyst source setup and raw asset scanner.

Goal:
Create the foundation for importing and cataloging Duelyst assets at scale.

Build:
- DuelystContentSettings with source_root_path, import_output_path, and catalog_output_path.
- Debug UI to validate the local Duelyst source folder.
- DuelystRawScanner that walks the source folder and records raw assets.
- duelyst_asset_catalog_raw.json output.
- duelyst_import_report.json or markdown report with counts by extension and guessed broad category.

Hard constraints:
- Do not copy/import assets yet.
- Do not generate gameplay units yet.
- Do not alter existing normal gameplay.
- Scanner must be safe to run multiple times.
- Missing or invalid source path must show a clear error.
- Keep paths configurable, not hardcoded to one developer machine.
- Update docs/decisions.md.

Acceptance criteria:
- The project opens and existing runs still work.
- Debug UI can validate the Duelyst source folder.
- Scanner produces a raw catalog file.
- Report shows total files and counts by extension/category.
- Unknown files are preserved in the catalog, not ignored.
- Errors are readable.

Manual test:
1. Set the Duelyst source path to an invalid folder and confirm a readable error.
2. Set the source path to the real local Duelyst folder and confirm validation passes.
3. Run the scanner.
4. Open the generated raw catalog and report.
5. Re-run the scanner and confirm it overwrites/updates cleanly without duplicates.
6. Start a normal run and confirm existing gameplay still works.
```

---

# 9. Do not skip the browser

The content browser is not optional.

Without it, imported content becomes invisible and hard to debug.

The browser should eventually answer:

```text
What Duelyst assets do we have?
Which ones are units?
Which ones are VFX?
Which ones are SFX?
Which ones are already used?
Which ones are broken?
Which ones are enabled in debug only?
Which ones are enabled in normal runs?
What faction/role does this asset belong to?
What gameplay object uses this asset?
```

The browser is also the first step toward a player-facing collection screen.

---

# 10. How to convert many units safely

Do not hand-design every Duelyst unit first.

Use this sequence:

```text
1. Catalog unit assets.
2. Guess faction and visual tags.
3. Generate conservative gameplay shells.
4. Keep generated shells debug-only.
5. Test them in sandbox.
6. Promote small groups into faction packs.
7. Balance promoted units.
8. Enable promoted units in normal runs.
```

Generated units should be boring but functional.

Promoted units should become interesting through:

```text
traits
flaws
evolutions
relic interactions
faction mechanics
unique ability packages
```

---

# 11. Suggested faction identity mechanics

These should guide automated classification and later pack design.

## Lyonar

Feel:

```text
formation, armor, protection, banners, beams, righteous impact
```

Mechanics:

```text
armor
shields
adjacency buffs
frontline blockers
healing
revenge when core is damaged
```

Unit roles:

```text
blocker
support aura
single-target defender
anti-swarm shield wall
```

Enemy roles:

```text
armored squads
shield bearers
healers
formation elites
```

## Songhai

Feel:

```text
speed, timing, burst, dodges, blades, wind, combo turns
```

Mechanics:

```text
fast attacks
crit windows
teleport/blink
chain hits
dodge
burst after delay
```

Unit roles:

```text
assassin
single-target burst
chain attacker
fast anti-boss unit
```

Enemy roles:

```text
fast runners
blinkers
assassins that skip blockers
combo elites
```

## Vetruvian

Feel:

```text
sand, constructs, obelisks, geometry, artifacts, ancient machines
```

Mechanics:

```text
obelisks
summon structures
sand shields
area control
construct scaling
```

Unit roles:

```text
artillery
summoner
zone controller
support construct
```

Enemy roles:

```text
shielded constructs
sand swarms
obelisk buffers
slow siege enemies
```

## Abyssian

Feel:

```text
swarm, sacrifice, shadow, souls, death economy, corruption
```

Mechanics:

```text
summons
death triggers
sacrifice
soul explosions
corruption tiles
life drain
```

Unit roles:

```text
summoner
sacrifice engine
swarm defender
death explosion unit
```

Enemy roles:

```text
swarms
ghosts
on-death enemies
corruptors
```

## Magmar

Feel:

```text
big bodies, eggs, mutation, regen, acid, primal impact
```

Mechanics:

```text
regen
eggs
growth over waves
armor break
cleave
mutation
```

Unit roles:

```text
scaling bruiser
splash melee
regen blocker
anti-armor unit
```

Enemy roles:

```text
regenerators
huge tanks
egg spawns
acid carriers
```

## Vanar

Feel:

```text
frost, control, positioning, crystals, ranged pressure, silence
```

Mechanics:

```text
slow
freeze
brittle
range control
walls
silence
```

Unit roles:

```text
control
slow tower
long-range attacker
anti-fast defender
```

Enemy roles:

```text
frost-resistant units
range disruptors
slow auras
crystal shields
```

## Neutral

Feel:

```text
mercenaries, beasts, golems, flexible filler, economy glue
```

Mechanics:

```text
generic roles
economy units
basic attackers
beasts
golems
bridging synergies
```

---

# 12. Content promotion rules

A generated unit can become normal-run content only if:

```text
It has a valid sprite/animation fallback.
It has a readable role.
It has a cost and stat profile.
It has at least one counter or weakness.
It has inspect text.
It is included in at least one content pack.
It has been tested in sandbox.
It has run logger support.
It has failure coach tags.
It does not crash VFX/SFX fallback paths.
```

A generated enemy can become normal-run content only if:

```text
It has clear threat tags.
It appears in wave preview correctly.
It has a counter profile.
It has a reward value.
It has readable visuals at wave scale.
It has death/leak behavior.
It is not visually confused with player units without enemy tint/outline.
```

---

# 13. Enemy/player visual distinction

Because many Duelyst units can be both defenders and enemies, the project needs strong visual rules.

Player units:

```text
normal faction colors
friendly base ring
shop/evolution frame
soft highlight on hover
```

Enemy units:

```text
enemy outline or tint
health bar style difference
direction arrow or path marker
threat icon for elites
red/hostile base ring
```

Summons:

```text
smaller ring
short duration indicator if temporary
owner color
```

Arena sendables:

```text
owner-colored accent
send cost icon
lane marker
```

This is mandatory if the same Duelyst visuals are reused across roles.

---

# 14. Performance constraints

Content ingestion can hurt performance if done carelessly.

Claude should track:

```text
number of imported textures
texture memory
number of loaded SpriteFrames
number of AudioStreams loaded at once
combat VFX spawned per second
SFX played per second
browser thumbnail cost
```

Rules:

```text
Do not preload every Duelyst asset into memory on game start.
Load catalogs first.
Lazy-load previews.
Lazy-load content pack assets.
Unload unused preview assets when browser closes.
Use fallbacks if an asset fails to load.
```

The content browser should be allowed to load more assets than normal gameplay, but normal gameplay should only load enabled packs.

---

# 15. Normal run content budget after this milestone

After the ingestion milestone, do not immediately enable everything.

Recommended first normal-run content budget:

```text
Player defenders:
60-80 enabled units

Enemies:
40-60 enabled enemies

Relics:
30-50

Traits:
30-50

Flaws:
20-30

Pacts:
15-25

Map themes:
3-6

SFX events:
20-30 mapped events

VFX events:
20-30 mapped events
```

This is already a lot of content.

Everything else can exist as:

```text
indexed
previewable
debug-only
generated-unbalanced
pack-disabled
```

---

# 16. What this milestone unlocks later

Once this pipeline exists, future features become much easier.

## Co-op

Co-op can use the catalog to create:

```text
player-specific faction packs
shared team skins
ally aid unit visuals
breach enemies from unused Duelyst units
route-specific enemy families
```

## Arena mode

Arena mode can use the catalog to create:

```text
sendable units
round roster drafts
arena UI cards
lane warnings
Duelyst board/arena backgrounds
round victory/defeat SFX
```

## Procedural content

The map generator can use MapThemeDef assets instead of hardcoded visuals.

## Daily/weekly challenges

Challenges can enable specific content packs:

```text
Vanar-only week
Abyssian swarm week
Lyonar shield wall challenge
Magmar egg economy challenge
```

## Player collection

The content browser can evolve into:

```text
unit collection
mastery screen
faction codex
enemy bestiary
relic archive
```

---

# 17. Biggest risks

## Risk 1: Too much content too early

Solution:

```text
Use readiness levels and pack enablement.
```

## Risk 2: Bad naming/path guesses

Solution:

```text
Use manual override files and never destroy unknown assets.
```

## Risk 3: Visual soup

Solution:

```text
Use VFX priority, enemy outlines, event throttling, and readability tests.
```

## Risk 4: Audio spam

Solution:

```text
Use SFX cooldowns, priority, and max simultaneous limits.
```

## Risk 5: Huge load times

Solution:

```text
Catalog everything, but lazy-load assets by enabled pack.
```

## Risk 6: Claude adds unbalanced generated units to normal runs

Solution:

```text
generated_unbalanced content must be debug-only by default.
Normal-run content requires explicit promotion.
```

---

# 18. Definition of done for this milestone

This milestone is complete when:

```text
1. Duelyst source folder can be configured and validated.
2. Raw scanner creates a complete asset catalog.
3. Asset categorizer assigns useful categories.
4. Assets can be imported/referenced safely.
5. Content browser can preview units/images/SFX/VFX/UI/map assets.
6. Unit catalog groups unit assets by faction and tags.
7. At least 50 generated unit shells exist in debug.
8. At least 30 generated enemy shells exist in debug.
9. At least 50 SFX and 50 VFX are cataloged.
10. At least 15 SFX events and 12 VFX events are mapped.
11. At least 1 UI skin pass uses Duelyst UI pieces.
12. At least 1 map theme uses Duelyst map/board assets.
13. Faction foundation content packs exist.
14. Content pack manager can enable/disable packs.
15. Content validator catches broken references.
16. 50% reuse report exists and is generated from real data.
```

---

# 19. Best next sequence

Use this order:

```text
D0. Asset source path setup
D1. Raw asset scanner
D2. Asset categorizer
D3. Godot import/reference layer
D4. Content browser MVP
D5. Unit animation preview
D6. Unit catalog builder
D7. Generated unit shells
D8. Defender/enemy dual-use conversion
D9. SFX catalog and event mapping
D10. VFX catalog and event mapping
D11. HUD/UI skin ingestion
D12. Map/arena asset ingestion
D13. Faction foundation packs
D14. Content pack enablement UI
D15. Content validation pass
D16. Duelyst collection browser
D17. 50% reuse report
```

Do not skip D4.
Do not enable generated units in normal runs until D15 exists.
Do not hand-add hundreds of units before D6-D7.

---

# 20. Short instruction for Claude

Paste this to Claude when starting the milestone:

```text
We are starting the Duelyst Content Ingestion Milestone.

The goal is not to manually add more units. The goal is to build a safe content pipeline that lets us reuse 50%+ and eventually most/all of Duelyst assets: units, enemies, HUD, VFX, SFX, map/arena assets, icons, and UI pieces.

Important distinction:
- Imported/previewable content can be huge.
- Normal-run playable content must stay curated and validated.

Implement the milestone in small testable steps starting with D0-D1.
Do not change normal gameplay yet.
Do not enable generated content in normal runs yet.
Use readiness levels.
Use content packs.
Add validation and reports.
Update docs/decisions.md after each step.
```
