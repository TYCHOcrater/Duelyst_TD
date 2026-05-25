extends Node

# Drives the planning -> combat -> [pact choice] -> planning loop.

signal phase_changed(phase: String)            # "planning" | "combat" | "pact_choice" | "ended"
signal planning_started(wave: int)
signal combat_started(wave: int)
signal wave_resolved(wave: int, leaks: int)
signal pact_choice_started(options: Array)     # Array[String] of pact ids
signal relic_choice_started(options: Array)    # Array[String] of relic ids
signal run_ended(victory: bool)
# Emitted at planning start with a breakdown {base, interest, pact, total}.
signal income_granted(breakdown: Dictionary)

enum Phase { PLANNING, COMBAT, PACT_CHOICE, RELIC_CHOICE, ENDED }

const POST_WAVE_DELAY := 1.0
const PACT_INTERVAL := 3                       # offer pact every N waves
const RELIC_WAVES := [5]                       # offer relic after these wave numbers
const INTEREST_PER_GOLD := 10                  # +1 interest per N gold floated
const INTEREST_MAX := 5                        # hard cap per planning phase

var phase: int = Phase.PLANNING
var current_wave: int = 0
var wave_leaks: int = 0
var spawner: Node = null
var draft: Node = null
var max_waves: int = 0
# C4: reference to SessionController so we can gate wave-start on every slot
# marking ready. Solo runs (slot_count == 1) start the wave immediately when
# the local slot readies up. Multi-player runs wait until every slot is ready.
var session: Node = null

# C4: emitted whenever a slot's ready state changes so HUDs can render a
# "waiting for P2..." style indicator.
signal slot_ready_changed(slot_id: int, ready: bool)

func configure(_spawner: Node, _draft: Node, _max_waves: int, _session: Node = null) -> void:
	spawner = _spawner
	draft = _draft
	max_waves = _max_waves
	session = _session

func start() -> void:
	current_wave = 0
	_start_planning()

func _start_planning() -> void:
	phase = Phase.PLANNING
	var next_wave := current_wave + 1
	if current_wave > 0:
		# Interest computed from gold floated INTO this planning phase (before base income).
		var floated_before: int = GameState.gold
		var interest: int = mini(INTEREST_MAX, floated_before / INTEREST_PER_GOLD)
		var pact_bonus: int = ModifierTotals.sum_int("wave_gold_bonus")
		var base: int = 5 + int(floor(current_wave / 2.0))
		var total: int = base + interest + pact_bonus
		GameState.add_gold(total)
		var breakdown := {
			"base": base,
			"interest": interest,
			"pact": pact_bonus,
			"total": total,
			"floated_before": floated_before,
			"wave": next_wave,
		}
		RunLog.record("planning_income", breakdown)
		income_granted.emit(breakdown)
	draft.generate_offers(next_wave)
	planning_started.emit(next_wave)
	phase_changed.emit("planning")

func confirm_start_wave() -> void:
	if phase != Phase.PLANNING:
		return
	current_wave += 1
	phase = Phase.COMBAT
	wave_leaks = 0
	# C4: every slot's ready flag clears when combat begins so the next
	# planning phase needs fresh confirmations.
	_clear_ready_flags()
	GameState.set_wave(current_wave)
	combat_started.emit(current_wave)
	phase_changed.emit("combat")
	spawner.start_wave(current_wave)

# C4: a single slot signals "I'm ready". Wave starts only when all slots
# in the session are ready. In solo this is the legacy 1-press path.
func set_slot_ready(slot_id: int, ready: bool) -> void:
	if phase != Phase.PLANNING:
		return
	if session == null:
		# Backward compat: no session bound, treat as legacy single-press.
		confirm_start_wave()
		return
	var slots: Array = session.player_slots
	if slot_id < 0 or slot_id >= slots.size():
		return
	slots[slot_id].ready_for_wave = ready
	slot_ready_changed.emit(slot_id, ready)
	if ready and _all_slots_ready():
		confirm_start_wave()

# C4 debug: skip the all-ready gate and start the wave immediately.
# Useful for solo testing of co-op-only flows.
func debug_force_start_wave() -> void:
	if phase != Phase.PLANNING:
		return
	confirm_start_wave()

func _all_slots_ready() -> bool:
	if session == null:
		return true
	for s in session.player_slots:
		if not s.ready_for_wave:
			return false
	return true

func _clear_ready_flags() -> void:
	if session == null:
		return
	for s in session.player_slots:
		if s.ready_for_wave:
			s.ready_for_wave = false
			slot_ready_changed.emit(s.slot_id, false)

func notify_leak() -> void:
	wave_leaks += 1

func notify_wave_cleared() -> void:
	if phase != Phase.COMBAT:
		return
	wave_resolved.emit(current_wave, wave_leaks)
	GameState.add_gold(3 + current_wave * 2)
	if current_wave >= max_waves:
		phase = Phase.ENDED
		phase_changed.emit("ended")
		run_ended.emit(GameState.lives > 0)
		return
	# Relic choice takes priority over pact choice if both happen to land
	# on the same wave (none currently overlap, but be defensive).
	if _should_offer_relic():
		_begin_relic_choice()
		return
	if _should_offer_pact():
		_begin_pact_choice()
		return
	_post_wave_planning()

func _should_offer_pact() -> bool:
	if current_wave <= 0 or current_wave >= max_waves:
		return false
	if current_wave % PACT_INTERVAL != 0:
		return false
	var pool := PactManager.pact_ids.size() - PactManager.active_ids.size()
	return pool > 0

func _should_offer_relic() -> bool:
	if current_wave <= 0 or current_wave >= max_waves:
		return false
	if not (current_wave in RELIC_WAVES):
		return false
	var pool := RelicManager.relic_ids.size() - RelicManager.active_ids.size()
	return pool > 0

func _begin_pact_choice() -> void:
	phase = Phase.PACT_CHOICE
	var options: Array = PactManager.roll_offers(3)
	pact_choice_started.emit(options)
	phase_changed.emit("pact_choice")

func _begin_relic_choice() -> void:
	phase = Phase.RELIC_CHOICE
	var options: Array = RelicManager.roll_offers(3)
	relic_choice_started.emit(options)
	phase_changed.emit("relic_choice")

func confirm_pact_chosen(pact_id: String) -> void:
	if phase != Phase.PACT_CHOICE:
		return
	_post_wave_planning()

func confirm_relic_chosen(relic_id: String) -> void:
	if phase != Phase.RELIC_CHOICE:
		return
	_post_wave_planning()

func _post_wave_planning() -> void:
	var tree := get_tree()
	if tree == null or not is_inside_tree():
		return
	await tree.create_timer(POST_WAVE_DELAY).timeout
	if phase == Phase.ENDED or not is_inside_tree():
		return
	_start_planning()
