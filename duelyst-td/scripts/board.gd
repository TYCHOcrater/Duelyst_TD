extends Node2D

# Board: owns the grid + tile renderer + enemy path + hover indicator.

signal map_loaded(map_id: String)
signal map_load_failed(reason: String)

# C1: when a multi-route map loads, the active route is enemy_path (curve
# from route[0]). Additional routes are exposed here so the wave_spawner
# can iterate them in C2 (multi-route spawning) without needing to query
# GridController internals.
var routes: Array = []          # Array of route dicts from the validated map
var cores: Array = []           # Array of Vector2i — all core positions
var topology: String = "single"
var background_image_path: String = ""

const TILE_RENDERER_SCRIPT := preload("res://scripts/tile_renderer.gd")
const HOVER_SCRIPT := preload("res://scripts/hover_indicator.gd")

var grid: GridController = null
var map_path: String = ""

@onready var tile_renderer: Node2D = $TileRenderer
@onready var enemy_path: Path2D = $EnemyPath
@onready var hover_indicator: Node2D = $HoverIndicator
@onready var error_label: Label = $ErrorLabel

func load_map(path: String) -> bool:
	map_path = path
	var result := MapLoader.load_path(path)
	if not result.get("ok", false):
		var msg: String = result.get("error", "Unknown error")
		error_label.text = "Map error in %s:\n%s" % [path.get_file(), msg]
		error_label.visible = true
		map_load_failed.emit(msg)
		return false
	return _apply_loaded(result["map"])

# Apply an already-validated MapDef (e.g. from MapGenerator or an in-memory editor).
func load_dict(raw: Dictionary) -> bool:
	map_path = ""
	var result := MapLoader.validate(raw)
	if not result.get("ok", false):
		var msg: String = result.get("error", "Unknown error")
		error_label.text = "Generated map invalid:\n%s" % msg
		error_label.visible = true
		map_load_failed.emit(msg)
		return false
	return _apply_loaded(result["map"])

func _apply_loaded(map: Dictionary) -> bool:
	error_label.visible = false
	grid = GridController.new()
	grid.load_from(map)
	tile_renderer.set_grid(grid)
	hover_indicator.set_grid(grid)
	# Multi-route metadata. For "single" topology these stay empty and the
	# existing enemy_path/curve flow is unchanged.
	topology = String(map.get("topology", "single"))
	routes = map.get("routes", [])
	cores = map.get("cores", [])
	background_image_path = String(map.get("background_image", ""))
	# Active curve = grid's primary path_chain (route[0] for outburst).
	enemy_path.curve = grid.build_path_curve()
	map_loaded.emit(map["id"])
	return true

# C1 helper for future C2 (multi-route enemy spawning): build a curve from
# any of the loaded routes by id. Returns null if no match.
func curve_for_route(route_id: String) -> Curve2D:
	for r in routes:
		if String(r.get("id", "")) != route_id:
			continue
		var chain: Array = r.get("path_chain", [])
		if chain.size() < 2 or grid == null:
			return null
		var curve := Curve2D.new()
		# Extend one tile outward at the spawn end so the enemy enters from
		# off-grid, matching the single-route flow in GridController.
		var first: Vector2i = chain[0]
		var second: Vector2i = chain[1]
		var entry_offset: Vector2i = first - second
		var entry: Vector2 = grid.grid_to_world(first.x + entry_offset.x, first.y + entry_offset.y)
		curve.add_point(entry)
		for pt in chain:
			curve.add_point(grid.grid_to_world(pt.x, pt.y))
		curve.bake_interval = 5.0
		return curve
	return null

func reload_map() -> bool:
	if map_path == "":
		return false
	return load_map(map_path)
