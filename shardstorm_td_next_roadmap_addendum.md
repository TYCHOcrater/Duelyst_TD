# Shardstorm TD — Next Roadmap Addendum

## Purpose

This addendum is for the current fork point in development.

The first implementation pass already proved that the project can load maps, spawn enemies, place units, run combat, offer draft shops, apply traits/flaws/relics/pacts, show summaries, and support multiple content packs.

The next risk is **not** “we need more content.”

The next risk is:

> The game may become a normal tower defense with more roguelike options, instead of becoming a distinct, sticky, endlessly replayable Duelyst-based defense game.

So the next roadmap should focus on the three design decisions that will define the game:

1. **How units grow during a run.**
2. **How co-op actually feels.**
3. **How the player reads, enjoys, and remembers each run.**

Procedural map generation and the in-game map editor are still important, but they should not be the immediate focus unless the current core loop already feels locked.

---

# Current Status Snapshot

Original §17 first implementation iterations:

| # | Goal | Status |
|---|------|--------|
| 1 | Project skeleton | Done |
| 2 | Grid + MapDef | Done |
| 3 | Enemy pathing | Done |
| 4 | Unit placement | Done |
| 5 | Combat | Done |
| 6 | Draft shop | Done |
| 7 | Procedural map generator | Not done |
| 8 | Traits + modifiers | Done |
| 9 | Pacts | Done |
| 10 | Map editor MVP | Not done |

Extra systems already built beyond the original first ten:

- flaws
- relics
- evolution
- mastery
- daily seed
- failure coach
- multiple content packs
- splitter waves
- silence waves
- corruption waves
- run summary
- first polish passes

The game has enough foundation to test bigger design direction now.

---

# Recommended Immediate Focus

Do **not** immediately focus on:

- online multiplayer
- a huge map editor
- 100 more Duelyst units
- final UI skinning
- ranked arena mode
- full procedural map system

Instead, focus on a **playable decision fork**:

> Should the game use classic TD upgrades, autobattler-style merging, or a hybrid?

This decision affects everything:

- shop design
- economy
- UI
- co-op trading
- unit attachment
- balance
- content production
- run identity
- long-term replayability

The best next milestone is therefore:

> Build a small, testable “unit growth bake-off” where classic upgrades, merging, and evolution can be compared in the same 10–15 wave run.

---

# Main Recommendation: Use a Hybrid, Not Pure Classic TD or Pure Autobattler

## Problem with pure classic TD upgrade

Classic TD upgrade usually looks like:

```text
Place unit -> spend gold -> +damage/+range/+speed -> repeat
```

This is reliable, but it can feel solved and flat unless the upgrade tree is very deep.

It also encourages players to think in terms of math efficiency instead of attachment:

```text
Which tower has the best DPS per gold?
```

That is useful, but not enough for the kind of replayable, Dota/Legion/Warcraft-custom-map feeling desired here.

## Problem with pure autobattler merge

Pure autobattler merging usually looks like:

```text
Buy duplicates -> combine three copies -> stronger unit
```

This creates dopamine and attachment, but in a tower defense it can create problems:

- too much shop RNG
- too much bench management
- too little map-placement strategy
- too many weak units waiting for merges
- bad feeling when the right duplicate never appears
- awkward co-op interactions

## Recommended model

Use:

> **Drafted TD placement + duplicate merging + branch evolution.**

The player still plays a tower defense:

- place units on meaningful tiles
- read the wave
- build counters
- manage economy
- survive leaks

But units grow more like an autobattler/roguelike:

- buy duplicate copies
- gain unit shards
- merge into star levels
- choose evolution branches
- attach traits/flaws/relic synergies

This gives the game stronger run identity.

---

# Proposed Unit Growth Model

## Core rule

Each placed unit is a persistent `UnitInstance`.

A `UnitInstance` has:

```text
base_unit_id
star_level
xp_or_kill_count
shard_count
trait_ids
flaw_ids
evolution_path_ids
placed_tile
lifetime_stats
```

## Star levels

Use 3 star levels.

```text
1-star: base unit
2-star: merged/improved unit, choose first evolution branch
3-star: capstone unit, choose final specialization
```

## Duplicate rules

Recommended first tuning:

```text
Buy first copy -> creates/places unit
Buy duplicate copy -> adds 1 shard to that unit type
2 shards -> upgrade one chosen copy to 2-star
5 total shards -> upgrade one chosen copy to 3-star
```

Why not strict “3 copies combine into 1” at first?

Because tower defense runs are shorter than most autobattler matches, and strict 3-of-kind merging can feel too slow or too shop-RNG dependent.

The shard model lets duplicate drafting feel good without requiring the player to keep many board/bench copies.

## Evolution choices

When a unit reaches 2-star, the player chooses between 2 branches.

When a unit reaches 3-star, the player chooses a capstone.

Example:

```text
Windblade Adept
  2-star option A: Storm Duelist
    faster attacks, chain strike
  2-star option B: Sunblade Guard
    gains armor aura, slower attacks

  3-star option A: Tempest Saint
    every third attack hits multiple enemies
  3-star option B: Dawn Bulwark
    grants shield to nearby allies at wave start
```

The important rule:

> Evolution should change behavior, not just increase numbers.

---

# How This Should Feel

The player should think:

```text
I need anti-armor for wave 8.
But the shop offered a duplicate for my Bloodtear Alchemist.
If I buy it, I can evolve him into a huge splash carry.
Can I survive one more wave without anti-armor?
```

That is the target feeling.

The game becomes about:

- greed vs survival
- countering waves vs completing unit builds
- adapting to draft RNG
- building emotional attachment to specific units
- choosing identity instead of only buying efficiency

---

# Unit Growth Modes to Test

Claude should implement these as configuration options so the team can compare them.

```text
classic_upgrade
merge_stars
merge_evolution_hybrid
```

## Mode 1: Classic Upgrade

```text
Spend gold to upgrade placed unit.
Upgrade increases stats or unlocks fixed ability.
```

Pros:

- easy to understand
- easy to balance
- good TD tradition

Cons:

- less exciting draft decisions
- less unit attachment
- can become spreadsheet optimization

## Mode 2: Merge Stars

```text
Buying duplicates increases star level.
Star level gives stat increase.
```

Pros:

- satisfying shop dopamine
- easy to understand
- makes duplicates exciting

Cons:

- can still be too numeric
- may overemphasize RNG

## Mode 3: Merge Evolution Hybrid

```text
Buying duplicates unlocks evolution choices.
Evolution changes behavior.
```

Pros:

- strongest identity
- best replayability
- supports Duelyst content well
- enables weird builds

Cons:

- more UI work
- more content design work
- harder to balance

## Recommendation

Build all three lightly, then commit to:

```text
merge_evolution_hybrid
```

Classic upgrades can remain as a fallback mechanic for simple units, relics, or map-editor modes.

---

# Most Impactful Roadmap From Here

## Milestone A — Unit Growth Bake-Off

Goal:

> Decide the core unit-growth model before adding many more units.

Expected result:

A 10–15 wave run where you can test classic upgrades vs merge stars vs merge evolution hybrid.

---

## Iteration A1 — Growth Mode Flag

### Goal

Add a global run setting that controls how units upgrade.

```text
growth_mode = classic_upgrade | merge_stars | merge_evolution_hybrid
```

### Build

- Add `GrowthMode` enum or equivalent.
- Add growth mode to `RunConfig`.
- Show active growth mode in debug UI.
- Make shop/unit systems aware of growth mode.

### Test

- Start a run in each growth mode.
- UI displays the selected mode.
- No gameplay breaks when switching modes.

### Acceptance criteria

```text
RunConfig stores growth mode.
Debug menu can choose growth mode.
Run summary records growth mode.
Existing runs still work.
```

---

## Iteration A2 — Unit Instance Identity

### Goal

Make individual units feel persistent.

### Build

Each placed unit should track:

```text
instance_id
base_unit_id
owner_player_id
star_level
kill_count
damage_dealt
waves_survived
traits
flaws
evolution_choices
```

### Test

- Place two copies of the same unit.
- Each has a different instance id.
- Each tracks separate damage/kills.
- Run summary can show top unit instance.

### Acceptance criteria

```text
Unit instances are inspectable.
Lifetime stats persist through waves.
Selling/death records final stats.
```

---

## Iteration A3 — Classic Upgrade Prototype

### Goal

Implement the baseline TD upgrade model for comparison.

### Build

- Add upgrade button to unit inspect panel.
- Upgrade costs gold.
- Upgrade increases level.
- Each level applies simple stat scaling.

Recommended placeholder scaling:

```text
Level 1: base
Level 2: +25% damage, +10% attack speed
Level 3: +50% damage, +20% attack speed, +1 range if applicable
```

### Test

- Place unit.
- Upgrade it during planning.
- Gold decreases.
- Unit becomes stronger.
- Run summary records upgrades bought.

### Acceptance criteria

```text
Classic upgrade mode is playable for 10 waves.
Upgrade UI is clear.
Upgrades are disabled in other growth modes unless allowed.
```

---

## Iteration A4 — Duplicate Shard System

### Goal

Make duplicate shop offers useful.

### Build

When the player buys a unit already owned:

```text
If no placed copy exists:
  create placeable unit token.
If placed copy exists:
  ask whether to place new copy or convert to shard.
If converted:
  add shard to that base unit id.
```

For first prototype, allow simple behavior:

```text
Buy duplicate -> automatically adds shard to that unit type.
```

### Test

- Buy Windblade Adept.
- Buy another Windblade Adept.
- Shard count increases.
- UI shows progress toward next star.

### Acceptance criteria

```text
Duplicate purchases are visible and satisfying.
Shard progress is shown in shop and unit inspect panel.
Same seed gives same duplicate offers.
```

---

## Iteration A5 — Star Upgrade Prototype

### Goal

Convert shards into star levels.

### Build

Recommended thresholds:

```text
2 shards -> 2-star
5 shards -> 3-star
```

When threshold is reached:

- show upgrade available marker
- player selects which placed copy to upgrade if multiple exist
- star level improves stats
- VFX/audio feedback plays

Recommended placeholder star bonuses:

```text
2-star: +35% damage, +20% health or utility strength
3-star: +80% damage, +40% health or utility strength, stronger ability
```

### Test

- Buy enough duplicates.
- Upgrade a selected unit to 2-star.
- Unit becomes visually distinct.
- Upgrade persists through waves.

### Acceptance criteria

```text
Star upgrade is player-controlled.
Unit inspect panel shows star level.
Run summary shows starred units.
```

---

## Iteration A6 — Evolution Choice Prototype

### Goal

Make star upgrades become meaningful choices, not only stat bumps.

### Build

Add `EvolutionDef` data.

Example schema:

```json
{
  "id": "windblade_storm_duelist",
  "base_unit_id": "windblade_adept",
  "required_star": 2,
  "display_name": "Storm Duelist",
  "description": "Attacks chain to a second enemy for reduced damage.",
  "stat_mods": {
    "attack_speed_mult": 1.15
  },
  "behavior_mods": ["chain_attack_1"]
}
```

### Test

- Upgrade a unit to 2-star.
- Evolution choice panel appears.
- Choosing option changes behavior.
- Run summary records evolution.

### Acceptance criteria

```text
At least 4 units have 2 evolution choices.
Choices are data-driven.
Evolution changes combat behavior, not just stats.
```

---

## Iteration A7 — Shop Duplicate Bias

### Goal

Make merging possible without feeling forced or random.

### Build

Add slight shop bias:

```text
Owned unit base ids are slightly more likely to appear.
Units matching current build tags are slightly more likely.
Missing counter tools are occasionally offered.
```

Important:

```text
Do not guarantee duplicates.
Do not make shops deterministic unless using daily/challenge seed.
```

### Test

- In a 10-wave run, the player should usually see at least a few duplicate opportunities.
- Different seeds still feel different.
- Shop does not offer only owned units.

### Acceptance criteria

```text
Bias values are tunable in data.
Run summary logs duplicate offers seen and bought.
```

---

## Iteration A8 — Growth Bake-Off Report

### Goal

Help choose the final growth model.

### Build

After each run, show:

```text
growth mode
units bought
duplicates bought
upgrades purchased
star upgrades achieved
evolutions chosen
gold spent on growth
gold spent on new units
top damage unit
failure reason
player rating prompt, optional
```

### Test

Play three runs:

```text
one classic_upgrade
one merge_stars
one merge_evolution_hybrid
```

Compare:

- which was more exciting
- which had better decisions
- which was easier to understand
- which created more memorable units
- which produced better pacing

### Acceptance criteria

```text
The game can produce a comparison report.
The report helps decide which growth model to keep.
```

---

# Milestone A Gate

Do not move into major content expansion until this question has an answer:

```text
What is the main way units grow during a run?
```

Recommended answer:

```text
Merge evolution hybrid.
```

Keep classic upgrade only if:

- merging feels too random
- UI burden is too high
- placement strategy becomes weaker
- players cannot understand the system quickly

---

# Milestone B — Co-op Vertical Slice

Goal:

> Make co-op testable locally without online networking.

The goal is not “finished multiplayer.”

The goal is to prove whether co-op should be:

```text
shared board
parallel boards
linked boards
arena pressure
```

Recommendation:

> Start with parallel boards and shared fate.

Each player has their own board, but the team has a shared Heart.

---

## Co-op Model Recommendation

Use:

```text
Player 1 Board + Player 2 Board
Local Shield per player
Shared Team Heart
Synchronized planning phase
Simultaneous combat phase
Limited aid actions
Shared pact decisions
```

Why this is good:

- each player has ownership
- skilled player cannot fully dominate another player’s board
- team still cares about leaks
- split-screen is natural
- solo architecture can become one PlayerSlot
- arena mode later becomes easier

---

## Iteration B1 — Multi-Board Debug Mode

### Goal

Run two boards inside one session.

### Build

- `SessionController` owns multiple `PlayerSlot`s.
- Each `PlayerSlot` owns one `Board`.
- Debug setting: `player_count = 1 | 2`.
- Both boards can use same map or different maps.

### Test

- Launch 1-player mode.
- Launch 2-board debug mode.
- Each board spawns enemies.
- Each board has independent gold/core/unit state.

### Acceptance criteria

```text
Existing solo mode still works.
Two boards can run in one session.
Board state is not accidentally shared.
```

---

## Iteration B2 — Synced Phases

### Goal

Make co-op pacing understandable.

### Build

Co-op phases:

```text
Planning phase starts for all players.
Each player can ready up.
Combat starts when all ready or debug force-start is pressed.
Combat ends only when all boards resolve.
Reward phase happens after all boards finish.
```

### Test

- Board 1 finishes early.
- Board 2 is still fighting.
- Session waits for Board 2.
- Both players enter next planning phase together.

### Acceptance criteria

```text
No board advances wave alone.
Ready state is visible.
Solo mode uses same phase system.
```

---

## Iteration B3 — Local Shield + Shared Team Heart

### Goal

Create shared fate without removing player ownership.

### Rules

```text
Each player has Local Shield.
Leaks damage Local Shield first.
If Local Shield is empty, leaks damage Team Heart.
Team Heart reaches 0 -> team loses.
```

### Test

- Player 1 leaks.
- Player 1 Local Shield drops.
- Player 2 remains safe.
- When Player 1 shield is empty, further leaks damage Team Heart.
- Team loss triggers when Team Heart reaches 0.

### Acceptance criteria

```text
UI clearly shows Local Shield and Team Heart.
Run summary shows which board leaked and when.
```

---

## Iteration B4 — Aid Tokens

### Goal

Allow players to help each other without destroying board ownership.

### Build

Each player gets limited `AidToken`s.

First aid action:

```text
Send Echo Unit:
Choose one of your units.
Send a temporary echo copy to ally board for the next wave.
Echo disappears after combat.
```

### Test

- Player 1 sends unit echo to Player 2.
- Echo appears on Player 2 board.
- Echo fights during next wave.
- Echo disappears after wave.
- Token is consumed.

### Acceptance criteria

```text
Aid action is obvious and satisfying.
Aid cannot be spammed.
Aid is logged in run summary.
```

---

## Iteration B5 — Co-op Draft Moment

### Goal

Create co-op discussion between waves.

### Build

Every few waves, show a team draft choice:

```text
Option A: both players gain a relic
Option B: one player gains strong unit, other gains gold
Option C: team gains aid tokens, enemies gain +health
```

### Test

- Choice appears after wave 3 or 5.
- Choice affects both players.
- Single-player can use same system as solo event choice.

### Acceptance criteria

```text
Co-op has at least one meaningful shared decision.
Choice is recorded in summary.
```

---

## Iteration B6 — Co-op Merge Interaction

### Goal

Connect the unit growth system to co-op.

### Build one simple interaction:

```text
Trade Token:
Once per act, a player may send one duplicate shard to an ally.
```

Why shard trade instead of full unit trading?

- simpler UI
- fewer board ownership bugs
- supports merge/evolution system
- creates teamwork without chaos

### Test

- Player 1 owns Windblade shard.
- Player 2 needs one Windblade shard for 2-star.
- Player 1 sends shard.
- Player 2 upgrades unit.

### Acceptance criteria

```text
Shard transfer is clear.
Shard transfer is limited.
Run summary records it.
```

---

# Milestone B Gate

Before implementing online multiplayer, answer:

```text
Is local/debug co-op fun enough with two boards?
Do aid actions create teamwork?
Does shared Heart create tension without frustration?
Does synchronized pacing feel okay?
```

If no, tune co-op rules before networking.

---

# Milestone C — UI and Feel Foundation

Goal:

> Make the current game easier to understand before adding more systems.

This is not final art polish.

This is **playability polish**.

---

## Iteration C1 — Shop Card Clarity

### Goal

The player should understand an offer in 2 seconds.

Each shop card should show:

```text
unit name
faction
role
cost
trait
flaw
owned count / shard progress
counter tags
small icon/sprite
```

Example:

```text
Windblade Adept
Lyonar / Melee / Anti-Swarm
Cost: 6
Trait: Echoing
Flaw: Proud
Owned: 1 copy, 1/2 shards to 2-star
Good vs: Swarm, Fast
Weak vs: Armor
```

### Test

- Player can tell which offers are duplicates.
- Player can tell which offer helps against the next wave.
- Player can tell risky offers from safe offers.

### Acceptance criteria

```text
Shop cards are readable at normal resolution.
Duplicate/shard state is highly visible.
Trait/flaw text does not overwhelm the card.
```

---

## Iteration C2 — Unit Inspect Panel

### Goal

Make attachment and strategy visible.

Unit inspect should show:

```text
name
faction
role
star level
current evolution
damage type
range
attack speed
DPS estimate
traits/flaws
kills
damage dealt
next upgrade requirement
targeting mode
```

### Test

- Click any unit.
- Understand what it does.
- Understand how to upgrade/evolve it.
- Change targeting mode from this panel.

### Acceptance criteria

```text
No important unit state is hidden.
Panel supports classic upgrade and merge/evolution modes.
```

---

## Iteration C3 — Upcoming Wave Preview

### Goal

The player should know what they are preparing for.

Show:

```text
wave number
enemy family
threat tags
armor/magic resistance/shield/regen
boss warning
recommended counters
```

Example:

```text
Wave 8: Ironbound March
Threats: Armor, Slow, High Health
Recommended: Magic, Armor Break, Poison
Bad: Pure Physical Swarm
```

### Test

- Player sees wave preview during planning.
- Player can draft/upgrade accordingly.
- Failure coach uses same tags after loss.

### Acceptance criteria

```text
Wave preview uses data, not hardcoded text.
Wave threat tags match actual enemies.
```

---

## Iteration C4 — Combat Readability Pass

### Goal

Reduce chaos before adding more units/VFX.

Build/readability rules:

```text
Elite enemies have marker.
Boss enemies have marker and warning audio.
Shielded enemies have visible shield state.
Armored enemies have armor icon.
Silenced units show silence state.
Corrupted tiles pulse subtly.
Damage numbers are filtered or grouped.
Low-priority hit VFX are suppressed during huge waves.
```

### Test

- During a busy wave, player can identify the top threat.
- Player can tell when units are disabled.
- Player can tell when the core is in danger.

### Acceptance criteria

```text
Important information wins over visual noise.
VFX budget/priority system exists, even if simple.
```

---

## Iteration C5 — Run Summary 2.0

### Goal

Make each run memorable and useful.

Show:

```text
run title
seed
map
wave reached
result
main build tags
top damage unit
top evolved unit
best economy unit
biggest leak wave
most dangerous enemy type
growth mode
relics/pacts
co-op aid used, if any
failure coach advice
```

### Test

- Finish a run.
- Summary tells a story.
- Summary suggests one next improvement.

### Acceptance criteria

```text
Summary is useful for balancing and player learning.
Summary can be screenshotted/shared.
```

---

# Milestone D — Content Expansion, but Controlled

Goal:

> Add content in coherent packs, not random units.

Do not add a Duelyst unit just because it exists.

Every new content pack should add a mini-metagame.

---

## Content Pack Rule

Each pack should contain:

```text
3-5 player units
1 enemy family or enemy counter
1 wave modifier
1 relic
1 trait
1 flaw
1 pact or event
1 evolution branch set
1 challenge seed
balance notes
```

Each pack should answer:

```text
What build does this enable?
What counters this build?
What wave tests this build?
What relic makes it exciting?
What flaw makes it risky?
```

---

## Suggested Next Packs

## Pack D1 — Lyonar Formation Pack

Fantasy:

```text
Disciplined frontline, shields, adjacency bonuses, holy beams.
```

Gameplay:

```text
positioning matters
frontline stability
anti-swarm through formation
weak to magic/anti-shield enemies
```

Possible Duelyst names:

```text
Silverguard Knight
Windblade Adept
Azurite Lion
Sunriser
Ironcliffe Guardian
```

Systems to test:

```text
adjacency aura
shield refresh
formation bonus
blocker identity
```

---

## Pack D2 — Abyssian Sacrifice Swarm Pack

Fantasy:

```text
many small units, death triggers, shadow bursts, risky scaling.
```

Gameplay:

```text
summons
death value
overcrowding
explosion combos
weak to silence and anti-summon waves
```

Possible Duelyst names:

```text
Wraithling
Bloodmoon Priestess
Shadow Watcher
Abyssal Crawler
Darkspine Elemental
```

Systems to test:

```text
summon cap
death trigger queue
sacrifice economy
visual clutter control
```

---

## Pack D3 — Vanar Frost Control Pack

Fantasy:

```text
slow, brittle, control, snowballing precision.
```

Gameplay:

```text
slows enemies
turns slows into damage
struggles against slow-resistant enemies
loves long paths
```

Possible Duelyst names:

```text
Snow Chaser
Hearth-Sister
Crystal Cloaker
Gravity Well
Frostiva
```

Systems to test:

```text
slow stacking
brittle trigger
control resistance
anti-stall enemy adaptation
```

---

## Pack D4 — Magmar Egg Mutation Pack

Fantasy:

```text
eggs, growth, regeneration, mutation, brutal impact.
```

Gameplay:

```text
delayed power
unit transformation
tankiness
regen
weak early, strong late
```

Possible Duelyst names:

```text
Young Silithar
Veteran Silithar
Earth Walker
Elucidator
Makantor Warbeast
```

Systems to test:

```text
egg objects
hatching
regeneration
mutation evolution
```

---

# Milestone E — Procedural Maps and Editor

Goal:

> Return to the two unfinished original tasks after the core growth and co-op direction is clearer.

Do this after Milestones A and some of C.

Why wait?

Because map generation depends on what the core game values:

- If merging matters, maps need enough stable placement slots for carries.
- If formations matter, maps need adjacency patterns.
- If co-op matters, maps need comparable pressure between players.
- If special tiles matter, generator must place them intentionally.

---

## Iteration E1 — Map Validator First

### Goal

Prevent bad maps before generating many of them.

Validate:

```text
spawn exists
core exists
path exists
path length range
buildable count range
buildable tiles near path
no unreachable core
no impossible enemy route
special tiles not blocking path
co-op map balance score, later
```

### Test

- Valid map passes.
- Missing core fails.
- Broken path fails.
- Too few buildable tiles fails.

### Acceptance criteria

```text
Validator gives human-readable errors.
Validator can run from debug menu.
Map loading uses validator warnings/errors.
```

---

## Iteration E2 — Simple Seeded Generator

### Goal

Generate basic playable maps.

Build:

```text
choose map size
choose spawn/core
carve path
place buildable tiles around path
place blocked tiles
run validator
retry on failure
```

### Test

- Same seed gives same map.
- Different seed gives different map.
- 20 generated seeds are playable.

### Acceptance criteria

```text
Generator never knowingly outputs invalid map.
Generated maps are saved as MapDef.
Run summary records generated map seed.
```

---

## Iteration E3 — Map Shape Templates

### Goal

Make generated maps strategically different.

Templates:

```text
straight pressure
long snake
spiral
split lane
crossroads
island build zones
narrow choke
wide road
```

### Test

- Each template creates distinct placement decisions.
- Wave difficulty does not become wildly unfair.

### Acceptance criteria

```text
MapDef records shape template.
Daily/challenge seeds can force template.
```

---

## Iteration E4 — Special Tile Placement

### Goal

Make maps part of build identity.

Tiles:

```text
high ground: +range
mana tile: faster abilities
growth tile: scaling over waves
cracked tile: strong but may break
corrupted tile: strong but risky
portal tile: enemy branch risk
```

### Test

- Special tiles are readable.
- Player can inspect tile effect.
- Generator does not place too many.

### Acceptance criteria

```text
Special tiles affect placement decisions.
Special tiles are balanced by rarity and risk.
```

---

## Iteration E5 — Map Editor MVP

### Goal

Create and test maps in-game.

Build:

```text
paint path
paint buildable
paint blocked
place spawn
place core
place special tile
validate
save
load
test play
```

### Test

- Create a map from blank.
- Validate it.
- Save it.
- Load it.
- Play it.

### Acceptance criteria

```text
Editor uses same MapDef as generator.
Editor cannot silently save broken maps without warning.
```

---

# Milestone F — Arena / Legion Mode Later

Do not start this yet.

Arena mode should come after:

- growth model is chosen
- co-op board model works locally
- economy is stable
- wave counters are readable
- content validator exists

When ready, build it as a separate mode:

```text
Survival Mode
Co-op Survival Mode
Rival Storm / Arena Mode
```

Arena mode should use:

```text
parallel boards
pressure resource
send attackers
income vs defense vs attack choices
build-based attacker echoes
```

Do not mix arena rules into the core survival mode too early.

---

# The Most Impactful Next 20 Claude Iterations

This is the recommended order from the current project state.

```text
A1. Growth Mode Flag
A2. Unit Instance Identity
A3. Classic Upgrade Prototype
A4. Duplicate Shard System
A5. Star Upgrade Prototype
A6. Evolution Choice Prototype
A7. Shop Duplicate Bias
A8. Growth Bake-Off Report

C1. Shop Card Clarity
C2. Unit Inspect Panel
C3. Upcoming Wave Preview
C4. Combat Readability Pass
C5. Run Summary 2.0

B1. Multi-Board Debug Mode
B2. Synced Phases
B3. Local Shield + Shared Team Heart
B4. Aid Tokens
B5. Co-op Draft Moment
B6. Co-op Merge Interaction

E1. Map Validator First
E2. Simple Seeded Generator
```

After these 20, choose the next direction based on playtesting:

```text
If growth feels amazing -> add content packs built around evolutions.
If co-op feels amazing -> improve local co-op UI and then consider networking.
If maps feel stale -> continue E3-E5 map generation/editor work.
If players are confused -> continue UI/readability before more systems.
```

---

# What Claude Should Not Do Without Permission

```text
Do not add 50+ new units at once.
Do not implement online networking yet.
Do not build a complex map editor before map validator exists.
Do not hardcode unit evolution logic in scripts if it can be data-driven.
Do not add new FX that obscure enemies or path tiles.
Do not let duplicate merging bypass economy balance.
Do not make co-op a single shared board unless explicitly testing that mode.
Do not remove the existing TD placement strategy.
```

---

# Claude Prompt Template — Next Iteration

Use this for every next step:

```text
Read:
- docs/co_op_roguelike_td_design_doc.md
- docs/shardstorm_td_content_bible.md
- docs/shardstorm_td_research_engagement_addendum.md
- docs/shardstorm_td_next_roadmap_addendum.md
- docs/decisions.md

Implement iteration [A1/B1/C1/etc.]: [iteration name].

Goal:
[one sentence]

Constraints:
- Keep the system data-driven.
- Preserve current single-player run functionality.
- Use existing command/action architecture where possible.
- Use SessionRng for randomness.
- Add debug UI or a test scene so I can verify the feature.
- Update docs/decisions.md.
- Do not implement future milestones unless they are required for this iteration.

Acceptance criteria:
[paste from the selected iteration]

Manual test checklist:
[paste from the selected iteration]

After implementation, report:
1. Files changed.
2. Data/schema changes.
3. How to test in Godot.
4. Known limitations.
5. Suggested next iteration.
```

---

# Specific Next Prompt to Give Claude

Start with this:

```text
Read the design docs and implement Iteration A1: Growth Mode Flag.

Goal:
Add a configurable growth_mode to RunConfig so we can test classic upgrades, merge stars, and merge evolution hybrid without committing to one yet.

Growth modes:
- classic_upgrade
- merge_stars
- merge_evolution_hybrid

Acceptance criteria:
- RunConfig stores growth_mode.
- Debug/new-run UI can choose growth_mode.
- The selected growth_mode is visible during a run.
- Run summary records growth_mode.
- Existing gameplay still works in the default mode.
- No actual upgrade/merge logic is required yet beyond plumbing.

Manual test:
1. Start a run in classic_upgrade mode.
2. Confirm UI shows classic_upgrade.
3. End run and confirm summary records classic_upgrade.
4. Repeat for merge_stars and merge_evolution_hybrid.
5. Confirm existing placement/combat/shop still works.

Constraints:
- Keep this as plumbing only.
- Do not implement the full upgrade system yet.
- Update docs/decisions.md with the reason for adding growth_mode.
```

---

# Final Recommendation

The most impactful road is:

```text
1. Decide unit growth by testing it, not debating it.
2. Use merge/evolution hybrid as the likely target.
3. Make UI readable enough to support that complexity.
4. Build local/debug co-op before online co-op.
5. Return to procedural maps after the growth/co-op loop is clearer.
6. Add content only in coherent packs with counters and challenges.
```

The next big design bet should be:

> The game is a tower defense where units are not disposable towers; they are drafted Duelyst characters that become run-defining carries, supports, monsters, or cursed experiments through merging and evolution.

That gives the project a stronger identity than either normal TD upgrades or pure autobattler merging alone.
