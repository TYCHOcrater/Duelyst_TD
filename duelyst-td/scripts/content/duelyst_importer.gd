extends RefCounted

# DuelystImporter (D3 of the ingestion milestone).
#
# Reads catalog_categorized.json and copies entries from their abs_path into
# `res://assets/duelyst/<category>/<safe_id>.<ext>` (Godot auto-imports them
# on the next editor scan and they become loadable as Texture2D / AudioStream).
#
# This is the heavyweight option — copies bytes. For dev-time preview the
# Content Browser (D4) reads directly from abs_path via Image.load_from_file
# and doesn't need this step.
#
# Idempotent: skips files where dest exists and source size matches.
# Selective: import_categories(["icon", "ui_image"]) imports only those.
# Reports: writes user://duelyst_content/import_report.json with per-category
#          counts of imported / skipped / failed.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")
const IMPORT_DEST_ROOT := "res://assets/duelyst/"

# Default categories that are safe to import in bulk. Skips unit/fx atlases
# because the existing tools/convert_units.py converts those into SpriteFrames
# differently — we don't want to clash.
const DEFAULT_CATEGORIES := ["icon", "ui_image", "map_tile", "map_background", "font"]

static func import_categories(categories: Array = []) -> Dictionary:
	if categories.is_empty():
		categories = DEFAULT_CATEGORIES
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
	# Ensure dest root exists. Note: writing to res:// only works when running
	# from the editor (or a debug build with project dir writable). In an
	# exported game this will fail, which is correct — D3 is dev-only.
	if not DirAccess.dir_exists_absolute(IMPORT_DEST_ROOT):
		var err := DirAccess.make_dir_recursive_absolute(IMPORT_DEST_ROOT)
		if err != OK:
			return {"ok": false, "message": "Cannot create %s (err %d) — D3 requires running from editor." % [IMPORT_DEST_ROOT, err]}
	var imported: Dictionary = {}
	var skipped: Dictionary = {}
	var failed: Dictionary = {}
	var paths_written: Array = []
	var category_set: Dictionary = {}
	for c in categories:
		category_set[c] = true
	for e in entries:
		var category: String = e.get("category", "")
		if not category_set.has(category):
			continue
		var src: String = e.get("abs_path", "")
		var ext: String = e.get("extension", "")
		var id: String = e.get("id", "")
		if src == "" or ext == "" or id == "":
			failed[category] = int(failed.get(category, 0)) + 1
			continue
		var category_dir: String = IMPORT_DEST_ROOT.path_join(category)
		if not DirAccess.dir_exists_absolute(category_dir):
			DirAccess.make_dir_recursive_absolute(category_dir)
		var dest: String = category_dir.path_join(id + ext)
		if _already_imported(src, dest):
			skipped[category] = int(skipped.get(category, 0)) + 1
			continue
		var copy_err := _copy_file(src, dest)
		if copy_err != OK:
			failed[category] = int(failed.get(category, 0)) + 1
			continue
		imported[category] = int(imported.get(category, 0)) + 1
		paths_written.append(dest)
	# Write report
	var report := {
		"imported_at": Time.get_datetime_string_from_system(),
		"categories_requested": categories,
		"imported": imported,
		"skipped": skipped,
		"failed": failed,
		"sample_paths": paths_written.slice(0, min(20, paths_written.size())),
	}
	var report_path: String = settings.output_path_for("import_report.json")
	var rf := FileAccess.open(report_path, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify(report, "  "))
		rf.close()
	settings.mark_imported()
	return {
		"ok": true,
		"imported": imported,
		"skipped": skipped,
		"failed": failed,
		"report_path": report_path,
		"dest_root": IMPORT_DEST_ROOT,
	}

static func _already_imported(src: String, dest: String) -> bool:
	if not FileAccess.file_exists(dest):
		return false
	var src_size: int = FileAccess.get_file_as_bytes(src).size()
	var dest_size: int = FileAccess.get_file_as_bytes(dest).size()
	return src_size == dest_size

static func _copy_file(src: String, dest: String) -> int:
	var in_file := FileAccess.open(src, FileAccess.READ)
	if in_file == null:
		return FileAccess.get_open_error()
	var bytes := in_file.get_buffer(in_file.get_length())
	in_file.close()
	var out_file := FileAccess.open(dest, FileAccess.WRITE)
	if out_file == null:
		return FileAccess.get_open_error()
	out_file.store_buffer(bytes)
	out_file.close()
	return OK
