extends Node

# Cross-run mastery: persisted per-unit stats. Unlocks mastery levels
# (Initiate/Adept/Master/Champion/Legend) based on accumulated kills,
# placements, victories, and best wave reached while the unit was placed.

const MASTERY_PATH := "user://mastery.json"

# Tier thresholds: progression unlocks at (kills >= K AND wins >= W AND placements >= P).
# Levels are derived in mastery_level().
const TIERS := [
	{"level": 1, "name": "Initiate",  "kills": 0,   "wins": 0, "placements": 3},
	{"level": 2, "name": "Adept",     "kills": 50,  "wins": 0, "placements": 0},
	{"level": 3, "name": "Master",    "kills": 100, "wins": 1, "placements": 0},
	{"level": 4, "name": "Champion",  "kills": 200, "wins": 3, "placements": 0},
	{"level": 5, "name": "Legend",    "kills": 500, "wins": 5, "placements": 0},
]

var _data: Dictionary = {}   # unit_id -> {kills, wins, runs, placements, max_wave}

func _ready() -> void:
	_load()

# --- API ---

func get_entry(unit_id: String) -> Dictionary:
	if not _data.has(unit_id):
		return {"kills": 0, "wins": 0, "runs": 0, "placements": 0, "max_wave": 0}
	return _data[unit_id]

func mastery_level(unit_id: String) -> int:
	var e: Dictionary = get_entry(unit_id)
	var k: int = int(e.get("kills", 0))
	var w: int = int(e.get("wins", 0))
	var p: int = int(e.get("placements", 0))
	var level: int = 0
	for tier in TIERS:
		if k >= int(tier["kills"]) and w >= int(tier["wins"]) and p >= int(tier["placements"]):
			level = int(tier["level"])
	return level

func tier_name(level: int) -> String:
	for tier in TIERS:
		if int(tier["level"]) == level:
			return tier["name"]
	return ""

func record_run(stats: Dictionary) -> void:
	# Walk RunLog stats and increment per-unit accumulators.
	var placements: Dictionary = stats.get("placements_by_unit", {})
	var damage_by_unit: Dictionary = stats.get("damage_by_unit", {})
	var wave_reached: int = int(stats.get("wave_reached", 0))
	var victory: bool = String(stats.get("result", "")) == "victory"
	# Estimate kills per unit from damage attribution. Real kill counts per
	# unit would require per-tower tracking across the whole run -- the
	# damage proxy is good enough for mastery tier gating.
	var total_damage: int = int(stats.get("damage_dealt", 0))
	var total_kills: int = int(stats.get("enemies_killed", 0))
	for unit_id in placements:
		var e: Dictionary = get_entry(unit_id)
		# Make a copy so mutations don't get lost if get_entry returned defaults.
		var entry: Dictionary = e.duplicate()
		entry["placements"] = int(entry.get("placements", 0)) + int(placements[unit_id])
		entry["runs"] = int(entry.get("runs", 0)) + 1
		if victory:
			entry["wins"] = int(entry.get("wins", 0)) + 1
		if wave_reached > int(entry.get("max_wave", 0)):
			entry["max_wave"] = wave_reached
		# Kills proxy: fraction of total kills weighted by this unit's damage share.
		if total_damage > 0:
			var share: float = float(int(damage_by_unit.get(unit_id, 0))) / float(total_damage)
			var est_kills: int = int(round(share * float(total_kills)))
			entry["kills"] = int(entry.get("kills", 0)) + est_kills
		_data[unit_id] = entry
	_save()

func sorted_entries() -> Array:
	# Returns Array of {unit_id, entry, level} sorted by level desc, kills desc.
	var rows: Array = []
	for uid in _data.keys():
		var e: Dictionary = _data[uid]
		rows.append({
			"unit_id": uid,
			"entry": e,
			"level": mastery_level(uid),
		})
	rows.sort_custom(func(a, b):
		if int(a.level) != int(b.level):
			return int(a.level) > int(b.level)
		return int(a.entry.get("kills", 0)) > int(b.entry.get("kills", 0))
	)
	return rows

# --- IO ---

func _load() -> void:
	if not FileAccess.file_exists(MASTERY_PATH):
		return
	var f := FileAccess.open(MASTERY_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed

func _save() -> void:
	var f := FileAccess.open(MASTERY_PATH, FileAccess.WRITE)
	if not f:
		push_warning("Mastery: could not open %s for write" % MASTERY_PATH)
		return
	f.store_string(JSON.stringify(_data, "  "))
	f.close()
