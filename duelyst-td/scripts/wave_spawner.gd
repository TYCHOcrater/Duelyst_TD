extends Node

# Data-driven wave spawner. Reads a wave-set from EnemyFactory.

signal wave_cleared()

var path: Path2D
# C2: when the active map has multiple routes, paths holds one Path2D per
# route. `path` always equals paths[0] for backward compat. For single-route
# topology paths is just [path].
var paths: Array = []
# C6: parallel to `paths` — the route_id of each Path2D so leaks can be
# routed to the correct Gate Shield. Empty string at index 0 for legacy
# single-topology maps (no routes array on the MapDef).
var route_ids: Array = []
var _path_by_route: Dictionary = {}
var grid: GridController = null
var phase_controller: Node = null
var wave_set: Dictionary = {}    # {id, name, waves: [...]}

var active_enemies: int = 0
var spawning: bool = false
var current_wave_index: int = 0
var stopped: bool = false
var _first_leak_consumed_this_wave: bool = false
# C8: per-route leak counter for this wave, and a flag so a breach packet
# only spawns once per route per wave (no infinite chain).
const BREACH_TRIGGER_LEAKS := 3
var _leaks_this_wave_by_route: Dictionary = {}
var _breach_fired_this_wave_by_route: Dictionary = {}
# Set when a breach packet is spawned so _on_enemy_died can credit the
# correct route once that packet is killed. Single-shot since breaches
# don't fire concurrently per route.
var _last_breach_route: String = ""

func configure(_path: Path2D, _wave_set: Dictionary, _phase_ctrl: Node) -> void:
	path = _path
	paths = [_path] if _path != null else []
	route_ids = [""] if _path != null else []
	_rebuild_path_by_route()
	wave_set = _wave_set
	phase_controller = _phase_ctrl

# C2/C6: set the full route_paths array (board.route_paths) and the parallel
# route_ids list so leaks can be routed to the matching Gate Shield. Wave-set
# is reused; each scheduled spawn is fanned out onto every path so all routes
# see the same enemy progression simultaneously.
func configure_paths(_paths: Array, _route_ids: Array = []) -> void:
	paths = _paths
	if _route_ids.size() == paths.size():
		route_ids = _route_ids
	else:
		route_ids = []
		for _i in paths.size():
			route_ids.append("")
	_rebuild_path_by_route()
	if not paths.is_empty():
		path = paths[0]

func _rebuild_path_by_route() -> void:
	_path_by_route.clear()
	for i in paths.size():
		var rid: String = route_ids[i] if i < route_ids.size() else ""
		_path_by_route[rid] = paths[i]

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
	_leaks_this_wave_by_route.clear()
	_breach_fired_this_wave_by_route.clear()
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
	# C2: fan one logical spawn out onto every active route.
	if paths.is_empty():
		_spawn_at_progress_on(enemy_id, 0.0, path, "")
		return
	for i in paths.size():
		var p: Path2D = paths[i]
		if p == null:
			continue
		var rid: String = route_ids[i] if i < route_ids.size() else ""
		_spawn_at_progress_on(enemy_id, 0.0, p, rid)

# Debug-only: spawn an enemy directly from a generated shell dict at the
# path start. Used by the D8 debug F4 keybind. Counts toward active_enemies
# so wave_cleared still fires correctly if the user spawns during combat.
# Debug spawn always targets the primary path (slot 0's route).
func debug_spawn_shell(shell: Dictionary) -> bool:
	if not is_inside_tree() or path == null or shell.is_empty():
		return false
	var enemy = EnemyFactory.make_enemy_from_shell(shell)
	if enemy == null:
		return false
	path.add_child(enemy)
	enemy.progress = 0.0
	var primary_rid: String = route_ids[0] if not route_ids.is_empty() else ""
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end.bind(primary_rid))
	enemy.tree_exited.connect(_on_enemy_removed)
	enemy.wants_to_spawn.connect(_on_enemy_wants_to_spawn.bind(primary_rid))
	active_enemies += 1
	return true

func _spawn_at_progress_on(enemy_id: String, at_progress: float, on_path: Path2D, route_id: String) -> void:
	if on_path == null:
		return
	var enemy = EnemyFactory.make_enemy(enemy_id)
	if enemy == null:
		push_warning("Spawner: could not create enemy %s" % enemy_id)
		return
	on_path.add_child(enemy)
	enemy.progress = at_progress
	enemy.died.connect(_on_enemy_died)
	# C6: bind the route_id at connect time so the leak handler can route the
	# damage to the correct Gate Shield. Splitter children inherit the parent's
	# route via the `parent_route_id` payload on wants_to_spawn.
	enemy.reached_end.connect(_on_enemy_reached_end.bind(route_id))
	enemy.tree_exited.connect(_on_enemy_removed)
	enemy.wants_to_spawn.connect(_on_enemy_wants_to_spawn.bind(route_id))
	active_enemies += 1

func _on_enemy_wants_to_spawn(child_id: String, at_progress: float, parent_route_id: String) -> void:
	# Called by splitter enemies on death. Spawn child at the requested progress
	# on the same route the parent was on.
	if not is_inside_tree() or stopped:
		return
	var on_path: Path2D = _path_by_route.get(parent_route_id, path)
	_spawn_at_progress_on(child_id, at_progress, on_path, parent_route_id)

func _on_enemy_died(reward: int, enemy_id: String) -> void:
	var bonus: int = ModifierTotals.sum_int("kill_gold_bonus")
	var total: int = reward + bonus
	GameState.add_gold(total)
	# C8: killing a breach packet banks leak-saves on its route. We don't
	# know the route from `died` alone; the per-enemy bind in _spawn_at_progress_on
	# stores it on the enemy as the connection's bound arg for reached_end,
	# but for died() we walk the towers' last-kill credit via groups instead.
	# Simpler: track by scanning live enemies of family=elite at death time.
	# (Practically, breach packets carry enemy_id == "breach_packet".)
	if enemy_id == "breach_packet":
		var rid: String = String(_last_breach_route)
		if rid != "":
			GameState.grant_breach_saves(rid)
			RunLog.record("breach_killed", {"route_id": rid, "saves_granted": GameState.BREACH_SAVES_PER_KILL, "wave": current_wave_index})
			_last_breach_route = ""
	RunLog.record("enemy_killed", {
		"enemy_id": enemy_id,
		"reward": reward,
		"pact_bonus": bonus,
		"wave": current_wave_index,
	})

func _on_enemy_reached_end(damage: int, enemy_id: String, route_id: String) -> void:
	# Pact: first leak per wave can be ignored entirely.
	var effective_damage: int = damage
	if ModifierTotals.has_flag("ignore_first_leak") and not _first_leak_consumed_this_wave:
		_first_leak_consumed_this_wave = true
		effective_damage = 0
		RunLog.record("leak_ignored", {"enemy_id": enemy_id, "wave": current_wave_index, "route_id": route_id})
	else:
		_first_leak_consumed_this_wave = true
		effective_damage += ModifierTotals.sum_int("leak_damage_delta")
	if effective_damage > 0:
		# C6: route the damage through Gate Shield first; overflow hits Core.
		var breakdown: Dictionary = GameState.take_leak_damage(route_id, effective_damage)
		AudioManager.play("base_hit", 0.1)
		# Burst at the gate tile so the leak reads on the map too. Color +
		# size shift on whether the shield absorbed it or the Core took it.
		_spawn_leak_fx(route_id, int(breakdown.get("shield_hits", 0)), int(breakdown.get("core_hits", 0)))
		RunLog.record("leak", {
			"enemy_id": enemy_id,
			"damage": effective_damage,
			"wave": current_wave_index,
			"route_id": route_id,
			"shield_hits": breakdown.get("shield_hits", 0),
			"core_hits": breakdown.get("core_hits", 0),
			"saved": breakdown.get("saved", false),
		})
		# C8: track per-route leak count. When the threshold is crossed (and
		# we haven't already spawned a breach this wave on this route), drop
		# a breach packet at the start of that route.
		_leaks_this_wave_by_route[route_id] = int(_leaks_this_wave_by_route.get(route_id, 0)) + 1
		if int(_leaks_this_wave_by_route[route_id]) >= BREACH_TRIGGER_LEAKS \
				and not bool(_breach_fired_this_wave_by_route.get(route_id, false)):
			_breach_fired_this_wave_by_route[route_id] = true
			_spawn_breach_packet(route_id)

func _spawn_breach_packet(route_id: String) -> void:
	var spawn_path: Path2D = _path_by_route.get(route_id, path)
	if spawn_path == null:
		return
	_last_breach_route = route_id
	_spawn_at_progress_on("breach_packet", 0.0, spawn_path, route_id)
	# Wave banner-style attention cue — heavy red vignette at the gate.
	var host: Node = get_tree().current_scene
	if host and spawn_path.curve and spawn_path.curve.point_count > 0:
		var spawn_pos: Vector2 = spawn_path.to_global(spawn_path.curve.get_point_position(0))
		CombatFX.burst(host, spawn_pos, Color(1.0, 0.3, 0.3), 24, 1.2)
	AudioManager.play_event("boss_warning")
	RunLog.record("breach_spawned", {"route_id": route_id, "wave": current_wave_index, "trigger_leaks": BREACH_TRIGGER_LEAKS})

func _spawn_leak_fx(route_id: String, shield_hits: int, core_hits: int) -> void:
	var gate_path: Path2D = _path_by_route.get(route_id, path)
	if gate_path == null or gate_path.curve == null:
		return
	var n: int = gate_path.curve.point_count
	if n == 0:
		return
	var local_pos: Vector2 = gate_path.curve.get_point_position(n - 1)
	var gate_pos: Vector2 = gate_path.to_global(local_pos)
	var host: Node = get_tree().current_scene
	if host == null:
		return
	if core_hits > 0:
		# Core hit — heavy red burst, larger if multiple HP came off.
		var scale_mult: float = clamp(0.8 + 0.25 * core_hits, 0.8, 2.0)
		CombatFX.burst(host, gate_pos, Color(1.0, 0.35, 0.3), 18, scale_mult)
	elif shield_hits > 0:
		# Shield absorbed — amber spark, contained.
		CombatFX.burst(host, gate_pos, Color(1.0, 0.7, 0.3), 10, 0.7)
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
