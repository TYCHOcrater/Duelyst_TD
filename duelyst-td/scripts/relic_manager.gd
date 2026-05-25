extends Node

# Parallel to PactManager. Effects use the same vocabulary (sum_int / product_float
# / has_flag) so consumers can query both via the ModifierTotals helper.

const RELICS_DIR := "res://data/relics/"

signal relics_changed()
signal offers_rolled(options: Array)

var relics: Dictionary = {}          # id -> def
var relic_ids: Array[String] = []
var active_ids: Array[String] = []   # acquired this run, in order
var current_offers: Array[String] = []  # awaiting pick

func _ready() -> void:
	_load()

func reset() -> void:
	active_ids.clear()
	current_offers.clear()
	relics_changed.emit()

func _load() -> void:
	var dir := DirAccess.open(RELICS_DIR)
	if not dir:
		push_error("RelicManager: dir %s not accessible" % RELICS_DIR)
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
		var f := FileAccess.open(RELICS_DIR + fname, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("RelicManager: failed to parse %s" % fname)
			continue
		var rid: String = parsed.get("id", fname.get_basename())
		relics[rid] = parsed
		relic_ids.append(rid)
	print("RelicManager: loaded %d relics" % relics.size())

func get_def(id: String) -> Dictionary:
	return relics.get(id, {})

func is_active(id: String) -> bool:
	return id in active_ids

func is_offered(id: String) -> bool:
	return id in current_offers

func roll_offers(count: int) -> Array[String]:
	var pool: Array[String] = []
	for rid in relic_ids:
		if not is_active(rid):
			pool.append(rid)
	var shuffled: Array = SessionRng.shuffle(pool)
	var picked: Array[String] = []
	var take: int = min(count, shuffled.size())
	for i in take:
		picked.append(shuffled[i])
	current_offers = picked
	offers_rolled.emit(current_offers)
	return current_offers

func activate(id: String) -> bool:
	if not relics.has(id):
		return false
	if is_active(id):
		return false
	active_ids.append(id)
	current_offers.clear()
	relics_changed.emit()
	return true

func sum_int(effect_type: String) -> int:
	var total := 0
	for rid in active_ids:
		var def: Dictionary = relics.get(rid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				total += int(effect.get("amount", 0))
	return total

func product_float(effect_type: String) -> float:
	var prod := 1.0
	for rid in active_ids:
		var def: Dictionary = relics.get(rid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				prod *= float(effect.get("mult", 1.0))
	return prod

func has_flag(effect_type: String) -> bool:
	for rid in active_ids:
		var def: Dictionary = relics.get(rid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				return true
	return false
