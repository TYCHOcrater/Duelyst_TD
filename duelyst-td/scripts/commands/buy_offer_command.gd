class_name BuyOfferCommand
extends Command

# In the current 2-step UX, "buying" an offer just selects it for placement
# preview; gold is spent on PlaceUnitCommand. This makes the action explicit
# and revertable (cancel/right-click).

var offer_index: int

func _init(idx: int) -> void:
	offer_index = idx

func execute(main: Node) -> bool:
	var draft = main.draft_director
	var placement = main.placement
	if draft == null or placement == null:
		reason = "scene not bound"
		return false
	if main.phase_controller.phase != main.phase_controller.Phase.PLANNING:
		reason = "not in planning phase"
		return false
	if offer_index < 0 or offer_index >= draft.current_offers.size():
		reason = "offer index out of range"
		return false
	var unit_id: String = draft.current_offers[offer_index]
	var trait_id: String = draft.get_trait_for(offer_index)
	var flaw_id: String = draft.get_flaw_for(offer_index)
	# A7: any time the player buys an offer of a base they already own,
	# bump the "duplicate offers bought" counter. Captured here (not in the
	# shard path alone) so classic-mode duplicate placements also count.
	if _already_owns_base(unit_id) and RunLog.active:
		RunLog.stats["duplicate_offers_bought"] = int(RunLog.stats.get("duplicate_offers_bought", 0)) + 1
	# A4: in merge_stars / merge_evolution_hybrid, buying a unit you already
	# have placed converts the offer into a shard immediately (no placement
	# preview). Gold spent, shard recorded, offer consumed — committed action.
	if _is_merge_mode() and _already_owns_base(unit_id):
		return _execute_shard_buy(main, unit_id, trait_id, flaw_id, draft)
	# Toggle: clicking the same offer cancels.
	if placement.current_unit_id == unit_id and placement.current_trait_id == trait_id and placement.current_flaw_id == flaw_id:
		placement.cancel_selection()
	else:
		placement.select_unit_for_placement(unit_id, trait_id, flaw_id)
	success = true
	var suffix := ""
	if trait_id != "":
		suffix = " + " + trait_id
	if flaw_id != "":
		suffix += " / " + flaw_id
	reason = "selected offer #%d (%s%s)" % [offer_index, unit_id, suffix]
	return true

func _is_merge_mode() -> bool:
	return RunConfig.growth_mode in ["merge_stars", "merge_evolution_hybrid"]

func _already_owns_base(base_unit_id: String) -> bool:
	for t in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("towers"):
		if is_instance_valid(t) and "unit_id" in t and t.unit_id == base_unit_id:
			return true
	return false

func _execute_shard_buy(main: Node, unit_id: String, trait_id: String, flaw_id: String, draft) -> bool:
	# Charge cost (same as placing — trait/flaw modifiers respected).
	var cost: int = UnitFactory.effective_cost(unit_id, trait_id, flaw_id)
	if GameState.gold < cost:
		reason = "insufficient gold for shard (have %d, need %d)" % [GameState.gold, cost]
		return false
	GameState.spend_gold(cost)
	var new_count: int = RunLog.add_shard(unit_id, 1)
	draft.consume_offer(unit_id)
	AudioManager.play("place_tower", 0.10)
	RunLog.record("shard_purchased", {
		"unit": unit_id,
		"cost": cost,
		"new_shard_count": new_count,
	})
	success = true
	reason = "+1 shard for %s (now %d, cost %d)" % [unit_id, new_count, cost]
	return true

func describe() -> String:
	return "BuyOffer #%d" % offer_index
