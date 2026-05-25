extends Node2D

# Board: owns the grid + tile renderer + enemy path + hover indicator.

signal map_loaded(map_id: String)
signal map_load_failed(reason: String)

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
	enemy_path.curve = grid.build_path_curve()
	map_loaded.emit(map["id"])
	return true

func reload_map() -> bool:
	if map_path == "":
		return false
	return load_map(map_path)
