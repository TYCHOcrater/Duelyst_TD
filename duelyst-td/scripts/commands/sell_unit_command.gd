class_name SellUnitCommand
extends Command

func execute(main: Node) -> bool:
	var placement = main.placement
	if placement == null:
		reason = "placement not bound"
		return false
	if placement.placement_locked:
		reason = "selling locked during combat"
		return false
	var t = placement.picked_tower
	if t == null or not is_instance_valid(t):
		reason = "no tower picked"
		return false
	var refund: int = int(t.sell_value())
	var uid: String = t.unit_id
	GameState.add_gold(refund)
	AudioManager.play("ui_select")
	t.queue_free()
	placement._clear_picked_tower()
	RunLog.record("sell_unit", {"unit": uid, "refund": refund})
	success = true
	reason = "sold %s for %dg" % [uid, refund]
	return true

func describe() -> String:
	return "SellUnit"
