class_name StartWaveCommand
extends Command

func execute(main: Node) -> bool:
	var phase = main.phase_controller
	if phase == null:
		reason = "phase controller not bound"
		return false
	if phase.phase != phase.Phase.PLANNING:
		reason = "wave already in progress"
		return false
	AudioManager.play("wave_start")
	# C4: marks the local slot ready. PhaseController starts the wave only
	# when every slot is ready. In solo this remains a single-press flow.
	var session = main.session if "session" in main else null
	if session != null and phase.has_method("set_slot_ready"):
		var slot_id: int = session.local_slot_id
		phase.set_slot_ready(slot_id, true)
		success = true
		if phase.phase == phase.Phase.COMBAT:
			reason = "wave %d started" % phase.current_wave
		else:
			reason = "slot %d ready — waiting for others" % slot_id
		return true
	# Legacy fallback if session isn't wired yet.
	phase.confirm_start_wave()
	success = true
	reason = "wave %d started" % phase.current_wave
	return true

func describe() -> String:
	return "StartWave"
