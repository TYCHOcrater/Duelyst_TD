class_name PromoteUnitCommand
extends Command

# A5: spend shards to promote the picked tower's star_level.

func execute(main: Node) -> bool:
	var placement = main.placement
	if placement == null:
		reason = "placement not bound"
		return false
	if placement.placement_locked:
		reason = "promotion locked during combat"
		return false
	var t = placement.picked_tower
	if t == null or not is_instance_valid(t):
		reason = "no tower picked"
		return false
	if not (RunConfig.growth_mode in ["merge_stars", "merge_evolution_hybrid"]):
		reason = "star promotion disabled in growth_mode '%s'" % RunConfig.growth_mode
		return false
	if t.star_level >= 3:
		reason = "%s is already 3-star (max)" % t.unit_id
		return false
	var cost: int = t.star_promotion_cost()
	var have: int = RunLog.shard_count(t.unit_id)
	if have < cost:
		reason = "need %d shards, have %d" % [cost, have]
		return false
	if not t.promote_star():
		reason = "promote_star failed"
		return false
	AudioManager.play("place_tower", 0.12)
	# Re-emit selected so HUD refreshes the panel.
	placement.tower_selected.emit(t)
	success = true
	reason = "promoted %s to %d★ (cost %d shards)" % [t.unit_id, t.star_level, cost]
	return true

func describe() -> String:
	return "PromoteUnit"
