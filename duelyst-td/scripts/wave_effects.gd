extends Node

# Manages active wave-modifier effects (silence, future: fog, corruption, etc.)
# scheduled via create_timer with stale-callback guards.

signal effect_started(effect_id: String)
signal effect_ended(effect_id: String)

# Active effects: effect_id -> end_time (seconds since boot)
var active: Dictionary = {}

# Stale-timer guard: every wave start increments this; timers compare against
# the captured wave_id at schedule time, no-op when they don't match.
var current_wave_id: int = 0

# Per-wave flag set from wave_modifier. wave_spawner reads on each leak.
var corrupt_on_leak: bool = false

# Weak ref to the active grid so towers can query corruption by world pos
# without coupling to the board scene tree.
var _grid_ref: WeakRef = null

func set_grid(g: GridController) -> void:
	_grid_ref = weakref(g)

func is_position_corrupted(world_pos: Vector2) -> bool:
	var g = _grid_ref.get_ref() if _grid_ref else null
	if g == null:
		return false
	return g.is_corrupted_at_world(world_pos)

# --- Wave lifecycle ---

func start_wave(modifier: Dictionary) -> void:
	current_wave_id += 1
	active.clear()
	corrupt_on_leak = false
	# Clear any leftover corruption from previous wave.
	var g = _grid_ref.get_ref() if _grid_ref else null
	if g != null:
		g.clear_corruption()
	if modifier.is_empty():
		return
	var kind: String = modifier.get("type", "")
	match kind:
		"silence":
			_schedule_silence(
				current_wave_id,
				float(modifier.get("first_at", 5.0)),
				float(modifier.get("interval", 8.0)),
				float(modifier.get("duration", 1.5)),
			)
		"corruption":
			corrupt_on_leak = bool(modifier.get("on_leak", true))
		_:
			push_warning("WaveEffects: unknown modifier type '%s'" % kind)

func clear_all() -> void:
	current_wave_id += 1
	corrupt_on_leak = false
	for eid in active.keys():
		effect_ended.emit(eid)
	active.clear()
	var g = _grid_ref.get_ref() if _grid_ref else null
	if g != null:
		g.clear_corruption()

# --- Queries ---

func is_silenced() -> bool:
	return active.has("silence")

func remaining(effect_id: String) -> float:
	if not active.has(effect_id):
		return 0.0
	var now: float = Time.get_ticks_msec() / 1000.0
	return max(0.0, float(active[effect_id]) - now)

# --- Silence scheduling ---

func _schedule_silence(wave_id: int, first_at: float, interval: float, duration: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(first_at).timeout.connect(
		_trigger_silence.bind(wave_id, duration, interval),
		CONNECT_ONE_SHOT,
	)

func _trigger_silence(wave_id: int, duration: float, repeat_interval: float) -> void:
	if wave_id != current_wave_id or not is_inside_tree():
		return
	active["silence"] = Time.get_ticks_msec() / 1000.0 + duration
	effect_started.emit("silence")
	var tree := get_tree()
	tree.create_timer(duration).timeout.connect(
		_end_silence.bind(wave_id),
		CONNECT_ONE_SHOT,
	)
	if repeat_interval > 0.0:
		tree.create_timer(repeat_interval).timeout.connect(
			_trigger_silence.bind(wave_id, duration, repeat_interval),
			CONNECT_ONE_SHOT,
		)

func _end_silence(wave_id: int) -> void:
	if wave_id != current_wave_id:
		return
	if active.has("silence"):
		active.erase("silence")
		effect_ended.emit("silence")
