extends Node

# EvolutionManager (A6) — loads per-base-unit EvolutionDef branches from
# res://data/evolutions/<base_unit_id>.json and serves the choice list to
# the HUD when a tower reaches a star level with options available.
#
# Schema (per file):
#   {
#     "base_unit_id": "...",
#     "evolutions": { "2": [ EvolutionDef, EvolutionDef ], "3": [...] }
#   }
# EvolutionDef:
#   { id, display_name, description, stat_mods{...}, behavior_mods[...] }
#
# A6 MVP applies stat_mods only — behavior_mods are recorded as tags for
# later iterations to wire actual code paths (chain attack, etc.).

const DIR := "res://data/evolutions/"

var by_unit: Dictionary = {}    # base_unit_id -> { "2": [defs...], "3": [...] }

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	by_unit.clear()
	if not DirAccess.dir_exists_absolute(DIR):
		return
	var dir := DirAccess.open(DIR)
	if not dir:
		return
	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if not fname.ends_with(".json"):
			continue
		var path: String = DIR.path_join(fname)
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var uid: String = parsed.get("base_unit_id", fname.get_basename())
		by_unit[uid] = parsed.get("evolutions", {})
	dir.list_dir_end()
	print("EvolutionManager: loaded evolutions for %d unit(s)" % by_unit.size())

func has_choices(base_unit_id: String, star_level: int) -> bool:
	return get_choices(base_unit_id, star_level).size() > 0

func get_choices(base_unit_id: String, star_level: int) -> Array:
	# Returns array of EvolutionDef dicts for this base unit at this star.
	if not by_unit.has(base_unit_id):
		return []
	var per_star: Dictionary = by_unit[base_unit_id]
	return per_star.get(str(star_level), [])

func get_def(base_unit_id: String, evolution_id: String) -> Dictionary:
	# Returns the EvolutionDef by id across all star levels, or {} if not found.
	if not by_unit.has(base_unit_id):
		return {}
	var per_star: Dictionary = by_unit[base_unit_id]
	for star_key in per_star.keys():
		for d in per_star[star_key]:
			if String(d.get("id", "")) == evolution_id:
				return d
	return {}
