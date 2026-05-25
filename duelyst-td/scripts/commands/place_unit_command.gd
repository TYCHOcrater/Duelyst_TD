class_name PlaceUnitCommand
extends Command

var unit_id: String
var position: Vector2

func _init(_unit_id: String, _position: Vector2) -> void:
	unit_id = _unit_id
	position = _position

func execute(main: Node) -> bool:
	var placement = main.placement
	if placement == null:
		reason = "placement controller not bound"
		return false
	if placement.placement_locked:
		reason = "placement locked (combat phase)"
		return false
	var def: Dictionary = UnitFactory.get_def(unit_id)
	if def.is_empty():
		reason = "unknown unit id: %s" % unit_id
		return false
	if not placement.is_valid_placement(position):
		reason = "tile is not buildable (path / blocked / occupied)"
		return false
	var trait_id: String = placement.current_trait_id
	var flaw_id: String = placement.current_flaw_id
	var cost: int = UnitFactory.effective_cost(unit_id, trait_id, flaw_id)
	if GameState.gold < cost:
		reason = "insufficient gold (have %d, need %d)" % [GameState.gold, cost]
		return false
	GameState.spend_gold(cost)
	var tower = UnitFactory.make_tower(unit_id, trait_id, flaw_id)
	if tower == null:
		reason = "UnitFactory failed to build tower"
		GameState.add_gold(cost)
		return false
	tower.global_position = position
	placement.add_child(tower)
	AudioManager.play("place_tower")
	placement.cancel_selection()
	RunLog.record("buy_offer", {
		"unit": unit_id,
		"trait": trait_id,
		"flaw": flaw_id,
		"cost": cost,
		"faction": def.get("faction", "neutral"),
		"pos": [position.x, position.y],
	})
	success = true
	var suffix := ""
	if trait_id != "":
		suffix = " + " + trait_id
	if flaw_id != "":
		suffix += " / " + flaw_id
	reason = "placed %s%s (cost %d)" % [unit_id, suffix, cost]
	return true

func describe() -> String:
	return "Place %s @ (%d,%d)" % [unit_id, int(position.x), int(position.y)]
