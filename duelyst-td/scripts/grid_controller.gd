class_name GridController
extends RefCounted

# Lightweight holder for a loaded MapDef + coordinate helpers.

signal corruption_changed()

const TILE_B := "B"
const TILE_P := "P"
const TILE_X := "X"
const TILE_S := "S"
const TILE_C := "C"

var width: int = 0
var height: int = 0
var tile_size: int = 64
var origin: Vector2 = Vector2.ZERO
var tiles: Array = []            # Array of row strings
var spawn: Vector2i = Vector2i.ZERO
var core: Vector2i = Vector2i.ZERO
var path_chain: Array = []       # Array[Vector2i] from spawn to core
# Dynamic tile state — outside the static tile_type. Cleared on wave clear.
var corrupted_tiles: Dictionary = {}  # Vector2i -> true

func load_from(map: Dictionary) -> void:
	width = int(map["width"])
	height = int(map["height"])
	tile_size = int(map["tile_size"])
	origin = map["origin"]
	tiles = map["tiles"]
	spawn = map["spawn"]
	core = map["core"]
	path_chain = map["path_chain"]

func get_tile(c: int, r: int) -> String:
	if c < 0 or c >= width or r < 0 or r >= height:
		return TILE_X
	return tiles[r].substr(c, 1)

func is_buildable(c: int, r: int) -> bool:
	return get_tile(c, r) == TILE_B

func is_path(c: int, r: int) -> bool:
	var t := get_tile(c, r)
	return t == TILE_P or t == TILE_S or t == TILE_C

func grid_to_world(c: int, r: int) -> Vector2:
	# Center of the tile.
	return origin + Vector2((c + 0.5) * tile_size, (r + 0.5) * tile_size)

func world_to_grid(world: Vector2) -> Vector2i:
	var rel := world - origin
	var c := int(floor(rel.x / tile_size))
	var r := int(floor(rel.y / tile_size))
	return Vector2i(c, r)

func in_bounds(c: int, r: int) -> bool:
	return c >= 0 and c < width and r >= 0 and r < height

func build_path_curve() -> Curve2D:
	var curve := Curve2D.new()
	if path_chain.size() < 2:
		return curve
	# Extend the first point one tile outward so enemies enter from off-screen.
	var first: Vector2i = path_chain[0]
	var second: Vector2i = path_chain[1]
	var entry_offset: Vector2i = first - second
	var entry: Vector2 = grid_to_world(first.x + entry_offset.x, first.y + entry_offset.y)
	curve.add_point(entry)
	for p in path_chain:
		curve.add_point(grid_to_world(p.x, p.y))
	curve.bake_interval = 5.0
	return curve

func tile_world_rect(c: int, r: int) -> Rect2:
	return Rect2(origin + Vector2(c * tile_size, r * tile_size), Vector2(tile_size, tile_size))

# --- Corruption (dynamic per-wave state) ---

func is_corrupted(gp: Vector2i) -> bool:
	return corrupted_tiles.has(gp)

func is_corrupted_at_world(world_pos: Vector2) -> bool:
	return is_corrupted(world_to_grid(world_pos))

func clear_corruption() -> void:
	if corrupted_tiles.is_empty():
		return
	corrupted_tiles.clear()
	corruption_changed.emit()

func corrupt_nearest_buildable(world_pos: Vector2, max_total: int = 6) -> Vector2i:
	# Mark the nearest BUILDABLE tile (manhattan distance) that isn't already
	# corrupted. Returns the grid coord, or (-1, -1) if none available or the
	# cap is reached. Cap prevents a leaky wave from making placement impossible.
	if corrupted_tiles.size() >= max_total:
		return Vector2i(-1, -1)
	var origin_gp: Vector2i = world_to_grid(world_pos)
	var best: Vector2i = Vector2i(-1, -1)
	var best_d: int = 99999
	for r in height:
		for c in width:
			if not is_buildable(c, r):
				continue
			var gp := Vector2i(c, r)
			if corrupted_tiles.has(gp):
				continue
			var d: int = abs(c - origin_gp.x) + abs(r - origin_gp.y)
			if d < best_d:
				best_d = d
				best = gp
	if best.x >= 0:
		corrupted_tiles[best] = true
		corruption_changed.emit()
	return best
