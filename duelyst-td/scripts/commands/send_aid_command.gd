class_name SendAidCommand
extends Command

# C7: Aid Token v1. Sends a temporary copy of a unit to an ally's route.
# Tower lives for the duration of the next combat phase, then is removed.
# Requires:
#   - source slot owns at least 1 aid token
#   - target slot exists and is NOT the source
#   - target slot has owned_tiles (a route was assigned)
# On success: decrements source's aid_tokens, spawns a TempAid tower at a
# chosen tile in the target's zone, registers it for wave-end cleanup.

var source_slot_id: int
var unit_id: String
var target_slot_id: int

func _init(_src: int, _unit_id: String, _target: int) -> void:
	source_slot_id = _src
	unit_id = _unit_id
	target_slot_id = _target

func execute(main: Node) -> bool:
	var session = main.session if "session" in main else null
	if session == null:
		reason = "session not bound"
		return false
	if source_slot_id == target_slot_id:
		reason = "cannot aid yourself"
		return false
	if target_slot_id < 0 or target_slot_id >= session.player_slots.size():
		reason = "target slot %d not present" % target_slot_id
		return false
	if source_slot_id < 0 or source_slot_id >= session.player_slots.size():
		reason = "source slot %d not present" % source_slot_id
		return false
	var target_slot = session.player_slots[target_slot_id]
	if target_slot.owned_tiles.is_empty():
		reason = "target has no owned tiles"
		return false
	# Spend the token before placing so a failed placement still costs.
	if not session.consume_aid_token(source_slot_id):
		reason = "no aid tokens left on slot %d" % source_slot_id
		return false
	# Pick the tile in target's zone closest to the target's route midpoint —
	# midfield placement is the most useful default for an aid drop.
	var place_tile: Vector2i = _pick_drop_tile(main, target_slot)
	var place_pos: Vector2 = main.board.grid.grid_to_world(place_tile.x, place_tile.y)
	# Instantiate the unit, mark it as an aid copy, parent into placement.
	var aid_tower = UnitFactory.make_tower(unit_id, "", "")
	if aid_tower == null:
		reason = "could not make aid tower for unit_id %s" % unit_id
		return false
	if "is_aid_unit" in aid_tower:
		aid_tower.is_aid_unit = true
	if "aid_source_slot" in aid_tower:
		aid_tower.aid_source_slot = source_slot_id
	main.placement.add_child(aid_tower)
	aid_tower.global_position = place_pos
	# Soft tint so aid copies are visually distinct from owned towers.
	aid_tower.modulate = Color(0.85, 0.95, 1.15, 1.0)
	# Track it for wave-end cleanup.
	aid_tower.add_to_group("aid_units")
	RunLog.record("aid_sent", {
		"from_slot": source_slot_id,
		"to_slot": target_slot_id,
		"unit_id": unit_id,
		"tile": [place_tile.x, place_tile.y],
	})
	success = true
	reason = "aid sent: slot %d -> slot %d (%s)" % [source_slot_id, target_slot_id, unit_id]
	return true

func _pick_drop_tile(main: Node, target_slot) -> Vector2i:
	# Walk the target's owned_tiles dict; pick the one closest to the
	# midpoint of their route's path_chain. Falls back to any owned tile.
	var owned_keys: Array = target_slot.owned_tiles.keys()
	if owned_keys.is_empty():
		return Vector2i.ZERO
	var routes: Array = main.board.routes
	var rid: String = String(target_slot.route_id).split(",")[0]
	var anchor: Vector2i = owned_keys[0]
	for r in routes:
		if String(r.get("id", "")) != rid:
			continue
		var chain: Array = r.get("path_chain", [])
		if not chain.is_empty():
			anchor = chain[chain.size() / 2]
		break
	var best: Vector2i = owned_keys[0]
	var best_d: int = 9999
	for k in owned_keys:
		var d: int = abs(k.x - anchor.x) + abs(k.y - anchor.y)
		if d < best_d:
			best_d = d
			best = k
	return best

func describe() -> String:
	return "SendAid(%s -> slot %d, unit %s)" % [str(source_slot_id), target_slot_id, unit_id]
