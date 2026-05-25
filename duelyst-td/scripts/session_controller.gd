extends Node

# SessionController: owns the PlayerSlot array for the current run.
# Lives as a child of main.tscn (one per run, not an autoload).
#
# For C0 this is plumbing only:
#   - reads RunConfig.player_count + session_topology at _ready
#   - creates N PlayerSlot data objects
#   - slot 0 is the local player; slots 1..N-1 exist in memory for C1+
#
# C1 will populate slot.route_id from a CoopMapDef.
# C2 will route enemy spawning per-slot.
# C4 will gate phase transitions on all-ready.

const PLAYER_SLOT_SCRIPT := preload("res://scripts/player_slot.gd")
const AID_TOKENS_PER_RUN := 2          # C7: each slot starts the run with this many aid tokens

signal slots_changed(slots: Array)
signal aid_tokens_changed(slot_id: int, current: int)

var player_slots: Array = []
var local_slot_id: int = 0  # which slot the local player controls

# Main.gd calls configure() explicitly after RunLog.start_run so that
# record_player_slots lands in active stats. Child _ready fires before
# parent _ready in Godot, so auto-configuring here would race.

func configure(n: int, topology: String) -> void:
	var clamped: int = clamp(n, RunConfig.MIN_PLAYER_COUNT, RunConfig.MAX_PLAYER_COUNT)
	player_slots.clear()
	for i in clamped:
		var slot = PLAYER_SLOT_SCRIPT.new(i)
		# C7: seed aid tokens. Solo (clamped==1) keeps them for symmetry but
		# can't actually use them — no ally route exists.
		slot.aid_tokens = AID_TOKENS_PER_RUN
		player_slots.append(slot)
	print("SessionController: %d slot(s), topology=%s, aid_tokens/slot=%d" % [clamped, topology, AID_TOKENS_PER_RUN])
	if RunLog.active:
		RunLog.record_player_slots(summary_for_run_log())
	slots_changed.emit(player_slots)

# C10: find the slot that owns route_id, or -1 if none. Solo slot 0 owns the
# joined "rid1,rid2,..." string so any rid in that list returns 0.
func slot_for_route(route_id: String) -> int:
	if route_id == "":
		return -1
	for i in player_slots.size():
		var ids: PackedStringArray = String(player_slots[i].route_id).split(",")
		if route_id in ids:
			return i
	return -1

# C10: bump a stat for the given slot. Stats dict has integer counters
# (units_placed / leaks / core_damage_taken).
func add_slot_stat(slot_id: int, key: String, delta: int = 1) -> void:
	if slot_id < 0 or slot_id >= player_slots.size():
		return
	var slot = player_slots[slot_id]
	slot.stats[key] = int(slot.stats.get(key, 0)) + delta

# C7: spend one aid token from slot `from_slot_id`. Returns true on success.
func consume_aid_token(from_slot_id: int) -> bool:
	if from_slot_id < 0 or from_slot_id >= player_slots.size():
		return false
	var slot = player_slots[from_slot_id]
	if slot.aid_tokens <= 0:
		return false
	slot.aid_tokens -= 1
	aid_tokens_changed.emit(from_slot_id, slot.aid_tokens)
	return true

# C3: assign each slot the route it owns, and seed the slot's owned-tile
# set so placement_controller can ask `local_slot.owns_tile(gp)`.
# Conventions:
#   - In solo (slot_count == 1), slot 0 owns EVERY route in the map (the lone
#     player must be able to build along every lane).
#   - In multi, slot i owns routes[i] (and only that route). Extra routes
#     beyond slot_count remain unowned — nobody can build in their zone.
# The "owned" tiles for a route are: the route's path_chain tiles + every
# buildable tile within OWNERSHIP_RADIUS of any chain tile.
const OWNERSHIP_RADIUS := 3

func assign_routes(board) -> void:
	if player_slots.is_empty() or board == null:
		return
	var routes: Array = board.routes
	var grid: GridController = board.grid
	if routes.is_empty() or grid == null:
		# Single-topology: slot 0 owns everything that's buildable.
		_assign_universal_ownership(grid)
		return
	if player_slots.size() == 1:
		# Solo on a multi-route map: slot 0 owns all routes.
		var all_ids: Array = []
		for r in routes:
			all_ids.append(String(r.get("id", "")))
		player_slots[0].route_id = ",".join(all_ids)
		player_slots[0].owned_tiles = _zone_for_routes(routes, all_ids, grid)
		return
	for i in player_slots.size():
		if i >= routes.size():
			player_slots[i].route_id = ""
			player_slots[i].owned_tiles = {}
			continue
		var rid: String = String(routes[i].get("id", ""))
		player_slots[i].route_id = rid
		player_slots[i].owned_tiles = _zone_for_routes(routes, [rid], grid)

func _assign_universal_ownership(grid: GridController) -> void:
	var slot = player_slots[0]
	slot.route_id = ""
	slot.owned_tiles = {}
	if grid == null:
		return
	for y in grid.height:
		for x in grid.width:
			if grid.is_buildable(x, y):
				slot.owned_tiles[Vector2i(x, y)] = true

func _zone_for_routes(routes: Array, route_ids: Array, grid: GridController) -> Dictionary:
	var out: Dictionary = {}
	for r in routes:
		var rid: String = String(r.get("id", ""))
		if not route_ids.has(rid):
			continue
		var chain: Array = r.get("path_chain", [])
		for pt in chain:
			for dy in range(-OWNERSHIP_RADIUS, OWNERSHIP_RADIUS + 1):
				for dx in range(-OWNERSHIP_RADIUS, OWNERSHIP_RADIUS + 1):
					var gp: Vector2i = Vector2i(pt.x + dx, pt.y + dy)
					if not grid.in_bounds(gp.x, gp.y):
						continue
					if not grid.is_buildable(gp.x, gp.y):
						continue
					out[gp] = true
	return out

func slot_count() -> int:
	return player_slots.size()

func local_slot():
	if local_slot_id < player_slots.size():
		return player_slots[local_slot_id]
	return null

func summary_for_run_log() -> Array:
	var out: Array = []
	for s in player_slots:
		out.append(s.to_dict())
	return out
