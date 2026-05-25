extends RefCounted

# DuelystCategorizer (D2). Reads catalog_raw.json (D1 output) + an optional
# manual_overrides.json, refines each entry's `category` and infers `faction`,
# writes catalog_categorized.json + report_categorized.json.
#
# Categories produced (per milestone doc §4 + §D2):
#   unit_sprite           PNG/JPG in /units/, /unit_gifs/, /generals/
#   unit_animation_data   .plist sibling of a unit sprite
#   fx_sprite             PNG in /fx/, /particles/, /decals/, /masks/
#   fx_animation_data     .plist in /fx/, /particles/
#   sfx                   .m4a/.mp3/.ogg in /sfx/
#   music                 .m4a/.mp3/.ogg in /music/
#   ui_image              PNG in /ui/ and ui-section subfolders
#   icon                  PNG in /icons/, /crests/, /ribbons/, /emotes/, /runes/, /profile_icons/
#   map_tile              PNG in /tiles/
#   map_background        PNG in /maps/
#   font                  .ttf / .otf / .woff / .eot
#   unknown               everything else (preserved, not discarded)
#
# Faction inference: keyword match on path or filename. Six Duelyst factions
# plus neutral. Manual overrides win over inference.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

const FACTION_KEYWORDS := {
	"lyonar": ["lyonar", "f1_", "silverguard", "windblade", "azurite", "sunriser", "ironcliffe", "argeon"],
	"songhai": ["songhai", "f2_", "kaido", "chakri", "lantern", "onyx", "twilight", "hammon", "geomancer", "heartseeker", "reva"],
	"vetruvian": ["vetruvian", "f3_", "orbweaver", "obelysk", "pyromancer", "rasha", "scioness", "ciphyron"],
	"abyssian": ["abyssian", "f4_", "shadow", "wraith", "blacksolus", "gloomchaser", "lilithe", "cassyva", "maehv", "arcanedevourer", "bloodmoon"],
	"magmar": ["magmar", "f5_", "silithar", "earthwalker", "vaath", "starhorn", "ragnora"],
	"vanar": ["vanar", "f6_", "snowchaser", "frostiva", "gravity", "kindredhunter", "sister", "kara", "faie", "ilena"],
}

# Categorize returns {ok, entries, counts, catalog_path}.
static func categorize() -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var raw_path: String = settings.output_path_for("catalog_raw.json")
	if not FileAccess.file_exists(raw_path):
		return {"ok": false, "message": "Raw catalog not found at %s — run the scanner first." % raw_path}
	var f := FileAccess.open(raw_path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Raw catalog is not valid JSON."}
	var raw_entries: Array = parsed.get("entries", [])
	# Optional manual overrides
	var overrides: Dictionary = _load_overrides(settings)
	# Build a path index for sibling .plist/.png pairing (for unit_animation_data)
	var path_by_rel: Dictionary = {}
	for e in raw_entries:
		path_by_rel[String(e.get("rel_path", ""))] = e
	# Classify each entry
	var categorized: Array = []
	var counts := {
		"by_category": {},
		"by_faction": {},
		"unit_atlases_paired": 0,
		"total": 0,
	}
	for e in raw_entries:
		var entry: Dictionary = (e as Dictionary).duplicate()
		var id: String = entry.get("id", "")
		var category: String = _guess_category(entry, path_by_rel)
		var faction: String = _guess_faction(entry)
		# Manual override application
		if overrides.has(id):
			var ovd: Dictionary = overrides[id]
			if ovd.has("category"):
				category = ovd["category"]
			if ovd.has("faction"):
				faction = ovd["faction"]
		entry["category"] = category
		entry["faction"] = faction
		entry["readiness_level"] = max(int(entry.get("readiness_level", 0)), 1)  # Level 1 = Imported (catalog form)
		categorized.append(entry)
		# Counts
		var bc: Dictionary = counts["by_category"]
		bc[category] = int(bc.get(category, 0)) + 1
		if faction != "":
			var bf: Dictionary = counts["by_faction"]
			bf[faction] = int(bf.get(faction, 0)) + 1
		counts["total"] = int(counts["total"]) + 1
		if category == "unit_animation_data":
			counts["unit_atlases_paired"] = int(counts["unit_atlases_paired"]) + 1
	# Write outputs
	var cat_path: String = settings.output_path_for("catalog_categorized.json")
	var fc := FileAccess.open(cat_path, FileAccess.WRITE)
	if fc == null:
		return {"ok": false, "message": "Cannot write %s" % cat_path}
	fc.store_string(JSON.stringify({
		"source_root": settings.source_root,
		"categorized_at": Time.get_datetime_string_from_system(),
		"override_count": overrides.size(),
		"entries": categorized,
	}, "  "))
	fc.close()
	var rep_path: String = settings.output_path_for("report_categorized.json")
	var fr := FileAccess.open(rep_path, FileAccess.WRITE)
	if fr == null:
		return {"ok": false, "message": "Cannot write %s" % rep_path}
	fr.store_string(JSON.stringify(counts, "  "))
	fr.close()
	settings.mark_categorized()
	return {
		"ok": true,
		"catalog_path": cat_path,
		"report_path": rep_path,
		"counts": counts,
		"override_count": overrides.size(),
	}

# --- Internals ---

static func _guess_category(entry: Dictionary, path_by_rel: Dictionary) -> String:
	var ext: String = String(entry.get("extension", "")).to_lower()
	var rel: String = String(entry.get("rel_path", "")).to_lower()
	var top: String = String(entry.get("top_dir", "")).to_lower()
	# Fonts
	if ext in [".ttf", ".otf", ".woff", ".eot"]:
		return "font"
	# Audio
	if ext in [".m4a", ".mp3", ".ogg", ".wav"]:
		if top == "music":
			return "music"
		return "sfx"
	# .plist atlas metadata
	if ext == ".plist":
		if top in ["units", "unit_gifs", "generals"]:
			return "unit_animation_data"
		if top in ["fx", "particles", "decals", "masks"]:
			return "fx_animation_data"
		return "unknown"
	# Image extensions
	if ext in [".png", ".jpg", ".jpeg", ".webp"]:
		if top in ["units", "unit_gifs", "generals"]:
			return "unit_sprite"
		if top in ["fx", "particles", "decals", "masks", "prismatic", "tonal_gradients"]:
			return "fx_sprite"
		if top in ["icons", "crests", "ribbons", "emotes", "runes", "profile_icons", "core_gem"]:
			return "icon"
		if top == "tiles":
			return "map_tile"
		if top == "maps":
			return "map_background"
		if top in ["ui", "battlelog", "booster_pack_opening", "boss_battles", "browsers", "card_backgrounds", "challenges", "codex", "dialogue", "free_card_of_the_day", "loot_crates", "matchmaking", "modifiers", "play", "referral_dialog", "rift", "season_rewards", "shop", "tutorial", "arena", "scenes"]:
			return "ui_image"
		# Fallback for stray top-level PNGs
		return "ui_image"
	return "unknown"

static func _guess_faction(entry: Dictionary) -> String:
	var rel: String = String(entry.get("rel_path", "")).to_lower()
	var top: String = String(entry.get("top_dir", "")).to_lower()
	# Skip faction inference for non-faction sections like sfx/music/ui (mostly neutral)
	if top in ["sfx", "music", "fonts", "ui"]:
		return ""
	for faction in FACTION_KEYWORDS.keys():
		for keyword in FACTION_KEYWORDS[faction]:
			if keyword in rel:
				return faction
	# Files in units/ without faction keyword → neutral
	if top in ["units", "unit_gifs", "generals"]:
		return "neutral"
	return ""

static func _load_overrides(settings: RefCounted) -> Dictionary:
	var path: String = settings.output_path_for("manual_overrides.json")
	if not FileAccess.file_exists(path):
		# Write a stub so the user can find it.
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({
				"_note": "Per-id manual category/faction overrides. Format: {\"<entry_id>\": {\"category\": \"unit_sprite\", \"faction\": \"lyonar\"}}",
				"_example": {"units_boss_andromeda_png": {"category": "unit_sprite", "faction": "neutral"}},
			}, "  "))
			f.close()
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	# Strip _note / _example helper keys
	var out: Dictionary = {}
	for k in parsed.keys():
		if String(k).begins_with("_"):
			continue
		out[String(k)] = parsed[k]
	return out
