extends Node

# Loads UnitDefs from data/units.json and builds tower nodes on demand.

const UNITS_DIR := "res://data/units/"
const TOWER_TEMPLATE := "res://scenes/tower.tscn"

var units: Dictionary = {}  # id -> UnitDef dict
var unit_ids: Array[String] = []  # ordered list

func _ready() -> void:
	_load_units()

func _load_units() -> void:
	var dir := DirAccess.open(UNITS_DIR)
	if not dir:
		push_error("UnitFactory: directory %s not accessible" % UNITS_DIR)
		return
	dir.list_dir_begin()
	var files: Array[String] = []
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if fname.ends_with(".json"):
			files.append(fname)
	dir.list_dir_end()
	files.sort()
	for fname in files:
		var path := UNITS_DIR + fname
		var f := FileAccess.open(path, FileAccess.READ)
		if not f:
			push_warning("UnitFactory: failed to open %s" % path)
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("UnitFactory: failed to parse %s" % path)
			continue
		var uid: String = parsed.get("id", fname.get_basename())
		units[uid] = parsed
		unit_ids.append(uid)
	print("UnitFactory: loaded %d units from %s" % [units.size(), UNITS_DIR])

func get_def(id: String) -> Dictionary:
	if units.has(id):
		return units[id]
	# Fall back to enabled-pack shells (D14 PackManager integration).
	for shell in PackManager.enabled_defender_shells():
		if String(shell.get("id", "")) == id:
			return shell
	return {}

func sprite_frames_for(id: String) -> SpriteFrames:
	var def := get_def(id)
	var asset_id: String = def.get("asset_profile_id", "")
	if asset_id == "":
		return null
	var path := "res://assets/units/%s/%s.tres" % [asset_id, asset_id]
	if not ResourceLoader.exists(path):
		push_warning("UnitFactory: missing SpriteFrames %s" % path)
		return null
	return load(path)

func make_tower(id: String, trait_id: String = "", flaw_id: String = "") -> Node2D:
	var def := get_def(id)
	if def.is_empty():
		push_error("UnitFactory: unknown unit '%s'" % id)
		return null
	var template := load(TOWER_TEMPLATE) as PackedScene
	var t: Node2D = template.instantiate()
	t.apply_def(def)
	if trait_id != "":
		var trait_def: Dictionary = TraitManager.get_def(trait_id)
		if not trait_def.is_empty():
			t.apply_trait(trait_def)
	if flaw_id != "":
		var flaw_def: Dictionary = FlawManager.get_def(flaw_id)
		if not flaw_def.is_empty():
			t.apply_flaw(flaw_def)
	return t

func effective_cost(id: String, trait_id: String = "", flaw_id: String = "") -> int:
	var def := get_def(id)
	var base: float = float(def.get("cost", 0))
	var mult: float = 1.0
	if trait_id != "":
		var trait_def: Dictionary = TraitManager.get_def(trait_id)
		mult *= float(trait_def.get("stat_mods", {}).get("cost_mult", 1.0))
	if flaw_id != "":
		var flaw_def: Dictionary = FlawManager.get_def(flaw_id)
		mult *= float(flaw_def.get("stat_mods", {}).get("cost_mult", 1.0))
	return int(round(base * mult))

func all_ids() -> Array[String]:
	# Curated res://data/units/ ids + any defender_shells from enabled content
	# packs (D14). Packs are debug-only by default — they only flow into the
	# shop after the dev toggles them on in the Content Pack Manager.
	var out: Array[String] = []
	for u in unit_ids:
		out.append(u)
	for shell in PackManager.enabled_defender_shells():
		var id: String = String(shell.get("id", ""))
		if id != "" and not (id in out):
			out.append(id)
	return out

func ids_by_filter(filter: Dictionary) -> Array[String]:
	# Optional filter keys: factions (Array[String]), tags (Array[String]),
	#   max_cost (int), min_cost (int).
	var out: Array[String] = []
	for id in unit_ids:
		var d := units[id] as Dictionary
		if filter.has("factions") and not (d.get("faction", "") in filter["factions"]):
			continue
		if filter.has("max_cost") and int(d.get("cost", 0)) > int(filter["max_cost"]):
			continue
		if filter.has("min_cost") and int(d.get("cost", 0)) < int(filter["min_cost"]):
			continue
		if filter.has("tags"):
			var ts: Array = d.get("tags", [])
			var any := false
			for t in filter["tags"]:
				if t in ts:
					any = true
					break
			if not any:
				continue
		out.append(id)
	return out
