extends Node

signal gold_changed(value: int)
signal lives_changed(value: int)
signal wave_changed(value: int)
signal game_over(victory: bool)
# C6: per-route Gate Shields. Leaks damage the route's shield first; once
# shields are 0 leaks fall through to the shared Core (`lives`).
signal gate_shield_changed(route_id: String, current: int, max_hp: int)
# C8: per-route breach-save bank. Killing a breach packet adds saves; each
# save absorbs the next leak on that route (no shield/core damage at all).
signal breach_save_changed(route_id: String, current: int)

const START_GOLD := 20
const START_LIVES := 20
const GATE_SHIELD_PER_ROUTE := 3

var gold: int = START_GOLD
var lives: int = START_LIVES
var wave: int = 0
var game_running: bool = true
# C6: route_id -> current HP, route_id -> max HP. Empty for single-topology maps.
var gate_shields: Dictionary = {}
var gate_shield_max: Dictionary = {}
# C8: route_id -> int. Each save consumes the next leak on that route.
var breach_saves: Dictionary = {}
const BREACH_SAVES_PER_KILL := 2

func reset() -> void:
	gold = START_GOLD
	lives = START_LIVES
	wave = 0
	game_running = true
	gate_shields.clear()
	gate_shield_max.clear()
	breach_saves.clear()
	gold_changed.emit(gold)
	lives_changed.emit(lives)
	wave_changed.emit(wave)

# C6: called by main after the board's routes are known. Single-topology
# maps pass an empty `routes` array — no shields exist there, leaks go
# straight to the Core (same as pre-C6 behavior).
func init_gate_shields(routes: Array, per_route_hp: int = GATE_SHIELD_PER_ROUTE) -> void:
	gate_shields.clear()
	gate_shield_max.clear()
	for r in routes:
		var rid: String = String(r.get("id", ""))
		if rid == "":
			continue
		gate_shields[rid] = per_route_hp
		gate_shield_max[rid] = per_route_hp
		gate_shield_changed.emit(rid, per_route_hp, per_route_hp)

# C6: an enemy leaked on `route_id`. Damages that route's gate shield first,
# overflow bleeds into Core lives. Returns the breakdown {shield_hits, core_hits}
# so leak logs can record both.
func take_leak_damage(route_id: String, amount: int) -> Dictionary:
	if not game_running or amount <= 0:
		return {"shield_hits": 0, "core_hits": 0, "saved": false}
	# C8: if a breach save is banked for this route, eat the entire leak.
	if route_id != "" and int(breach_saves.get(route_id, 0)) > 0:
		breach_saves[route_id] = int(breach_saves[route_id]) - 1
		breach_save_changed.emit(route_id, breach_saves[route_id])
		return {"shield_hits": 0, "core_hits": 0, "saved": true}
	var shield_hits: int = 0
	var core_hits: int = 0
	if route_id != "" and gate_shields.has(route_id) and gate_shields[route_id] > 0:
		var s: int = gate_shields[route_id]
		shield_hits = min(s, amount)
		gate_shields[route_id] = s - shield_hits
		gate_shield_changed.emit(route_id, gate_shields[route_id], gate_shield_max.get(route_id, 0))
		amount -= shield_hits
	if amount > 0:
		core_hits = amount
		take_damage(amount)
	return {"shield_hits": shield_hits, "core_hits": core_hits, "saved": false}

# C8: a breach packet was killed on this route — bank some saves.
func grant_breach_saves(route_id: String, amount: int = BREACH_SAVES_PER_KILL) -> void:
	if route_id == "" or amount <= 0:
		return
	breach_saves[route_id] = int(breach_saves.get(route_id, 0)) + amount
	breach_save_changed.emit(route_id, breach_saves[route_id])

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func take_damage(amount: int) -> void:
	if not game_running:
		return
	lives = max(0, lives - amount)
	lives_changed.emit(lives)
	if lives <= 0:
		game_running = false
		game_over.emit(false)

func set_wave(w: int) -> void:
	wave = w
	wave_changed.emit(wave)

func declare_victory() -> void:
	if not game_running:
		return
	game_running = false
	game_over.emit(true)
