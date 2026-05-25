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
	# Phase controller emits combat_started which records the wave_start event.
	phase.confirm_start_wave()
	success = true
	reason = "wave %d started" % phase.current_wave
	return true

func describe() -> String:
	return "StartWave"
