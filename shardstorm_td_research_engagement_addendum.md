# Shardstorm TD - Research-Backed Engagement and Iteration Addendum

Companion docs:

- `co_op_roguelike_td_design_doc.md`
- `shardstorm_td_content_bible.md`

Purpose:

This document turns game-design research, MOBA/tower-defense genre lessons, and current hybrid TD trends into **missing puzzle pieces** that Claude Code can continuously iterate on.

The project constraint remains unchanged:

> Visible and audible content should come from Duelyst/OpenDuelyst assets wherever possible. The innovation should come from systems, recombination, pacing, modes, data, balance, and player-facing feedback rather than new art production.

---

## 0. The Big Missing Layer

The existing design docs describe the game object: units, waves, maps, pacts, co-op structure, content pipeline.

The missing layer is the **engagement engine**:

```text
Why does the player come back after 5 runs?
Why after 50 runs?
Why after 500 runs?
What do players talk about?
What do they try to master?
What do they show off?
What can Claude keep adding forever without breaking the core?
```

The answer should not be “more units.”

The answer should be:

```text
same ritual + new puzzle + visible mastery + social comparison + personal build identity + readable failure + safe experimentation
```

That is the shared feeling behind old Warcraft III custom maps, Dota, Legion TD, Chaos TD, auto-battlers, roguelike deckbuilders, and long-lived PvP games.

---

## 1. Research Translation

### 1.1 MDA: design from desired feelings, not only mechanics

**Source idea:** MDA separates Mechanics, Dynamics, and Aesthetics. Designers create mechanics, but players experience dynamics and feelings.

**Translation for this game:**

Do not ask only:

```text
What does this unit do?
```

Ask:

```text
What feeling does this produce?
```

Required target feelings:

```text
calm planning
smart greed
dread before wave start
combo satisfaction
panic when the wave slips through
relief after recovery
curiosity at the next draft
```

Every feature Claude adds should state its target aesthetic.

Example:

```text
Feature: Debt enemies return after leaks.
Mechanic: leaked enemies become marked and reappear later.
Dynamic: leaking is not just damage; it creates future pressure.
Aesthetic: dread, guilt, comeback tension.
```

### 1.2 Self-Determination Theory / PENS: long engagement needs autonomy, competence, relatedness

**Source idea:** player enjoyment and future play are strongly related to autonomy, competence, and relatedness.

**Translation for this game:**

| Need | Shardstorm implementation |
|---|---|
| Autonomy | Draft choices, pact choices, map path choices, multiple valid builds, optional risk modes |
| Competence | clear counters, death recap, run summary, mastery badges, better tools as player learns |
| Relatedness | co-op saves, shared pacts, daily seeds, build sharing, community maps, score comparisons |

Do not rely on grind. Make the player feel:

```text
I chose this.
I understand why it worked or failed.
I can compare this run with friends.
```

### 1.3 GameFlow: challenge, feedback, control, clear goals

**Source idea:** player enjoyment is tied to concentration, challenge, skill, control, clear goals, feedback, immersion, and social interaction.

**Translation for this game:**

The game needs these specific feedback tools:

```text
wave preview
threat estimate
lane heatmap
unit contribution screen
leak explanation
draft offer explanation
map danger overlay
post-run build identity summary
```

If the player loses and says “I have no idea what happened,” the run is not doing its job.

### 1.4 MOBA lessons: mastery, teamwork, competition, and metagame

**Source idea:** MOBA engagement is heavily shaped by competition, mastery, teamwork, and the metagame around the game.

**Translation for this game:**

Shardstorm needs:

```text
mastery paths per unit and faction
recognizable roles
team-saving moments
leaderboards and daily seeds
build names
a codex that teaches counters and synergies
patch notes that intentionally shift the meta
```

The metagame is not optional. Even for a solo/co-op TD, players should be able to talk in shorthand:

```text
“Vanar frost debt build”
“Magmar egg greed opener”
“Abyssian leak economy”
“Lyonar wall comp”
“Vetruvian beam maze”
```

### 1.5 Riot design lessons: clarity, counterplay, and mastery display

**Source idea:** competitive games must make threats readable, give players useful responses, and let players express long-term skill growth.

**Translation for this game:**

Every enemy, boss, wave mod, and pact needs:

```text
one readable warning
one understandable counter
one post-failure explanation
```

Bad design:

```text
Enemy randomly ignores towers and leaks.
```

Good design:

```text
Phasing enemy glows blue for 2 seconds, then ignores blockers for 4 tiles.
Counters: slow, silence, reveal, burst before phase.
Death recap: 8 Phasing enemies leaked because no reveal/slow was active near lane 2.
```

### 1.6 Tower defense research/trends: generated content is not enough; validation and tactic discovery matter

**Source idea:** TDs benefit from procedural levels and waves, but generated content must be tested, validated, and analyzed. Recent TD hybrids often combine roguelike structure, deck/draft systems, tile placement, co-op/action, and procedural boards.

**Translation for this game:**

The map generator must be paired with:

```text
map validator
wave validator
simulated bot testing
run telemetry
strategy classifier
balance reports
```

Claude should not only add content. Claude should also add tools that answer:

```text
Which builds are winning?
Which waves kill players?
Which units are never chosen?
Which map seeds are unfair?
Which tactics are emerging?
```

---

## 2. The Long Engagement Model

Shardstorm should be designed around seven retention pillars.

### Pillar 1: The Ritual

The player should always know the loop:

```text
draft -> place -> prepare -> wave -> panic/joy -> rewards -> summary -> draft
```

This repetition should be comforting.

Do not change the ritual too much between modes. Change what happens inside the ritual.

### Pillar 2: Build Identity

Every run should get a name automatically.

Examples:

```text
Frost Debt Fortress
Abyssian Sacrifice Swarm
Lyonar Banner Wall
Vetruvian Beam Bazaar
Magmar Egg Economy
Songhai Lightning Roulette
```

The game should generate this from tags:

```text
dominant_faction
primary_damage_type
primary_strategy
risk_profile
special_pact
map_trait
```

### Pillar 3: Mastery Without Boredom

A player should get better by learning:

```text
wave counters
unit timings
path shapes
economy greed limits
faction synergies
pact risk
boss mechanics
```

The game should avoid permanent raw stat upgrades early. They make the player wonder if they won because they were smart or because the account got stronger.

Better meta progression:

```text
new units
new traits
new pacts
new maps
new enemy families
new challenge modes
cosmetics/profile badges using Duelyst frames/icons
starting draft variants
```

### Pillar 4: Meaningful Failure

Losses should say:

```text
You almost had it.
Here is what killed you.
Here is what would have helped.
Try again with a different answer.
```

Required systems:

```text
wave death recap
leak timeline
unit contribution graph
biggest threat list
counter suggestions
seed retry button
```

### Pillar 5: Social Comparison

Even before online co-op, the game needs social surfaces:

```text
daily seed
weekly challenge
shareable run code
leaderboard per seed
faction badges
weird build awards
community map code
```

This gives the game a metagame without requiring a finished multiplayer backend.

### Pillar 6: Patchable Meta

Long-lived strategy games survive by changing enough to reopen discovery without destroying trust.

Shardstorm should have content packs like:

```text
Storm Season 1: Frost Debt
- +8 Vanar units mapped
- +3 frost traits
- +2 wave mods
- daily seed ladder
- balance pass: slows less stackable, brittle stronger

Storm Season 2: Abyssian Choir
- sacrifice units
- death-trigger relics
- new boss
- co-op rescue pact
```

Claude should support this by keeping all content data-driven.

### Pillar 7: Player-Created Content

The map editor is not just a tool. It is a retention system.

Required long-term path:

```text
create map
validate map
simulate map
publish map code
rate map
play daily community map
feature weird maps
```

---

## 3. Missing Puzzle Pieces To Add To The Main Design Docs

These are the highest-value missing sections to give Claude.

---

# Puzzle Piece A: Player Motivation Matrix

Add this to the design docs.

## Goal

Make sure features serve different player types without making separate games.

## Player types

| Player type | Wants | Systems to support |
|---|---|---|
| Optimizer | best build, clean math, high score | detailed stats, seed retry, leaderboards, DPS breakdown |
| Experimenter | weird combos, surprise, mutations | pacts, relics, traits, unstable units, sandbox mode |
| Greeder | risk economy, late payoff | interest, eco units, debt leaks, bonus wave pressure |
| Collector | unlocks, unit identity, mastery | unit mastery, codex, faction badges, alternate variants |
| Social player | team saves, stories, blame, clutch | co-op pacts, assist portals, pings, run recap cards |
| Builder | maps, custom rules, creative layouts | map editor, tile palette, publishable seeds, validator |
| Competitor | ranked/arena/daily ladder | Rival Storm, daily seed, score rules, fair scoring |

## Claude task

Implement `PlayerMotivationTag` and let content declare which motivations it serves.

Example:

```json
{
  "id": "blood_dividend",
  "motivation_tags": ["greeder", "experimenter"],
  "risk_level": 4
}
```

---

# Puzzle Piece B: Aesthetic Target Table

## Goal

Every major system must declare what emotion it creates.

## Table

| Emotion | Mechanics that create it | Anti-pattern |
|---|---|---|
| Comfort | repeated loop, predictable phase timing | too much random interruption |
| Curiosity | draft offers, pacts, new tile mods | all choices are stat bumps |
| Dread | boss warnings, unstable map, debt enemies | surprise one-shots |
| Greed | interest, eco units, optional enemy sends | mandatory greed meta |
| Relief | emergency saves, clutch leaks, shield recovery | no comeback tools |
| Pride | run title, badges, mastery stats | pure grind rewards |
| Social tension | shared pacts, aid requests, ally saves | one player controls everyone |

## Claude task

Add an `aesthetic_tags` array to all major content definitions:

```json
{
  "id": "mirror_war",
  "aesthetic_tags": ["dread", "curiosity", "pride"]
}
```

Then create debug filters:

```text
show all content tagged greed
show all content tagged dread
show all content tagged relief
```

This helps you see if the content library is emotionally lopsided.

---

# Puzzle Piece C: The Strategy Triangle

## Goal

The game needs a simple counter grammar that players can learn forever.

## Core triangle

```text
Swarm beats over-specialized single target.
Armor beats low-damage spam.
Burst beats elites and bosses.
Control beats speed and assassins.
Siege/AoE beats clumps.
True damage/status beats defensive gimmicks.
Economy beats easy waves but loses to pressure spikes.
```

## Enemy counters

| Enemy pressure | Player answer |
|---|---|
| Swarm | splash, chain, poison, death explosions |
| Heavy armor | magic, true damage, armor shred |
| Fast runners | slow, stun, early targeting, long lanes |
| Shielded enemies | multi-hit, dispel, delayed burst |
| Regenerators | poison, focus fire, anti-heal |
| Splitters | controlled AoE, cleanup units |
| Phasers | reveal, silence, burst window |
| Boss | single-target scaling, armor shred, debuff uptime |

## Claude task

Create `CounterProfileDef`:

```json
{
  "id": "fast_runner",
  "threat_tags": ["speed", "leak_risk"],
  "recommended_answers": ["slow", "stun", "early_targeting", "long_lane"],
  "ui_warning": "Fast enemies punish short lanes and slow openers."
}
```

Use it in wave previews and death recaps.

---

# Puzzle Piece D: Timing Windows

## Goal

Long engagement in Dota/Legion-style games comes from timing knowledge.

Players should learn:

```text
I need anti-swarm before wave 4.
I need boss damage before wave 8.
I can greed if wave 6 is weak.
I must stop greeding before wave 10.
This unit is an early carry.
This unit is a late scaler.
```

## Add timing identities

Every unit should have a timing identity:

```text
early_hold
midgame_spike
late_scaler
boss_killer
economy_greed
panic_button
support_enabler
```

Every wave should have a pressure timing:

```text
check_swarm
check_armor
check_boss_damage
check_speed
check_control_resistance
check_economy_punish
```

## Claude task

Add fields:

```json
{
  "unit_timing": "late_scaler",
  "wave_pressure_check": "check_swarm"
}
```

Then add wave preview text:

```text
Wave 7 checks swarm cleanup. Your current build has weak AoE coverage.
```

---

# Puzzle Piece E: Run Identity Engine

## Goal

Turn each run into a story and a shareable object.

## Required output after every run

```text
Run Name: Frost Debt Fortress
Dominant Faction: Vanar
Build Tags: slow, brittle, shields, debt
Greed Score: 72/100
Clutch Moment: Wave 9, 1 Heart remaining
Biggest Carry: Crystal Cloaker, 31% total damage
Biggest Mistake: No anti-armor answer before Wave 12
Unlocked: Frost Debt badge, Bronze
Seed: SHARD-48391
```

## Claude task

Implement `RunIdentityAnalyzer`.

Inputs:

```text
units bought
traits chosen
pacts chosen
wave results
damage dealt
leaks
rerolls
gold floated
map theme
```

Outputs:

```text
run_name
build_tags
summary_card
share_code
badge_progress
```

---

# Puzzle Piece F: Death Recap / Failure Coach

## Goal

Make failure readable and motivating.

## Death recap modules

```text
1. What killed you?
2. When did the run turn bad?
3. What counter was missing?
4. Which unit underperformed?
5. Which draft offer might have helped?
6. Retry same seed / new seed.
```

Example:

```text
You lost to Wave 11: Ironbound March.
Main problem: armored enemies survived too long.
Your build had high physical damage but no armor shred or magic damage.
Best performing unit: Sunstone Templar.
Lowest value unit: Bloodtear Alchemist.
Suggested counters: armor_shred, magic_beam, poison, boss_focus.
```

## Claude task

Implement `FailureCoach` using already-logged wave and unit stats. Keep advice rule-based at first.

---

# Puzzle Piece G: Unit Mastery Without Stat Inflation

## Goal

Let players attach to Duelyst units without making balance impossible.

## Mastery model

```text
Mastery XP comes from using a unit.
Mastery does not increase raw damage/HP in normal runs.
Mastery unlocks knowledge, variants, cosmetics, and challenge starts.
```

## Mastery rewards

| Mastery level | Reward |
|---|---|
| 1 | codex entry and basic tips |
| 2 | alternate trait can appear |
| 3 | unit-specific challenge seed |
| 4 | cosmetic card frame / banner |
| 5 | risky evolution appears in draft pool |
| 6 | title: “Windblade Adept Specialist” |

## Claude task

Create `UnitMasteryDef` and `UnitMasteryProgress`.

Do not add permanent +damage unlocks unless explicitly enabled by a mode flag.

---

# Puzzle Piece H: Codex As Skill Tree

## Goal

The codex should not just list content. It should teach mastery.

## Codex pages

```text
Unit page
- role
- timing
- counters
- best traits
- common mistakes
- mastery progress
- sample builds

Enemy page
- warning icon
- what it does
- counters
- waves seen
- leak damage

Faction page
- identity
- early/mid/late plan
- common synergies
- weakness

Pact page
- risk rating
- best builds
- hidden dangers
```

## Claude task

Build the codex from data fields rather than hand-written pages only.

---

# Puzzle Piece I: Greed and Tempo System

## Goal

Recover the joy of Legion TD / Dota custom map economy pressure.

## Core concept

The player should constantly ask:

```text
Can I greed one more wave?
Do I need to stabilize now?
Can I leak safely?
Will this eco unit pay off before the next boss?
```

## Add Greed Score

Track:

```text
gold floated
interest earned
eco units bought
rerolls skipped
optional pressure accepted
leaks taken intentionally
waves cleared with low margin
```

## Economy mechanics

### Interest

```text
At wave start, gain +1 gold per 10 unspent gold, up to a cap.
```

### Bounty pressure

```text
Optional wave modifier: +20% enemy count, +2 reward gold.
```

### Debt leaks

```text
Leaking may preserve immediate resources but creates future debt enemies.
```

### Eco units

```text
Weak combat units that generate gold if placed early or if conditions are met.
```

## Claude task

Implement `GreedTracker` and show a post-wave Greed/Tempo readout.

---

# Puzzle Piece J: Patchable Content Packs

## Goal

Make Claude able to add content in coherent bundles.

## Content pack format

```json
{
  "id": "season_frost_debt",
  "display_name": "Frost Debt",
  "enabled": true,
  "units": [],
  "traits": [],
  "pacts": [],
  "waves": [],
  "bosses": [],
  "map_modifiers": [],
  "balance_overrides": [],
  "daily_seed_rules": []
}
```

## Design rule

Each pack should have:

```text
one new build archetype
one counter-archetype
one boss or wave check
one map modifier
one challenge seed
one balance risk note
```

## Claude task

Create a `ContentPackDef` loader and a debug menu to enable/disable packs.

---

# Puzzle Piece K: Daily Seed / Weekly Challenge

## Goal

Create social comparison without multiplayer.

## Daily Seed rules

```text
same seed for everyone
fixed draft order or controlled random pool
same map/waves/pacts
scoreboard categories
one restart allowed category and unlimited restart category
```

## Score categories

```text
highest wave
core health remaining
gold efficiency
fewest leaks
fastest clear
weirdest winning build
faction-specific score
```

## Weekly Challenge examples

```text
Vanar only
No selling
All enemies +20% speed
Start with Blood Dividend pact
Generated map has two cores
Draft offers only flawed units
```

## Claude task

Add `ChallengeRuleDef` and local scoreboard storage first. Online leaderboard can come later.

---

# Puzzle Piece L: Visual Clarity Law

## Goal

Duelyst assets are beautiful but busy. TDs die when players cannot read threats.

## Law

At combat zoom, the player must instantly read:

```text
where enemies are
which enemies are dangerous
what my units are targeting
why something leaked
which effects are cosmetic vs gameplay
```

## Rules

```text
Gameplay VFX beats cosmetic VFX.
Enemy warning icons beat faction flavor.
Elite outlines must be consistent.
Boss telegraphs must be bigger than normal attacks.
Status icons must be limited and grouped.
Damage numbers are optional; leak and boss warnings are mandatory.
```

## Claude task

Add `ClarityProfileDef`:

```json
{
  "id": "elite_fast",
  "outline": "yellow",
  "icon": "speed_boot",
  "warning_sfx": "sfx_warning_fast",
  "priority": 80
}
```

Use priority to suppress low-priority VFX when the screen is crowded.

---

# Puzzle Piece M: Co-op Role System

## Goal

Prepare co-op around complementary roles, not just more players.

## Co-op roles

| Role | Job | Systems |
|---|---|---|
| Holder | survives hard lanes | shields, walls, guardians |
| Greeder | invests for late team payoff | eco units, taunt, bounty waves |
| Controller | slows/stuns dangerous waves | Vanar/control units |
| Cleaner | swarm/AoE specialist | Abyssian/Magmar AoE |
| Boss Killer | single-target scaling | Songhai/Lyonar burst |
| Support | sends aid, buffs allies | portals, shared relics |

## Claude task

Add role tags to units and run summary:

```text
Team lacked: Boss Killer.
Player 2 acted as: Greeder / Controller.
Player 1 saved allies 4 times.
```

Even in single-player, this helps the game diagnose build gaps.

---

# Puzzle Piece N: Threat Director

## Goal

Make waves feel responsive without feeling unfair.

## Threat Director inputs

```text
player build tags
recent leaks
dominant damage type
lack of counters
greed score
wave number
map difficulty
chosen pacts
```

## Outputs

```text
wave modifier choices
elite type
bonus reward pressure
warning text
boss preparation hint
```

## Rule

Never hard-counter the player without warning.

Good:

```text
You have leaned heavily into slows. The storm is adapting: next wave has Frost-Resistant elites. Reward +2 gold.
```

Bad:

```text
All enemies are suddenly slow immune and you lose.
```

## Claude task

Build `ThreatDirector` as a transparent weighted system. Log every reason a wave mod was chosen.

---

# Puzzle Piece O: Automated Playtesting Harness

## Goal

Claude should be able to generate and test content without relying entirely on your manual playtime.

## Bot levels

```text
Bot 0: random legal placement
Bot 1: cheapest valid unit placement
Bot 2: range/value heuristic
Bot 3: counter-aware heuristic
Bot 4: greedy heuristic
```

## Test outputs

```text
seed
map id
wave reached
units bought
gold spent
damage by unit
leaks by wave
boss time-to-kill
crash/errors
balance warnings
```

## Claude task

Create a headless simulation mode:

```text
simulate 100 seeds using Bot 2
output balance_report.json
```

Minimum viable report:

```json
{
  "seeds_tested": 100,
  "median_wave_reached": 9,
  "p90_wave_reached": 13,
  "unwinnable_seeds": [123, 891],
  "overperforming_units": ["ironcliffe_guardian"],
  "underpicked_units": ["bloodtear_alchemist"]
}
```

---

# Puzzle Piece P: Tactic Discovery / Build Classifier

## Goal

Find emergent builds instead of guessing.

## Build tags to classify

```text
slow_stack
summon_swarm
high_armor
single_target_burst
chain_lightning
poison_dot
greed_economy
leak_debt
wall_maze
boss_rush
random_mutation
```

## Claude task

Implement `BuildClassifier`:

```text
Read run logs.
Assign build tags.
Compare win rate by build tag.
Print top 5 builds and bottom 5 builds.
```

This becomes the balancing dashboard.

---

# Puzzle Piece Q: Build Sharing

## Goal

Let players turn a run into something communicable.

## Share card contents

```text
Run Name
Seed
Map theme
Final wave
Core health
Top 5 units
Pacts
Traits
Greed score
Damage pie
Screenshot
Share code
```

## Claude task

Create a `RunShareCard` scene using Duelyst UI frames/card backgrounds.

No online sharing needed at first. Just save an image locally.

---

# Puzzle Piece R: Mode Shelf

## Goal

Do not make one mode do everything. Create a shelf of modes using the same systems.

## Recommended modes

### 1. Standard Run

```text
Main roguelike TD run.
```

### 2. Daily Storm

```text
Same seed for all players.
Score comparison.
```

### 3. Puzzle Defense

```text
Hand-authored tiny challenge.
Fixed units and fixed wave.
```

### 4. Draft Lab

```text
Fast testing mode.
Choose faction/pact and fight 5 waves.
```

### 5. Endless Collapse

```text
Post-win score chase.
Map becomes increasingly unstable.
```

### 6. Community Map Gauntlet

```text
Play validated user maps.
```

### 7. Rival Storm

```text
Legion-inspired arena mode.
```

## Claude task

Implement `GameModeDef` as data, not hard-coded scenes.

---

# Puzzle Piece S: Onboarding That Does Not Kill Discovery

## Goal

Teach the player without making the game sterile.

## Onboarding path

```text
Run 1: basic placement, path, core, gold
Run 2: draft offers and unit roles
Run 3: traits/flaws
Run 4: pacts
Run 5: generated maps and tile mods
Run 6: boss mechanics
```

## Rule

Tutorials should unlock understanding, not content power.

## Claude task

Add `TutorialHintDef`:

```json
{
  "id": "first_fast_wave_hint",
  "trigger": "wave_preview_has_tag:speed",
  "condition": "player_has_no_tag:slow",
  "message": "Fast enemies punish short lanes. Consider slows, early targeting, or longer path coverage."
}
```

---

# Puzzle Piece T: Ethical Retention Rules

## Goal

Long engagement should come from mastery and creativity, not coercive habits.

## Rules

```text
No daily login pressure in core design.
No hidden punishment for not playing.
No pay-to-win assumptions.
No grind-only power creep.
No random reward that hides core probabilities.
No dark-pattern timers.
```

Good retention:

```text
I want to try a new build.
I want to beat my seed score.
I want to see what this pact does.
I want to show my friend this map.
```

Bad retention:

```text
I must log in because I will miss currency.
I must grind because numbers are too low.
```

## Claude task

Add this section to `docs/design_values.md` and make Claude check new systems against it.

---

## 4. Concrete Systems Claude Should Add Next

This section is a practical backlog.

---

## Track 1: Run Logging Foundation

### Why

Every long-engagement feature depends on logs.

### Implement

```text
RunLog
WaveLog
UnitPerformanceLog
EconomyLog
DraftLog
LeakLog
PactLog
MapLog
```

### Acceptance criteria

```text
After a run, a JSON log is saved.
The log contains seed, map, waves, units, damage, leaks, gold, pacts, and result.
The log can be loaded by a debug viewer.
```

### Claude prompt

```text
Implement the Run Logging Foundation from shardstorm_td_research_engagement_addendum.md.
Keep it deterministic and data-driven.
Add a debug panel to export and view the current run log.
Do not change combat balance.
Update docs/decisions.md.
```

---

## Track 2: Run Identity Analyzer

### Implement

```text
BuildClassifier
RunNameGenerator
RunSummaryCard
```

### Acceptance criteria

```text
After a run, game displays a generated run name.
Top tags are shown.
Top unit and biggest threat are shown.
Summary is derived from RunLog.
```

---

## Track 3: Failure Coach

### Implement

```text
DeathRecapPanel
CounterSuggestionRules
WaveFailureAnalyzer
```

### Acceptance criteria

```text
On loss, game explains main cause.
At least 5 failure causes are supported:
- too little AoE
- too little boss damage
- no slow/control
- armor counter missing
- greed too high
```

---

## Track 4: Counter Profiles

### Implement

```text
CounterProfileDef
ThreatTags
WavePreviewWarnings
EnemyCodexCounterSection
```

### Acceptance criteria

```text
Enemy data includes threat tags.
Wave preview shows at least one warning.
Death recap can reference missing counters.
```

---

## Track 5: Timing Identities

### Implement

```text
UnitTimingTag
WavePressureCheck
TimingHintUI
```

### Acceptance criteria

```text
Each unit has early/mid/late/economy/boss/support timing tag.
Each wave declares what it checks.
UI can warn when build lacks the next check.
```

---

## Track 6: Greed Tracker

### Implement

```text
GreedScore
TempoScore
InterestSystem
OptionalBountyPressure
```

### Acceptance criteria

```text
Player can earn interest.
Game tracks greed score.
Post-wave UI shows greed/tempo summary.
Greed can be disabled by config.
```

---

## Track 7: Codex Skill Tree

### Implement

```text
CodexScene
UnitCodexPage
EnemyCodexPage
FactionCodexPage
PactCodexPage
```

### Acceptance criteria

```text
Codex reads from data.
At least 12 units, 8 enemies, 6 factions, and 5 pacts have pages.
Pages include counters and common mistakes.
```

---

## Track 8: Daily Seed

### Implement

```text
DailySeedGenerator
ChallengeRuleDef
LocalScoreboard
ScoreFormula
```

### Acceptance criteria

```text
Today’s seed is deterministic by date.
Player can run Daily Storm.
Local scores are stored.
Score formula is visible.
```

---

## Track 9: Content Pack Loader

### Implement

```text
ContentPackDef
PackEnableDebugMenu
BalanceOverrideDef
```

### Acceptance criteria

```text
Content can be grouped into packs.
Packs can be enabled/disabled in debug.
Disabled pack content does not appear in drafts/waves.
```

---

## Track 10: Simulated Playtesting

### Implement

```text
HeadlessRunSimulator
BotPlayerHeuristic
BalanceReportGenerator
```

### Acceptance criteria

```text
Can simulate 10 seeds from debug button.
Can simulate 100 seeds from command line.
Outputs median wave reached and unit pick/win rates.
```

---

## Track 11: Clarity Profiles

### Implement

```text
ClarityProfileDef
VfxPriorityManager
EliteOutlineSystem
ThreatIconLayer
```

### Acceptance criteria

```text
Elite enemies have consistent readable markers.
Boss warnings suppress low-priority cosmetic effects.
Fast/armored/phasing enemies have distinct icons.
```

---

## Track 12: Share Card

### Implement

```text
RunShareCardScene
SaveShareCardImage
ShareCodeGenerator
```

### Acceptance criteria

```text
After a run, player can save a summary card image.
Card uses Duelyst UI/card frame assets.
Card includes seed, build name, wave, top unit, pacts, and score.
```

---

## 5. Design Hypothesis Cards

Claude should add or update one hypothesis card per major feature.

Template:

```text
HYPOTHESIS ID:
Feature:
Target player motivation:
Target aesthetic:
Expected effect:
Metric to watch:
Failure sign:
Rollback plan:
```

Examples:

### H001 - Run names increase replay memory

```text
Feature: RunIdentityAnalyzer
Target motivation: competence, social comparison
Target aesthetic: pride, curiosity
Expected effect: players remember and share runs more easily
Metric to watch: share-card usage, seed retry rate
Failure sign: names feel random or inaccurate
Rollback plan: improve tag weighting, allow manual rename later
```

### H002 - Greed score creates Legion-style tension

```text
Feature: GreedTracker + interest
Target motivation: autonomy, mastery
Target aesthetic: greed, dread, pride
Expected effect: players intentionally take economic risks
Metric to watch: average gold floated, leak timing, win rate by greed score
Failure sign: greed is always correct or always wrong
Rollback plan: adjust interest cap and bounty pressure
```

### H003 - Death recap reduces frustration

```text
Feature: FailureCoach
Target motivation: competence
Target aesthetic: relief, determination
Expected effect: losses feel understandable and replayable
Metric to watch: same-seed retry after loss
Failure sign: advice is wrong or obvious
Rollback plan: simplify to factual recap before giving advice
```

### H004 - Daily seed creates metagame before multiplayer

```text
Feature: Daily Storm
Target motivation: relatedness, competition
Target aesthetic: pride, rivalry
Expected effect: players compare scores and builds
Metric to watch: daily mode repeats, score improvements
Failure sign: score formula feels opaque
Rollback plan: show score breakdown and alternate categories
```

---

## 6. The “Old Custom Map” Feeling Checklist

A feature should score well on this checklist before becoming a priority.

```text
Does it create table-talk?
Does it create a build name?
Does it make greed possible?
Does it create a timing window?
Does it create a counter players can learn?
Does it let players recover from a mistake?
Does it make failure understandable?
Does it work with reused Duelyst assets?
Does it add content through data?
Does it support solo now and co-op later?
```

High-scoring examples:

```text
Daily seed
Run identity analyzer
Death recap
Greed tracker
Pacts
Threat director
Community maps
Co-op assist portals
```

Low-scoring examples:

```text
+5% account-wide damage
one-off hand-made cutscene
unreadable random enemy immunity
new art-only skin system
complex multiplayer before solo is fun
```

---

## 7. Balance Philosophy

### 7.1 Do not overbalance the fun out

Long-lived strategy games need discovery. Some combinations should feel temporarily outrageous.

Allowed:

```text
rare broken-feeling synergies
high-risk high-reward builds
seed-specific weird solutions
power spikes that players can plan around
```

Not allowed:

```text
one build is always best
one faction cannot win
unreadable enemy counters
mandatory meta progression stats
```

### 7.2 Balance around counters, not sameness

Bad balance:

```text
Every unit has similar DPS.
```

Good balance:

```text
Some units are bad alone but excellent in a build.
Some units solve one wave type but fail another.
Some units are early stabilizers.
Some units are late greed payoffs.
```

### 7.3 Balance around timing

Use timing windows:

```text
Wave 3 checks basic damage.
Wave 5 checks speed control.
Wave 8 checks boss damage.
Wave 11 checks armor.
Wave 14 checks swarm cleanup.
Wave 16 checks full build coherence.
```

This makes runs learnable without making them identical.

---

## 8. Duelyst-Specific Reuse Strategy

### 8.1 Content multiplication without new art

Use the same Duelyst units in different content roles:

```text
base player unit
elite enemy
boss echo
summon token
map event apparition
pact manifestation
shop portrait
codex illustration
```

### 8.2 Variant creation tools

```text
scale
outline
tint
shader overlay
particle aura
shadow size
UI border
sound pitch
animation speed
```

### 8.3 Claude asset rule

If Claude cannot find the exact asset, it should create a placeholder asset profile with a clear TODO and keep the game running.

```json
{
  "asset_profile_id": "TODO_duelyst_asset_windblade_adept",
  "fallback_sprite": "placeholder_unit_lyonar",
  "todo": "Map to actual Duelyst sprite path during asset import pass."
}
```

### 8.4 Faction silhouette rule

Each faction should be readable by palette and VFX:

```text
Lyonar: gold/white/shields
Songhai: red/smoke/lightning
Vetruvian: sand/sun/beams
Abyssian: purple/black/souls
Magmar: orange/lava/bones
Vanar: blue/ice/crystals
Neutral: mixed/utility
```

---

## 9. Research-Inspired Source List

These are not tasks for Claude to implement directly. They are design lenses.

### Core game design theory

- Robin Hunicke, Marc LeBlanc, Robert Zubek - **MDA: A Formal Approach to Game Design and Game Research**  
  https://users.cs.northwestern.edu/~hunicke/MDA.pdf
- Jesse Schell - **The Art of Game Design: A Book of Lenses**  
  https://www.taylorfrancis.com/books/mono/10.1201/b17723/art-game-design-jesse-schell
- Katie Salen and Eric Zimmerman - **Rules of Play**  
  https://mitpress.mit.edu/9780262240451/rules-of-play/
- George Skaff Elias, Richard Garfield, K. Robert Gutschera - **Characteristics of Games**  
  https://mitpress.mit.edu/9780262017138/characteristics-of-games/
- Raph Koster - **A Theory of Fun for Game Design**  
  https://www.oreilly.com/library/view/theory-of-fun/9781449363208/
- David Sirlin - **Playing to Win**  
  https://www.sirlin.net/ptw

### Motivation and retention

- Richard M. Ryan, C. Scott Rigby, Andrew Przybylski - **The Motivational Pull of Video Games: A Self-Determination Theory Approach**  
  https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf
- PENS model overview  
  https://selfdeterminationtheory.org/player-experience-of-needs-satisfaction-pens/
- Penelope Sweetser and Peta Wyeth - **GameFlow: A Model for Evaluating Player Enjoyment in Games**  
  https://www.valuesatplay.org/wp-content/uploads/2007/09/sweetser.pdf
- **Creatability, achievability, and immersibility: New game design elements that increase online game usage**  
  https://www.sciencedirect.com/science/article/pii/S0268401223001135
- **Pathways to Mastery: A Taxonomy of Player Progression Systems in Commercial Video Games**  
  https://www.intechopen.com/chapters/1221745

### MOBA and competitive-game design

- **MOBA games: A literature review**  
  https://www.sciencedirect.com/science/article/pii/S1875952117300149
- **Motivational Profiling of League of Legends Players**  
  https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2020.01307/full
- **Mind the gap: Distributed practice enhances performance in a MOBA game**  
  https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0275843
- **Players’ continuous willingness to play in MOBA game ranking mode**  
  https://www.nature.com/articles/s41599-024-03934-1
- Riot - **Clarity in League**  
  https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/
- Riot - **Champion Counterplay**  
  https://www.leagueoflegends.com/en-us/news/dev/quick-gameplay-thoughts-may-14/
- Riot - **Updating Champion Mastery**  
  https://www.leagueoflegends.com/en-us/news/dev/dev-updating-champion-mastery/
- **Game updates enhance players’ engagement: a case of DOTA2**  
  https://dl.acm.org/doi/epdf/10.1145/3485190.3485209

### Tower defense, procedural content, and analytics

- **A Novel Procedural Content Generation Algorithm for Tower Defense Games**  
  https://dl.acm.org/doi/fullHtml/10.1145/3564982.3564993
- **Emergence of Player Tactics by expert-guided Machine Learning: An industry tower defence case study**  
  https://www.sciencedirect.com/science/article/pii/S1875952125000436
- **Procedural generation of levels for a tower defense game**  
  https://aaltodoc.aalto.fi/items/d4db6e73-5499-4d12-a42d-daa58b252683/full
- **Reinforcement Learning for High-Level Strategic Control in Tower Defense Games**  
  https://arxiv.org/abs/2406.07980
- **Procedural Content Generation in Games: A Survey with Insights on Emerging LLM Integration**  
  https://arxiv.org/abs/2410.15644

### Genre examples / trend references

- **Legion TD 2** - tactics, teamwork, prediction, multiplayer/single-player TD  
  https://steamcommunity.com/app/469600/
- **Rogue Tower** - roguelike TD, expanding path, card upgrades  
  https://store.steampowered.com/app/1843760/Rogue_Tower/
- **Isle of Arrows** - tile placement + TD + roguelike runs/events/modifiers  
  https://gridpop.co/isle/
- **Orcs Must Die! Deathtrap** - co-op action TD + roguelite progression  
  https://store.steampowered.com/app/2273980/Orcs_Must_Die_Deathtrap/

### Duelyst asset base

- OpenDuelyst GitHub repository  
  https://github.com/open-duelyst/duelyst
- Duelyst Animated Sprites for Godot  
  https://godotengine.org/asset-library/asset/1653

---

## 10. Recommended Next Claude Prompt

Use this prompt next:

```text
Read:
- docs/co_op_roguelike_td_design_doc.md
- docs/shardstorm_td_content_bible.md
- docs/shardstorm_td_research_engagement_addendum.md

Implement Track 1: Run Logging Foundation.

Rules:
- Do not rebalance combat.
- Do not add new art requirements.
- Keep all fields serializable.
- Log enough data for future RunIdentityAnalyzer, FailureCoach, GreedTracker, and BuildClassifier.
- Add a debug UI button to export the current run log.
- Add at least one sample exported log to docs/examples/run_log_example.json.
- Update docs/decisions.md.

Before coding, summarize:
1. files to modify
2. data structures to add
3. how logs will be saved
4. how this supports later engagement systems

After coding, summarize:
1. how to test
2. where the log is written
3. known limitations
```

---

## 11. Priority Order

Do these before more units.

```text
1. Run Logging Foundation
2. Counter Profiles + Wave Preview Warnings
3. Death Recap / Failure Coach
4. Run Identity Analyzer
5. Greed Tracker
6. Daily Seed
7. Unit Mastery / Codex
8. Simulated Playtesting Harness
9. Content Pack Loader
10. Share Card
```

Reason:

```text
More content without logs, feedback, counters, and identity will become noise.
More content after these systems becomes long-term engagement fuel.
```

---

## 12. Final Design Bet

The missing puzzle piece is not one feature.

It is the loop where every run becomes:

```text
readable puzzle
personal build
measurable mastery
shareable story
new experiment
```

That is how a tower defense game stops being “just waves” and starts feeling like an old custom-map obsession.
