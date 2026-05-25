extends Node2D

const BASE_SCENE := preload("res://scenes/base.tscn")
const PHASE_SCRIPT := preload("res://scripts/phase_controller.gd")
const DRAFT_SCRIPT := preload("res://scripts/draft_director.gd")
const DEBUG_OVERLAY_SCENE := preload("res://scenes/debug_overlay.tscn")
const MAP_GENERATOR := preload("res://scripts/map_generator.gd")

const STARTER_MAP := "res://data/maps/starter_neutral.json"
const CUSTOM_MAP_DIR := "user://maps/"
const STARTER_WAVE_SET := "act1"

@onready var board: Node2D = $World/Board
@onready var spawner: Node = $WaveSpawner
@onready var placement: Node2D = $Placement
@onready var hud: CanvasLayer = $HUD
@onready var world: Node2D = $World
@onready var session: Node = $SessionController

var phase_controller: Node
var draft_director: Node
var base: Node = null

func _ready() -> void:
	# --use-generated forces procgen for headless smoke tests.
	if "--use-generated" in OS.get_cmdline_args():
		RunConfig.map_source = "generated"
	GameState.reset()
	PactManager.reset()
	RelicManager.reset()
	if RunConfig.seed == 0:
		RunConfig.randomize_seed()
	SessionRng.set_seed(RunConfig.seed)
	RunLog.start_run(RunConfig.seed)
	session.configure(RunConfig.player_count, RunConfig.session_topology)
	CommandBus.bind_main(self)
	add_child(DEBUG_OVERLAY_SCENE.instantiate())
	if not _load_configured_map():
		# Validation error already surfaced via the board's ErrorLabel.
		# Halt the game cleanly so the user can read it.
		return
	_spawn_base()
	placement.bind_grid(board.grid)
	placement.path = board.enemy_path
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
	phase_controller.run_ended.connect(_on_run_ended)
	spawner.wave_cleared.connect(phase_controller.notify_wave_cleared)
	GameState.game_over.connect(_on_game_over_safety)
	var wave_set: Dictionary = EnemyFactory.get_wave_set(STARTER_WAVE_SET)
	if wave_set.is_empty():
		push_error("main: wave-set '%s' not found" % STARTER_WAVE_SET)
		return
	spawner.configure(board.enemy_path, wave_set, phase_controller)
	spawner.grid = board.grid
	WaveEffects.set_grid(board.grid)
	phase_controller.configure(spawner, draft_director, spawner.get_wave_count())
	await get_tree().create_timer(0.4).timeout
	phase_controller.start()

func _load_configured_map() -> bool:
	match RunConfig.map_source:
		"generated":
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
		_:
			return board.load_map(STARTER_MAP)

func _input(event: InputEvent) -> void:
	# F3 = reload current map JSON. Useful for iterating on a map without
	# restarting the run. The grid + curve update; existing enemies/towers stay.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if board.reload_map():
			RunLog.record("map_reloaded", {"path": board.map_path})
			print("Map reloaded.")

func _spawn_base() -> void:
	if base != null and is_instance_valid(base):
		base.queue_free()
	base = BASE_SCENE.instantiate()
	world.add_child(base)
	if board.grid:
		base.global_position = board.grid.grid_to_world(board.grid.core.x, board.grid.core.y)

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
