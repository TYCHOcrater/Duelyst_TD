class_name RerollShopCommand
extends Command

func execute(main: Node) -> bool:
	var draft = main.draft_director
	var phase = main.phase_controller
	if draft == null or phase == null:
		reason = "scene not bound"
		return false
	if phase.phase != phase.Phase.PLANNING:
		reason = "rerolls only during planning"
		return false
	var cost: int = draft.reroll_cost()
	if GameState.gold < cost:
		reason = "insufficient gold (have %d, need %d)" % [GameState.gold, cost]
		return false
	# DraftDirector.try_reroll handles spend; check first so we set our reason.
	var ok: bool = draft.try_reroll(phase.current_wave + 1)
	if not ok:
		reason = "draft rejected reroll"
		return false
	AudioManager.play("ui_select")
	RunLog.record("reroll", {"cost": cost})
	success = true
	reason = "rerolled (cost %d)" % cost
	return true

func describe() -> String:
	return "RerollShop"
