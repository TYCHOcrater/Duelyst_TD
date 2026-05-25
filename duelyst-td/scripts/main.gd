extends Node2D

const BASE_SCENE := preload("res://scenes/base.tscn")
const PHASE_SCRIPT := preload("res://scripts/phase_controller.gd")
const DRAFT_SCRIPT := preload("res://scripts/draft_director.gd")
const DEBUG_OVERLAY_SCENE := preload("res://scenes/debug_overlay.tscn")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")
const AMBIENT_FX_SCRIPT := preload("res://scripts/ambient_fx.gd")
const _SEND_AID_CMD := preload("res://scripts/commands/send_aid_command.gd")

const STARTER_MAP := "res://data/maps/starter_neutral.json"
const BATTLEGROUND_MAP := "res://data/maps/battleground_test.json"
const CUSTOM_MAP_DIR := "user://maps/"
const STARTER_WAVE_SET := "act1"

var _battleground_override: bool = false

@onready var board: Node2D = $World/Board
@onready var spawner: Node = $WaveSpawner
@onready var placement: Node2D = $Placement
@onready var hud: CanvasLayer = $HUD
@onready var world: Node2D = $World
@onready var session: Node = $SessionController
@onready var net: Node = $NetController

var phase_controller: Node
var draft_director: Node
var base: Node = null

func _ready() -> void:
	# --use-generated forces procgen for headless smoke tests.
	if "--use-generated" in OS.get_cmdline_args():
		RunConfig.map_source = "generated"
	# --use-battleground loads the new 4-core outburst map for visual review.
	if "--use-battleground" in OS.get_cmdline_args():
		RunConfig.map_source = "fixed"
		_battleground_override = true
	# C11 smoke test: generate 5 outburst-2p maps from sequential seeds and
	# print pass/fail. Exits before bringing up the rest of the scene.
	if "--test-outburst-gen-5" in OS.get_cmdline_args():
		_run_outburst_gen_smoke_test()
		get_tree().quit(0)
		return
	# C12 smoke test: exercise the NetController loopback path post-init.
	# Defers the trigger so all autoloads/scene nodes are ready first.
	var _do_net_loopback: bool = "--test-net-loopback" in OS.get_cmdline_args()
	GameState.reset()
	PactManager.reset()
	RelicManager.reset()
	if RunConfig.seed == 0:
		RunConfig.randomize_seed()
	SessionRng.set_seed(RunConfig.seed)
	RunLog.start_run(RunConfig.seed)
	session.configure(RunConfig.player_count, RunConfig.session_topology)
	CommandBus.bind_main(self)
	var dbg := DEBUG_OVERLAY_SCENE.instantiate()
	add_child(dbg)
	if dbg.has_method("bind_spawner"):
		dbg.bind_spawner(spawner)
	if not _load_configured_map():
		# Validation error already surfaced via the board's ErrorLabel.
		# Halt the game cleanly so the user can read it.
		return
	_apply_map_background()
	_spawn_base()
	_spawn_ambient_fx()
	# C3: now that the grid + routes are loaded, seed each PlayerSlot's
	# owned-tile set so placement can gate by zone. In solo this just makes
	# every buildable tile belong to slot 0 (no visible change).
	session.assign_routes(board)
	placement.bind_grid(board.grid)
	placement.bind_session(session)
	placement.path = board.enemy_path
	# C5: camera gets a board reference so 1..4 / TAB hotkeys can focus
	# routes and overview the map.
	var cam: Node = world.get_node_or_null("Camera2D")
	if cam and cam.has_method("bind_board"):
		cam.bind_board(board)
	phase_controller = Node.new()
	phase_controller.set_script(PHASE_SCRIPT)
	phase_controller.name = "PhaseController"
	add_child(phase_controller)
	draft_director = Node.new()
	draft_director.set_script(DRAFT_SCRIPT)
	draft_director.name = "DraftDirector"
	add_child(draft_director)
	hud.bind_placement(placement)
	hud.bind_phase(phase_controller, draft_director)
	hud.bind_session(session)
	hud.set_seed_label(RunConfig.format_seed())
	hud.set_growth_mode_label(RunConfig.growth_mode_label())
	hud.set_players_label(RunConfig.player_count, RunConfig.session_topology)
	placement.tower_selected.connect(hud.show_tower_panel)
	placement.tower_deselected.connect(hud.hide_tower_panel)
	placement.preview_changed.connect(hud.on_preview_changed)
	draft_director.offers_changed.connect(hud.show_draft_offers)
	phase_controller.phase_changed.connect(hud.on_phase_changed)
	phase_controller.planning_started.connect(_on_planning_started)
	phase_controller.combat_started.connect(_on_combat_started)
	phase_controller.pact_choice_started.connect(hud.show_pact_choice)
	phase_controller.relic_choice_started.connect(hud.show_relic_choice)
	phase_controller.income_granted.connect(hud.show_income_breakdown)
	phase_controller.wave_resolved.connect(hud.on_wave_resolved)
	phase_controller.run_ended.connect(_on_run_ended)
	spawner.wave_cleared.connect(phase_controller.notify_wave_cleared)
	spawner.wave_cleared.connect(_credit_tower_wave_survival)
	# C7: clean up Aid Token temp units at wave end.
	spawner.wave_cleared.connect(_despawn_aid_units)
	GameState.game_over.connect(_on_game_over_safety)
	var wave_set: Dictionary = EnemyFactory.get_wave_set(STARTER_WAVE_SET)
	if wave_set.is_empty():
		push_error("main: wave-set '%s' not found" % STARTER_WAVE_SET)
		return
	spawner.configure(board.enemy_path, wave_set, phase_controller)
	# C2: hand the spawner the full per-route Path2D array so each scheduled
	# spawn fans out onto every route. For single-topology maps route_paths
	# is just [enemy_path] and behavior is unchanged.
	# C6: also pass parallel route_ids so leaks can route through the matching
	# Gate Shield, and initialize each route's Gate Shield HP.
	if board.route_paths.size() > 1:
		var rids: Array = []
		for r in board.routes:
			rids.append(String(r.get("id", "")))
		spawner.configure_paths(board.route_paths, rids)
		GameState.init_gate_shields(board.routes)
		print("main: multi-route spawn enabled across %d route(s) [topology=%s]" % [
			board.route_paths.size(), board.topology
		])
	spawner.grid = board.grid
	WaveEffects.set_grid(board.grid)
	# C4: phase_controller needs session so wave-start can gate on all-ready.
	phase_controller.configure(spawner, draft_director, spawner.get_wave_count(), session)
	await get_tree().create_timer(0.4).timeout
	phase_controller.start()
	if _do_net_loopback:
		_run_net_loopback_smoke_test()
		await get_tree().create_timer(0.2).timeout
		get_tree().quit(0)

func _apply_map_background() -> void:
	# C1: if the loaded map declares a background_image, swap the static
	# BackgroundSprite's texture. Falls back to the default battlemap3
	# texture (already set in main.tscn) when the map doesn't override.
	var path: String = String(board.background_image_path) if board != null else ""
	if path == "" or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var bg_sprite: Sprite2D = $BackgroundLayer/BackgroundSprite
	if bg_sprite:
		bg_sprite.texture = tex

func _load_configured_map() -> bool:
	match RunConfig.map_source:
		"generated":
			# C11: outburst generator activates when player_count == 2 AND the
			# session topology is "outburst". Otherwise fall through to the
			# legacy single-route generator.
			if RunConfig.player_count == 2 and RunConfig.session_topology == "outburst":
				var ob: Dictionary = MAP_GENERATOR.generate_outburst(RunConfig.seed, 2)
				if ob.get("ok", false):
					return board.load_dict(ob["map"])
				push_warning("generate_outburst failed: %s — falling back to single-route" % ob.get("error", "?"))
			var gen: Dictionary = MAP_GENERATOR.generate_forgiving(RunConfig.seed)
			if not gen.get("ok", false):
				push_error("Generator failed: %s" % gen.get("error", "unknown"))
				return board.load_map(STARTER_MAP)  # safe fallback
			return board.load_dict(gen["map"])
		"custom":
			var path: String = CUSTOM_MAP_DIR + RunConfig.custom_map_id + ".json"
			if not FileAccess.file_exists(path):
				push_error("Custom map not found: %s" % path)
				return board.load_map(STARTER_MAP)
			return board.load_map(path)
		"fixed_path":
			# Menu picker can specify an explicit res:// map file.
			if RunConfig.custom_map_id != "" and ResourceLoader.exists(RunConfig.custom_map_id):
				return board.load_map(RunConfig.custom_map_id)
			return board.load_map(STARTER_MAP)
		_:
			if _battleground_override:
				return board.load_map(BATTLEGROUND_MAP)
			return board.load_map(STARTER_MAP)

func _input(event: InputEvent) -> void:
	# F3 = reload current map JSON. Useful for iterating on a map without
	# restarting the run. The grid + curve update; existing enemies/towers stay.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if board.reload_map():
			RunLog.record("map_reloaded", {"path": board.map_path})
			print("Map reloaded.")
	# C4: F5 = debug force-start the wave even if some slots aren't ready.
	# Useful for solo testing of co-op-only flows.
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		if phase_controller and phase_controller.has_method("debug_force_start_wave"):
			phase_controller.debug_force_start_wave()
			print("F5: debug force-start wave")
	# C12: F7 = debug NetController loopback. Pretends a remote client
	# placed a Backline Archer at the local cursor position so the relay
	# path is exercised end-to-end without needing two real processes.
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		if net and net.has_method("demo_loopback"):
			net.demo_loopback("backline_archer", get_viewport().get_mouse_position(), 1)
			print("F7: net loopback fired (remote PlaceUnit @ mouse)")
	# C7: F6 = debug send aid. Source = local slot, target = slot 1 if it
	# exists (won't fire in solo). Subject = currently picked tower's unit_id.
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		var picked = placement.picked_tower if placement else null
		if picked == null or not is_instance_valid(picked):
			print("F6: pick a tower first")
		elif session.player_slots.size() < 2:
			print("F6: needs >= 2 player slots (currently %d)" % session.player_slots.size())
		else:
			var target_id: int = 1 if session.local_slot_id != 1 else 0
			CommandBus.dispatch(_SEND_AID_CMD.new(session.local_slot_id, picked.unit_id, target_id))

func _spawn_ambient_fx() -> void:
	# Atmospheric layer: drifting dust + pulsing core glow + spawn portal.
	# Sits between the background and the world units (parented to world so
	# pan/zoom move it with the board, but z_index keeps it behind units).
	# Instantiating from the script (not Node2D.new + set_script) so the
	# typed `setup` method is visible to the static analyzer.
	var fx = AMBIENT_FX_SCRIPT.new()
	fx.name = "AmbientFX"
	world.add_child(fx)
	fx.setup(board, Vector2(get_viewport_rect().size))

func _spawn_base() -> void:
	if base != null and is_instance_valid(base):
		base.queue_free()
	base = BASE_SCENE.instantiate()
	world.add_child(base)
	if board.grid:
		base.global_position = board.grid.grid_to_world(board.grid.core.x, board.grid.core.y)

func _run_net_loopback_smoke_test() -> void:
	print("--- C12 NetController loopback smoke ---")
	print("net.state = %s" % str(net.state))
	# Fake a remote PlaceUnit. With no map_source/topology hijack, this lands
	# at a screen-space coord that will likely fail is_valid_placement —
	# we're testing the apply path itself, not the placement outcome.
	GameState.add_gold(50)  # ensure affordable
	net.demo_loopback("backline_archer", Vector2(400, 300), 1)
	# Bus history should now contain a PlaceUnit attempt.
	var hist: Array = CommandBus.recent(5)
	var seen: bool = false
	for rec in hist:
		if String(rec.get("type", "")) == "place_unit_command":
			seen = true
			print("loopback PlaceUnit  success=%s  reason=%s" % [rec.get("success"), rec.get("reason")])
			break
	if not seen:
		print("FAIL: loopback did not produce a PlaceUnit command in history")

func _run_outburst_gen_smoke_test() -> void:
	print("--- C11 outburst generator smoke test (5 seeds) ---")
	for s in range(1, 6):
		var res: Dictionary = MAP_GENERATOR.generate_outburst(s, 2)
		if res.get("ok", false):
			var routes: Array = res["map"].get("routes", [])
			var n_len: int = (routes[0].get("path_chain", []) as Array).size() if routes.size() > 0 else 0
			var s_len: int = (routes[1].get("path_chain", []) as Array).size() if routes.size() > 1 else 0
			print("seed=%d  PASS  attempts=%d  routes=%d  north_len=%d  south_len=%d" % [s, int(res.get("attempts", 0)), routes.size(), n_len, s_len])
		else:
			print("seed=%d  FAIL  %s" % [s, str(res.get("error", "?"))])
	# Determinism check: seed=1 twice must produce identical path_chain[0].
	var a: Dictionary = MAP_GENERATOR.generate_outburst(1, 2)
	var b: Dictionary = MAP_GENERATOR.generate_outburst(1, 2)
	if a.get("ok", false) and b.get("ok", false):
		var a_chain: Array = a["map"]["routes"][0].get("path_chain", [])
		var b_chain: Array = b["map"]["routes"][0].get("path_chain", [])
		print("determinism: seed=1 chain match = %s (north_len %d == %d)" % [a_chain == b_chain, a_chain.size(), b_chain.size()])

func _despawn_aid_units() -> void:
	# C7: removes every aid-flagged temp tower so they only last one wave.
	# Spawns a small fade-out burst at each location for clarity.
	for t in get_tree().get_nodes_in_group("aid_units"):
		if not is_instance_valid(t):
			continue
		var pos: Vector2 = t.global_position
		var host: Node = get_tree().current_scene
		if host:
			CombatFX.burst(host, pos, Color(0.85, 0.9, 1.0), 8, 0.55)
		t.queue_free()

func _credit_tower_wave_survival() -> void:
	# A2: every tower still standing at wave-clear gets +1 to its
	# waves_survived counter (both local field + RunLog.instances).
	for t in get_tree().get_nodes_in_group("towers"):
		if is_instance_valid(t) and t.has_method("notify_wave_survived"):
			t.notify_wave_survived()

func _on_planning_started(wave: int) -> void:
	placement.set_locked(false)
	hud.show_wave_banner_planning(wave)

func _on_combat_started(wave: int) -> void:
	placement.set_locked(false)
	hud.show_wave_banner(wave)

func _on_run_ended(victory: bool) -> void:
	if GameState.game_running:
		if victory:
			GameState.declare_victory()
		else:
			GameState.game_over.emit(false)
	if RunLog.active:
		RunLog.end_run("victory" if victory else "defeat")

func _on_game_over_safety(victory: bool) -> void:
	if RunLog.active:
		RunLog.end_run("victory" if victory else "defeat")
