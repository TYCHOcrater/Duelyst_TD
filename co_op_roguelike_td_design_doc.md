# Co-op Roguelike Tower Defense Design Doc

Working title: **Shardstorm TD**
Engine: **Godot 4.x**
Implementation helper: **Claude Code**
Art/audio base: **Duelyst/OpenDuelyst asset library**
Primary goal: **An experiment-friendly tower defense framework where new units, waves, maps, roguelike drafts, and co-op rules can be changed mostly through data.**

---

## 1. North Star

This is not a normal tower defense game where the player memorizes one perfect build order.

The fantasy is:

> You and your allies are defending unstable battle-shards. Every run gives you weird units, weird maps, strange bargains, and different ways to help or sabotage the wave ecosystem. The game should feel like Duelyst units escaped into a roguelike Legion TD / Chaos TD machine.

The design should support quick experiments:

- Add a unit without touching combat code.
- Add a wave modifier without rewriting wave logic.
- Generate maps without hand-authoring every level.
- Support single-player now, but make the architecture able to spawn multiple player boards later.
- Support a map editor that writes the same map format the procedural generator uses.
- Keep arena/versus mode as a separate ruleset, not as a mutation of the core mode.

---

## 2. Recommended Core Concept

### Mode 1: Run Defense

Single-player or co-op roguelike tower defense.

Players defend a core against a fixed number of waves. After the final boss wave, endless scoring begins.

The important twist:

> Even in single-player, the game should be built as one PlayerSlot controlling one Board. Later co-op becomes multiple PlayerSlots and multiple Boards running under one shared SessionController.

This means the MVP is not a throwaway single-player game. It is the one-player version of the co-op architecture.

### Mode 2: Rival Storm

Arena / Legion TD inspired mode.

Players each defend their own board. Some choices create attacker echoes that are sent to enemy boards. This should be built after Run Defense is fun, because it needs clean wave, board, and enemy systems first.

---

## 3. Co-op Recommendation

Do **not** start with all players defending one shared core. Shared-core TD often causes quarterbacking: one strong player tells everyone else what to build.

Use this instead:

## Parallel Boards, Shared Fate

Each player has their own board and own local core shield. The team also has a shared Heart.

Leak rules:

1. Enemies that reach a player's core damage that player's local shield.
2. When local shield is gone, further leaks damage the shared Heart.
3. If the shared Heart reaches zero, the team loses.

Co-op interaction happens through explicit systems:

- **Aid Portal:** Send a temporary copy of one unit to another player's board for one wave.
- **Gold Gift:** Spend gold to give another player a discounted shop reroll or emergency unit.
- **Taunt:** A strong player can pull bonus enemies into their own next wave for extra team rewards.
- **Relief Valve:** A struggling player can mark a lane as unstable; allies get opportunities to intercept some enemies.
- **Team Pacts:** Every few waves, the team chooses one shared boon with one shared curse.

This gives each player personal agency while still feeling cooperative.

### Solo Compatibility

In solo, there is one Board, one PlayerSlot, one local core, one shared Heart. The same systems exist, but some are hidden or redirected:

- Aid Portal becomes a temporary duplicate or reserve bench mechanic.
- Gold Gift becomes a self-discount choice.
- Team Pacts become run modifiers.

---

## 4. Session Structure

A run is split into Acts.

Example default:

- Act 1: Waves 1-5
- Act 2: Waves 6-10
- Act 3: Waves 11-15
- Boss: Wave 16
- Endless: Wave 17+

Each wave loop:

1. Planning phase starts.
2. Player receives gold and a draft/shop offering.
3. Player places, moves, upgrades, fuses, or sells units.
4. Optional pact/map event is resolved.
5. Combat phase starts.
6. Enemies path toward the core.
7. Units attack automatically.
8. Leaks and rewards are resolved.
9. The game records run stats.

### Planning Phase

The player should be doing a small number of meaningful actions, not micromanaging 80 things.

Default actions:

- Buy unit from draft.
- Place unit on buildable tile.
- Move a limited number of units.
- Upgrade or fuse units.
- Reroll shop.
- Lock one shop option for next wave.
- Choose a Pact or event option.

### Combat Phase

Combat should be mostly automatic.

Potential active buttons can exist later, but the MVP should not require action-game micro.

---

## 5. Roguelike Draft System

The draft is the heart of replayability.

Each wave, the player receives a shop containing random unit offers.

Each offer is not just a base unit. It can be:

> Base Unit + Trait + Flaw + Price Modifier

Example:

- Windblade Adept, Echoing, Fragile, 8 gold
- Ironcliffe Guardian, Slow-Burning, Expensive, 13 gold
- Bloodmoon Priestess, Bonded, Volatile, 10 gold

This makes the Duelyst content feel new without requiring thousands of handcrafted towers.

### Unit Tags

Each unit should have tags used for synergies and generation.

Examples:

- Faction: Lyonar, Songhai, Vetruvian, Abyssian, Magmar, Vanar, Neutral
- Role: Archer, Mage, Guardian, Swarm, Artillery, Support, Assassin
- Damage: Physical, Magic, Siege, Poison, True
- Behavior: SingleTarget, AoE, Chain, Aura, Summoner, Debuffer
- Economy: Greedy, Discount, Treasure, Sacrifice

### Draft Rules

The shop should avoid pure randomness.

Use weighted generation:

- Guarantee at least one affordable option.
- Increase odds for tags the player already owns.
- Occasionally offer off-build temptations.
- Add act-based power scaling.
- Add pity rules for missing roles, such as anti-swarm or anti-armor.

### Rerolls

Rerolling should be cheap early and more expensive later, or cost a separate resource.

Reroll tension is important. If rerolls are too cheap, drafting loses meaning. If too expensive, runs feel random and unfair.

---

## 6. Units as Towers

Units are placed like towers but preserve Duelyst identity.

A unit is a board object with:

- Cost
- Range
- Attack cooldown
- Damage
- Damage type
- Targeting priority
- Tags
- Ability package
- Upgrade options
- Sell value
- Footprint size

Units should be allowed to move during planning, but not freely during combat.

Recommended movement rule:

- Each planning phase, every unit can move once within its move radius.
- Some units have special mobility.
- Moving during combat is disabled by default.

This gives the game a tactical board-game feeling without becoming an RTS.

### Unit Roles

Minimum MVP roles:

1. **Basic Shooter** - simple single-target damage.
2. **Splash Unit** - anti-swarm.
3. **Slow/Debuff Unit** - control.
4. **Support Aura** - buffs nearby units.
5. **Economy Unit** - weak combat but improves future income.
6. **Blocker/Guardian** - affects pathing or absorbs enemies if blockers are allowed.

Do not implement 100 units first. Implement 6 reliable archetypes, then map Duelyst units into them.

---

## 7. Experimental Mechanics To Make The Game Unusual

These are optional modules. Build the core first, then toggle these as experiments.

### 7.1 Pacts: Co-op Boons With Curses

Every 3 waves, choose one Pact.

Examples:

- **Shared Arsenal:** All players get one free unit. Enemy health +15%.
- **Blood Dividend:** Gain gold when a unit dies. Units lose 10% max HP each wave.
- **Greedy Horizon:** +3 gold per wave. Shops offer one fewer unit.
- **Mirror War:** Your strongest unit appears as an enemy mini-boss later.
- **Overflow Mercy:** First leak each wave is ignored. All later leaks deal +1 damage.

Pacts are excellent for co-op because they create table talk without requiring real-time coordination.

### 7.2 Enemy Echoes

When a player relies too hard on one strategy, the game can echo it back.

Examples:

- Too many slows -> enemies gain partial slow resistance.
- Too much splash -> armored elites appear.
- Too much single-target -> swarm waves become more common.

Use carefully. This should feel like the storm adapting, not like the game punishing the player for being smart.

### 7.3 Units With Flaws

Roguelike units become more interesting if the player drafts imperfect tools.

Examples:

- Glass: +40% damage, dies if hit by a leak shockwave.
- Lazy: Does not attack first 2 seconds of each wave.
- Proud: Gets stronger if no adjacent ally.
- Bonded: Buffs one chosen ally, weak alone.
- Haunted: On sell, spawns an enemy next wave.

### 7.4 Tile Mutations

Maps should change lightly during a run.

Examples:

- A mana tile appears: adjacent units charge abilities faster.
- A cracked tile appears: unit on it has extra range but can break.
- A growth tile appears: unit gets stronger every wave it stays there.
- A portal tile appears: enemies can temporarily branch paths.

This makes map generation more dynamic and helps avoid solved layouts.

### 7.5 Leaks Become Debt, Not Just Damage

A leak can do more than subtract health.

Examples:

- Some leaked enemies return later as stronger Debt enemies.
- Leaks can corrupt tiles near the core.
- Leaks can reduce next shop size.
- In co-op, leaks can become interceptable enemies on an ally's board.

This makes losing ground dramatic instead of binary.

---

## 8. Map Generation

The game needs procedural maps and an in-game map editor. Both should use the same MapDef format.

### MapDef Data

A map should be serializable as JSON or Godot Resource data.

Minimum fields:

- id
- name
- seed
- width
- height
- tiles
- spawn_points
- core_points
- path_rules
- build_rules
- decorations
- author
- version

Tile fields:

- coord
- tile_type
- buildable
- walkable
- height
- tags
- modifier_id

### Generator Goals

A generated map must have:

- At least one valid path from spawn to core.
- Enough buildable tiles near the path.
- No impossible enemy routes.
- No degenerate path that is too short.
- Some interesting local decisions: chokepoints, bends, islands, risky power tiles.

### Suggested Generation Algorithm

1. Choose map size and theme.
2. Pick spawn and core positions.
3. Generate one or more path anchors.
4. Carve a path using weighted random walk or A* through anchors.
5. Widen or decorate parts of the path.
6. Mark nearby tiles as buildable.
7. Add special tiles.
8. Validate the map.
9. If validation fails, retry with the same seed plus attempt index.
10. Save final MapDef.

### Validation Metrics

- path_length_min
- path_length_max
- buildable_tile_count_min
- buildable_near_path_ratio
- average_distance_from_buildable_to_path
- number_of_turns
- number_of_chokepoints
- number_of_spawn_points
- number_of_core_points

Claude should implement validators early. Procedural generation without validators becomes a bug factory.

---

## 9. In-Game Map Editor

The map editor should not be a separate tool. It should be an in-game mode.

### Editor MVP

The editor can:

- Create blank map.
- Paint path tiles.
- Paint buildable tiles.
- Place spawn point.
- Place core point.
- Place blocked terrain.
- Place special tiles.
- Validate map.
- Save MapDef.
- Load MapDef.
- Test-play map immediately.

### Editor Later

- Co-op editing with multiple cursors.
- Randomize selected region.
- Symmetry tools.
- Map rating / tags.
- Wave preview overlay.
- Heatmap of enemy paths and tower coverage.

Important rule:

> The map editor and procedural map generator must output the same format.

---

## 10. Progression and Meta Progression

Avoid raw permanent power at first. Raw stat upgrades make balance harder and can make new players feel weak.

Better meta progression:

### Unlock-Based Progression

- Unlock new unit pools.
- Unlock new traits.
- Unlock new Pacts.
- Unlock new map themes.
- Unlock new enemy families.
- Unlock starting relic options.

### Mastery Progression

Each unit can have a mastery track that unlocks variants, not raw strength.

Example:

- Mastery 1: Unit appears in draft pool.
- Mastery 2: Unlock one alternate trait.
- Mastery 3: Unlock one cosmetic border or sound.
- Mastery 4: Unlock one risky evolution.

### Run Records

Track:

- Highest endless wave.
- Best score per map seed.
- Best score per faction.
- Weirdest winning build.
- Fastest boss kill.
- Least gold spent victory.

This supports score chasing without needing heavy account progression.

---

## 11. Arena / Legion Mode Design

This should be a separate GameModeRules resource called RivalStormRules.

Core loop:

1. Each player defends their own board.
2. Each wave defeated gives income.
3. Players can spend a separate resource to send attackers.
4. Sent attackers appear in enemy waves after a delay.
5. The winner is the last player/team with a surviving Heart.

### Important Distinction

Do not literally send your placed towers as enemies in the first version. That creates many edge cases.

Instead, generate **attacker echoes** from unit tags.

Examples:

- Player owns many Abyssian units -> sends swarm echoes.
- Player owns many Magmar units -> sends bruiser echoes.
- Player buys a Send card -> sends specific enemy package.

This keeps arena mode compatible with the roguelike unit system.

---

## 12. Technical Architecture For Godot

Build the project as data-driven modules.

### Core Scenes / Nodes

- **GameRoot**
  - Owns scene transitions.
  - Loads main menus, run sessions, editor, test scenes.

- **SessionController**
  - Owns the run state.
  - Creates PlayerSlots.
  - Advances planning/combat phases.
  - Owns global RNG seed.
  - Talks to GameModeRules.

- **PlayerSlot**
  - Represents one player, local or remote.
  - Has player_id, input profile, board reference, economy, draft state.

- **Board**
  - Owns grid, path, placed units, enemies, core.
  - Should not know whether it is solo or co-op.

- **GridController**
  - Converts between grid coordinates and world positions.
  - Owns TileMapLayer or grid data.

- **PathController**
  - Stores current enemy paths.
  - Validates routes.
  - Supports path previews.

- **WaveDirector**
  - Creates waves from WaveDef and run difficulty.
  - Spawns enemies.
  - Applies wave modifiers.

- **DraftDirector**
  - Generates shop offers.
  - Applies draft weights, pity rules, locks, rerolls.

- **EconomyController**
  - Gold gain, spending, interest, refunds, bounties.

- **UnitFactory**
  - Creates unit instances from UnitDef + TraitDef + modifiers.

- **CombatSystem**
  - Target acquisition, attacks, damage resolution.

- **StatusEffectSystem**
  - Slow, burn, poison, armor break, stun, shield, etc.

- **Relic/Pact System**
  - Applies run modifiers.

- **MapGenerator**
  - Creates MapDef.

- **MapEditorController**
  - Edits MapDef in game.

- **SaveRunSystem**
  - Saves unlocks, records, and settings.

### Data Resources

Use Godot Resources or JSON files. Favor data formats Claude can edit safely.

Recommended data files:

- data/units/*.json
- data/enemies/*.json
- data/traits/*.json
- data/waves/*.json
- data/relics/*.json
- data/pacts/*.json
- data/maps/*.json
- data/game_modes/*.json
- data/balance/default_numbers.json

### UnitDef Example

```json
{
  "id": "windblade_adept",
  "display_name": "Windblade Adept",
  "sprite": "duelyst/units/windblade_adept.png",
  "faction": "lyonar",
  "tags": ["melee", "guardian", "physical"],
  "cost": 6,
  "range": 2,
  "attack_cooldown": 0.9,
  "damage": 8,
  "damage_type": "physical",
  "targeting": "first",
  "ability_package": "basic_attack",
  "upgrade_pool": ["range_plus", "cleave", "guard_aura"]
}
```

### TraitDef Example

```json
{
  "id": "echoing",
  "display_name": "Echoing",
  "rarity": "rare",
  "compatible_tags": ["mage", "archer", "support"],
  "stat_mods": {
    "damage_mult": 0.75
  },
  "behavior_mods": ["repeat_attack_at_50_percent_power"]
}
```

---

## 13. Multiplayer-Safe Architecture

Even before networking, follow these rules:

1. Every run has a seed.
2. Every board has a board_id.
3. Every player has a player_id.
4. All random decisions go through SessionRng.
5. Player commands are explicit objects.
6. The board applies commands, not raw UI clicks.
7. Game state can be serialized for debugging.

### Command Examples

- PlaceUnitCommand
- MoveUnitCommand
- SellUnitCommand
- BuyDraftOfferCommand
- RerollDraftCommand
- ChoosePactCommand
- StartWaveCommand

This makes it easier to add:

- Replays
- Undo during planning
- Online multiplayer
- AI test players
- Debug tools

---

## 14. Split-Screen Plan

Do not implement split-screen first.

First implement multiple Board instances in the same session.

Then add a view layout layer:

- 1 player: one full-screen board view.
- 2 players: vertical or horizontal split.
- 3-4 players: grid split.

Each view should point at one PlayerSlot/Board.

UI should be mostly per-player, but shared run events should use a central overlay.

---

## 15. Visual Direction

Use Duelyst assets as a strength, not as generic tower sprites.

Suggested presentation:

- Isometric or top-down grid with Duelyst character sprites.
- Combat readable at a glance.
- Strong silhouettes.
- Minimal animation requirements at first.
- Impact effects and sounds do a lot of the juice.

Avoid overly detailed pathing visuals in MVP. Clean readability matters more.

---

## 16. MVP Scope

The MVP should prove the core loop, not the entire dream.

### MVP Must Have

- One generated map.
- One editable map format.
- One path from spawn to core.
- Core health.
- 6 unit archetypes.
- 6 enemy archetypes.
- 10 waves.
- Gold income.
- Draft shop.
- Reroll.
- Unit placement.
- Basic combat.
- Win/lose screen.
- Run seed displayed.
- Basic balancing file.

### MVP Should Not Have Yet

- Online multiplayer.
- Full split-screen.
- 100 Duelyst units.
- Complex boss scripting.
- Account progression.
- Ranked arena.
- Co-op map editing.
- Advanced status interactions.

---

## 17. First 10 Implementation Iterations For Claude Code

### Iteration 1: Project Skeleton

Goal: Create the core folders, scenes, and data loading.

Acceptance criteria:

- Godot project opens.
- GameRoot loads a RunTest scene.
- DataLoader can read units/enemies/waves JSON.
- A seeded SessionRng exists.
- There is a docs/decisions.md file.

### Iteration 2: Grid and MapDef

Goal: Create a board from MapDef.

Acceptance criteria:

- Board renders a simple grid.
- Spawn and core appear.
- Path tiles and buildable tiles are visible.
- Grid/world coordinate conversion works.

### Iteration 3: Enemy Pathing

Goal: Spawn enemies that follow the path and damage the core.

Acceptance criteria:

- Enemies spawn from spawn point.
- Enemies move to core.
- Reaching core reduces health.
- Wave ends when all enemies are dead or leaked.

### Iteration 4: Unit Placement

Goal: Place one basic unit on buildable tiles.

Acceptance criteria:

- Player can select a unit from debug UI.
- Player can place it on valid tiles.
- Invalid placement is rejected.
- Unit stores board coordinate and UnitDef id.

### Iteration 5: Combat

Goal: Units attack enemies.

Acceptance criteria:

- Unit finds target in range.
- Unit attacks on cooldown.
- Enemy takes damage and dies.
- Kill rewards gold.

### Iteration 6: Draft Shop

Goal: Replace debug unit button with draft offers.

Acceptance criteria:

- Shop shows 3 offers.
- Offers come from UnitDef pool.
- Player can buy if enough gold.
- Player can reroll.
- Shop refreshes each wave.

### Iteration 7: Procedural Map Generator

Goal: Generate valid maps from seed.

Acceptance criteria:

- MapGenerator creates MapDef.
- Validator rejects impossible maps.
- Same seed generates same map.
- Run screen shows seed.

### Iteration 8: Traits and Modifiers

Goal: Draft offers can include a trait.

Acceptance criteria:

- TraitDef loads from data.
- Shop can offer UnitDef + TraitDef.
- Trait modifies stats or behavior.
- UI shows trait name.

### Iteration 9: Pacts

Goal: Add run-level choices every few waves.

Acceptance criteria:

- Pact choices appear after wave 3 and 6.
- Player chooses one.
- Pact modifies run state.
- Pact is saved in run summary.

### Iteration 10: Map Editor MVP

Goal: Edit and save a simple map in game.

Acceptance criteria:

- Editor can paint tile types.
- Editor can place spawn/core.
- Editor validates map.
- Editor saves MapDef.
- Saved map can be played.

---

## 18. Claude Code Operating Rules

Use this section as instruction text for Claude Code.

### General Rules

- Prefer data-driven implementation over hard-coded content.
- Do not add large systems without updating docs/decisions.md.
- Every random outcome must use SessionRng, not global random.
- Every feature needs a small test scene or debug path.
- Keep single-player implemented as one PlayerSlot, not as special-case code.
- Do not implement online multiplayer until the board/session architecture is stable.
- Do not import all Duelyst content into gameplay at once. Create a small curated test pool first.
- If a data schema changes, write a migration note.

### When Asked To Implement A Feature

Claude should answer with:

1. Files it will modify.
2. Data schema changes.
3. Risks / edge cases.
4. Implementation steps.
5. Acceptance test.

Then implement.

### Prompt Template

```text
Read docs/co_op_roguelike_td_design_doc.md and docs/decisions.md.
Implement Iteration [N]: [name].

Constraints:
- Keep the game data-driven.
- Use SessionRng for all random decisions.
- Single-player must remain one PlayerSlot controlling one Board.
- Do not introduce networking yet.
- Add or update a small test scene/debug UI so I can verify the feature.
- Update docs/decisions.md with any architectural decision.

After coding, summarize:
- What changed.
- How to test it in Godot.
- Any known limitations.
```

---

## 19. Balance Defaults

Starting numbers for early tests:

- Starting gold: 20
- Gold per wave: 8 + wave_index
- Shop size: 3
- Reroll cost: 2, increasing by 1 each reroll in the same planning phase
- Unit sell refund: 70%
- Core health: 20
- Local shield in co-op: 10
- Shared Heart in co-op: 30
- Base waves per run: 16
- Endless starts: wave 17

Unit starting ranges:

- Short range: 2 tiles
- Medium range: 3 tiles
- Long range: 4-5 tiles

Enemy starting stats:

- Grunt: low health, normal speed
- Runner: low health, high speed
- Brute: high health, low speed
- Swarm: many small enemies
- Shielded: resists first hit or has armor
- Boss: high health, special modifier

---

## 20. Content Mapping Strategy For Duelyst Assets

Do not map every Duelyst unit manually at first.

Create an AssetCatalog that scans available sprites and lets you assign gameplay definitions gradually.

Recommended approach:

1. Import assets into a stable folder.
2. Create asset_catalog.json with sprite ids and paths.
3. Create 6 handcrafted UnitDefs using selected sprites.
4. Add more units only after the combat loop is fun.
5. Later, write an assisted mapping tool that suggests tags based on faction/name/source folder.

---

## 21. Questions To Decide During Iteration

These are not blockers for MVP, but they shape the final game.

1. Should the game feel more like a board game or an arcade defense game?
2. Should players be able to block or alter enemy paths with units?
3. Should units have health and be attackable, or are they pure towers?
4. Should shops be fully random, faction-biased, or deck-like?
5. Should co-op be local-first, online-first, or both eventually?
6. Should the arena mode be PvP, PvE race, or asynchronous ghost competition?
7. Should meta progression unlock variety only, or also small power?
8. Should endless mode be a main attraction or just a score appendix?

---

## 22. Recommended Immediate Decision

Build this first:

> A single-player roguelike TD run where the player defends one generated board for 10 waves using drafted Duelyst units with simple traits.

But architect it like this:

> SessionController -> PlayerSlot -> Board

That one choice keeps co-op, split-screen, arena mode, replay, and AI testing possible later.

---

## 23. Design Philosophy

The best version of this game is not just "Duelyst but tower defense."

It should be:

- A run-based tactical defense sandbox.
- A co-op strategy game where players have their own problems but share consequences.
- A map-generation toy.
- A unit-synergy experiment machine.
- A platform where weird rules can be added without breaking the whole project.

The forbidden-genre feeling is a strength. Tower defense becomes fresh when the map, units, economy, and co-op pressure are all unstable in controlled ways.
