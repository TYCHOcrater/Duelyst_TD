extends RefCounted

# DuelystUnitCatalogBuilder (D6 of the ingestion milestone).
#
# Reads catalog_categorized.json and groups raw unit entries by their atlas
# prefix (e.g. "f1_silverguardsquire") into DuelystUnitCatalogEntry records.
#
# Heuristic: a Duelyst unit atlas is a (.plist, .png) pair under units/. The
# atlas .plist enumerates frames like "<prefix>_idle_001.png", which D2
# scanned as individual frame sprites. We collapse those back into one
# per-unit record holding:
#   - source_asset_ids: [plist_id, png_id, frame_ids...]
#   - animations: {name: frame_count}
#   - visual_tags: heuristic from filename keywords (humanoid/beast/etc.)
#   - allowed_roles: ["defender", "enemy", "arena_sendable"]
#   - readiness_level: 3 (Classified) if we have plist+png+at least one anim
#
# Output: user://duelyst_content/unit_catalog.json + report_unit_catalog.json
# Does NOT generate gameplay stats (cost/damage/range) — that's D7's job.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

# Regex to detect frame-name sprites (atlas sub-frames). Pattern is
# "<prefix>_<animation>_<3digit>" where the animation is one of these:
const FRAME_RE := "^(.+?)_(idle|breathing|breath|attack|attacking|run|walk|death|die|dying|hit|hurt|damage|cast|spell|spawn|win|projectile)_(\\d{3})$"

const VISUAL_TAG_KEYWORDS := {
	"knight": "humanoid_armor",
	"guard": "humanoid_armor",
	"squire": "humanoid_armor",
	"warrior": "humanoid_armor",
	"archer": "humanoid_ranged",
	"sniper": "humanoid_ranged",
	"hunter": "humanoid_ranged",
	"mage": "humanoid_caster",
	"witch": "humanoid_caster",
	"priest": "humanoid_caster",
	"priestess": "humanoid_caster",
	"shaman": "humanoid_caster",
	"sister": "humanoid_caster",
	"sorcerer": "humanoid_caster",
	"assassin": "humanoid_agile",
	"chaser": "humanoid_agile",
	"fox": "beast",
	"jaguar": "beast",
	"lion": "beast",
	"wolf": "beast",
	"bear": "beast",
	"hound": "beast",
	"silithar": "reptile",
	"dragon": "dragon",
	"juggernaut": "construct_large",
	"golem": "construct",
	"obelisk": "construct",
	"obelysk": "construct",
	"orb": "construct",
	"crawler": "demon_small",
	"wraith": "spirit",
	"shadow": "spirit",
	"ghost": "spirit",
	"boss": "boss",
}

static func build() -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var cat_path: String = settings.output_path_for("catalog_categorized.json")
	if not FileAccess.file_exists(cat_path):
		return {"ok": false, "message": "Categorized catalog missing — run D1+D2 first."}
	var f := FileAccess.open(cat_path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Catalog JSON malformed."}
	var entries: Array = parsed.get("entries", [])
	# Bucket by candidate unit prefix.
	var by_prefix: Dictionary = {}
	var frame_regex := RegEx.new()
	frame_regex.compile(FRAME_RE)
	for e in entries:
		var category: String = e.get("category", "")
		if not (category in ["unit_sprite", "unit_animation_data"]):
			continue
		var rel: String = e.get("rel_path", "")
		var top: String = e.get("top_dir", "")
		if top != "units":
			continue
		# Strip "units/" and the extension to get the file stem.
		var fname: String = rel.substr(6) if rel.begins_with("units/") else rel.get_file()
		var stem: String = fname.get_basename()
		var prefix: String = stem
		var anim_hit: String = ""
		var frame_idx: int = -1
		var m = frame_regex.search(stem)
		if m:
			prefix = m.get_string(1)
			anim_hit = m.get_string(2)
			frame_idx = int(m.get_string(3))
		if not by_prefix.has(prefix):
			by_prefix[prefix] = {
				"prefix": prefix,
				"source_asset_ids": [],
				"animations": {},  # name → frame_count
				"has_plist": false,
				"has_png": false,
				"faction": "",
				"plist_abs_path": "",
			}
		var bucket: Dictionary = by_prefix[prefix]
		bucket["source_asset_ids"].append(e.get("id", ""))
		if e.get("faction", "") != "" and bucket["faction"] == "":
			bucket["faction"] = e["faction"]
		if category == "unit_animation_data":
			bucket["has_plist"] = true
			bucket["plist_abs_path"] = e.get("abs_path", "")
		elif category == "unit_sprite":
			if anim_hit == "":
				# Whole-unit sprite (no frame index)
				bucket["has_png"] = true
			else:
				var anims: Dictionary = bucket["animations"]
				anims[anim_hit] = int(anims.get(anim_hit, 0)) + 1
	# Pass 2: for buckets that have a .plist, read its frame names to populate
	# animation counts. Atlas frames live inside the XML, not as separate files.
	for prefix in by_prefix.keys():
		var b: Dictionary = by_prefix[prefix]
		if not b["has_plist"]:
			continue
		var plist_path: String = b["plist_abs_path"]
		if plist_path == "":
			continue
		var anim_map: Dictionary = _extract_animations_from_plist(plist_path, frame_regex)
		# Merge: prefer plist-derived counts but keep file-scanned counts as fallback.
		if anim_map.size() > 0:
			b["animations"] = anim_map
	# Materialize unit catalog entries.
	var unit_entries: Array = []
	var faction_counts: Dictionary = {}
	for prefix in by_prefix.keys():
		var b: Dictionary = by_prefix[prefix]
		var anims: Dictionary = b["animations"]
		var readiness: int = 2  # Previewable
		if b["has_plist"] and b["has_png"] and anims.size() >= 1:
			readiness = 3  # Classified
		var visual_tags: Array[String] = _visual_tags_for(prefix)
		var unit: Dictionary = {
			"id": prefix,
			"display_name": _humanize(prefix),
			"faction": b["faction"],
			"source_asset_ids": b["source_asset_ids"],
			"has_plist": b["has_plist"],
			"has_png": b["has_png"],
			"animation_set": anims,
			"animation_count": anims.size(),
			"visual_tags": visual_tags,
			"allowed_roles": _allowed_roles_for(prefix),
			"readiness_level": readiness,
			"sprite_frames_tres_exists": ResourceLoader.exists("res://assets/units/%s/%s.tres" % [prefix, prefix]),
			"enabled_in_normal_runs": false,
			"enabled_in_debug": true,
		}
		unit_entries.append(unit)
		var fc: String = b["faction"]
		faction_counts[fc] = int(faction_counts.get(fc, 0)) + 1
	# Sort by prefix for stable output.
	unit_entries.sort_custom(func(a, b): return a["id"] < b["id"])
	# Write outputs.
	var out_path: String = settings.output_path_for("unit_catalog.json")
	var fc := FileAccess.open(out_path, FileAccess.WRITE)
	if fc == null:
		return {"ok": false, "message": "Cannot write %s" % out_path}
	fc.store_string(JSON.stringify({
		"built_at": Time.get_datetime_string_from_system(),
		"total_units": unit_entries.size(),
		"units": unit_entries,
	}, "  "))
	fc.close()
	# Report
	var report_path: String = settings.output_path_for("report_unit_catalog.json")
	var rf := FileAccess.open(report_path, FileAccess.WRITE)
	var sprite_frames_ready: int = 0
	var with_animations: int = 0
	for u in unit_entries:
		if u["sprite_frames_tres_exists"]:
			sprite_frames_ready += 1
		if int(u["animation_count"]) > 0:
			with_animations += 1
	if rf:
		rf.store_string(JSON.stringify({
			"total_units": unit_entries.size(),
			"by_faction": faction_counts,
			"with_animations": with_animations,
			"sprite_frames_ready": sprite_frames_ready,
		}, "  "))
		rf.close()
	return {
		"ok": true,
		"total_units": unit_entries.size(),
		"by_faction": faction_counts,
		"sprite_frames_ready": sprite_frames_ready,
		"with_animations": with_animations,
		"out_path": out_path,
	}

static func _extract_animations_from_plist(path: String, frame_regex: RegEx) -> Dictionary:
	# Duelyst's .plist atlases are PropertyList XML. Each frame name appears as
	# <key>name_anim_NNN.png</key> inside the <frames> dict. We don't need full
	# XML parsing — a regex over the file text finds the keys directly. Each
	# .plist is ~50KB so 696 of them parse in well under a second.
	var anims: Dictionary = {}
	if not FileAccess.file_exists(path):
		return anims
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return anims
	var text: String = f.get_as_text()
	f.close()
	var key_re := RegEx.new()
	key_re.compile("<key>([^<]+\\.png)</key>")
	for m in key_re.search_all(text):
		var frame_name: String = m.get_string(1).get_basename()  # strip ".png"
		var anim_match = frame_regex.search(frame_name)
		if anim_match:
			var anim: String = anim_match.get_string(2)
			anims[anim] = int(anims.get(anim, 0)) + 1
	return anims

static func _humanize(prefix: String) -> String:
	# "f1_silverguardsquire" → "Silverguard Squire" (drop faction tag, split CamelCase).
	var s: String = prefix
	# Drop fN_ prefix
	if s.length() >= 3 and s[0] == "f" and s[1].is_valid_int() and s[2] == "_":
		s = s.substr(3)
	if s.begins_with("boss_"):
		s = "Boss " + s.substr(5)
	s = s.replace("_", " ")
	# Split lowercase compound words by attempting capitalization at common suffix breaks.
	# Cheap heuristic: capitalize first letter of each space-separated token.
	var tokens: Array = s.split(" ", false)
	var out: Array = []
	for t in tokens:
		if t.length() > 0:
			out.append(t[0].to_upper() + t.substr(1))
	return " ".join(out)

static func _visual_tags_for(prefix: String) -> Array[String]:
	var out: Array[String] = []
	var lower: String = prefix.to_lower()
	for kw in VISUAL_TAG_KEYWORDS.keys():
		if kw in lower:
			var tag: String = VISUAL_TAG_KEYWORDS[kw]
			if not (tag in out):
				out.append(tag)
	return out

static func _allowed_roles_for(prefix: String) -> Array[String]:
	# Default: any Duelyst unit could be a defender, enemy, or arena sendable.
	# Bosses get boss role instead of arena.
	if prefix.begins_with("boss_"):
		return ["defender", "enemy", "boss"]
	return ["defender", "enemy", "arena_sendable"]
