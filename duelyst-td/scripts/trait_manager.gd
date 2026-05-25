extends Node

# Loads TraitDefs from data/traits/ and rolls them onto draft offers.

const TRAITS_DIR := "res://data/traits/"

# Probability a draft offer rolls a trait, by wave (slowly ramps).
const BASE_TRAIT_CHANCE := 0.30
const TRAIT_CHANCE_PER_WAVE := 0.03   # +3% per wave reached
const TRAIT_CHANCE_MAX := 0.65

var traits: Dictionary = {}
var trait_ids: Array[String] = []

func _ready() -> void:
	_load()

func _load() -> void:
	var dir := DirAccess.open(TRAITS_DIR)
	if not dir:
		push_warning("TraitManager: dir %s not accessible" % TRAITS_DIR)
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
		var f := FileAccess.open(TRAITS_DIR + fname, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("TraitManager: failed to parse %s" % fname)
			continue
		var tid: String = parsed.get("id", fname.get_basename())
		traits[tid] = parsed
		trait_ids.append(tid)
	print("TraitManager: loaded %d traits" % traits.size())

func get_def(id: String) -> Dictionary:
	return traits.get(id, {})

# Returns a trait id rolled for this unit + wave, or "" for no trait.
# Buff-only towers (damage <= 0) never get traits since the mods don't apply
# meaningfully.
func maybe_roll(unit_def: Dictionary, wave: int) -> String:
	if traits.is_empty():
		return ""
	if int(unit_def.get("damage", 0)) <= 0:
		return ""
	var chance: float = min(TRAIT_CHANCE_MAX, BASE_TRAIT_CHANCE + wave * TRAIT_CHANCE_PER_WAVE)
	if SessionRng.randf() > chance:
		return ""
	# Pick a random trait. Future: filter by compatible_tags.
	return SessionRng.pick(trait_ids)
