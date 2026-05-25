class_name UpgradeUnitCommand
extends Command

func execute(main: Node) -> bool:
	var placement = main.placement
	if placement == null:
		reason = "placement not bound"
		return false
	if placement.placement_locked:
		reason = "upgrading locked during combat"
		return false
	var t = placement.picked_tower
	if t == null or not is_instance_valid(t):
		reason = "no tower picked"
		return false
	if t.level >= 4:
		reason = "tower at max level"
		return false
	# A3: gate classic upgrades by growth_mode. merge_stars mode promotes
	# via shards instead; merge_evolution_hybrid still allows classic.
	if not (RunConfig.growth_mode in ["classic_upgrade", "merge_evolution_hybrid"]):
		reason = "classic upgrades disabled in growth_mode '%s'" % RunConfig.growth_mode
		return false
	var cost: int = int(t.upgrade_cost())
	if GameState.gold < cost:
		reason = "insufficient gold (have %d, need %d)" % [GameState.gold, cost]
		return false
	GameState.spend_gold(cost)
	t.upgrade()
	AudioManager.play("place_tower")
	RunLog.record("upgrade_unit", {"unit": t.unit_id, "cost": cost, "level": t.level})
	# Re-emit selected so HUD refreshes the panel.
	placement.tower_selected.emit(t)
	success = true
	reason = "upgraded %s to lvl %d (cost %d)" % [t.unit_id, t.level + 1, cost]
	return true

func describe() -> String:
	return "UpgradeUnit"
