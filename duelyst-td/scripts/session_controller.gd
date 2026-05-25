extends Node

# SessionController: owns the PlayerSlot array for the current run.
# Lives as a child of main.tscn (one per run, not an autoload).
#
# For C0 this is plumbing only:
#   - reads RunConfig.player_count + session_topology at _ready
#   - creates N PlayerSlot data objects
#   - slot 0 is the local player; slots 1..N-1 exist in memory for C1+
#
# C1 will populate slot.route_id from a CoopMapDef.
# C2 will route enemy spawning per-slot.
# C4 will gate phase transitions on all-ready.

const PLAYER_SLOT_SCRIPT := preload("res://scripts/player_slot.gd")

signal slots_changed(slots: Array)

var player_slots: Array = []
var local_slot_id: int = 0  # which slot the local player controls

# Main.gd calls configure() explicitly after RunLog.start_run so that
# record_player_slots lands in active stats. Child _ready fires before
# parent _ready in Godot, so auto-configuring here would race.

func configure(n: int, topology: String) -> void:
	var clamped: int = clamp(n, RunConfig.MIN_PLAYER_COUNT, RunConfig.MAX_PLAYER_COUNT)
	player_slots.clear()
	for i in clamped:
		var slot = PLAYER_SLOT_SCRIPT.new(i)
		player_slots.append(slot)
	print("SessionController: %d slot(s), topology=%s" % [clamped, topology])
	if RunLog.active:
		RunLog.record_player_slots(summary_for_run_log())
	slots_changed.emit(player_slots)

func slot_count() -> int:
	return player_slots.size()

func local_slot():
	if local_slot_id < player_slots.size():
		return player_slots[local_slot_id]
	return null

func summary_for_run_log() -> Array:
	var out: Array = []
	for s in player_slots:
		out.append(s.to_dict())
	return out
