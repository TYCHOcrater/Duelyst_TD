# Shardstorm TD - Content Bible

Companion document to: `co_op_roguelike_td_design_doc.md`

Engine: Godot 4.x  
Implementation helper: Claude Code  
Content source: OpenDuelyst / Duelyst asset repository  
Design intent: reuse Duelyst sprites, names, animations, effects, sounds, icons, tiles, UI, and faction identity to build a roguelike co-op tower defense game with a repeatable core loop and high-session variety.

---

## 0. Content North Star

The game should feel like this:

> Duelyst's army escaped the card game and became a living Legion TD / Chaos TD machine. Every run uses familiar pieces, but the board, draft, traits, wave pressure, and pacts make the same simple defense ritual feel different every time.

This content bible assumes almost all visible and audible content comes from Duelyst sources. New code may combine, tint, scale, layer, and sequence assets, but the project should avoid needing original art, bespoke animation, or custom audio for the MVP.

### The emotional target

The player should feel four things repeatedly:

1. **I know this rhythm.** Draft, place, prepare, watch the wave, collect reward.
2. **This run is weird.** Different units, different lane shape, different tile bonuses, different pacts.
3. **My build is becoming a machine.** Units start as separate towers, then become a system.
4. **I could have optimized that better.** Losses should feel understandable and replayable.

This is the shared DNA of Dota custom maps, Legion TD, Chaos TD, auto-battlers, and old Warcraft III custom games: the action is repetitive in a good way, but the decisions around the repetition create stories.

---

## 1. Asset Reuse Rules

### Rule 1: Duelyst assets are the content source of truth

All player units, enemies, bosses, icons, impact effects, UI frames, tiles, music, and sounds should be selected from the Duelyst/OpenDuelyst asset pool whenever possible.

Recommended content categories to import or map:

```text
units        -> player towers, enemies, bosses, summoned tokens
unit_gifs    -> optional preview animations / shop previews
fx           -> attacks, spell impacts, aura effects, explosions
particles    -> map ambience, hits, deaths, leaks, pacts
sfx          -> attacks, impacts, UI, wave starts, boss warnings
music        -> lobby, planning, combat, boss, endless
maps         -> backgrounds and board theme references
tiles        -> generated map tiles and editor palette
ui           -> HUD panels, buttons, shop frames, reward panels
icons        -> tags, damage types, faction symbols, pacts
crests       -> faction identity, player banners, mode select
runes        -> special tiles, pact markers, wave warnings
card_backgrounds -> draft/shop cards and reward choices
```

### Rule 2: Do not require one-to-one fidelity to original Duelyst mechanics

A Duelyst card name can become a tower, enemy, boss, relic, trait, map modifier, or wave. The name and asset create identity; the tower defense kit creates gameplay.

Example:

```text
Original Duelyst: Ironcliffe Guardian is a minion with Airdrop and Provoke.
Shardstorm TD: Ironcliffe Guardian is a high-cost guardian tower that slows enemies in an adjacent lane and intercepts one leak per wave.
```

### Rule 3: Build a content adapter layer

Do not hard-code Duelyst filenames inside combat code. Use data.

Every content object should point to an asset profile:

```json
{
  "asset_profile_id": "duelyst_ironcliffe_guardian",
  "display_name": "Ironcliffe Guardian",
  "unit_anim": "f1IroncliffeGuardian",
  "portrait": "ironcliffe_guardian_portrait",
  "attack_sfx": "sfx_f1_guardian_attack",
  "hit_sfx": "sfx_metal_impact_heavy",
  "death_sfx": "sfx_unit_death_heavy",
  "attack_vfx": "vfx_lyonar_gold_impact",
  "death_vfx": "vfx_unit_death_gold"
}
```

If the exact asset mapping is unknown, Claude should generate a placeholder asset profile and keep the game running.

### Rule 4: Recoloring is allowed, new art is not required

Enemy variants should mostly be generated through shaders:

```text
normal enemy    -> original colors
elite enemy     -> brighter outline, gold/red tint, bigger scale
corrupted enemy -> purple/black tint, dark particle trail
armored enemy   -> gray/metal overlay and shield icon
frost enemy     -> blue tint and snow trail
boss enemy      -> original sprite + scale + aura + boss bar
```

This multiplies content without needing new sprites.

---

## 2. Faction Content Identity

The six Duelyst factions plus Neutral should define gameplay archetypes. This lets the player learn the content quickly.

| Faction | Visual language | Gameplay language | TD fantasy |
|---|---|---|---|
| Lyonar Kingdoms | gold, white, shields, holy impact, banners | protection, healing, sturdy formations, Provoke, Zeal | holds the line and turns defense into damage |
| Songhai Empire | red, smoke, lightning, blades, teleport flashes | speed, reactivation, crits, chain attacks, movement tricks | precision towers that reward timing and positioning |
| Vetruvian Imperium | sand, sun, obelisks, beam lines, mirage | summoning, lane geometry, Blast, Dervish swarms, debuffs | shapes the battlefield with structures and beams |
| Abyssian Host | purple, black, souls, Wraithlings, creep | sacrifice, death triggers, swarm, life drain, corruption | converts death and leaks into future power |
| Magmar Aspects | orange, lava, bones, eggs, primal impacts | growth, Frenzy, Rebirth, self-damage, huge bodies | slow scaling monsters that become unstoppable |
| Vanar Kindred | blue, ice, snow, crystals, frost fog | slow, stun, walls, Vespyr synergy, control | controls wave tempo and buys time |
| Neutral | mixed creatures, golems, beasts, mechs | glue roles, generic supports, economy, anti-specific tools | fills missing build needs and enables cross-faction builds |

### Faction composition rules

A draft can be fully mixed, but faction identity should matter.

Suggested default:

```text
60% chance: offers match one of the player's current strongest tags
25% chance: neutral / utility offer
15% chance: off-faction strange offer
```

This creates consistency without forcing a deck-building screen before each run.

---

## 3. Duelyst Keyword Translation

Duelyst keywords should be translated into tower defense mechanics. This is one of the fastest ways to reuse content meaningfully.

| Duelyst keyword | TD translation | Implementation note |
|---|---|---|
| Ranged | long attack range | simple stat modifier |
| Provoke | guardian aura / intercept / lane hold | avoid full path blocking at MVP; use slow/intercept first |
| Celerity | attacks twice, or has two projectiles per cycle | strong with on-hit traits |
| Frenzy | splash/cleave around target | good anti-swarm identity |
| Blast | line attack down path | ideal for Vetruvian beams and corridor maps |
| Airdrop | can be placed on special remote tiles, or can be sent through Aid Portal | useful for co-op later |
| Flying | ignores terrain limits, can target flying enemies, or can be placed on cliff tiles | keep simple in MVP |
| Dying Wish | triggers when sold, destroyed, or after a fixed number of waves | creates roguelike tradeoffs |
| Opening Gambit | triggers when placed or upgraded | easy to implement as placement effect |
| Deathwatch | triggers when enemies die nearby | ideal for Abyssian economy/scaling |
| Grow | gains stats after each wave survived | great Magmar scaling |
| Rebirth | leaves an egg that revives if not destroyed by leak shock | creates delayed power |
| Zeal | stronger near core, near shrine tiles, or when team Heart is damaged | good Lyonar identity |
| Backstab | bonus damage against enemies already damaged or passing from behind | Songhai assassin behavior |
| Stun | short hard stop with diminishing returns | Vanar control identity |
| Infiltrate | stronger on far side / risky forward tiles | map-positioning mechanic |
| Gateway | spawns temporary units | Vetruvian obelisks and structure content |

### MVP keyword limit

Start with these eight only:

```text
Ranged
Provoke
Celerity
Frenzy
Blast
Opening Gambit
Dying Wish
Grow
```

Add the rest once combat is stable.

---

## 4. Player Unit Content

### Unit design model

Each player unit is not just a tower. It is a kit made of:

```text
Duelyst identity
+ TD role
+ attack pattern
+ faction keyword
+ upgrade path
+ asset profile
```

Example:

```text
Windblade Adept
Role: cheap starter duelist
Pattern: single-target melee/short range slash
Keyword: Zeal
Upgrade identity: becomes a strong core-side defender
```

### MVP roster philosophy

Do not begin by implementing 100+ units. Start with a curated roster that covers all core TD roles.

Recommended first playable roster:

```text
6 factions x 5 units = 30 faction units
10 neutral units = 40 total player units
```

That is already enough for many runs if traits, flaws, maps, pacts, and upgrades exist.

---

## 5. MVP Player Unit Roster

Numbers below are intentionally rough starting values. They are for feel testing, not final balance.

Stat scale assumptions:

```text
Cost: 3-20 gold
Damage: 3-60
Cooldown: 0.4-3.0 seconds
Range: 1-6 grid cells
```

### Lyonar Kingdoms

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Windblade Adept | cheap duelist | short range, fast single-target, +damage near core/shrine | Zeal carry, double strike, core sentinel | simple first Lyonar tower |
| Azurite Lion | burst striker | Celerity: attacks twice per cycle, low damage per hit | on-hit scaling, anti-fast, crit pair | teaches Celerity |
| Silverguard Knight | guardian | Provoke aura: enemies in adjacent path cells are slowed; can intercept first leak nearby | larger aura, armor break, core wall | readable defensive anchor |
| Lightchaser | heal-scaler | gains temporary damage whenever any allied unit is healed/buffed | healing engine, aura DPS, self-sustain | turns support into offense |
| Sunriser | healing splash | when a nearby ally is healed/buffed, emits small damage pulse | splash support, sustain engine | creates satisfying golden pulse builds |
| Ironcliffe Guardian | heavy guardian | high cost, slow attacks, strong intercept once per wave | lane bastion, boss hold, global taunt | iconic high-health tower |
| Elyx Stormblade | legendary support bruiser | grants one nearby unit Celerity for first 8 seconds of each wave | haste aura, boss shred | late-run excitement |

### Songhai Empire

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Heartseeker | long-range chip | very long range, low damage, prioritizes first enemy | mark target, flying coverage, multi-shot | clean ranged starter |
| Kaido Assassin | lane finisher | bonus damage to enemies below 40% health | execute, backstab, crit chains | creates kill-zone endings |
| Chakri Avatar | spell/reroll scaler | gains attack speed after each shop reroll or spell-like pact this wave | scaling carry, storm style | converts draft behavior into combat |
| Widowmaker | precision archer | ranged shot, draws/generates 1 gold on elite kill once per wave | economy sniper, anti-elite | satisfying tactical economy |
| Gore Horn | ramp assassin | gains small permanent damage after killing an enemy, capped per act | snowball carry, risky weak start | makes runs memorable |
| Flamewreath | movement pulse | after being moved in planning, first attacks deal area pulse | map-dependent burst | encourages repositioning |
| Storm Kage | legendary spell engine | casts Kage Lightning at the highest-health enemy every N attacks | boss killer | high-impact red lightning fantasy |

### Vetruvian Imperium

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Dunecaster | Dervish support | buffs temporary summons and nearby structures | summon support, aura | makes Dervish builds work |
| Orb Weaver | duplicator | places as two weak linked towers in adjacent tiles if possible | split beams, linked damage | weird spatial unit |
| Pyromancer | line blast | Blast: attacks through enemies in a straight line | longer beams, burning line | perfect TD tower shape |
| Ethereal Obelysk | summoner structure | periodically summons temporary Wind Dervish on nearby path edge | Dervish swarm, lane pressure | structure identity |
| Imperial Saboteur | debuff aura | enemies near its target lose armor/damage reduction | support/debuffer | useful in all builds |
| Starfire Scarab | heavy artillery | slow Blast projectile, high line damage | anti-column, siege | satisfying corridor reward |
| Aymara Healer | drain tank | damages one enemy and heals core shield for a fraction on elite hits | sustain/control | late defensive comeback tool |

### Abyssian Host

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Bad Omen | cheap deathwatch | gains temporary damage when enemies die nearby | swarm scaler | cheap spooky starter |
| Gloomchaser | Wraithling seed | periodically creates a temporary Wraithling turret on adjacent build tile | swarm engine | uses token content |
| Bloodmoon Priestess | death summoner | Deathwatch: spawns temporary Wraithling when enemies die nearby, limited per wave | swarm density, sacrifice | iconic Abyssian engine |
| Aphotic Devourer | sacrifice bruiser | consumes nearby temporary summons during planning for bonus damage | tall carry | turns swarm into big unit |
| Black Solus | Wraithling commander | grows stronger based on number of Wraithlings summoned this run | late carry | gives swarm a payoff |
| Shadowdancer | drain pulse | Deathwatch: pulses small damage and heals core shield | sustain engine | satisfying kill feedback |
| Vorpal Reaver | legendary death bomb | if destroyed/sold, summons six temporary Wraithling turrets for next wave | panic button | dramatic Dying Wish |

### Magmar Aspects

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Phalanxar | cheap bruiser | slow movement/short range but high early stats | sturdy starter | simple Magmar feel |
| Kujata | economy risk | nearby new units cost less but start wave with minor damage/fragility | greedy engine | great roguelike risk/reward |
| Young Silithar | rebirth unit | if destroyed/sold, leaves Egg that revives next planning phase | egg mechanics | introduces Rebirth |
| Earth Walker | Grow tower | gains health/damage every wave it survives | long-run scaling | classic Magmar scaling |
| Primordial Gazer | buff support | Opening Gambit: buffs nearby unit damage and max health | placement puzzle | low-code support unit |
| Grimrock | heavy Grow | expensive, slow, gains large stats each act | slow monster carry | creates anticipation |
| Makantor Warbeast | frenzy sweeper | short range, Frenzy splash, burst first attack | anti-swarm elite | iconic wave clearer |
| Unstable Leviathan | chaos legendary | huge attacks; every few attacks hits random enemy or ally-shock tile | high variance | roguelike chaos piece |

### Vanar Kindred

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Snowchaser | cheap frost unit | slows first enemy hit each wave; can return to shop as discount if sold | flexible starter | Vanar control identity |
| Crystal Cloaker | forward-risk unit | stronger when placed far from core or on frost tile | infiltrate-style risk | map-based unit |
| Crystal Wisp | economy unit | weak attack; grants +1 gold every few waves if it survives | greed tower | simple economic tension |
| Voice of the Wind | summon support | when buying/placing units, creates temporary Winter Maerid turret next wave | summon payoff | very fun support identity |
| Sleet Dasher | reset striker | when it kills an enemy, attacks again immediately with reduced damage | chain killer | high joy when it pops off |
| Draugar Lord | Vespyr transformer | buffs nearby Vespyr/frost units for first 10 seconds | faction payoff | big Vanar moment |
| Arctic Displacer | stun bruiser | first attack each wave stuns target and nearby enemies briefly | control anchor | clear anti-elite tool |
| Ancient Grove | wall support | Provoke aura + creates Treant intercept tokens on upgrade | defensive control | late control identity |

### Neutral

| Unit | TD role | Base kit | Upgrade direction | Why it belongs |
|---|---|---|---|---|
| Dragonlark | cheap anti-air/flying | fast, low damage, can attack flying enemies | early coverage | universal utility |
| Fire Spitter | ranged turret | long range, cannot target bosses by default or has low boss damage | anti-swarm lane chip | simple tower profile |
| Swamp Entangler | cheap slow | Provoke/slow aura, low damage | lane stall | faction-neutral control |
| Rock Pulverizer | blocker/guardian | heavy slow aura, high armor | defensive anchor | generic frontline |
| Bluetip Scorpion | anti-minion | double damage to normal enemies, weak vs bosses | wave-clear tech | clear specialization |
| Primus Fist | aura buffer | nearby units gain +damage for first seconds of wave | support opener | easy readable buff |
| Golem Metallurgist | tribal economy | Golems cost less / upgrade cheaper | build enabler | unlocks Golem runs |
| Skyrock Golem | sturdy shooter | simple reliable mid-cost tower | neutral baseline | helps balance |
| Healing Mystic | support healer | heals/buffs adjacent unit at wave start | enables Lyonar/Abyssian/Magmar synergies | cross-faction bridge |
| Jaxi | death token | on sell/death leaves Mini-Jax temporary ranged turret | Dying Wish tutorial | fun cheap value |
| Mana Artificer | tile economy | when sold after surviving 2 waves, creates temporary Mana Spring tile | map/economy bridge | makes maps feel alive |

---

## 6. Unit Upgrade System

The game needs upgrades, but the MVP should avoid huge branching trees. Use compact upgrades chosen from a small pool.

### Recommended model: three upgrade tiers

Each unit has three upgrade moments:

```text
Rank 1 -> base unit
Rank 2 -> choose one of two tactical upgrades
Rank 3 -> choose one of two identity upgrades
Rank 4 -> rare evolution, usually from trait/pact/relic, not normal gold
```

Example: Windblade Adept

```text
Rank 2A: Sharpened Blade - +25% damage
Rank 2B: Sun Guard - +1 range near core
Rank 3A: Zealot - gains big damage while core shield is not full
Rank 3B: Formation Fighter - gains attack speed for each adjacent Lyonar unit
Rank 4: Dawnblade Adept - first attack each wave hits twice and emits gold slash VFX
```

### Upgrade content rules

Upgrades should be written in a generic format:

```json
{
  "id": "windblade_zealot",
  "display_name": "Zealot",
  "unit_ids": ["windblade_adept"],
  "description": "+45% damage while core shield is below max.",
  "stat_mods": { "damage_mult_when_core_damaged": 1.45 },
  "behavior_mods": [],
  "vfx_profile_id": "vfx_lyonar_gold_flare"
}
```

This lets Claude add upgrades without touching core combat.

---

## 7. Traits and Flaws

The roguelike spice should come from traits and flaws. These modify Duelyst units so the same name does not always play the same.

### Trait examples

| Trait | Effect | Best on | VFX/SFX cue |
|---|---|---|---|
| Echoing | every third attack repeats at 50% power | ranged, blast, casters | ghost duplicate projectile |
| Overcharged | +40% damage, -20% cooldown, self-shocks nearby tile after wave | carries | electric crackle |
| Bonded | links to nearest ally; both gain small bonus if alive | support, guardians | thin tether line |
| Greedy | earns +1 gold on first elite kill each wave | snipers, assassins | coin sparkle |
| Frostbitten | attacks apply small slow | fast attackers | blue hit ring |
| Volcanic | first attack each wave creates small explosion | bruisers, artillery | lava burst |
| Haunted | on sell, spawns a weak enemy in next wave but gives bonus gold | cheap units | purple soul wisp |
| Mirrored | starts as two half-power copies | summons, cheap units | split shimmer |
| Veteran | starts at Rank 2 but costs more | any | silver border |
| Unstable | random high or low roll each wave | chaos units | glitchy aura |

### Flaw examples

| Flaw | Effect | Why it is useful |
|---|---|---|
| Fragile | takes extra damage from leak shock / map hazards | makes cheap power risky |
| Lazy | does not attack for first 2 seconds of combat | punishes fast waves |
| Proud | weaker if adjacent to another unit | spacing puzzle |
| Hungry | consumes 1 gold after each wave or loses damage | economy tension |
| Rooted | cannot move once placed unless upgraded | map commitment |
| Noisy | increases chance of elite in next wave | power with consequence |
| Fading | loses 5% damage each wave unless it gets a kill | anti-passive pressure |
| Oathbound | cannot be sold, but gives better stats | commitment |

### Draft offer format

```json
{
  "offer_id": "wave_4_offer_2",
  "unit_id": "heartseeker",
  "trait_id": "greedy",
  "flaw_id": "fragile",
  "cost": 7,
  "rarity": "uncommon"
}
```

---

## 8. Enemies

Enemies should also reuse Duelyst units. A player unit can appear as an enemy variant later, but use separate `EnemyDef` data so tuning does not contaminate player balance.

### Enemy readability rules

The player should identify threats within one second.

Use simple enemy classes:

```text
Runner      -> fast, low health
Bruiser     -> slow, high health
Swarm       -> many small bodies
Shielded    -> damage reduction until cracked
Caster      -> applies debuff or changes path state
Splitter    -> dies into smaller units
Healer      -> heals enemies nearby
Boss        -> unique wave centerpiece
```

### Enemy families from Duelyst content

| Enemy family | Duelyst assets to reuse | Behavior | Counterplay |
|---|---|---|---|
| Wraithling Swarm | Wraithling Token, Bad Omen, Bloodmoon Priestess | many low-health units; death-trigger bait | splash, Frenzy, pulses |
| Dervish Rush | Wind Dervish, Dunecaster, Orb Weaver | fast temporary attackers; some vanish if delayed | slows, early damage |
| Golem March | Rock Pulverizer, Skyrock Golem, Golem Metallurgist | slow armored line | armor break, Blast |
| Vespyr Frost | Snowchaser, Crystal Cloaker, Arctic Displacer | slows your attack speed / resists slow | raw damage, long range |
| Silithar Brood | Young Silithar, Veteran Silithar, Egg Token | rebirth into eggs if not overkilled | burst, execute |
| Magmar Stampede | Phalanxar, Earth Walker, Makantor Warbeast | fewer but heavier units; some Frenzy shockwaves | boss DPS, debuff |
| Abyssian Creep | Shadow Creep tile VFX, Shadowdancer, Vorpal Reaver | corrupts tiles after leaks | path control, cleanse effects |
| Mechaz0r Parts | Helm/Wings/etc., MECHAZ0R token | parts combine into elite if too many survive | priority targeting |
| General Echoes | Argeon, Kaleos, Zirix, Lilithe, Vaath, Faie, etc. | boss waves with faction mechanics | adapted strategy |

### EnemyDef example

```json
{
  "id": "enemy_wraithling_runner",
  "display_name": "Wraithling Runner",
  "asset_profile_id": "duelyst_wraithling_token",
  "family": "abyssian_swarm",
  "class": "runner",
  "hp": 20,
  "speed": 1.35,
  "armor": 0,
  "reward_gold": 1,
  "leak_damage": 1,
  "tags": ["swarm", "abyssian", "token"],
  "on_death": [],
  "vfx_trail": "vfx_shadow_wisp_trail"
}
```

---

## 9. Bosses

Bosses should be General Echoes. Use Duelyst generals and make each one a board event, not just a big HP bar.

### Boss design rules

A boss should test the player's build in a specific way:

```text
Can you kill a single high-health unit?
Can you handle adds?
Can you handle fast leaks?
Can you survive tile corruption?
Can you burst through shields?
Can you reposition around map mutation?
```

### First boss set

| Boss | Asset identity | Boss mechanic | Counterplay |
|---|---|---|---|
| Argeon Highmayne Echo | Lyonar general | periodically grants nearby enemies shield | splash after shield break; focus boss |
| Kaleos Xaan Echo | Songhai general | teleports forward every 25% HP lost | distributed defense, fast response |
| Zirix Starstrider Echo | Vetruvian general | summons Wind Dervish waves at side gates | anti-swarm and path coverage |
| Lilithe Blightchaser Echo | Abyssian general | spawns Wraithlings whenever an enemy dies | controlled kills, splash management |
| Vaath the Immortal Echo | Magmar general | grows damage/armor over time | early boss DPS |
| Faie Bloodwing Echo | Vanar general | periodically chills all units, slowing attacks | attack speed redundancy |

### Boss wave format

```json
{
  "wave_id": "boss_argeon_echo",
  "act": 1,
  "boss_id": "boss_argeon_echo",
  "spawn_groups": [
    { "time": 0, "enemy_id": "boss_argeon_echo", "count": 1, "path": "main" },
    { "time": 8, "enemy_id": "enemy_silverguard_shieldling", "count": 4, "interval": 0.8, "path": "main" }
  ],
  "modifiers": ["boss_music", "camera_warning", "no_shop_skip"]
}
```

---

## 10. Wave Content

### Wave rhythm

Each wave should have a readable purpose.

```text
Wave 1: teach basic runner
Wave 2: teach swarm
Wave 3: teach first elite
Wave 4: teach armored/bruiser
Wave 5: mini-boss or pact check
Wave 6: new path/event
Wave 7: speed check
Wave 8: swarm + armor mix
Wave 9: caster/support enemy
Wave 10: act boss
```

### First 16-wave campaign

This is a default solo run structure. Co-op can multiply or mirror it per board.

| Wave | Name | Content | Design purpose |
|---|---|---|---|
| 1 | Loose Wraiths | 12 Wraithling Runners | basic targeting and first kills |
| 2 | Dervish Line | 8 Wind Dervish Runners, 2 Dunecaster Acolytes | speed pressure |
| 3 | Golem Pebbles | 10 small Golem enemies, 1 Rock Pulverizer elite | introduces armor/bruiser |
| 4 | Frost Steps | Snowchaser runners that lightly slow attack speed | introduces status |
| 5 | First Echo | mini-boss: Silverguard Knight Echo + small adds | first build check |
| 6 | Split Dust | two spawn timings: Dervish rush then Wraithlings | tests coverage |
| 7 | Egg Clutch | Young Silithar enemies leave eggs if not burst down | teaches Rebirth threat |
| 8 | Creep Drizzle | Abyssian units corrupt 1-2 tiles on leak | map consequence |
| 9 | Scarab Corridor | Starfire Scarab slow elite with Dervish escort | line boss / anti-escort |
| 10 | Argeon Echo | Lyonar boss with shield pulses | act boss |
| 11 | Bazaar Flood | mixed Neutral swarm and Golems | post-boss density spike |
| 12 | Vanar Lock | Arctic Displacer elites stun nearby towers briefly | control pressure |
| 13 | Mech Parts | MECHAZ0R parts combine if enough leak/survive | priority targeting |
| 14 | Magmar Stampede | Phalanxar + Makantor elite rush | anti-bruiser + anti-swarm |
| 15 | Death Market | Abyssian enemies spawn Wraithlings on death | controlled AoE test |
| 16 | Faction Echo | random General Echo based on player's dominant build | final boss |

### Endless rules

Endless should not just add HP forever. It should add mutation layers.

```text
Endless 17-20: +HP, +speed, mixed families
Endless 21-25: two elite affixes per wave
Endless 26-30: map mutates every wave
Endless 31+: mirrored player units appear as enemy echoes
```

Recommended score formula:

```text
score = waves_cleared * 1000
      + gold_unspent * 10
      + core_health * 50
      + elite_kills * 100
      + pact_difficulty_bonus
      - leak_count * 100
```

---

## 11. Combat Mechanics

### Combat feel

Combat should be automatic but expressive. The player watches their machine operate. The joy comes from seeing the plan work.

Core principles:

```text
Readable before deep.
Big effects for big moments.
Fast waves should be exciting, not unreadable.
Damage numbers are optional; impact feedback is mandatory.
Every enemy death should feel like fuel.
```

### Combat phase pipeline

```text
1. Wave warning appears.
2. Enemies spawn according to WaveDef.
3. Units acquire targets according to targeting rules.
4. Units play windup/attack animation.
5. Projectiles or instant effects are spawned.
6. Hit is resolved.
7. Damage, status, death, gold, and triggers resolve.
8. Leak/core damage resolves.
9. End-of-wave effects resolve.
```

### Targeting rules

Every unit should support selectable or fixed targeting. Start fixed for MVP, then let advanced players override.

| Targeting mode | Use case |
|---|---|
| First | default TD behavior; target enemy closest to core |
| Last | cleanup / farming |
| Strongest | boss killer |
| Weakest | execute units |
| Fastest | anti-runner |
| Armored | anti-armor specialists |
| Marked | synergy builds |
| Random | chaos units only |

### Damage types

Keep damage types small at first.

| Damage type | Meaning | Strong against | Weak against |
|---|---|---|---|
| Strike | basic physical damage | unarmored, runners | armor |
| Arcane | magical/projectile damage | armor, shields | arcane-resistant enemies |
| Siege | slow heavy damage | structures, bosses, armor | swarms |
| Spirit | death/life/soul damage | shields, elites | spirit-resistant bosses |
| Frost | low damage + control | fast waves | frost enemies |
| True | rare, ignores mitigation | everything | should be limited |

### Armor and shields

Use simple rules.

```text
Armor reduces Strike and Frost damage by flat amount or percentage.
Shield absorbs a fixed amount before HP is hit.
Armor Break lowers armor for a short time.
Vulnerable increases all damage taken.
```

Avoid too many formulas. For MVP, use:

```text
final_damage = max(1, raw_damage - armor)
```

Then later switch to percentages if needed.

### Status effects

MVP statuses:

| Status | Effect | Notes |
|---|---|---|
| Slow | reduces movement speed | stack by strongest only |
| Stun | stops movement briefly | diminishing returns on bosses |
| Burn | damage over time | Magmar/Songhai/Vetruvian |
| Chill | reduces speed and attack pressure | Vanar |
| Marked | takes bonus damage from certain units | Songhai/Neutral |
| Vulnerable | takes increased damage | Vetruvian support |
| Shielded | absorbs damage | Lyonar enemies/units |
| Corrupted | creates negative tile or future debt | Abyssian |

### Trigger order

Trigger order must be deterministic for multiplayer, replay, and debugging.

Recommended order when an enemy dies:

```text
1. mark enemy as dying
2. award kill credit to last hitter
3. resolve on_hit kill triggers
4. resolve Deathwatch triggers from nearby/allied units
5. resolve enemy on_death effects
6. spawn tokens or child enemies
7. award gold/rewards
8. remove enemy body after death animation
```

### Blocking and pathing recommendation

Do not allow free unit blocking in MVP. It creates pathing problems fast.

Instead:

```text
Guardian units apply slow/intercept aura.
Treants/Eggs/Walls are temporary intercept objects, not true path blockers.
Enemies always have a valid path.
```

Later, the map editor can support dedicated blockade mode.

---

## 12. SFX and VFX Direction

### Audio/VFX goal

The player should be able to understand combat without reading numbers.

Every important event needs a distinct sound and visual identity:

```text
buy unit
place unit
invalid placement
upgrade unit
reroll shop
wave start
elite spawn
boss spawn
unit attack
enemy hit
enemy death
leak
core damage
pact chosen
gold gained
run lost
run won
```

### Faction VFX language

| Faction | Attack VFX | Hit VFX | Aura VFX | Death VFX |
|---|---|---|---|---|
| Lyonar | gold slashes, holy beams | shield sparks, gold burst | halo circle, banner glow | white-gold fade |
| Songhai | red slash trails, lightning | sharp spark, smoke pop | red wind swirl | smoke vanish |
| Vetruvian | sand beam, sun glyph | sand puff, bronze impact | obelisk rune pulse | dust collapse |
| Abyssian | purple souls, shadow bolts | black-purple splash | creep mist, soul orbit | soul release |
| Magmar | lava crack, bone impact | orange burst, quake ring | heat haze, ember field | ash explosion |
| Vanar | blue shard, frost mist | ice crack, snow puff | frost circle, snow orbit | crystal shatter |
| Neutral | simple impact, dust, generic magic | small burst | white/gray utility ring | normal poof |

### VFX priority tiers

Not all attacks can be huge. Use tiers.

```text
Tier 0: invisible math, no visual needed
Tier 1: small hit spark / projectile
Tier 2: normal unit attack VFX
Tier 3: elite attack, upgrade proc, large AoE
Tier 4: boss skill, pact trigger, wave mutation
```

Only 1-2 Tier 4 effects should happen at once.

### SFX profile system

Every unit should have an `sfx_profile_id`, not manually call files.

```json
{
  "id": "sfx_profile_lyonar_light_melee",
  "place": "sfx_ui_unit_place_gold",
  "attack_windup": "sfx_blade_swing_light",
  "attack_release": "sfx_lyonar_slash_release",
  "hit": "sfx_metal_light_hit",
  "death": "sfx_unit_death_light",
  "upgrade": "sfx_ui_upgrade_holy"
}
```

Fallback hierarchy:

```text
unit-specific sound
-> faction + role sound
-> role sound
-> generic sound
```

### Essential juice pass

Claude should add a `CombatJuiceController` early. It should support:

```text
hit pause for large hits
small camera shake for boss/leak only
floating gold pickup
brief enemy flash on hit
outline pulse on upgraded unit
core pulse on damage
screen-edge warning on leak
wave clear fanfare
```

Keep shake rare. Constant shake makes TD unreadable.

---

## 13. Maps and Visual Layout

### Map fantasy

Maps should look like Duelyst tactical battlefields stretched into tower defense lanes.

They should not look like random mazes. They should look like ritual arenas with clear lanes, build pads, faction flavor, and readable path direction.

The player should instantly know:

```text
where enemies spawn
where they are going
where I can build
which tiles are special
which path is dangerous
```

### Recommended camera/layout

For solo MVP:

```text
Board size: 11x9, 13x9, or 15x9
Path width: 1 tile
Buildable tiles: mostly adjacent to path, with pockets
Camera: fixed orthographic 2D
Unit anchor: centered on build tile, sprite slightly above tile center
Enemy anchor: path centerline
UI: shop on bottom or right side
```

For split-screen later:

```text
Board size should stay compact.
Do not make boards visually huge.
Let co-op feel like several little machines running together.
```

### Tile categories

| Tile | Visual | Gameplay |
|---|---|---|
| Path | brighter road / lane markers | enemies walk here |
| Buildable | raised pad / clean tile | units can be placed |
| Blocked | rocks, ruins, void, wall | no path/no build |
| Core | shrine/crystal/portal | enemies target this |
| Spawn | portal/gate | enemies enter here |
| Mana Spring | glowing blue/green rune | extra income or cooldown bonus |
| Shrine | faction rune | faction-specific bonuses |
| Cracked Tile | damaged ground | bonus power, chance to break |
| Creep Tile | Abyssian shadow | debuff or death synergy |
| Frost Tile | snow/ice overlay | slow/status synergy |
| Lava Tile | Magmar crack | damage/burn synergy |
| Portal Tile | swirling gate | alternate routing / co-op intercept |

### Map generator grammar

Instead of totally random maps, use lane grammar templates.

```text
Straight Lane       -> beginner readable
S-Curve             -> more tower coverage value
Fork and Merge      -> split pressure but same destination
Two-Spawner Merge   -> wave timing puzzle
Loop Pocket         -> enemies spend longer near central build area
Outer Ring          -> long path around build island
Broken Bridge       -> path has risky short segment near core
```

A generated map is:

```text
Theme + Lane Grammar + Special Tile Set + Build Pocket Pattern + Mutation Rule
```

Example:

```text
Vanar Frost Pass
+ S-Curve
+ Frost Tiles and Cracked Ice
+ two high-ground build pockets
+ every 4 waves one Frost Tile shifts position
```

### Map readability rules

Use three visual layers:

```text
Layer 1: background art / ambience, low contrast
Layer 2: gameplay grid, high clarity
Layer 3: units/effects/UI, highest clarity
```

Do not let background detail fight path readability. Duelyst art is rich; the TD board needs strong readability.

---

## 14. Map Themes

Each theme reuses Duelyst map/tile/faction assets but changes gameplay modifiers.

### Theme 1: Lyonar Citadel Causeway

Look:

```text
gold-white stone, banners, clean paths, glowing core shrine
```

Gameplay:

```text
more Shrine tiles
guardian units gain bonus
leaks damage shield before heart
```

Special tiles:

```text
Sun Shrine: adjacent units gain +10% damage while core shield is full
Banner Tile: support auras are 1 tile larger
```

### Theme 2: Songhai Rooftop Canal

Look:

```text
red rooftops, smoke, lanterns, narrow bridges, fast path lines
```

Gameplay:

```text
faster waves
more teleport/portal events
movement and repositioning matter
```

Special tiles:

```text
Blink Pad: unit placed here may move once after combat starts
Duelist Tile: first attack each wave is faster
```

### Theme 3: Vetruvian Sun Ruins

Look:

```text
desert stone, obelisks, sun glyphs, bronze platforms
```

Gameplay:

```text
longer straight lines for Blast units
summon structures have better tile support
```

Special tiles:

```text
Obelisk Socket: structures gain attack speed
Sunline Tile: line attacks deal +15% damage
```

### Theme 4: Abyssian Creep Mire

Look:

```text
purple-black ground, void cracks, soul fog, corrupted shrine
```

Gameplay:

```text
some leaks create Creep tiles
Abyssian units gain from deaths
risk/reward economy pacts appear more often
```

Special tiles:

```text
Creep Tile: Abyssian units gain power; non-Abyssian units lose small attack speed
Soul Well: first death nearby each wave grants gold or shield
```

### Theme 5: Magmar Fossil Rift

Look:

```text
lava cracks, bones, amber pools, broken stone bridges
```

Gameplay:

```text
more cracked tiles
Grow/Rebirth units are rewarded
some tiles become dangerous after waves
```

Special tiles:

```text
Lava Crack: attacks apply Burn, but tile may break after combat
Egg Nest: Rebirth units revive faster
```

### Theme 6: Vanar Frost Pass

Look:

```text
ice roads, blue crystals, snow drifts, frozen ruins
```

Gameplay:

```text
slow/control stronger
some enemies resist slow
paths can be visually slippery but mechanically clear
```

Special tiles:

```text
Frost Rune: attacks apply minor Chill
Crystal Shelf: +1 range, but cannot place heavy units
```

### Theme 7: Neutral Mana Bazaar

Look:

```text
classic Duelyst board vibe, mana springs, mixed banners, tournament arena
```

Gameplay:

```text
balanced teaching map
more economy tiles
best for first tutorial and editor testing
```

Special tiles:

```text
Mana Spring: +1 gold after every 3 waves if occupied
Market Tile: unit upgrades are discounted
```

---

## 15. Core Gameplay Content Loop

### The loop that should never change

The player should always be doing this:

```text
1. See the next wave preview.
2. Receive gold and draft offers.
3. Buy or greed.
4. Place or reposition a few units.
5. Choose one interesting risk/reward option.
6. Start wave.
7. Watch the build perform.
8. Get rewards and consequences.
9. Repeat.
```

This is the repetitive joy. The novelty comes from what changes inside that loop.

### What changes every session

```text
map seed
lane grammar
tile bonuses
starting faction bias
shop offers
unit traits/flaws
pacts
enemy family order
boss echo
run relics
leak consequences
```

### What stays learnable

```text
unit names and identities
basic enemy family behavior
wave rhythm
faction archetypes
economy pressure
core UI
combat timing
```

The trick is not infinite randomness. The trick is a stable grammar with random sentences.

### Dota / Legion / Chaos style ingredients

These games have a repeated preparation-combat rhythm with small optimizations that stack into big differences. Use these ingredients:

| Ingredient | TD implementation |
|---|---|
| clear phases | planning/combat/reward are distinct |
| economy greed | interest, risky economy units, late payoff |
| build identity | faction tags and unit synergies |
| power spikes | Rank 3 units, pacts, boss rewards |
| social moments | co-op aid, taunts, leak saves, shared pacts |
| readable failure | post-wave report says what leaked and why |
| build memes | strange unit+trait combos can carry runs |
| score chasing | seed score, endless wave, faction records |

### The good repetition formula

Each wave should ask:

```text
Can my current machine handle this specific pressure?
Should I patch a weakness or greed for scaling?
Do I trust my build enough to take a curse for future power?
```

If the answer is obvious too often, the run is boring. If the answer is unknowable, the run feels unfair.

---

## 16. Economy and Rewards

### Gold income

Suggested default:

```text
base gold per wave = 5 + floor(wave / 2)
kill gold = small, mostly from elites
leak penalty = no kill gold for leaked enemy
interest = optional, capped, unlock after MVP
```

### Economy units

Economy should be visible on the board, not only in menus.

Examples:

```text
Crystal Wisp: survive waves to generate gold.
Widowmaker: earns gold on first elite kill.
Kujata: discounts nearby new units at a health/stability cost.
Mana Artificer: creates a Mana Spring tile after surviving.
Golem Metallurgist: discounts Golem purchases/upgrades.
```

### Reward types

After special waves, offer one of these:

```text
free unit draft
trait injection
upgrade discount
pact choice
map tile blessing
core shield repair
shop size increase
faction banner bonus
```

### Avoid early meta-stat bloat

Do not add permanent +damage upgrades between runs in the first version. Use unlocks instead:

```text
unlock units
unlock traits
unlock pacts
unlock map themes
unlock bosses
unlock starting banners
unlock cosmetic borders
```

---

## 17. Pacts as Content

Pacts should be content, not code. They are the easiest way to create wild runs while reusing assets.

### Pact examples

| Pact | Boon | Curse | Visual/audio identity |
|---|---|---|---|
| Shared Arsenal | all players get a free draft | enemy HP +15% | neutral armory fanfare |
| Blood Dividend | gain gold when allied temporary units expire/die | non-temporary units lose small HP/shield each wave | Abyssian soul coin |
| Greedy Horizon | +3 gold per wave | shop has one fewer offer | Vetruvian sun market |
| Mirror War | strongest unit gains +25% damage | a copy appears as enemy mini-boss later | mirror shimmer |
| Frost Tax | enemies start slowed | every fifth enemy is slow-resistant | Vanar frost bell |
| Magma Oath | units gain Grow +1/+1 equivalent after boss | cracked tiles spread | Magmar eruption |
| Duelist's Bet | first unit placed each wave gets huge buff | if it gets no kills, lose gold | Songhai challenge gong |
| Citadel Law | core shield doubles | leaks spawn shielded enemies next wave | Lyonar horn |

### PactDef example

```json
{
  "id": "mirror_war",
  "display_name": "Mirror War",
  "rarity": "rare",
  "boon": {
    "type": "stat_mod_dominant_unit",
    "damage_mult": 1.25
  },
  "curse": {
    "type": "schedule_enemy_echo_of_strongest_unit",
    "delay_waves": 3
  },
  "vfx_profile_id": "vfx_mirror_shatter",
  "sfx_profile_id": "sfx_pact_mirror"
}
```

---

## 18. Shop and Draft Presentation

### Draft card layout

Use Duelyst card-like UI language.

Each offer card should show:

```text
unit portrait / animated idle preview
unit name
faction crest
cost
role icon
trait
flaw, if any
short kit text
DPS/control/economy tags
```

Example offer text:

```text
Azurite Lion
Lyonar / Celerity / Striker
Attacks twice per cycle.
Trait: Frostbitten - attacks apply minor slow.
Flaw: Proud - weaker next to allies.
Cost: 8 gold
```

### Draft sizes

Default:

```text
Wave 1: choose 1 of 3 starter units
Normal wave: shop has 4 offers
After boss: choose 1 of 3 rare rewards
Pact waves: pact choice + normal shop
```

### Shop UX features

```text
reroll
lock one offer
compare to owned units
show synergy tags
show affordable highlight
show warning if missing anti-swarm / anti-armor / boss DPS
```

Claude should implement shop as data-driven UI, not one-off panels.

---

## 19. Co-op Content Hooks

Even if multiplayer is later, content should support it.

### Co-op-specific content types

```text
Aid Units: temporary copied units sent to ally board
Team Pacts: shared boons/curses
Intercept Waves: leaked enemies appear on ally side path
Rescue Rewards: ally saving a leak grants both players gold
Taunt Waves: player pulls extra enemies for team reward
```

### Units that naturally support co-op later

| Unit | Co-op use |
|---|---|
| Ironcliffe Guardian | can intercept ally leak through Aid Portal |
| Heartseeker | temporary long-range aid unit |
| Ethereal Obelysk | sends Wind Dervish token to ally board |
| Bloodmoon Priestess | ally death/summon synergy pact |
| Kujata | discounts unit gifted to ally |
| Crystal Wisp | team economy bonus if protected |
| Healing Mystic | aid heal/shield dispatch |

### Co-op visual rule

Each player board should have a player-color edge treatment, but unit/faction colors remain Duelyst-authentic.

```text
Player 1: blue board edge
Player 2: red board edge
Player 3: green board edge
Player 4: purple board edge
```

Do not recolor every unit by player; it will damage faction readability.

---

## 20. Arena / Rival Storm Content

Arena should use the same units and enemy families, but with different economy.

### Send system

Players do not send arbitrary placed towers as enemies in the first version. They send attacker packets based on tags.

| Player build tag | Send packet unlocked |
|---|---|
| Lyonar / Guardian | Shielded March |
| Songhai / Assassin | Blink Runner |
| Vetruvian / Dervish | Dervish Rush |
| Abyssian / Wraithling | Wraith Swarm |
| Magmar / Grow | Primal Bruiser |
| Vanar / Frost | Chill Pack |
| Neutral / Golem | Golem Line |
| Mech | MECHAZ0R Parts |

### Arena round rhythm

```text
planning phase
send selection phase
combat phase
income reward
pressure escalation
```

Arena can become a separate mode once Run Defense is fun.

---

## 21. Content Data Schemas

### UnitDef

```json
{
  "id": "windblade_adept",
  "display_name": "Windblade Adept",
  "source": "duelyst",
  "asset_profile_id": "duelyst_windblade_adept",
  "faction": "lyonar",
  "roles": ["striker", "starter"],
  "keywords": ["zeal"],
  "tags": ["lyonar", "melee", "single_target", "zeal"],
  "cost": 5,
  "range": 2,
  "damage": 8,
  "cooldown": 0.85,
  "damage_type": "strike",
  "targeting": "first",
  "attack_pattern": "single",
  "placement_rules": ["buildable_tile"],
  "ability_package_id": "ability_zeal_core_damage_bonus",
  "upgrade_pool": ["windblade_sharpened", "windblade_sunguard", "windblade_zealot"],
  "sfx_profile_id": "sfx_profile_lyonar_light_melee",
  "vfx_profile_id": "vfx_profile_lyonar_slash"
}
```

### AbilityPackageDef

```json
{
  "id": "ability_celerity_double_attack",
  "display_name": "Celerity",
  "description": "Attacks twice each attack cycle.",
  "trigger": "on_attack_cycle",
  "effects": [
    { "type": "perform_attack", "damage_mult": 1.0 },
    { "type": "perform_attack", "damage_mult": 0.75, "delay": 0.15 }
  ]
}
```

### VfxProfileDef

```json
{
  "id": "vfx_profile_vetruvian_blast",
  "attack_windup": "fx_sun_glyph_charge",
  "projectile": "fx_sand_beam_line",
  "hit": "fx_bronze_impact",
  "kill": "fx_dust_collapse",
  "aura": null,
  "priority_tier": 2
}
```

### MapThemeDef

```json
{
  "id": "vanar_frost_pass",
  "display_name": "Vanar Frost Pass",
  "background_asset": "duelyst_map_frost",
  "tile_palette": "vanar_ice_tiles",
  "music_profile_id": "music_profile_frost_planning_combat",
  "allowed_special_tiles": ["frost_rune", "crystal_shelf", "cracked_ice"],
  "enemy_family_bias": ["vespyr_frost", "golem_march"],
  "lighting_profile": "cold_blue"
}
```

### WaveDef

```json
{
  "id": "wave_07_egg_clutch",
  "display_name": "Egg Clutch",
  "wave_index": 7,
  "preview_tags": ["rebirth", "burst_required"],
  "spawn_groups": [
    { "time": 0.0, "enemy_id": "enemy_young_silithar", "count": 8, "interval": 0.9, "path": "main" },
    { "time": 7.0, "enemy_id": "enemy_veteran_silithar_elite", "count": 2, "interval": 2.5, "path": "main" }
  ],
  "rewards": {
    "base_gold": 8,
    "bonus_choices": []
  }
}
```

---

## 22. MVP Content Implementation Plan for Claude Code

### Iteration C1: Content manifest

Goal: create content data folders and asset profiles.

Acceptance criteria:

```text
data/content/factions.json exists
data/content/unit_asset_profiles.json exists
data/content/vfx_profiles.json exists
data/content/sfx_profiles.json exists
Game can load content files and report missing asset references without crashing.
```

### Iteration C2: First 12 units

Goal: implement enough units to play early waves.

Use:

```text
Windblade Adept
Azurite Lion
Silverguard Knight
Heartseeker
Kaido Assassin
Pyromancer
Ethereal Obelysk
Bloodmoon Priestess
Young Silithar
Earth Walker
Snowchaser
Healing Mystic
```

Acceptance criteria:

```text
All 12 appear in shop.
All 12 can be placed.
Each has distinct attack behavior or stat identity.
Missing assets use fallback sprite/profile.
```

### Iteration C3: Enemy families

Goal: implement first enemy families.

Use:

```text
Wraithling Runner
Wind Dervish Runner
Rock Pulverizer Elite
Snowchaser Frostling
Young Silithar Eggling
```

Acceptance criteria:

```text
Enemies use Duelyst unit/token visuals.
Each family has distinct speed/HP/behavior.
Wave preview shows family tags.
```

### Iteration C4: First 10 waves

Goal: build first act.

Acceptance criteria:

```text
Wave 1-10 can be completed.
Wave 5 has mini-boss.
Wave 10 has Argeon Echo or placeholder General Echo.
Wave summary shows leaks, kills, gold, MVP unit.
```

### Iteration C5: SFX/VFX pass

Goal: make combat satisfying.

Acceptance criteria:

```text
Attack, hit, death, gold, leak, upgrade, wave start, boss warning have sounds.
Each faction has at least one unique attack/hit VFX profile.
Large hits have subtle hit pause.
```

### Iteration C6: Map themes and generator palette

Goal: make generated maps look intentional.

Acceptance criteria:

```text
At least 3 themes implemented: Neutral Mana Bazaar, Lyonar Citadel Causeway, Vanar Frost Pass.
Generated maps use theme tile palette.
Path/build/core/spawn tiles are visually clear.
```

### Iteration C7: Traits/flaws

Goal: make repeated units feel different.

Acceptance criteria:

```text
At least 8 traits and 6 flaws implemented.
Shop offers can display unit + trait + flaw.
Trait effects work in combat.
```

### Iteration C8: Pacts

Goal: add big run variety.

Acceptance criteria:

```text
At least 6 pacts exist.
Pacts show Duelyst-style reward cards.
Pact effects modify combat/economy/waves.
```

---

## 23. Prompt Template for Claude Code - Content Iteration

Use this prompt when adding content:

```text
Read docs/co_op_roguelike_td_design_doc.md and docs/shardstorm_td_content_bible.md.

Implement content iteration: [NAME].

Constraints:
- Reuse Duelyst/OpenDuelyst assets where possible.
- Do not hard-code asset filenames in combat code.
- Add content through data files first.
- Missing assets must fall back gracefully.
- Keep all randomness seeded through SessionRng.
- Keep combat deterministic.
- Update content docs if any schema changes.

Before coding, summarize:
1. Content files you will add or modify.
2. Asset profiles needed.
3. Behaviors or abilities required.
4. Risks and fallback plan.
5. How I will test it in Godot.

After coding, summarize:
1. What content was added.
2. What assets are still placeholders.
3. How to test.
4. What balance values are most likely to need tuning.
```

---

## 24. Balance Starting Points

### Unit cost bands

```text
3-5 gold: cheap starter / utility
6-9 gold: normal core units
10-14 gold: strong specialized units
15-20 gold: legendary or late-run anchors
```

### Unit DPS bands

```text
cheap support: 4-8 DPS
starter damage: 8-14 DPS
mid damage: 15-25 DPS
specialized anti-swarm: lower single-target, high total damage
boss killer: high single-target, weak swarm coverage
legendary: strong but requires build or drawback
```

### Enemy HP bands

```text
wave 1 runner: 10-25 HP
wave 1 bruiser: 40-70 HP
early elite: 150-250 HP
act 1 boss: 1000-1800 HP depending on map length
```

### Speed bands

```text
slow: 0.65x
normal: 1.0x
fast: 1.35x
runner: 1.65x
boss: 0.45x-0.75x
```

### Gold sanity

The player should usually be able to buy:

```text
Wave 1: 1 cheap unit
Wave 2: 1 cheap or save
Wave 3: second unit or first upgrade
Wave 5: at least 3-5 placed units
Wave 10: one strong identity online
```

If the player has nothing interesting to buy for two waves in a row, the economy is too stingy or the shop is too random.

---

## 25. Content QA Checklist

Before adding more content, check this:

```text
Can I tell what killed me?
Can I tell what each faction does?
Can I tell path tiles from build tiles instantly?
Does each wave have a purpose?
Does each unit have a reason to exist?
Does the shop offer at least one useful choice most waves?
Does the run produce at least one surprising combo?
Do SFX/VFX make hits feel good without clutter?
Can the same unit feel different with a trait/flaw?
Can Claude add a unit by editing data only?
```

If not, add clarity before adding more units.

---

## 26. Recommended First Vertical Slice

Build a small polished slice before scaling content.

### Slice content

```text
Map: Neutral Mana Bazaar
Waves: 1-5
Player units: 12
Enemy families: Wraithling, Dervish, Golem, Frost
Boss: Silverguard Knight Echo
Traits: Echoing, Frostbitten, Greedy, Volcanic
Flaws: Fragile, Lazy, Rooted
Pacts: Greedy Horizon, Shared Arsenal, Mirror War
```

### Slice success criteria

The slice is successful if:

```text
the same five waves are fun to replay three times
runs feel different due to draft and traits
the player can understand every leak
the best moment is visible without reading numbers
the content is loaded from data
```

Do not add 100 units before this slice feels good.

---

## 27. Final Content Bet

The strongest content direction is not simply "Duelyst tower defense." It is:

> A Duelyst asset remix where every run drafts a strange little army-machine, then tests it against faction-shaped wave puzzles on unstable generated battlefields.

The game should be easy to watch, easy to replay, and hard to solve perfectly.

The content should produce stories like:

```text
I got a Greedy Widowmaker and built my whole economy around elite sniping.
My Bloodmoon Priestess carried until Mirror War copied her into a nightmare boss.
A Vanar map made my bad slow build amazing.
Kujata discounted my army but almost killed my run with fragile units.
Our co-op board survived because an Ironcliffe Guardian aid portal intercepted the final leak.
```

That is the magic: familiar ritual, strange run, visible machine.
