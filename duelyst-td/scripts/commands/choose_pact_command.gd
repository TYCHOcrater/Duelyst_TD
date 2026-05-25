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
	if not PactManager.activate(pact_id):
		reason = "pact %s could not be activated" % pact_id
		return false
	AudioManager.play("wave_start")
	RunLog.record("pact_chosen", {"pact_id": pact_id, "after_wave": phase.current_wave})
	phase.confirm_pact_chosen(pact_id)
	success = true
	reason = "took pact %s" % pact_id
	return true

func describe() -> String:
	return "ChoosePact %s" % pact_id
