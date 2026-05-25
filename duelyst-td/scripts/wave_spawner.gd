extends Node

# Data-driven wave spawner. Reads a wave-set from EnemyFactory.

signal wave_cleared()

var path: Path2D
var grid: GridController = null
var phase_controller: Node = null
var wave_set: Dictionary = {}    # {id, name, waves: [...]}

var active_enemies: int = 0
var spawning: bool = false
var current_wave_index: int = 0
var stopped: bool = false
var _first_leak_consumed_this_wave: bool = false

func configure(_path: Path2D, _wave_set: Dictionary, _phase_ctrl: Node) -> void:
	path = _path
	wave_set = _wave_set
	phase_controller = _phase_ctrl

func get_wave_count() -> int:
	if wave_set.is_empty():
		return 0
	return (wave_set.get("waves", []) as Array).size()

func get_wave_def(wave_num: int) -> Dictionary:
	var waves: Array = wave_set.get("waves", [])
	if wave_num <= 0 or wave_num > waves.size():
		return {}
	return waves[wave_num - 1]

func start_wave(wave_num: int) -> void:
	current_wave_index = wave_num
	stopped = false
	_first_leak_consumed_this_wave = false
	var def := get_wave_def(wave_num)
	if def.is_empty():
		push_warning("Wave %d out of range" % wave_num)
		return
	AudioManager.play("wave_start")
	RunLog.record("wave_start", {
		"wave": wave_num,
		"name": def.get("name", ""),
		"tags": def.get("tags", []),
	})
	WaveEffects.start_wave(def.get("wave_modifier", {}))
	spawning = true
	_run_wave_async(def)

func stop() -> void:
	stopped = true

func _run_wave_async(def: Dictionary) -> void:
	# Flatten all spawn_groups into a (time, enemy_id) schedule so groups
	# spawn concurrently with their own delays/intervals.
	var groups: Array = def.get("spawn_groups", [])
	var schedule: Array = []
	for g in groups:
		var delay: float = float(g.get("delay", 0.0))
		var eid: String = g.get("enemy_id", "")
		var count: int = int(g.get("count", 1))
		var interval: float = float(g.get("interval", 0.7))
		for i in count:
			schedule.append([delay + i * interval, eid])
	schedule.sort_custom(func(a, b): return a[0] < b[0])
	var elapsed: float = 0.0
	for entry in schedule:
		if stopped or not is_inside_tree():
			spawning = false
			return
		var t: float = entry[0]
		var wait: float = t - elapsed
		if wait > 0.0:
			var tree := get_tree()
			if tree == null:
				spawning = false
				return
			await tree.create_timer(wait).timeout
		elapsed = t
		if stopped or not is_inside_tree():
			spawning = false
			return
		_spawn_one(entry[1])
	spawning = false
	if active_enemies == 0 and not stopped and is_inside_tree():
		_emit_clear()

func _spawn_one(enemy_id: String) -> void:
	_spawn_at_progress(enemy_id, 0.0)

# Debug-only: spawn an enemy directly from a generated shell dict at the
# path start. Used by the D8 debug F4 keybind. Counts toward active_enemies
# so wave_cleared still fires correctly if the user spawns during combat.
func debug_spawn_shell(shell: Dictionary) -> bool:
	if not is_inside_tree() or path == null or shell.is_empty():
		return false
	var enemy = EnemyFactory.make_enemy_from_shell(shell)
	if enemy == null:
		return false
	path.add_child(enemy)
	enemy.progress = 0.0
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.tree_exited.connect(_on_enemy_removed)
	enemy.wants_to_spawn.connect(_on_enemy_wants_to_spawn)
	active_enemies += 1
	return true

func _spawn_at_progress(enemy_id: String, at_progress: float) -> void:
	var enemy = EnemyFactory.make_enemy(enemy_id)
	if enemy == null:
		push_warning("Spawner: could not create enemy %s" % enemy_id)
		return
	path.add_child(enemy)
	enemy.progress = at_progress
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.tree_exited.connect(_on_enemy_removed)
	enemy.wants_to_spawn.connect(_on_enemy_wants_to_spawn)
	active_enemies += 1

func _on_enemy_wants_to_spawn(child_id: String, at_progress: float) -> void:
	# Called by splitter enemies on death. Spawn child at the requested progress.
	if not is_inside_tree() or stopped:
		return
	_spawn_at_progress(child_id, at_progress)

func _on_enemy_died(reward: int, enemy_id: String) -> void:
	var bonus: int = ModifierTotals.sum_int("kill_gold_bonus")
	var total: int = reward + bonus
	GameState.add_gold(total)
	RunLog.record("enemy_killed", {
		"enemy_id": enemy_id,
		"reward": reward,
		"pact_bonus": bonus,
		"wave": current_wave_index,
	})

func _on_enemy_reached_end(damage: int, enemy_id: String) -> void:
	# Pact: first leak per wave can be ignored entirely.
	var effective_damage: int = damage
	if ModifierTotals.has_flag("ignore_first_leak") and not _first_leak_consumed_this_wave:
		_first_leak_consumed_this_wave = true
		effective_damage = 0
		RunLog.record("leak_ignored", {"enemy_id": enemy_id, "wave": current_wave_index})
	else:
		_first_leak_consumed_this_wave = true
		effective_damage += ModifierTotals.sum_int("leak_damage_delta")
	if effective_damage > 0:
		GameState.take_damage(effective_damage)
		AudioManager.play("base_hit", 0.1)
		RunLog.record("leak", {
			"enemy_id": enemy_id,
			"damage": effective_damage,
			"wave": current_wave_index,
		})
	# Corruption modifier: leak corrupts the nearest buildable tile (capped at 6).
	# Uses the core's world position as the seed since the leak hits the core.
	if WaveEffects.corrupt_on_leak and grid != null:
		var seed_pos: Vector2 = grid.grid_to_world(grid.core.x, grid.core.y)
		grid.corrupt_nearest_buildable(seed_pos)
	if phase_controller:
		phase_controller.notify_leak()

func _on_enemy_removed() -> void:
	active_enemies -= 1
	if active_enemies <= 0 and not spawning and not stopped and is_inside_tree():
		_emit_clear()

func _emit_clear() -> void:
	wave_cleared.emit()
