extends Node

# PackManager (D14 of the ingestion milestone) — autoload that discovers
# faction/enemy/etc. content packs under res://data/content_packs/ and
# tracks which ones are enabled. UnitFactory queries it when listing
# offer-eligible units; the shop / draft director see pack content as if
# it were curated content, but only when the pack is toggled on.
#
# Enabled state persists to user://pack_state.json so the dev's toggle
# choices survive editor restarts.

signal packs_changed()

const PACK_DIR := "res://data/content_packs/duelyst/"
const STATE_PATH := "user://pack_state.json"

var packs: Dictionary = {}            # pack_id -> pack_dict
var enabled_ids: Dictionary = {}      # pack_id -> bool

const VALIDATOR_SCRIPT := preload("res://scripts/content/duelyst_content_validator.gd")

func _ready() -> void:
	_load_packs()
	_load_enabled_state()
	_boot_validate()

func _boot_validate() -> void:
	# D15: surface any pack issues at boot so typos in pack JSONs don't ambush
	# the user during a draft. Errors go to push_error (red in console);
	# warnings to push_warning (yellow). Nothing blocks the boot — bad packs
	# just won't appear in offers if their refs don't resolve.
	if packs.is_empty():
		return
	var res: Dictionary = VALIDATOR_SCRIPT.validate_all()
	var stats: Dictionary = res.get("stats", {})
	print("PackManager: validated %d pack(s) / %d shell(s) — %d errors, %d warnings" % [
		int(stats.get("packs_checked", 0)),
		int(stats.get("shells_checked", 0)),
		int(stats.get("errors", 0)),
		int(stats.get("warnings", 0)),
	])
	for e in res.get("errors", []):
		push_error("PackValidator: %s" % e)
	for w in res.get("warnings", []):
		push_warning("PackValidator: %s" % w)

func _load_packs() -> void:
	packs.clear()
	if not DirAccess.dir_exists_absolute(PACK_DIR):
		return
	var dir := DirAccess.open(PACK_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if not fname.ends_with(".json"):
			continue
		var path: String = PACK_DIR.path_join(fname)
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var pack_id: String = parsed.get("id", fname.get_basename())
		packs[pack_id] = parsed
	dir.list_dir_end()
	print("PackManager: loaded %d content pack(s) from %s" % [packs.size(), PACK_DIR])

func _load_enabled_state() -> void:
	if not FileAccess.file_exists(STATE_PATH):
		return
	var f := FileAccess.open(STATE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for pid in parsed:
		enabled_ids[String(pid)] = bool(parsed[pid])

func _save_enabled_state() -> void:
	var f := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(enabled_ids, "  "))
	f.close()

func is_enabled(pack_id: String) -> bool:
	return bool(enabled_ids.get(pack_id, false))

func set_enabled(pack_id: String, enabled: bool) -> void:
	if not packs.has(pack_id):
		return
	enabled_ids[pack_id] = enabled
	_save_enabled_state()
	packs_changed.emit()

func get_pack(pack_id: String) -> Dictionary:
	return packs.get(pack_id, {})

func all_pack_ids() -> Array:
	return packs.keys()

func enabled_pack_ids() -> Array:
	var out: Array = []
	for pid in packs.keys():
		if is_enabled(String(pid)):
			out.append(String(pid))
	return out

# Returns flattened defender_shells from all enabled packs. Each entry is the
# raw shell dict the pack JSON defined (cost/range/damage/etc.). UnitFactory
# consumes these alongside its res://data/units/*.json curated content.
func enabled_defender_shells() -> Array:
	var out: Array = []
	for pid in enabled_pack_ids():
		var pack: Dictionary = packs[pid]
		var shells: Array = pack.get("defender_shells", [])
		for s in shells:
			out.append(s)
	return out
