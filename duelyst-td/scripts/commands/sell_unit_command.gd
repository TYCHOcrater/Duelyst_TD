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
	var sell_pos: Vector2 = t.global_position
	GameState.add_gold(refund)
	AudioManager.play("ui_select")
	# Sell FX: small dust + gold-coin popup at the tower's tile so it's
	# clear what got refunded and from where.
	var host: Node = main.get_tree().current_scene
	if host:
		CombatFX.burst(host, sell_pos, Color(0.85, 0.85, 0.9), 10, 0.55)
		if refund > 0:
			var popup := Node2D.new()
			popup.set_script(preload("res://scripts/damage_popup.gd"))
			host.add_child(popup)
			popup.global_position = sell_pos + Vector2(0, -36)
			popup.setup(refund, Color(1.0, 0.85, 0.35), "+")
	t.queue_free()
	placement._clear_picked_tower()
	RunLog.record("sell_unit", {"unit": uid, "refund": refund})
	success = true
	reason = "sold %s for %dg" % [uid, refund]
	return true

func describe() -> String:
	return "SellUnit"
