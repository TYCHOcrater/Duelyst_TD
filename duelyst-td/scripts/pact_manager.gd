extends Node

# Loads PactDefs from data/pacts/ and tracks which are active in the current run.
# Other systems query effect totals via sum_int / product_float / has_flag.

const PACTS_DIR := "res://data/pacts/"

signal pacts_changed()
signal offers_rolled(options: Array)

var pacts: Dictionary = {}            # id -> def
var pact_ids: Array[String] = []
var active_ids: Array[String] = []    # chosen in this run, in order
# C9: parallel to active_ids — which slot chose each pact. -1 means "no
# attribution" (legacy / single-player runs default to local_slot_id=0).
var active_chooser: Array[int] = []
var current_offers: Array[String] = []  # 3 options awaiting pick

func _ready() -> void:
	_load()

func reset() -> void:
	active_ids.clear()
	active_chooser.clear()
	current_offers.clear()
	pacts_changed.emit()

func _load() -> void:
	var dir := DirAccess.open(PACTS_DIR)
	if not dir:
		push_error("PactManager: dir %s not accessible" % PACTS_DIR)
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
		var f := FileAccess.open(PACTS_DIR + fname, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("PactManager: failed to parse %s" % fname)
			continue
		var pid: String = parsed.get("id", fname.get_basename())
		pacts[pid] = parsed
		pact_ids.append(pid)
	print("PactManager: loaded %d pacts" % pacts.size())

func get_def(id: String) -> Dictionary:
	return pacts.get(id, {})

func is_active(id: String) -> bool:
	return id in active_ids

func is_offered(id: String) -> bool:
	return id in current_offers

func roll_offers(count: int) -> Array[String]:
	# Pick `count` distinct pacts the player hasn't taken yet.
	var pool: Array[String] = []
	for pid in pact_ids:
		if not is_active(pid):
			pool.append(pid)
	# Use SessionRng for determinism.
	var shuffled: Array = SessionRng.shuffle(pool)
	var picked: Array[String] = []
	var take: int = min(count, shuffled.size())
	for i in take:
		picked.append(shuffled[i])
	current_offers = picked
	offers_rolled.emit(current_offers)
	return current_offers

func activate(id: String, chosen_by_slot: int = -1) -> bool:
	if not pacts.has(id):
		return false
	if is_active(id):
		return false
	active_ids.append(id)
	# C9: parallel attribution. If unspecified, callers default to -1 so the
	# run summary can still distinguish "no record" from a real slot id.
	active_chooser.append(chosen_by_slot)
	current_offers.clear()
	pacts_changed.emit()
	return true

# C9: lookup the slot that picked the pact at active_ids index `i`, or -1 if
# no attribution exists for that index.
func chooser_for(i: int) -> int:
	if i < 0 or i >= active_chooser.size():
		return -1
	return active_chooser[i]

# --- Effect queries (sum_int, product_float, has_flag) ---

func sum_int(effect_type: String) -> int:
	var total := 0
	for pid in active_ids:
		var def: Dictionary = pacts.get(pid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				total += int(effect.get("amount", 0))
	return total

func product_float(effect_type: String) -> float:
	var prod := 1.0
	for pid in active_ids:
		var def: Dictionary = pacts.get(pid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				prod *= float(effect.get("mult", 1.0))
	return prod

func has_flag(effect_type: String) -> bool:
	for pid in active_ids:
		var def: Dictionary = pacts.get(pid, {})
		for effect in def.get("effects", []):
			if effect.get("type", "") == effect_type:
				return true
	return false
