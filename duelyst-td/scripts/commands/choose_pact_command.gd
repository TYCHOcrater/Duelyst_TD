class_name ChoosePactCommand
extends Command

var pact_id: String

func _init(pid: String) -> void:
	pact_id = pid

func execute(main: Node) -> bool:
	var phase = main.phase_controller
	if phase == null:
		reason = "phase controller not bound"
		return false
	if phase.phase != phase.Phase.PACT_CHOICE:
		reason = "not in pact choice phase"
		return false
	if not PactManager.is_offered(pact_id):
		reason = "pact %s not in current offers" % pact_id
		return false
	# C9: attribute the pact pick to the local slot so multi-player runs
	# can show "P2 chose Tempo" in the summary. Solo runs always log slot 0.
	var session = main.session if "session" in main else null
	var chooser_slot: int = session.local_slot_id if session != null else -1
	if not PactManager.activate(pact_id, chooser_slot):
		reason = "pact %s could not be activated" % pact_id
		return false
	AudioManager.play("wave_start")
	RunLog.record("pact_chosen", {
		"pact_id": pact_id,
		"after_wave": phase.current_wave,
		"chosen_by_slot": chooser_slot,
	})
	phase.confirm_pact_chosen(pact_id)
	success = true
	reason = "took pact %s" % pact_id
	return true

func describe() -> String:
	return "ChoosePact %s" % pact_id
