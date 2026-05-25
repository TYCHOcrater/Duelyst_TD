extends RefCounted

# DuelystReuseReport (D17 of the ingestion milestone).
#
# Reads the catalog files produced by D1/D2/D6/D8 and the content packs
# loaded by D14 PackManager, then writes a human-readable markdown report
# summarizing how much Duelyst content is indexed, classified, and actually
# playable. Output: user://duelyst_content/reuse_report.md (snapshot the
# dev can manually copy into docs/reports/ when committing canon).

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

static func generate() -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	# Load source catalogs
	var raw: Dictionary = _read_json(settings.output_path_for("catalog_raw.json"))
	var cat: Dictionary = _read_json(settings.output_path_for("catalog_categorized.json"))
	var ucat: Dictionary = _read_json(settings.output_path_for("unit_catalog.json"))
	var shells: Dictionary = _read_json(settings.output_path_for("unit_shells.json"))
	var enemy_shells: Dictionary = _read_json(settings.output_path_for("enemy_shells.json"))
	if cat.is_empty():
		return {"ok": false, "message": "categorized catalog missing — run D1+D2 first."}
	# Aggregate counts.
	var entries: Array = cat.get("entries", [])
	var by_category: Dictionary = {}
	for e in entries:
		var c: String = e.get("category", "unknown")
		by_category[c] = int(by_category.get(c, 0)) + 1
	# Playable counts (curated + enabled packs).
	var curated_count: int = 24
	var pack_count: int = PackManager.all_pack_ids().size()
	var enabled_pack_count: int = PackManager.enabled_pack_ids().size()
	var enabled_shell_count: int = PackManager.enabled_defender_shells().size()
	var total_playable: int = curated_count + enabled_shell_count
	var total_pack_shells: int = 0
	for pid in PackManager.all_pack_ids():
		var p: Dictionary = PackManager.get_pack(String(pid))
		total_pack_shells += (p.get("defender_shells", []) as Array).size()
	# Compose report
	var lines: Array[String] = []
	lines.append("# Duelyst Content Reuse Report")
	lines.append("")
	lines.append("_Generated: %s_" % Time.get_datetime_string_from_system())
	lines.append("_Source: %s_" % settings.source_root)
	lines.append("")
	lines.append("## Source inventory (D1 scan)")
	lines.append("")
	lines.append("- Total files scanned: **%d**" % int(raw.get("total_files", entries.size())))
	lines.append("- Distinct categories: **%d**" % by_category.size())
	lines.append("")
	lines.append("## Categorization (D2)")
	lines.append("")
	lines.append("| Category | Count |")
	lines.append("|---|---|")
	var cats: Array = by_category.keys()
	cats.sort_custom(func(a, b): return int(by_category[a]) > int(by_category[b]))
	for c in cats:
		lines.append("| %s | %d |" % [c, int(by_category[c])])
	lines.append("")
	lines.append("## Unit catalog (D6)")
	lines.append("")
	var total_units: int = int(ucat.get("total_units", 0))
	var unit_list: Array = ucat.get("units", [])
	var with_anim: int = 0
	var sprite_ready: int = 0
	var by_faction: Dictionary = {}
	for u in unit_list:
		if int(u.get("animation_count", 0)) > 0:
			with_anim += 1
		if u.get("sprite_frames_tres_exists", false):
			sprite_ready += 1
		var f: String = String(u.get("faction", ""))
		by_faction[f] = int(by_faction.get(f, 0)) + 1
	lines.append("- Total catalogued units: **%d**" % total_units)
	lines.append("- With animation data extracted: **%d** (%.0f%%)" % [with_anim, 100.0 * with_anim / max(1, total_units)])
	lines.append("- SpriteFrames .tres ready: **%d** (%.0f%%)" % [sprite_ready, 100.0 * sprite_ready / max(1, total_units)])
	lines.append("")
	lines.append("Per-faction:")
	lines.append("")
	lines.append("| Faction | Catalogued |")
	lines.append("|---|---|")
	var fkeys: Array = by_faction.keys()
	fkeys.sort()
	for f in fkeys:
		var label: String = f if f != "" else "(unset)"
		lines.append("| %s | %d |" % [label, int(by_faction[f])])
	lines.append("")
	lines.append("## Shells generated")
	lines.append("")
	lines.append("- D7 defender shells: **%d**" % int(shells.get("total_shells", 0)))
	lines.append("- D8 enemy shells:    **%d** (sprite-ready: %d)" % [
		int(enemy_shells.get("total_shells", 0)),
		int(enemy_shells.get("spawn_ready_count", 0)),
	])
	lines.append("")
	lines.append("## Content packs (D13/D14)")
	lines.append("")
	lines.append("- Packs discovered:    **%d**" % pack_count)
	lines.append("- Packs enabled:       **%d**" % enabled_pack_count)
	lines.append("- Total pack shells:   **%d**" % total_pack_shells)
	lines.append("- Enabled shells:      **%d**" % enabled_shell_count)
	lines.append("")
	lines.append("## Playable totals (current dev state)")
	lines.append("")
	lines.append("- Curated units (res://data/units/): **%d**" % curated_count)
	lines.append("- Pack shells in draft shop right now: **%d**" % enabled_shell_count)
	lines.append("- **Total playable units: %d**" % total_playable)
	lines.append("- **Total playable if all packs enabled: %d**" % (curated_count + total_pack_shells))
	lines.append("")
	lines.append("## Reuse score (vs. 50%% milestone target)")
	lines.append("")
	var unit_sprite_count: int = int(by_category.get("unit_sprite", 0))
	var unit_atlas_count: int = int(by_category.get("unit_animation_data", 0))
	var sfx_count: int = int(by_category.get("sfx", 0))
	var vfx_count: int = int(by_category.get("fx_sprite", 0)) + int(by_category.get("fx_animation_data", 0))
	var ui_count: int = int(by_category.get("ui_image", 0)) + int(by_category.get("icon", 0))
	var map_count: int = int(by_category.get("map_tile", 0)) + int(by_category.get("map_background", 0))
	lines.append("| Asset class | Indexed | Used | % used |")
	lines.append("|---|---|---|---|")
	lines.append("| Unit sprites | %d | %d (sprite-ready) | %.0f%% |" % [unit_sprite_count + unit_atlas_count, sprite_ready, 100.0 * sprite_ready / max(1, unit_atlas_count)])
	lines.append("| SFX | %d | %d (transcoded OGGs in use) | %.0f%% |" % [sfx_count, 5, 100.0 * 5 / max(1, sfx_count)])
	lines.append("| VFX | %d | %d (router events wired) | %.0f%% |" % [vfx_count, 13, 100.0 * 13 / max(1, vfx_count)])
	lines.append("| UI / icons | %d | %d (theme + cursor + frames + portraits) | small but present |" % [ui_count, 10])
	lines.append("| Map | %d | %d (1 default theme) | small |" % [map_count, 1])
	lines.append("")
	lines.append("## Notes")
	lines.append("")
	lines.append("- Unit-side reuse is the dominant metric and currently at ~%.0f%% (sprite-ready vs catalogued atlases)." % (100.0 * sprite_ready / max(1, unit_atlas_count)))
	lines.append("- SFX is bottlenecked by Godot's lack of native AAC (Duelyst ships .m4a). `tools/convert_sfx.py` can transcode more on demand.")
	lines.append("- Map theme ingestion is the smallest reuse area; D12 would lift it.")
	lines.append("")
	# Write
	var path: String = settings.output_path_for("reuse_report.md")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "message": "Cannot write %s" % path}
	f.store_string("\n".join(lines))
	f.close()
	return {
		"ok": true,
		"path": path,
		"total_files": int(raw.get("total_files", entries.size())),
		"total_units": total_units,
		"sprite_ready": sprite_ready,
		"playable_now": total_playable,
		"playable_max": curated_count + total_pack_shells,
	}

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
