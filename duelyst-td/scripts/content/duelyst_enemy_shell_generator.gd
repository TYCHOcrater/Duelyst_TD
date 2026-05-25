extends RefCounted

# DuelystEnemyShellGenerator (D8 of the ingestion milestone).
#
# Reads unit_catalog.json and produces enemy-tinted shells: same Duelyst
# sprite assets, but with HP/speed/reward/leak_damage stats appropriate for
# enemy waves rather than player towers.
#
# Output: user://duelyst_content/enemy_shells.json + report.
# Each shell carries `sprite_frames_ready` so the debug spawn UI can pick
# only those with a converted SpriteFrames .tres at res://assets/units/.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

# Enemy family → baseline stat block (matches existing data/enemies/*.json shape).
const FAMILY_TEMPLATES := {
	"swarm":    {"hp":  35, "speed": 72.0, "armor": 0, "physical_resist": 0.0,  "magic_resist": 0.0,  "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward":  5, "leak_damage": 1, "scale": 0.95},
	"fast":     {"hp":  55, "speed": 95.0, "armor": 0, "physical_resist": 0.0,  "magic_resist": 0.0,  "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward":  8, "leak_damage": 1, "scale": 0.95},
	"armored":  {"hp":  95, "speed": 52.0, "armor": 2, "physical_resist": 0.15, "magic_resist": 0.0,  "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward": 11, "leak_damage": 1, "scale": 1.0},
	"tank":     {"hp": 220, "speed": 36.0, "armor": 1, "physical_resist": 0.0,  "magic_resist": 0.0,  "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward": 20, "leak_damage": 2, "scale": 1.15},
	"shielded": {"hp":  55, "speed": 60.0, "armor": 0, "physical_resist": 0.0,  "magic_resist": 0.35, "regen_per_sec": 0.0, "shield_hp": 55, "gold_reward": 14, "leak_damage": 1, "scale": 1.0},
	"regen":    {"hp":  65, "speed": 55.0, "armor": 0, "physical_resist": 0.0,  "magic_resist": 0.0,  "regen_per_sec": 4.0, "shield_hp":  0, "gold_reward": 12, "leak_damage": 1, "scale": 1.0},
	"caster":   {"hp":  70, "speed": 60.0, "armor": 0, "physical_resist": 0.0,  "magic_resist": 0.20, "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward": 13, "leak_damage": 1, "scale": 1.0},
	"boss":     {"hp": 600, "speed": 40.0, "armor": 2, "physical_resist": 0.10, "magic_resist": 0.10, "regen_per_sec": 0.0, "shield_hp":  0, "gold_reward":180, "leak_damage": 5, "scale": 1.65},
}

# Visual tag → family preference (wins over faction-default).
const VISUAL_TAG_TO_FAMILY := {
	"humanoid_armor":    "armored",
	"humanoid_ranged":   "swarm",
	"humanoid_caster":   "caster",
	"humanoid_agile":    "fast",
	"beast":             "fast",
	"reptile":           "regen",
	"dragon":            "tank",
	"construct_large":   "tank",
	"construct":         "armored",
	"demon_small":       "swarm",
	"spirit":            "shielded",
	"boss":              "boss",
}

const FACTION_DEFAULT_FAMILY := {
	"lyonar":    "armored",
	"songhai":   "fast",
	"vetruvian": "armored",
	"abyssian":  "swarm",
	"magmar":    "tank",
	"vanar":     "shielded",
	"neutral":   "swarm",
	"":          "swarm",
}

const FACTION_TINTS := {
	"lyonar":    [1.0, 0.85, 0.4],
	"songhai":   [1.0, 0.5, 0.5],
	"vetruvian": [0.95, 0.75, 0.45],
	"abyssian":  [0.8, 0.55, 1.0],
	"magmar":    [1.0, 0.65, 0.35],
	"vanar":     [0.6, 0.9, 1.0],
	"neutral":   [0.9, 0.9, 0.9],
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
	var family_counts: Dictionary = {}
	var faction_counts: Dictionary = {}
	var ready_count: int = 0
	for u in units:
		var readiness: int = int(u.get("readiness_level", 0))
		if readiness < 2:
			continue
		var prefix: String = u.get("id", "")
		var faction: String = u.get("faction", "")
		var visual_tags: Array = u.get("visual_tags", [])
		var sprite_ready: bool = u.get("sprite_frames_tres_exists", false)
		var family: String = _pick_family(visual_tags, faction, prefix)
		var t: Dictionary = FAMILY_TEMPLATES[family]
		var shell: Dictionary = {
			"id": prefix + "_enemy",
			"source_duelyst_unit_id": prefix,
			"display_name": u.get("display_name", prefix),
			"asset_profile_id": prefix,
			"faction": faction if faction != "" else "neutral",
			"family": family,
			"tags": _tags_for(faction, visual_tags, family),
			"hp": int(t["hp"]),
			"speed": float(t["speed"]),
			"armor": int(t["armor"]),
			"physical_resist": float(t["physical_resist"]),
			"magic_resist": float(t["magic_resist"]),
			"regen_per_sec": float(t["regen_per_sec"]),
			"shield_hp": int(t["shield_hp"]),
			"gold_reward": int(t["gold_reward"]),
			"leak_damage": int(t["leak_damage"]),
			"scale": float(t["scale"]),
			"tint": FACTION_TINTS.get(faction, FACTION_TINTS["neutral"]),
			"hp_bar_offset": int(-55 * float(t["scale"])),
			"hp_bar_width": int(60 * float(t["scale"])),
			"description": "[generated] %s enemy from %s." % [family, faction if faction != "" else "neutral"],
			"balance_state": "generated_unbalanced",
			"sprite_frames_ready": sprite_ready,
			"enabled_in_debug": true,
			"enabled_in_normal_runs": false,
		}
		shells.append(shell)
		family_counts[family] = int(family_counts.get(family, 0)) + 1
		faction_counts[faction] = int(faction_counts.get(faction, 0)) + 1
		if sprite_ready:
			ready_count += 1
	# Write outputs
	var out_path: String = settings.output_path_for("enemy_shells.json")
	var fo := FileAccess.open(out_path, FileAccess.WRITE)
	if fo == null:
		return {"ok": false, "message": "Cannot write %s" % out_path}
	fo.store_string(JSON.stringify({
		"generated_at": Time.get_datetime_string_from_system(),
		"total_shells": shells.size(),
		"spawn_ready_count": ready_count,
		"shells": shells,
	}, "  "))
	fo.close()
	var rep_path: String = settings.output_path_for("report_enemy_shells.json")
	var rf := FileAccess.open(rep_path, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify({
			"total_shells": shells.size(),
			"spawn_ready_count": ready_count,
			"by_family": family_counts,
			"by_faction": faction_counts,
		}, "  "))
		rf.close()
	return {
		"ok": true,
		"total_shells": shells.size(),
		"spawn_ready_count": ready_count,
		"by_family": family_counts,
		"by_faction": faction_counts,
		"out_path": out_path,
	}

# --- Internals ---

static func _pick_family(visual_tags: Array, faction: String, prefix: String) -> String:
	if prefix.begins_with("boss_"):
		return "boss"
	for tag in visual_tags:
		if VISUAL_TAG_TO_FAMILY.has(tag):
			return VISUAL_TAG_TO_FAMILY[tag]
	return FACTION_DEFAULT_FAMILY.get(faction, "swarm")

static func _tags_for(faction: String, visual_tags: Array, family: String) -> Array:
	var tags: Array = [family]
	if faction != "":
		tags.append(faction)
	for vt in visual_tags:
		if not (vt in tags):
			tags.append(vt)
	return tags
