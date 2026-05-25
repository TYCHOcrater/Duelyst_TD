extends RefCounted

# DuelystContentSettings — pure data + methods, RefCounted so it auto-frees.
# Lazily constructed per-call via instance(); cheap because load() reads the
# tiny settings.json once. Holds the local paths the ingestion pipeline uses.
#
# Pipeline stages D0-D17 consume this:
#   D1 raw scanner writes catalog_raw.json under output_root
#   D2 categorizer reads catalog_raw + manual_overrides, writes catalog_categorized
#   D3 importer copies selected categories into res://assets/duelyst/
#   D4-D17 read the categorized catalog to build the browser, shells, etc.

const SETTINGS_PATH := "user://duelyst_content/settings.json"
const OUTPUT_ROOT := "user://duelyst_content/"
const DEFAULT_SOURCE_HINT := "E:/CODE/Duelyst_TD/duelyst-main/duelyst-main/app/resources"

var source_root: String = ""
var output_root: String = OUTPUT_ROOT
var last_scan_at: String = ""
var last_categorize_at: String = ""
var last_import_at: String = ""

func _init() -> void:
	load_from_disk()

func ensure_output_dir() -> bool:
	if DirAccess.dir_exists_absolute(output_root):
		return true
	var err := DirAccess.make_dir_recursive_absolute(output_root)
	if err != OK:
		push_error("DuelystContentSettings: cannot create %s (err %d)" % [output_root, err])
		return false
	return true

func load_from_disk() -> void:
	# Seed with a reasonable default the first time; the dev edits via the UI.
	source_root = DEFAULT_SOURCE_HINT
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	source_root = String(parsed.get("source_root", source_root))
	output_root = String(parsed.get("output_root", output_root))
	last_scan_at = String(parsed.get("last_scan_at", ""))
	last_categorize_at = String(parsed.get("last_categorize_at", ""))
	last_import_at = String(parsed.get("last_import_at", ""))

func save_to_disk() -> bool:
	if not ensure_output_dir():
		return false
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("DuelystContentSettings: cannot write %s" % SETTINGS_PATH)
		return false
	var data := {
		"source_root": source_root,
		"output_root": output_root,
		"last_scan_at": last_scan_at,
		"last_categorize_at": last_categorize_at,
		"last_import_at": last_import_at,
	}
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return true

func validate_source() -> Dictionary:
	# Returns {ok, message, marker_hits}.
	if source_root == "":
		return {"ok": false, "message": "Source path is empty. Point this at duelyst-main/app/resources."}
	if not DirAccess.dir_exists_absolute(source_root):
		return {"ok": false, "message": "Folder does not exist: %s" % source_root}
	# Sanity-check by looking for canonical Duelyst subfolders.
	var markers: Array[String] = ["units", "fx", "sfx", "ui"]
	var hits: Array[String] = []
	for m in markers:
		if DirAccess.dir_exists_absolute(source_root.path_join(m)):
			hits.append(m)
	if hits.size() < 2:
		return {
			"ok": false,
			"message": "Folder exists but doesn't look like a Duelyst resources tree (missing %s subdirs)" % ", ".join(markers.filter(func(x): return not (x in hits))),
			"marker_hits": hits,
		}
	return {
		"ok": true,
		"message": "Valid Duelyst source. Detected: %s" % ", ".join(hits),
		"marker_hits": hits,
	}

func output_path_for(name: String) -> String:
	return output_root.path_join(name)

func mark_scanned() -> void:
	last_scan_at = Time.get_datetime_string_from_system()
	save_to_disk()

func mark_categorized() -> void:
	last_categorize_at = Time.get_datetime_string_from_system()
	save_to_disk()

func mark_imported() -> void:
	last_import_at = Time.get_datetime_string_from_system()
	save_to_disk()
