# Shardstorm TD - Co-op, Multiplayer, and Arena Mode Addendum

This addendum defines how co-op, multiplayer, shared maps, and arena mode should work.

It is written for Claude Code as a practical design and implementation guide. The goal is not to lock the game into one final shape immediately. The goal is to build the right testable prototypes so the best version reveals itself through play.

---

## 0. Executive recommendation

Use this as the main co-op design:

```text
One shared world map
+ one shared central Core
+ one route per player
+ each player owns a defense zone
+ routes are visually connected
+ players can zoom out to see the whole battlefield
+ players can assist each other through limited, intentional systems
```

Call this topology:

```text
Starbase Co-op
```

This is stronger than a fully shared lane and stronger than totally separate boards.

Why:

```text
One shared lane:
+ easy to understand
+ very social
- alpha-player problem
- build-space arguments
- chaos with 3-4 players
- one good player can solve too much

Separate boards:
+ easy to implement
+ every player has agency
- feels like parallel solo games
- weak emotional co-op
- players do not naturally watch each other

Starbase Co-op:
+ every player has responsibility
+ one shared objective
+ easy to see who is in trouble
+ allows heroic saves
+ supports generated maps by player count
+ supports split-screen, online, and solo
+ keeps tower defense placement meaningful
```

The default co-op mode should be:

```text
Each player defends one route into a shared central Core.
Each route has its own enemy spawn and local Gate Shield.
If enemies leak through a route, they damage that route's Gate Shield first.
If the Gate Shield breaks, future leaks damage the shared Core.
Players can assist each other through aid tokens, central defense zones, bridge effects, and emergency breach events.
```

The experimental alternate mode should be:

```text
Labyrinth Raid
```

In Labyrinth Raid, all players defend one large, changing maze route together. This should not be the default, but it can become a challenge mode, boss mode, daily seed, or later co-op raid mode.

Arena mode should be a separate mode:

```text
Prism Clash
```

Prism Clash is a short-round PvP mode inspired by lane battlers. Players spend a timing-based resource to deploy Duelyst units into an arena. Rounds are best-of-5. Each round adds one new unit to the player's roster.

---

## 1. Design north star

The co-op game should feel like this:

```text
I have my lane.
You have your lane.
We are both defending the same Core.
I can see when you are in trouble.
I cannot play your game for you, but I can save you at the right moment.
Sometimes the map forces us to coordinate.
Sometimes the best play is greed.
Sometimes the best play is sacrifice.
Every run creates a story.
```

The arena game should feel like this:

```text
I know my small roster.
I watch your resource timing.
I bait your answer.
I send pressure at the right moment.
Between rounds I draft a new unit and adapt.
A match has a story arc instead of being one long fight.
```

---

## 2. Co-op topology options

Claude should support these topology types as data, but only the first one should be built now.

### 2.1 Starbase Co-op - recommended default

Structure:

```text
        Player 2 Spawn
              |
              v
Player 1 -> Shared Core <- Player 3
              ^
              |
        Player 4 Spawn
```

Each player route:

```text
spawn -> route path -> route gate -> shared core
```

Each player has:

```text
owned build zone
route id
local gate shield
local wave budget
local lane warnings
local shop/draft
```

The team shares:

```text
central Core
team pacts
team relics, sometimes
team boss events
team score
team failure state
```

Best for:

```text
main survival co-op
local split-screen
online co-op
2-4 players
clear responsibility
procedural generation
```

### 2.2 Braided Starbase - advanced default variant

Same as Starbase, but routes occasionally pass near each other.

Example:

```text
Player 1 route passes near Player 2 route for 5 tiles.
Support effects can cross the bridge.
Certain units can attack across the gap.
A breach in one lane can spill into the neighboring lane.
```

Best for:

```text
making players feel connected without merging all lanes
creating natural assist moments
making map generation more interesting
```

This should become the normal generated co-op map style after the simple Starbase version works.

### 2.3 Convergence Labyrinth

All player routes start separately, then merge into a shared final gauntlet near the Core.

Structure:

```text
P1 route ----\
P2 route ----- shared final route -> Core
P3 route ----/
```

Best for:

```text
late-wave panic
bosses
team ultimates
shared final defense
```

Risk:

```text
If the shared final route is too important, good players may dominate the whole match.
```

Use this as a map modifier, not always.

### 2.4 One Big Labyrinth - experimental mode

All players defend one giant route.

Best for:

```text
challenge mode
daily seed
raid mode
boss mode
party chaos
```

Risk:

```text
alpha-player problem
too much build-space conflict
harder readability
less personal responsibility
```

This should not be the main co-op foundation.

### 2.5 Parallel Boards - technical fallback

Each player has a separate board, but the team shares pacts, score, and Core fate.

Best for:

```text
debugging
online fallback
asynchronous variants
early multiplayer test
```

Risk:

```text
feels like solo games side by side
```

This is still useful as a debug topology because it is easy to test.

---

## 3. Recommended main co-op rules

### 3.1 Player count

Support this first:

```text
1 player
2 players
3 players
4 players
```

Do not support more than 4 until the game is stable.

### 3.2 Shared Core and lane Gate Shields

Each route has a Gate Shield.

```text
Enemy reaches end of Player 1 route.
If Player 1 Gate Shield > 0:
    damage Player 1 Gate Shield
else:
    damage shared Core
```

Team loses when:

```text
shared Core <= 0
```

This creates responsibility without instantly blaming one player for one mistake.

### 3.3 Gate Shield values

First test values:

```text
solo Gate Shield: 20
2-player Gate Shield per route: 15
3-player Gate Shield per route: 12
4-player Gate Shield per route: 10
shared Core: 30
```

These are placeholders. Tune after logs exist.

### 3.4 Route ownership

Each tile has an ownership mode:

```text
owned_by_player
shared_team
blocked
path
neutral_decor
```

Placement rules:

```text
Players can always build in their owned zone.
Players can build in shared_team zones if the zone allows it.
Players cannot build in another player's owned zone by default.
Temporary aid units can appear in ally zones.
```

This prevents grief and avoids one player taking over another player's lane.

### 3.5 Shared central defense ring

Near the Core, add a small shared build area.

Purpose:

```text
last line of defense
team identity
shared panic moments
boss mechanics
```

Rules:

```text
Shared ring has limited slots.
Each player can place at most N units there.
Default N = 1.
```

This gives the team one shared space without turning the whole game into a shared-lane argument.

---

## 4. Map generation for player count

The generator should create maps based on player count.

### 4.1 Generator input

```json
{
  "seed": 12345,
  "player_count": 3,
  "topology": "starbase",
  "theme": "neutral_arena",
  "difficulty": 1,
  "route_style": "braided",
  "special_tile_density": 0.08
}
```

### 4.2 Generator output

```text
CoopMapDef
```

Schema:

```json
{
  "id": "coop_starbase_12345",
  "name": "Starbase 12345",
  "seed": 12345,
  "player_count": 3,
  "topology": "starbase",
  "theme": "neutral_arena",
  "width": 42,
  "height": 42,
  "core": {
    "coord": [21, 21],
    "radius": 2,
    "shared_build_ring_radius": 5
  },
  "routes": [],
  "shared_zones": [],
  "assist_links": [],
  "special_tiles": [],
  "decorations": []
}
```

Route schema:

```json
{
  "route_id": "route_p1",
  "owner_player_slot": 1,
  "spawn_points": [[2, 21]],
  "gate_coord": [17, 21],
  "path_tiles": [[2,21], [3,21], [4,21]],
  "build_zone_tiles": [[3,19], [3,20], [3,22]],
  "route_length": 24,
  "difficulty_budget": 1.0,
  "modifiers": []
}
```

Assist link schema:

```json
{
  "id": "bridge_p1_p2_a",
  "from_route": "route_p1",
  "to_route": "route_p2",
  "tiles": [[12,18], [13,18]],
  "link_type": "support_bridge",
  "rules": {
    "allow_projectiles": false,
    "allow_auras": true,
    "allow_aid_units": true
  }
}
```

### 4.3 Generation algorithm

For Starbase:

```text
1. Place shared Core near center.
2. Choose player spawn anchors around the edge based on player_count.
3. For each player:
   a. Generate route from spawn anchor toward Core.
   b. Keep route length within target range.
   c. Add buildable tiles around route.
   d. Add local Gate before central Core zone.
4. Add shared central build ring.
5. Add assist links between neighboring routes.
6. Add special tiles.
7. Add decoration and theme props.
8. Validate map.
9. Retry if invalid.
```

### 4.4 Spawn anchors by player count

```text
1 player:
- west or south spawn into central Core

2 players:
- west and east
- or north and south

3 players:
- triangle layout

4 players:
- north, east, south, west
```

### 4.5 Route length normalization

All routes should be similar but not identical.

First target:

```text
route length variance <= 20 percent
buildable tile variance <= 25 percent
special tile variance <= 1 special tile difference
```

The goal is not perfect symmetry. The goal is perceived fairness.

### 4.6 Route personality

Each route can have one route modifier.

Examples:

```text
Long Road:
+ longer path
- fewer build slots

Choke Route:
+ strong central chokepoint
- armored waves more common

Greed Route:
+ bonus gold tile
- faster enemies

Bridge Route:
+ more assist links
- fewer solo build tiles

Storm Route:
+ more special tiles
- route mutates after boss waves
```

For fair co-op, route modifiers should be visible before the run starts.

### 4.7 Map validation

Validator must check:

```text
core exists
one route exists per player
all routes reach the core
all route lengths are within allowed range
each route has enough buildable tiles
each route has at least one emergency build zone near the gate
shared ring has valid build slots
assist links connect valid routes
path tiles do not overlap invalid blocked tiles
special tiles do not block route unless explicitly allowed
```

Validator should produce readable errors.

Example:

```text
InvalidMapError: route_p2 has only 5 buildable tiles, minimum is 12.
```

---

## 5. Co-op interaction systems

Co-op should not only mean "we both defend." It should mean "we can affect each other's survival."

Start with simple systems.

### 5.1 Aid Tokens

Each player gets limited Aid Tokens per act.

First version:

```text
Aid Token:
Send a temporary copy of one of your units to an ally route for one wave.
```

Rules:

```text
The copy has 50-70 percent power.
The copy disappears after the wave.
The copy cannot be sold.
The copy does not count for duplicate merging.
The receiving player can see it clearly as an allied aid unit.
```

Why this is good:

```text
heroic saves
low grief potential
easy to understand
works with all unit types
```

### 5.2 Emergency Shield

Alternative aid:

```text
Spend an Aid Token to shield an ally Gate for one leak.
```

This is useful when the map is too chaotic for temporary units.

### 5.3 Breach Tunnel

When a player leaks badly, some enemies do not immediately damage the Core. Instead, they enter a visible Breach Tunnel near the central Core.

Rules:

```text
If a route leaks more than X enemies in a wave:
    spawn a breach packet in the central route
    all players can attack it
    if killed, reduce Core damage
    if not killed, Core takes damage
```

This creates the co-op fantasy:

```text
Player 2 is collapsing.
Everyone sees the breach.
The team has one last chance to save the Core.
```

This is more exciting than invisible shared health loss.

### 5.4 Assist Bridges

Some maps have bridge tiles where effects can cross lanes.

Bridge rules can vary by map:

```text
allow_aura_crossing
allow_projectile_crossing
allow_temporary_unit_transfer
allow_gold_transfer
```

Example:

```text
A Vanar slow aura placed near a bridge also affects part of the neighboring route.
```

This makes map layout matter for co-op.

### 5.5 Team Ultimates

Team Ultimates are shared cooldown abilities charged by team performance.

First ultimates:

```text
Core Pulse:
Stun all enemies near the Core for 2 seconds.

Emergency Repair:
Restore 3 Gate Shield to the most damaged route.

Storm Recall:
Teleport the front enemy pack on each route backward by 4 tiles.
```

Rules:

```text
Only one team ultimate slot at first.
Charge through kills, elite kills, and boss damage.
Using it requires host/player 1 in local prototype.
Later, add voting or ping confirmation.
```

### 5.6 Shared Pacts

Pacts are team decisions.

Examples:

```text
Linked Greed:
All players gain +2 income.
If any route leaks, all routes lose 1 Gate Shield.

Fractured Routes:
Each route gains one special tile.
Routes mutate after every boss.

Shared Arsenal:
Each player gets one free unit.
Next wave has +20 percent enemies.

Heroic Debt:
The first route to break its Gate Shield is restored to half.
A Debt Boss appears later.
```

### 5.7 Co-op merge interaction

If the game moves toward autobattler merging, co-op should support it without allowing grief.

Safe first version:

```text
Players cannot trade units directly.
Players can gift one duplicate shard through a limited Aid Token.
Gifted shards go to the receiver's bench.
The receiver decides whether to use it.
```

Do not allow:

```text
stealing units
forced merges
selling ally units
direct gold draining
```

Optional later system:

```text
Tandem Evolution:
Two players with related unit families can unlock a temporary team evolution bonus.
```

Example:

```text
Player 1 has a Vanar frost unit.
Player 2 has a Lyonar shield unit.
Together they unlock Frostguard Aura for one boss wave.
```

---

## 6. Co-op economy and draft model

### 6.1 Individual shops, shared moments

Recommended:

```text
Each player has their own shop and gold.
The team shares pacts, boss rewards, and some relic choices.
```

Why:

```text
individual autonomy
less argument over purchases
clear personal responsibility
still creates team decisions
```

### 6.2 Shared team currency

Add later, not immediately.

Possible team currency:

```text
Core Charge
```

Earned by:

```text
elite kills
perfect waves
boss damage
saving allies through Aid Tokens
```

Spent on:

```text
team ultimates
central Core upgrades
emergency repairs
team relic activation
```

This gives the team shared goals without merging all economies.

### 6.3 Co-op draft moments

Every act, add one shared draft.

Examples:

```text
Choose one team Pact.
Choose one shared Core upgrade.
Choose one global map mutation.
Choose one boss reward.
```

Single-player should use the same system, just with one player choosing.

### 6.4 Anti-snowball support

If one player is struggling:

```text
Do not simply give them free power invisibly.
Offer visible recovery tools.
```

Examples:

```text
discounted stabilizer offer
free shield repair choice
ally Aid Token bonus
Breach Tunnel save opportunity
```

This preserves dignity and clarity.

---

## 7. Co-op camera and UI

### 7.1 Camera modes

The player should be able to:

```text
zoom into own route
zoom out to full Starbase map
jump camera to ally alert
inspect central Core
```

For local/split-screen:

```text
Each player has their own camera view.
Optional shared minimap shows all routes.
```

For online:

```text
Each client controls their own camera.
Pings and route alerts show on all clients.
```

### 7.2 Required co-op UI

Always show:

```text
shared Core health
player route Gate Shields
current wave phase
ready status per player
lane danger indicators
ally aid token availability
team ultimate charge
```

### 7.3 Lane danger indicators

Each route gets a danger level:

```text
green: stable
yellow: pressure
orange: high pressure
red: leak likely
purple: breach active
```

Danger calculation can use:

```text
enemies alive near gate
total enemy health on route
player DPS estimate
Gate Shield remaining
current leak count
boss presence
```

### 7.4 Ping system

Add simple pings before chat.

Pings:

```text
Help here
I can aid
Boss focus
Build here
Danger
Thanks
```

Do not overbuild social systems early. Pings are enough for testing.

---

## 8. Multiplayer technical model

### 8.1 Build local co-op first

Do not begin with online networking.

Order:

```text
1. Multi-player-slot architecture
2. One shared map with multiple routes
3. Local/debug two-player simulation
4. Split-screen or multi-camera support
5. Host-authoritative online prototype
```

### 8.2 Authoritative host model

For online, use a host-authoritative model.

```text
Clients submit commands.
Host validates commands.
Host simulates waves, RNG, damage, and enemy movement.
Host sends state updates/events to clients.
```

Do not start with deterministic lockstep. It is elegant but expensive and fragile for a first multiplayer implementation.

### 8.3 Command list

Everything important should be a command.

```text
ReadyCommand
UnreadyCommand
BuyOfferCommand
RerollShopCommand
PlaceUnitCommand
MoveUnitCommand
SellUnitCommand
MergeUnitCommand
ChooseEvolutionCommand
ChoosePactCommand
UseAidTokenCommand
UseTeamUltimateCommand
PingCommand
StartWaveCommand
DeployArenaUnitCommand
```

### 8.4 Server-only decisions

These must be host/server authoritative:

```text
RNG rolls
shop offers
enemy spawns
wave timing
damage
enemy death
unit death
leak damage
rewards
boss behavior
map generation
```

### 8.5 Client prediction

Client prediction is optional and should be minimal.

Safe prediction:

```text
placement preview
hover range
shop highlight
local UI sounds
```

Avoid predicting:

```text
combat results
gold rewards
enemy deaths
merge results
```

### 8.6 Multiplayer phases

Use phase sync.

```text
Planning phase:
- players buy/place/merge/inspect
- each player presses Ready
- host starts wave when all ready or timer expires

Combat phase:
- no shop changes unless explicitly allowed
- aid tokens and team ultimate may be allowed
- host simulates combat

Reward phase:
- rewards are granted
- pacts/events shown if needed
```

### 8.7 Reconnect and disconnect rules

First version:

```text
If a player disconnects, their route is controlled by simple AI or frozen.
Host can continue.
Disconnected player's units remain.
Their shop is locked.
```

Later:

```text
allow reconnect by player_id
restore PlayerSlot state
```

### 8.8 Godot implementation notes

Suggested nodes:

```text
SessionController
MultiplayerSessionController
PlayerSlot
CoopBoard
RouteController
CoreController
CommandQueue
NetworkCommandRelay
WaveDirector
ShopDirector
AidSystem
PingSystem
```

Important principle:

```text
Single-player is just multiplayer with player_count = 1.
```

---

## 9. Arena mode: Prism Clash

Arena should be a separate mode, not mixed into survival co-op.

Working title:

```text
Prism Clash
```

Core fantasy:

```text
A short tactical Duelyst-style lane battle where players spend regenerating Mana to deploy units, break the enemy Core, and adapt their roster between rounds.
```

### 9.1 Why separate mode

Survival co-op is about:

```text
drafting defense
map control
waves
long-run identity
team recovery
```

Arena is about:

```text
timing
pressure
counter-deployment
resource tempo
short rounds
mind games
```

They should share assets and unit definitions, but they should not share all rules.

### 9.2 Arena map

Use one symmetrical arena map.

Structure:

```text
Player A Core ---- lane/path ---- Player B Core
```

Optional advanced maps:

```text
2 lanes
center bridge
neutral shrine
side portals
```

Start simple:

```text
one lane
one central contest zone
two cores
clear deployment zones
```

### 9.3 Arena resource

Use a timing-based resource.

Suggested name:

```text
Mana
```

Alternative names:

```text
Prism
Aether
Duel Energy
```

Rules:

```text
Mana regenerates over time.
Mana has a cap.
Units cost Mana to deploy.
Stronger units cost more.
Players must time deployments.
```

First test values:

```text
mana cap: 10
mana regen: 1 every 2 seconds
cheap unit cost: 2
medium unit cost: 4
heavy unit cost: 6
legendary/boss-lite cost: 8
```

### 9.4 Arena roster

Match begins with:

```text
2-3 units in roster
```

After each round:

```text
each player drafts +1 unit into roster
```

Best-of-5 means the match has a growing strategic arc:

```text
Round 1: tiny roster, simple reads
Round 2: first adaptation
Round 3: counters emerge
Round 4: combos appear
Round 5: full mini-build duel
```

### 9.5 Draft between rounds

After each round:

```text
Show 3 unit offers.
Player chooses 1.
Add chosen unit to arena roster.
```

Fairness options:

```text
Option A: both players get same offers, choose secretly.
Option B: each player gets different offers from same rarity budget.
Option C: loser chooses first from a shared pool.
```

Recommended first version:

```text
Both players get 3 offers from the same rarity budget but not necessarily identical units.
Loser gets one free reroll.
```

This gives light comeback without feeling fake.

### 9.6 Arena deployment

Rules:

```text
Player can deploy units only in their deployment zone.
Deployed units walk toward enemy Core.
Units attack enemy units in range.
If no enemies block them, they attack the Core.
```

Unit AI priority:

```text
1. enemy unit attacking self
2. closest enemy unit in path
3. enemy Core
```

### 9.7 Arena unit roles

Map existing Duelyst units into arena roles.

```text
Swarm:
cheap pressure, weak to splash

Guardian:
high health, protects backline

Shooter:
ranged damage, weak if reached

Caster:
burst or status effect

Siege:
strong against Core, weak against units

Disruptor:
stun, silence, pull, slow

Assassin:
fast, targets backline or core

Support:
heals, shields, buffs
```

### 9.8 Arena round win conditions

Round ends when:

```text
one Core is destroyed
or round timer expires
```

If timer expires, winner is decided by:

```text
1. higher Core health
2. more Core damage dealt
3. fewer Mana wasted
4. sudden death, if needed
```

Recommended first round timer:

```text
180 seconds
```

### 9.9 Best-of match structure

```json
{
  "mode": "prism_clash",
  "best_of": 5,
  "starting_roster_size": 3,
  "draft_after_each_round": 1,
  "round_timer_seconds": 180,
  "mana_cap": 10,
  "mana_regen_interval": 2.0
}
```

### 9.10 Arena progression inside a match

Do not add permanent stat upgrades between rounds.

Add:

```text
new unit choices
sidegrade relics
temporary round modifiers
map events
```

Examples:

```text
Round 3 modifier:
Central shrine activates.
First player to hold it gains +1 Mana burst.

Round 4 modifier:
Core shields reduced by 20 percent.

Round 5 modifier:
Sudden storm, Mana regen faster.
```

### 9.11 Arena spells

Do not build spells first.

First build:

```text
unit deployment only
```

Later add:

```text
one spell slot per player
spell drafted between rounds
spells cost Mana
```

Examples:

```text
Core Pulse: damage enemies near your Core.
Wind Step: speed up allied units for 3 seconds.
Frost Wall: slow enemies in a tile area.
Soul Burst: sacrifice weakest ally to damage enemies.
```

### 9.12 Arena anti-stalemate

Add escalating pressure:

```text
After 120 seconds:
Mana regen +25 percent.

After 150 seconds:
Core shields decay slowly.

After 180 seconds:
Sudden death if no winner.
```

---

## 10. Shared data model between survival and arena

Use the same source Duelyst content, but different balance profiles.

### 10.1 UnitDef vs ModeProfile

Do not make separate unit assets.

Use:

```text
UnitDef
+ SurvivalProfile
+ ArenaProfile
```

Example:

```json
{
  "id": "windblade_adept",
  "display_name": "Windblade Adept",
  "asset_id": "duelyst_windblade_adept",
  "faction": "lyonar",
  "tags": ["melee", "duelist", "physical"],
  "survival_profile": {
    "cost_gold": 6,
    "range": 2,
    "damage": 8,
    "attack_cooldown": 0.9,
    "role": "basic_attacker"
  },
  "arena_profile": {
    "mana_cost": 3,
    "move_speed": 1.1,
    "health": 80,
    "damage": 9,
    "role": "marcher"
  }
}
```

### 10.2 Why separate mode profiles matter

Survival balance and arena balance will not match.

A unit that is fun as a tower may be broken as a PvP deployment unit.

Mode profiles let you reuse:

```text
name
sprite
animation
SFX
VFX
faction identity
tags
```

while changing:

```text
cost
health
damage
movement
cooldowns
role
AI
```

---

## 11. Experimental co-op ideas for later

These are not first implementation tasks, but they are worth preserving.

### 11.1 Living Core subsystems

The shared Core has subsystems:

```text
Shield
Reactor
Forge
Beacon
Archive
```

Leaks damage subsystems, creating different consequences.

Examples:

```text
Shield damaged:
Gate Shields repair slower.

Reactor damaged:
Team ultimate charges slower.

Forge damaged:
Shops cost +1 gold.

Beacon damaged:
Aid Token cooldowns increase.

Archive damaged:
Draft offers become less predictable.
```

This makes leaks narratively interesting instead of just health loss.

### 11.2 Route rotation event

After a boss, route modifiers rotate clockwise.

Example:

```text
Player 1's Greed Route becomes Player 2's problem.
Player 2's Storm Route becomes Player 3's problem.
```

Use sparingly. This can be funny and chaotic, but it may frustrate players if overused.

### 11.3 Shared boss vulnerabilities

Boss appears on all routes but is vulnerable only when players trigger conditions on different routes.

Example:

```text
Boss armor breaks only when Player 2 kills a Crystal Carrier.
Player 1 then has 10 seconds to damage the exposed boss.
```

This creates real co-op coordination.

### 11.4 Relay towers

A unit placed on a Relay Tile can project part of its effect to an ally route.

Examples:

```text
10 percent of damage copied to linked route
slow aura copied across bridge
shield pulse sent to ally Gate
```

### 11.5 Co-op combo callouts

When two players create a combo, show a callout.

Examples:

```text
Frost + Shield = Frostguard
Poison + Burn = Caustic Flame
Swarm + Sacrifice = Blood Tide
```

This makes co-op feel magical without requiring new art.

---

## 12. Implementation roadmap for Claude

This roadmap assumes the current game already has basic survival, draft shop, combat, traits, relics, pacts, flaws, waves, run summary, and content packs.

Focus now:

```text
Build a playable 2-player Starbase Co-op prototype locally/debug first.
Then add the Breach Tunnel and aid mechanics.
Then prototype Prism Clash separately.
Do not start online networking until local/debug co-op is fun and stable.
```

---

# Co-op implementation stages

## C0 - Player count plumbing

Goal:

```text
RunConfig supports player_count and topology.
Single-player still works as player_count = 1.
```

Add:

```text
player_count
session_topology
PlayerSlot array
route_id per player
```

Acceptance criteria:

```text
New run UI can choose 1, 2, 3, or 4 players.
Debug run can spawn PlayerSlot objects.
Existing solo mode still works.
Run summary records player_count and topology.
```

Manual test:

```text
Start 1-player run.
Start 2-player debug run.
Confirm both load without errors.
Confirm existing shop/combat works in 1-player.
```

## C1 - CoopMapDef schema

Goal:

```text
Create the data format for one shared map with multiple player routes.
```

Add:

```text
CoopMapDef
RouteDef
SharedZoneDef
AssistLinkDef
GateDef
```

Acceptance criteria:

```text
A hand-authored 2-player CoopMapDef loads.
Both routes render on one board.
Core renders in center.
Each route has distinct owner color/icon.
```

Manual test:

```text
Load debug_coop_2p_starbase.json.
Check that Player 1 and Player 2 paths are visible.
Check that both paths connect to the same Core.
```

## C2 - Multi-route enemy spawning

Goal:

```text
Each route spawns its own enemies.
```

Acceptance criteria:

```text
Wave spawner can spawn route_p1 enemies and route_p2 enemies.
Enemies follow their assigned route.
Enemies reaching the gate damage the correct Gate Shield.
If Gate Shield is broken, enemies damage shared Core.
```

Manual test:

```text
Start 2-player debug wave.
Watch enemies spawn on both routes.
Let Player 1 leak.
Confirm only Player 1 Gate Shield is damaged first.
Break Player 1 Gate Shield.
Confirm later leaks damage shared Core.
```

## C3 - Route ownership and placement zones

Goal:

```text
Players can place units only in legal zones.
```

Acceptance criteria:

```text
Player 1 can place in Player 1 build zone.
Player 1 cannot place in Player 2 owned zone.
Player 1 can place in shared ring only if shared slot limit allows.
Placement preview clearly shows legal/illegal tiles.
```

Manual test:

```text
Try placing Player 1 unit on Player 2 zone.
Confirm rejection message.
Place one unit in shared Core ring.
Confirm slot limit works.
```

## C4 - Synced co-op phases

Goal:

```text
Add ready checks and shared wave start.
```

Acceptance criteria:

```text
Each PlayerSlot has ready/unready state.
Wave starts when all players are ready.
Debug option can force start.
Combat phase runs both routes at once.
Reward phase resolves for all players.
```

Manual test:

```text
Set Player 1 ready.
Confirm wave does not start until Player 2 ready.
Set Player 2 ready.
Confirm wave starts.
```

## C5 - Co-op camera and overview

Goal:

```text
Player can inspect own route and zoom out to see full map.
```

Acceptance criteria:

```text
Camera can focus Player 1 route.
Camera can focus Player 2 route.
Overview key zooms to full Starbase.
Lane danger UI remains visible.
```

Manual test:

```text
Use camera hotkeys to jump between routes.
Zoom out during combat and confirm both routes are visible.
```

## C6 - Gate Shield and team Core UI

Goal:

```text
Make co-op survival state readable.
```

Acceptance criteria:

```text
UI shows shared Core health.
UI shows each route Gate Shield.
Damaged route flashes or pings.
Core damage has strong SFX/VFX.
```

Manual test:

```text
Leak Player 2 route.
Confirm Player 2 Gate Shield UI updates.
Break Gate Shield.
Leak again.
Confirm shared Core UI updates.
```

## C7 - Aid Token v1

Goal:

```text
Players can send a temporary copy of one unit to an ally route.
```

Acceptance criteria:

```text
Player can select one owned unit.
Player can choose ally route.
Temporary copy appears in valid ally assist slot.
Copy disappears after wave.
Aid Token count decreases.
```

Manual test:

```text
Player 1 sends unit to Player 2.
Start wave.
Confirm copy attacks enemies on Player 2 route.
Confirm copy disappears after wave.
```

## C8 - Breach Tunnel v1

Goal:

```text
Give the team a last-chance save moment when one route collapses.
```

Acceptance criteria:

```text
If a route leaks more than threshold, a breach packet spawns near Core.
All players can damage breach packet.
If killed, Core damage is reduced or cancelled.
If not killed, Core takes damage.
```

Manual test:

```text
Force Player 1 route to leak many enemies.
Confirm breach packet appears.
Kill it and confirm reduced Core damage.
Repeat and let it pass to confirm Core damage.
```

## C9 - Shared co-op pact

Goal:

```text
Pact choices affect all routes.
```

Acceptance criteria:

```text
After target wave, team pact choice appears.
Chosen pact applies to all players/routes.
Run summary records pact and who chose it.
```

Manual test:

```text
Choose a pact that increases enemy count.
Confirm both routes receive modified waves.
```

## C10 - 2-player Starbase balance pass

Goal:

```text
Make the 2-player prototype playable for 10 waves.
```

Acceptance criteria:

```text
2-player debug run can be won.
2-player debug run can be lost.
Run summary shows per-player stats and team stats.
Lane danger indicator roughly matches actual pressure.
```

Manual test:

```text
Play 3 full 2-player debug runs.
Record where they fail.
Tune Gate Shields and enemy budgets.
```

## C11 - Simple generated Starbase maps

Goal:

```text
Generate a simple co-op Starbase map from seed and player_count.
```

Acceptance criteria:

```text
Same seed + player_count creates same map.
Different seed changes route layout.
Validator rejects invalid maps.
2-player generated map is playable.
```

Manual test:

```text
Generate seeds 1, 2, 3, 4, 5 for 2 players.
Confirm all validate.
Play at least one wave on each.
```

## C12 - Online command relay prototype

Goal:

```text
Create the smallest possible host-client command flow.
```

Do this only after C0-C11 feel stable.

Acceptance criteria:

```text
Host creates session.
Client joins as Player 2.
Client can submit PlaceUnitCommand.
Host validates and applies it.
Both clients see placed unit.
Host controls wave start and enemy simulation.
```

Manual test:

```text
Run two local clients.
Place unit from client.
Start wave from host.
Confirm both see same wave result.
```

---

# Arena implementation stages

Do not begin these until the main co-op route prototype is playable, unless you intentionally want a separate experimental branch.

## A0 - Arena mode flag and scene

Goal:

```text
Add separate GameMode: prism_clash.
```

Acceptance criteria:

```text
Main menu/debug menu can launch Prism Clash.
Arena scene loads separately from survival.
No survival systems are broken.
```

## A1 - Arena map v1

Goal:

```text
Create one symmetrical arena with two cores and one lane.
```

Acceptance criteria:

```text
Player A Core and Player B Core render.
One path connects both sides.
Deployment zones are visible.
Units can be spawned manually for both players.
```

## A2 - Mana resource

Goal:

```text
Add regenerating Mana for each player.
```

Acceptance criteria:

```text
Mana increases over time up to cap.
Deploying unit spends Mana.
Cannot deploy without enough Mana.
UI shows current Mana clearly.
```

## A3 - Arena roster and deploy UI

Goal:

```text
Players can deploy units from a small roster.
```

Acceptance criteria:

```text
Starting roster has 3 units.
Each unit has Mana cost.
Clicking a unit enters deployment mode.
Clicking deployment zone spawns unit.
```

## A4 - Arena combat loop

Goal:

```text
Deployed units walk and fight toward enemy Core.
```

Acceptance criteria:

```text
Units march down lane.
Enemy units fight each other.
Surviving units damage enemy Core.
Core at 0 ends round.
```

## A5 - Best-of-5 round structure

Goal:

```text
Arena match has rounds.
```

Acceptance criteria:

```text
Round starts.
Round ends when Core destroyed or timer expires.
Winner gains round point.
First to 3 wins match.
Score UI shows current round score.
```

## A6 - Draft +1 unit after each round

Goal:

```text
Roster grows across rounds.
```

Acceptance criteria:

```text
After each round, each player sees 3 unit offers.
Each player chooses 1.
Chosen unit appears in roster next round.
Loser gets one free reroll, if enabled.
```

## A7 - Arena bots for testing

Goal:

```text
Allow solo testing against a basic bot.
```

Acceptance criteria:

```text
Bot spends Mana on affordable units.
Bot does not stall.
Player can complete a best-of-5 match against bot.
```

## A8 - Arena balance report

Goal:

```text
Track which units dominate arena.
```

Report:

```text
unit pick rate
unit deploy rate
mana spent per unit
core damage per unit
round win correlation
average match length
most common first-round winners
```

Acceptance criteria:

```text
After match, arena summary displays useful stats.
Stats save to run logs.
```

---

## 13. Most impactful next path

Given the current project status, the next most impactful path is:

```text
1. C0 Player count plumbing
2. C1 CoopMapDef schema
3. C2 Multi-route enemy spawning
4. C3 Route ownership and placement zones
5. C4 Synced co-op phases
6. C6 Gate Shield and team Core UI
7. C7 Aid Token v1
8. C8 Breach Tunnel v1
9. C10 2-player Starbase balance pass
10. C11 Simple generated Starbase maps
```

Do not do arena first unless you need a break from survival/co-op work.

Do not do full online first.

Do not add more content packs until this co-op topology is playable. More units will not answer the biggest design question, which is:

```text
Does shared-Core, multi-route co-op feel good?
```

---

## 14. Claude prompt template: next co-op task

Use this for C0.

```text
Read:
- docs/co_op_roguelike_td_design_doc.md
- docs/shardstorm_td_content_bible.md
- docs/shardstorm_td_research_engagement_addendum.md
- docs/shardstorm_td_next_roadmap_addendum.md
- docs/shardstorm_td_coop_multiplayer_arena_addendum.md
- docs/decisions.md

Implement C0: Player count plumbing.

Goal:
RunConfig supports player_count and session_topology so single-player becomes player_count = 1 and co-op can be added without rewriting the session.

Add:
- player_count field
- session_topology field
- PlayerSlot array creation based on player_count
- route_id placeholder per PlayerSlot
- debug/new-run UI option for player_count 1-4
- run summary field for player_count and topology

Hard constraints:
- Existing single-player gameplay must keep working.
- Do not implement multi-route maps yet.
- Do not implement online networking yet.
- Do not implement split-screen yet.
- Keep this as architecture/plumbing.
- Update docs/decisions.md.

Acceptance criteria:
- Starting a 1-player run works exactly as before.
- Starting a 2-player debug run creates two PlayerSlot objects.
- Run summary records player_count and session_topology.
- No existing unit/shop/combat systems are broken.

Manual test:
1. Start 1-player run.
2. Place units and start a wave.
3. End run and confirm summary shows player_count = 1.
4. Start 2-player debug run.
5. Confirm two PlayerSlots exist in debug UI/log.
6. Confirm no crashes.

After implementation, report:
1. Files changed.
2. Data schema changes.
3. How to test in Godot.
4. Known limitations.
5. Recommended next task.
```

---

## 15. Do not proceed gates

### Before generated co-op maps

Must be true:

```text
A hand-authored 2-player Starbase map works.
Both routes spawn enemies.
Gate Shields work.
Shared Core works.
Placement ownership works.
```

### Before online multiplayer

Must be true:

```text
All important player actions are commands.
2-player local/debug co-op works.
Run state can be summarized and logged.
Combat can run without direct UI dependencies.
SessionRng controls randomness.
```

### Before Prism Clash arena

Must be true:

```text
Survival units have clean UnitDef data.
ModeProfile split is possible.
Basic combat can be reused without survival-only assumptions.
```

### Before adding many more co-op mechanics

Must be true:

```text
Aid Token v1 is fun.
Breach Tunnel v1 is readable.
Players understand why the Core took damage.
```

---

## 16. Final design bet

The most promising multiplayer identity is:

```text
A shared-Core co-op tower defense where each player owns a route, but the map creates moments where allies can save each other.
```

The unusual twist should be:

```text
Enemies do not simply leak and subtract health.
Leaks create visible team emergencies: breaches, subsystem damage, route corruption, and future debt enemies.
```

That turns tower defense failure into co-op drama.

The arena mode should become:

```text
A short-round Duelyst unit battler where the roster grows between rounds and the match becomes a best-of-5 adaptation duel.
```

Together, these create two strong pillars:

```text
Survival Co-op:
longer roguelike buildcraft, shared Core, team saves

Prism Clash:
short PvP rounds, timing resource, roster adaptation
```

Build Survival Co-op first.
