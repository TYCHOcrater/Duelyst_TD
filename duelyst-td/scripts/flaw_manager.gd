extends Node

# Loads FlawDefs from data/flaws/ and rolls them onto draft offers that
# already have a trait. Same stat_mods vocabulary as traits — tower.apply_trait
# can apply either.

const FLAWS_DIR := "res://data/flaws/"

# Chance a trait-bearing offer ALSO gets a flaw, by wave.
const BASE_FLAW_CHANCE := 0.25
const FLAW_CHANCE_PER_WAVE := 0.025
const FLAW_CHANCE_MAX := 0.50

var flaws: Dictionary = {}
var flaw_ids: Array[String] = []

func _ready() -> void:
	_load()

func _load() -> void:
	var dir := DirAccess.open(FLAWS_DIR)
	if not dir:
		push_warning("FlawManager: dir %s not accessible" % FLAWS_DIR)
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
		var f := FileAccess.open(FLAWS_DIR + fname, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("FlawManager: failed to parse %s" % fname)
			continue
		var fid: String = parsed.get("id", fname.get_basename())
		flaws[fid] = parsed
		flaw_ids.append(fid)
	print("FlawManager: loaded %d flaws" % flaws.size())

func get_def(id: String) -> Dictionary:
	return flaws.get(id, {})

# Roll a flaw only if a trait was already rolled (flaws are the cost half
# of trait-bearing offers; pure flaws would just be "this is worse" with
# no upside).
func maybe_roll(unit_def: Dictionary, wave: int, trait_id: String) -> String:
	if trait_id == "" or flaws.is_empty():
		return ""
	if int(unit_def.get("damage", 0)) <= 0:
		return ""
	var chance: float = min(FLAW_CHANCE_MAX, BASE_FLAW_CHANCE + wave * FLAW_CHANCE_PER_WAVE)
	if SessionRng.randf() > chance:
		return ""
	return SessionRng.pick(flaw_ids)
