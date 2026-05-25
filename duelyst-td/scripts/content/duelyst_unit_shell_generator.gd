extends RefCounted

# DuelystUnitShellGenerator (D7 of the ingestion milestone).
#
# Reads unit_catalog.json (D6 output) and produces GeneratedUnitShell records:
# conservative tower-like gameplay stats inferred from the unit's visual_tags
# and faction. Every shell:
#   - balance_state = "generated_unbalanced"
#   - enabled_in_normal_runs = false (per content promotion rules)
#   - enabled_in_debug      = true
#
# Output: user://duelyst_content/unit_shells.json + report_unit_shells.json
#
# These shells are NOT written into res://data/units/. That promotion happens
# later via the content pack enablement UI (D14) once specific shells have
# been validated in the debug sandbox. Until then they exist only as
# user://-stored generated data.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

# Role → baseline stats (cost, range_px, damage, fire_rate, damage_type, extras).
# Range in pixels matches existing UnitDef schema (1 tile = ~64px).
const ROLE_TEMPLATES := {
	"basic_melee":    {"cost": 6,  "range": 96,  "damage": 5, "fire_rate": 1.0, "damage_type": "strike",  "extras": {}},
	"basic_ranged":   {"cost": 7,  "range": 192, "damage": 4, "fire_rate": 0.9, "damage_type": "strike",  "extras": {}},
	"blocker":        {"cost": 8,  "range": 80,  "damage": 4, "fire_rate": 0.8, "damage_type": "strike",  "extras": {}},
	"splash_mage":    {"cost": 9,  "range": 160, "damage": 6, "fire_rate": 0.7, "damage_type": "arcane",  "extras": {"splash_radius": 48}},
	"support_aura":   {"cost": 6,  "range": 112, "damage": 0, "fire_rate": 1.0, "damage_type": "strike",  "extras": {"buff_damage_mult": 0.15, "buff_radius": 96}},
	"control_unit":   {"cost": 7,  "range": 176, "damage": 3, "fire_rate": 0.8, "damage_type": "frost",   "extras": {"slow_duration": 0.6, "slow_factor": 0.6}},
	"assassin":       {"cost": 8,  "range": 112, "damage": 8, "fire_rate": 1.3, "damage_type": "strike",  "extras": {}},
	"artillery":      {"cost": 11, "range": 256, "damage": 7, "fire_rate": 0.5, "damage_type": "siege",   "extras": {"splash_radius": 64}},
	"summoner":       {"cost": 9,  "range": 144, "damage": 2, "fire_rate": 0.7, "damage_type": "spirit",  "extras": {}},
	"economy_unit":   {"cost": 8,  "range": 0,   "damage": 0, "fire_rate": 0.0, "damage_type": "strike",  "extras": {"gold_per_wave": 2}},
	"boss_body":      {"cost": 18, "range": 112, "damage": 10,"fire_rate": 0.5, "damage_type": "strike",  "extras": {}},
}

# Visual tag → role.
const VISUAL_TAG_TO_ROLE := {
	"humanoid_armor":    "blocker",
	"humanoid_ranged":   "basic_ranged",
	"humanoid_caster":   "splash_mage",
	"humanoid_agile":    "assassin",
	"beast":             "basic_melee",
	"reptile":           "basic_melee",
	"dragon":            "artillery",
	"construct_large":   "artillery",
	"construct":         "blocker",
	"demon_small":       "basic_melee",
	"spirit":            "control_unit",
	"boss":              "boss_body",
}

# Faction colour for projectiles (matches existing FACTION_COLORS in hud.gd).
const FACTION_COLORS := {
	"lyonar":    [1.0, 0.85, 0.4],
	"songhai":   [1.0, 0.4, 0.4],
	"vetruvian": [0.95, 0.7, 0.35],
	"abyssian":  [0.7, 0.4, 1.0],
	"magmar":    [1.0, 0.55, 0.25],
	"vanar":     [0.55, 0.85, 1.0],
	"neutral":   [0.85, 0.85, 0.85],
}

# Faction hint biases the role pick when visual tags are ambiguous / empty.
const FACTION_DEFAULT_ROLE := {
	"lyonar":    "blocker",
	"songhai":   "assassin",
	"vetruvian": "artillery",
	"abyssian":  "splash_mage",
	"magmar":    "basic_melee",
	"vanar":     "control_unit",
	"neutral":   "basic_melee",
	"":          "basic_melee",
}

static func generate() -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var cat_path: String = settings.output_path_for("unit_catalog.json")
	if not FileAccess.file_exists(cat_path):
		return {"ok": false, "message": "Unit catalog missing — run D6 first."}
	var f := FileAccess.open(cat_path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "unit_catalog.json malformed."}
	var units: Array = parsed.get("units", [])
	var shells: Array = []
	var role_counts: Dictionary = {}
	var faction_counts: Dictionary = {}
	for u in units:
		# Skip readiness < 2 (no plist/png at all) and frame-name false positives.
		var readiness: int = int(u.get("readiness_level", 0))
		if readiness < 2:
			continue
		var prefix: String = u.get("id", "")
		var faction: String = u.get("faction", "")
		var visual_tags: Array = u.get("visual_tags", [])
		var role: String = _pick_role(visual_tags, faction, prefix)
		var template: Dictionary = ROLE_TEMPLATES[role]
		var shell: Dictionary = {
			"id": prefix + "_shell",
			"source_duelyst_unit_id": prefix,
			"display_name": u.get("display_name", prefix),
			"faction": faction if faction != "" else "neutral",
			"asset_profile_id": prefix,
			"role": role,
			"rarity": _rarity_for(prefix, role),
			"cost": int(template["cost"]),
			"range": int(template["range"]),
			"damage": int(template["damage"]),
			"fire_rate": float(template["fire_rate"]),
			"damage_type": template["damage_type"],
			"targeting": "first",
			"projectile_speed": 440,
			"projectile_color": FACTION_COLORS.get(faction, FACTION_COLORS["neutral"]),
			"tags": _tags_for(faction, visual_tags, role),
			"allowed_roles": u.get("allowed_roles", ["defender"]),
			"animation_set": u.get("animation_set", {}),
			"description": _description_for(role, faction),
			"balance_state": "generated_unbalanced",
			"enabled_in_normal_runs": false,
			"enabled_in_debug": true,
		}
		# Apply role-specific extras.
		for k in (template["extras"] as Dictionary).keys():
			shell[k] = template["extras"][k]
		shells.append(shell)
		role_counts[role] = int(role_counts.get(role, 0)) + 1
		faction_counts[faction] = int(faction_counts.get(faction, 0)) + 1
	# Write outputs
	var out_path: String = settings.output_path_for("unit_shells.json")
	var fo := FileAccess.open(out_path, FileAccess.WRITE)
	if fo == null:
		return {"ok": false, "message": "Cannot write %s" % out_path}
	fo.store_string(JSON.stringify({
		"generated_at": Time.get_datetime_string_from_system(),
		"total_shells": shells.size(),
		"shells": shells,
	}, "  "))
	fo.close()
	var rep_path: String = settings.output_path_for("report_unit_shells.json")
	var rf := FileAccess.open(rep_path, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify({
			"total_shells": shells.size(),
			"by_role": role_counts,
			"by_faction": faction_counts,
		}, "  "))
		rf.close()
	return {
		"ok": true,
		"total_shells": shells.size(),
		"by_role": role_counts,
		"by_faction": faction_counts,
		"out_path": out_path,
	}

# --- Internals ---

static func _pick_role(visual_tags: Array, faction: String, prefix: String) -> String:
	if prefix.begins_with("boss_") or prefix.begins_with("critter_"):
		return "boss_body" if prefix.begins_with("boss_") else "basic_melee"
	for tag in visual_tags:
		if VISUAL_TAG_TO_ROLE.has(tag):
			return VISUAL_TAG_TO_ROLE[tag]
	return FACTION_DEFAULT_ROLE.get(faction, "basic_melee")

static func _rarity_for(prefix: String, role: String) -> String:
	# Bosses are legendary; "general" prefix → epic; otherwise heuristic.
	if prefix.begins_with("boss_"):
		return "legendary"
	if "general" in prefix.to_lower():
		return "epic"
	if role in ["artillery", "summoner", "support_aura"]:
		return "rare"
	return "common"

static func _tags_for(faction: String, visual_tags: Array, role: String) -> Array:
	var tags: Array = []
	if faction != "":
		tags.append(faction)
	for vt in visual_tags:
		if not (vt in tags):
			tags.append(vt)
	tags.append(role)
	return tags

static func _description_for(role: String, faction: String) -> String:
	var base: String = ""
	match role:
		"basic_melee":    base = "Close-range basic attacker."
		"basic_ranged":   base = "Ranged basic attacker."
		"blocker":        base = "Frontline blocker with shorter range and steady damage."
		"splash_mage":    base = "Splash damage caster."
		"support_aura":   base = "Aura tower; buffs nearby defenders."
		"control_unit":   base = "Applies slow on hit; chips at speed."
		"assassin":       base = "Fast single-target burst."
		"artillery":      base = "Long-range siege with area impact."
		"summoner":       base = "Summons assist units (planned)."
		"economy_unit":   base = "Generates extra gold each wave."
		"boss_body":      base = "Boss-tier body. High health and damage."
		_:                base = "Generated shell."
	return "[generated] %s" % base
