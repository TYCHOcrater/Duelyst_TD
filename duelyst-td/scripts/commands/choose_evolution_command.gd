extends Command

# A6: applies an EvolutionDef to the currently-pending tower.

var evolution_id: String

func _init(evo_id: String) -> void:
	evolution_id = evo_id

func execute(main: Node) -> bool:
	var placement = main.placement
	if placement == null:
		reason = "placement not bound"
		return false
	var t = placement.picked_tower
	if t == null or not is_instance_valid(t):
		reason = "no tower picked"
		return false
	if int(t.pending_evolution_star) <= 0:
		reason = "no pending evolution for this tower"
		return false
	var evo_def: Dictionary = EvolutionManager.get_def(t.unit_id, evolution_id)
	if evo_def.is_empty():
		reason = "unknown evolution '%s' for unit '%s'" % [evolution_id, t.unit_id]
		return false
	t.apply_evolution(evo_def)
	# Re-emit selected so HUD refreshes the panel + hides the choice modal.
	placement.tower_selected.emit(t)
	success = true
	reason = "applied %s to %s" % [evolution_id, t.unit_id]
	return true

func describe() -> String:
	return "ChooseEvolution %s" % evolution_id
