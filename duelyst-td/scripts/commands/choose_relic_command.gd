class_name ChooseRelicCommand
extends Command

var relic_id: String

func _init(rid: String) -> void:
	relic_id = rid

func execute(main: Node) -> bool:
	var phase = main.phase_controller
	if phase == null:
		reason = "phase controller not bound"
		return false
	if phase.phase != phase.Phase.RELIC_CHOICE:
		reason = "not in relic choice phase"
		return false
	if not RelicManager.is_offered(relic_id):
		reason = "relic %s not in current offers" % relic_id
		return false
	if not RelicManager.activate(relic_id):
		reason = "relic %s could not be activated" % relic_id
		return false
	AudioManager.play("wave_start")
	# C9: attribute the relic pick to the local slot for the run summary.
	var session = main.session if "session" in main else null
	var chooser_slot: int = session.local_slot_id if session != null else -1
	RunLog.record("relic_chosen", {
		"relic_id": relic_id,
		"after_wave": phase.current_wave,
		"chosen_by_slot": chooser_slot,
	})
	phase.confirm_relic_chosen(relic_id)
	success = true
	reason = "took relic %s" % relic_id
	return true

func describe() -> String:
	return "ChooseRelic %s" % relic_id
