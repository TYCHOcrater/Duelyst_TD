extends RefCounted

# DuelystRawScanner (D1 of the content ingestion milestone).
# Walks an absolute Duelyst-source folder and produces a JSON catalog of
# every file it finds, plus a counts-by-extension/section report.
#
# Output: <settings.output_root>/catalog_raw.json + report_raw.json
# Idempotent: re-running overwrites the catalog cleanly.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

# Files we never care about: build artifacts, source-code, large videos, etc.
const SKIP_EXTENSIONS := [
	".git", ".gitignore", ".gitattributes",
	".coffee", ".js", ".ts", ".html", ".css", ".scss",
	".md", ".txt", ".yml", ".yaml",
	".lock", ".log",
	".mp4", ".webm",
]
const SKIP_DIR_NAMES := ["node_modules", ".git", "web", "scenes"]

const MAX_DEPTH := 12

# Broad category guesses based on top-level subfolder name. The D2 categorizer
# refines these into proper categories (unit_sprite vs fx_sprite vs sfx etc.).
const SECTION_HINTS := {
	"units": "units",
	"unit_gifs": "units",
	"generals": "units",
	"sfx": "sfx",
	"music": "music",
	"fx": "fx",
	"particles": "fx",
	"ui": "ui",
	"icons": "icons",
	"crests": "icons",
	"ribbons": "icons",
	"profile_icons": "icons",
	"emotes": "icons",
	"runes": "icons",
	"core_gem": "icons",
	"masks": "fx",
	"decals": "fx",
	"maps": "maps",
	"tiles": "maps",
	"prismatic": "fx",
	"battlelog": "ui",
	"booster_pack_opening": "ui",
	"boss_battles": "ui",
	"browsers": "ui",
	"card_backgrounds": "ui",
	"challenges": "ui",
	"codex": "ui",
	"dialogue": "ui",
	"free_card_of_the_day": "ui",
	"loot_crates": "ui",
	"matchmaking": "ui",
	"modifiers": "ui",
	"play": "ui",
	"referral_dialog": "ui",
	"rift": "ui",
	"season_rewards": "ui",
	"shop": "ui",
	"tutorial": "ui",
	"tonal_gradients": "fx",
	"arena": "ui",
	"fonts": "fonts",
	"noise.png": "fx",
	"noise_128.png": "fx",
}

# Scan returns {ok, files: [{...}], counts: {...}, report_path}.
static func scan(progress_cb: Callable = Callable()) -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var v: Dictionary = settings.validate_source()
	if not v.get("ok", false):
		return {"ok": false, "message": v.get("message", "source invalid")}
	if not settings.ensure_output_dir():
		return {"ok": false, "message": "Cannot create output dir"}
	var files: Array = []
	var counts := {
		"by_extension": {},
		"by_section": {},
		"by_top_dir": {},
		"total_files": 0,
		"total_bytes": 0,
		"skipped": 0,
	}
	var src: String = settings.source_root
	_walk(src, src, files, counts, 0, progress_cb)
	# Write catalog
	var catalog_path: String = settings.output_path_for("catalog_raw.json")
	var fc := FileAccess.open(catalog_path, FileAccess.WRITE)
	if fc == null:
		return {"ok": false, "message": "Cannot write %s" % catalog_path}
	fc.store_string(JSON.stringify({
		"source_root": settings.source_root,
		"scanned_at": Time.get_datetime_string_from_system(),
		"total_files": counts["total_files"],
		"entries": files,
	}, "  "))
	fc.close()
	# Write report
	var report_path: String = settings.output_path_for("report_raw.json")
	var fr := FileAccess.open(report_path, FileAccess.WRITE)
	if fr == null:
		return {"ok": false, "message": "Cannot write %s" % report_path}
	fr.store_string(JSON.stringify(counts, "  "))
	fr.close()
	settings.mark_scanned()
	return {
		"ok": true,
		"catalog_path": catalog_path,
		"report_path": report_path,
		"counts": counts,
		"sample": files.slice(0, min(10, files.size())),
	}

static func _walk(src_root: String, dir_path: String, files: Array, counts: Dictionary, depth: int, progress_cb: Callable) -> void:
	if depth > MAX_DEPTH:
		return
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if entry.to_lower() in SKIP_DIR_NAMES:
				continue
			_walk(src_root, full_path, files, counts, depth + 1, progress_cb)
		else:
			var ext: String = "." + entry.get_extension().to_lower()
			if ext in SKIP_EXTENSIONS:
				counts["skipped"] = int(counts["skipped"]) + 1
				continue
			var rel: String = full_path.replace(src_root, "").trim_prefix("/").trim_prefix("\\")
			var top_dir: String = rel.split("/")[0] if "/" in rel else rel.split("\\")[0]
			var section: String = SECTION_HINTS.get(top_dir, "unknown")
			var size: int = FileAccess.get_file_as_bytes(full_path).size() if FileAccess.file_exists(full_path) else 0
			files.append({
				"id": _stable_id(rel),
				"rel_path": rel.replace("\\", "/"),
				"abs_path": full_path,
				"top_dir": top_dir,
				"section_hint": section,
				"extension": ext,
				"size_bytes": size,
				"readiness_level": 0,  # Level 0 = Discovered, per the milestone doc §2
			})
			counts["total_files"] = int(counts["total_files"]) + 1
			counts["total_bytes"] = int(counts["total_bytes"]) + size
			var be: Dictionary = counts["by_extension"]
			be[ext] = int(be.get(ext, 0)) + 1
			var bs: Dictionary = counts["by_section"]
			bs[section] = int(bs.get(section, 0)) + 1
			var bt: Dictionary = counts["by_top_dir"]
			bt[top_dir] = int(bt.get(top_dir, 0)) + 1
			if progress_cb.is_valid() and counts["total_files"] % 250 == 0:
				progress_cb.call(int(counts["total_files"]))
	dir.list_dir_end()

static func _stable_id(rel_path: String) -> String:
	# Stable, deterministic id derived from path. Lowercase, alnum + underscore.
	var s: String = rel_path.replace("\\", "/").to_lower()
	var out := ""
	for c in s:
		if c.is_valid_int() or (c >= "a" and c <= "z"):
			out += c
		elif c == "/" or c == "_" or c == "-" or c == ".":
			out += "_"
	# Collapse repeated underscores
	while "__" in out:
		out = out.replace("__", "_")
	return out.trim_suffix("_").trim_prefix("_")
