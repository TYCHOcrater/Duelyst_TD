class_name FailureCoach
extends RefCounted

# Rule-based advice generator. analyze(stats) -> Array of insight dicts
# {severity, title, body, hint}.
#
# Severities:
#   3 = primary cause (only fires on defeat)
#   2 = real problem (fires on either result)
#   1 = soft observation

# Per-family advice for the "you lost to X" insight.
const FAMILY_ADVICE := {
	"swarm": {
		"title": "Swarm overran you",
		"body": "Swarm enemies leaked the most. Nothing was breaking up the groups.",
		"hint": "Splash damage (Pyromancer, Firebreather) clears swarms fast. Even one mid-lane changes the math.",
	},
	"fast": {
		"title": "Runners punished short coverage",
		"body": "Fast enemies sprinted past your towers.",
		"hint": "Slows (Snowchaser, Frost Dryad) buy your other towers the seconds they need.",
	},
	"tank": {
		"title": "Tanks soaked everything",
		"body": "High-HP enemies walked through your DPS.",
		"hint": "Burst single-target (Caster, Kaido Assassin) chews through big HP. Targeting 'strongest' helps.",
	},
	"armored": {
		"title": "Armor blunted your damage",
		"body": "Armored enemies took heavily reduced damage.",
		"hint": "Arcane/spirit/frost (Pyromancer, Caster, Snowchaser, Bloodmoon Priestess) bypasses armor. Strike damage gets eaten.",
	},
	"regen": {
		"title": "Regen out-healed your damage",
		"body": "Regenerating enemies recovered between hits.",
		"hint": "Burst kills (Caster, Kaido Assassin) beat regen. Sustained chip damage gives them time to heal.",
	},
	"shielded": {
		"title": "Shields ate your big shots",
		"body": "Shielded enemies absorbed first hits and reduced magic damage afterward.",
		"hint": "Fast multi-hit (Archer, Azurite Lion, Sandcaster) eats shields. Heavy single-shot casters waste damage on the shield.",
	},
	"boss": {
		"title": "The boss tanked the run",
		"body": "The boss walked the rest of the way after surviving your fire.",
		"hint": "Single-target casters (Caster, Kaido Assassin) focus bosses. Mix in splash for the adds.",
	},
}

static func analyze(stats: Dictionary) -> Array:
	var insights: Array = []
	var result: String = String(stats.get("result", "in_progress"))

	# --- Severity 3: who killed you (defeat only) ---
	if result == "defeat":
		var by_family := _aggregate_leaks_by_family(stats)
		var top_family := _argmax_str(by_family)
		if top_family != "" and int(by_family.get(top_family, 0)) >= 1 and FAMILY_ADVICE.has(top_family):
			var adv: Dictionary = FAMILY_ADVICE[top_family]
			var n: int = int(by_family[top_family])
			insights.append({
				"severity": 3,
				"title": adv.get("title", ""),
				"body": adv.get("body", "") + "  (%d leaked)" % n,
				"hint": adv.get("hint", ""),
			})

	# --- Severity 2: damage-type imbalance vs encountered families ---
	var dmg_by_type := _damage_by_type(stats)
	var total_dmg: int = 0
	for v in dmg_by_type.values():
		total_dmg += int(v)
	if total_dmg > 0:
		var phys: int = int(dmg_by_type.get("strike", 0)) + int(dmg_by_type.get("siege", 0))
		var magic: int = int(dmg_by_type.get("arcane", 0)) + int(dmg_by_type.get("spirit", 0)) + int(dmg_by_type.get("frost", 0))
		var phys_pct: float = float(phys) / float(total_dmg)
		var magic_pct: float = float(magic) / float(total_dmg)
		var seen_armored: bool = _faced_family(stats, "armored")
		var seen_shielded: bool = _faced_family(stats, "shielded")
		if phys_pct >= 0.80 and seen_armored:
			insights.append({
				"severity": 2,
				"title": "Damage too one-sided",
				"body": "%d%% of your damage was strike/siege. Armored enemies cut that in half." % int(round(phys_pct * 100)),
				"hint": "Bring at least one arcane/frost tower (Pyromancer, Caster, Snowchaser) for armored waves.",
			})
		if magic_pct >= 0.80 and seen_shielded:
			insights.append({
				"severity": 2,
				"title": "All magic, no multi-hit",
				"body": "%d%% of your damage was arcane/spirit/frost. Shields halved most of it." % int(round(magic_pct * 100)),
				"hint": "A fast multi-hit tower (Archer, Azurite Lion, Sandcaster) eats shields before they reduce the rest.",
			})

	# --- Severity 1-2: economy heuristics ---
	if int(stats.get("rerolls", 0)) >= 6:
		insights.append({
			"severity": 1,
			"title": "Lots of rerolls",
			"body": "%d rerolls this run; that's gold spent hunting offers." % int(stats.get("rerolls", 0)),
			"hint": "Sometimes locking the build and upgrading what's placed pays more than chasing perfect picks.",
		})
	var floated: int = int(stats.get("gold_earned", 0)) - int(stats.get("gold_spent", 0))
	if floated > 40 and result == "defeat":
		insights.append({
			"severity": 2,
			"title": "Sat on gold",
			"body": "Run ended with %d gold unspent." % floated,
			"hint": "Past wave 5 or so, converting gold into placed/upgraded units usually wins over hoarding.",
		})
	var bought: int = int(stats.get("units_bought", 0))
	var wave: int = int(stats.get("wave_reached", 0))
	if bought <= 2 and result == "defeat" and wave >= 3:
		insights.append({
			"severity": 2,
			"title": "Too few units placed",
			"body": "Only %d unit(s) placed across %d waves." % [bought, wave],
			"hint": "Even a cheap second or third tower at chokepoints adds a lot of coverage.",
		})

	# Sort by severity descending and cap to keep the panel readable.
	insights.sort_custom(func(a, b): return int(a.severity) > int(b.severity))
	if insights.size() > 3:
		insights = insights.slice(0, 3)
	return insights

# --- helpers ---

static func _aggregate_leaks_by_family(stats: Dictionary) -> Dictionary:
	var by_enemy: Dictionary = stats.get("leaks_by_enemy", {})
	var by_family: Dictionary = {}
	for eid in by_enemy:
		var def: Dictionary = EnemyFactory.get_def(String(eid))
		var fam: String = def.get("family", "unknown")
		by_family[fam] = int(by_family.get(fam, 0)) + int(by_enemy[eid])
	return by_family

static func _damage_by_type(stats: Dictionary) -> Dictionary:
	var by_unit: Dictionary = stats.get("damage_by_unit", {})
	var by_type: Dictionary = {}
	for uid in by_unit:
		var def: Dictionary = UnitFactory.get_def(String(uid))
		var dt: String = def.get("damage_type", "strike")
		by_type[dt] = int(by_type.get(dt, 0)) + int(by_unit[uid])
	return by_type

static func _faced_family(stats: Dictionary, family: String) -> bool:
	# Did the player encounter this family at all this run?
	# Look in kills_by_enemy + leaks_by_enemy (any encounter at all).
	for source in ["kills_by_enemy", "leaks_by_enemy"]:
		var d: Dictionary = stats.get(source, {})
		for eid in d:
			var def: Dictionary = EnemyFactory.get_def(String(eid))
			if def.get("family", "") == family:
				return true
	return false

static func _argmax_str(d: Dictionary) -> String:
	var best_key := ""
	var best_val: int = -1
	for k in d:
		var v := int(d[k])
		if v > best_val:
			best_val = v
			best_key = String(k)
	return best_key
