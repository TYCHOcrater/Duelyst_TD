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
	RunLog.record("relic_chosen", {"relic_id": relic_id, "after_wave": phase.current_wave})
	phase.confirm_relic_chosen(relic_id)
	success = true
	reason = "took relic %s" % relic_id
	return true

func describe() -> String:
	return "ChooseRelic %s" % relic_id
