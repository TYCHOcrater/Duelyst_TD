class_name MapGenerator
extends RefCounted

# Seeded procedural map generator. Produces MapDef dicts that pass MapLoader.validate.
#
# Algorithm (single-linear-path random walk):
#   1. Pick spawn on left edge, target core on right edge.
#   2. Self-avoiding random walk biased toward +X. Reject any step that would
#      make the new tile adjacent to an existing path tile (other than current),
#      which keeps the path a single thick=1 chain that the loader accepts.
#   3. On success, mark spawn/core and emit the tile rows.
#   4. Validate via MapLoader + extra quality metrics (length, turns, buildables).
#   5. Retry up to MAX_ATTEMPTS with a stirred seed if the carve gets stuck or
#      the quality check fails.
#
# Use:
#   var result := MapGenerator.generate(run_seed)
#   if result.get("ok", false):
#       var map_dict: Dictionary = result.map     # ready for board.load_dict(...)
#   else:
#       push_error(result.error)

const WIDTH := 20
const HEIGHT := 8
const TILE_SIZE := 64
const ORIGIN := [0, 56]
const MAX_ATTEMPTS := 60
const MIN_PATH_LENGTH := 14
const MAX_PATH_LENGTH := 80
const MIN_TURNS := 3
const MIN_BUILDABLE_RATIO := 0.55

const ASCII_B := 66  # 'B'
const ASCII_P := 80  # 'P'
const ASCII_S := 83  # 'S'
const ASCII_C := 67  # 'C'

static func generate(seed_int: int) -> Dictionary:
	for attempt in MAX_ATTEMPTS:
		var rng := RandomNumberGenerator.new()
		# Stir the seed by attempt index so failed attempts don't loop.
		rng.seed = (seed_int ^ (int(attempt) * 2654435761))
		var tiles: PackedStringArray = _try_carve(rng)
		if tiles.is_empty():
			continue
		var dict: Dictionary = _build_dict(tiles, seed_int, attempt)
		var validation: Dictionary = MapLoader.validate(dict)
		if not validation.get("ok", false):
			continue
		var quality: Dictionary = _check_quality(tiles, validation["map"])
		if not quality.ok:
			continue
		return {"ok": true, "map": validation["map"], "attempts": attempt + 1}
	return {"ok": false, "error": "MapGenerator: no valid map after %d attempts" % MAX_ATTEMPTS}

# Like generate, but loops until success even with adverse seeds.
# Walks seed forward by 1 if the original cluster fails MAX_ATTEMPTS.
# Useful for the "random map" button which should always produce something.
static func generate_forgiving(seed_int: int, max_cluster_walks: int = 10) -> Dictionary:
	for walk in max_cluster_walks:
		var res := generate(seed_int + walk)
		if res.get("ok", false):
			res["seed_used"] = seed_int + walk
			return res
	return {"ok": false, "error": "MapGenerator: cluster-walk exhausted"}

static func _try_carve(rng: RandomNumberGenerator) -> PackedStringArray:
	var grid: Array = []
	for r in HEIGHT:
		var row := PackedByteArray()
		row.resize(WIDTH)
		for c in WIDTH:
			row[c] = ASCII_B
		grid.append(row)
	var spawn_y: int = rng.randi_range(1, HEIGHT - 2)
	var current := Vector2i(0, spawn_y)
	grid[current.y][current.x] = ASCII_P
	var path: Array[Vector2i] = [current]
	var prev_dir: Vector2i = Vector2i(1, 0)
	var safety := 0
	while current.x < WIDTH - 1:
		safety += 1
		if safety > WIDTH * HEIGHT * 4:
			return PackedStringArray()
		var dirs: Array = _weighted_dirs(rng, prev_dir, current)
		var picked: Vector2i = Vector2i.ZERO
		var found := false
		for d in dirs:
			var nxt: Vector2i = current + d
			if not _valid_step(grid, current, nxt):
				continue
			picked = nxt
			found = true
			break
		if not found:
			return PackedStringArray()
		prev_dir = picked - current
		current = picked
		grid[current.y][current.x] = ASCII_P
		path.append(current)
	# Mark endpoints.
	grid[path[0].y][path[0].x] = ASCII_S
	grid[path[path.size() - 1].y][path[path.size() - 1].x] = ASCII_C
	var tiles := PackedStringArray()
	for r in HEIGHT:
		tiles.append((grid[r] as PackedByteArray).get_string_from_ascii())
	return tiles

static func _valid_step(grid: Array, current: Vector2i, nxt: Vector2i) -> bool:
	if nxt.x < 0 or nxt.x >= WIDTH or nxt.y < 0 or nxt.y >= HEIGHT:
		return false
	if grid[nxt.y][nxt.x] != ASCII_B:
		return false
	# nxt's 4-neighbors (except current) must NOT be path tiles, or we'd create a branch.
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = nxt + d
		if n == current:
			continue
		if n.x < 0 or n.x >= WIDTH or n.y < 0 or n.y >= HEIGHT:
			continue
		if grid[n.y][n.x] != ASCII_B:
			return false
	return true

static func _weighted_dirs(rng: RandomNumberGenerator, prev_dir: Vector2i, current: Vector2i) -> Array:
	# Build a weighted bag, shuffle, dedupe (preserve first-occurrence order).
	# Bias: +X gets 4 votes, +Y / -Y get 2 each, -X gets 1 only if not at left edge.
	var bag: Array[Vector2i] = []
	for i in 4:
		bag.append(Vector2i(1, 0))
	for i in 2:
		bag.append(Vector2i(0, 1))
		bag.append(Vector2i(0, -1))
	if current.x > 1:
		bag.append(Vector2i(-1, 0))
	# Fisher-Yates shuffle.
	for i in range(bag.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: Vector2i = bag[i]
		bag[i] = bag[j]
		bag[j] = t
	# Dedupe preserving order, drop immediate reverse.
	var reverse: Vector2i = -prev_dir
	var seen: Dictionary = {}
	var out: Array = []
	for d in bag:
		if d == reverse:
			continue
		var k: String = "%d,%d" % [d.x, d.y]
		if seen.has(k):
			continue
		seen[k] = true
		out.append(d)
	return out

static func _build_dict(tiles: PackedStringArray, seed_int: int, attempt: int) -> Dictionary:
	return {
		"id": "rand_%08x_%d" % [seed_int & 0xFFFFFFFF, attempt],
		"name": "Random Storm · %08X" % (seed_int & 0xFFFFFFFF),
		"version": 1,
		"width": WIDTH,
		"height": HEIGHT,
		"tile_size": TILE_SIZE,
		"origin": ORIGIN,
		"tiles": Array(tiles),
	}

static func _check_quality(tiles: PackedStringArray, map: Dictionary) -> Dictionary:
	var path_chain: Array = map.get("path_chain", [])
	var path_len: int = path_chain.size()
	if path_len < MIN_PATH_LENGTH:
		return {"ok": false, "reason": "path length %d < %d" % [path_len, MIN_PATH_LENGTH]}
	if path_len > MAX_PATH_LENGTH:
		return {"ok": false, "reason": "path length %d > %d" % [path_len, MAX_PATH_LENGTH]}
	var turns: int = 0
	for i in range(2, path_chain.size()):
		var d1: Vector2i = path_chain[i - 1] - path_chain[i - 2]
		var d2: Vector2i = path_chain[i] - path_chain[i - 1]
		if d1 != d2:
			turns += 1
	if turns < MIN_TURNS:
		return {"ok": false, "reason": "only %d turns, need %d" % [turns, MIN_TURNS]}
	var buildable: int = 0
	for row in tiles:
		for ch in row:
			if ch == "B":
				buildable += 1
	var ratio: float = float(buildable) / float(WIDTH * HEIGHT)
	if ratio < MIN_BUILDABLE_RATIO:
		return {"ok": false, "reason": "buildable ratio %.2f < %.2f" % [ratio, MIN_BUILDABLE_RATIO]}
	return {"ok": true, "path_length": path_len, "turns": turns, "buildable": buildable}

# -------------------------------------------------------------------------
# C11: outburst (multi-route) generator. v1 supports player_count == 2.
# 4-player still routes to the curated battleground_test map. 1-player keeps
# the existing generate() flow.
#
# Layout for 2p:
#   20×20 grid, spawn at (10, 10), cores at (10, 1) and (10, 18).
#   Each route is a biased random walk (forward bias toward the target row,
#   small chance of 1-tile lateral bend). North route stays in y ≤ 9,
#   south route stays in y ≥ 11 — they share only the spawn tile and never
#   cross-adjacency-touch.
# -------------------------------------------------------------------------
const OB_WIDTH := 20
const OB_HEIGHT := 20
const OB_SPAWN := Vector2i(10, 10)
const OB_BEND_CHANCE := 0.28
const OB_MAX_CARVE_STEPS := 80
const OB_MIN_ROUTE_LENGTH := 10

static func generate_outburst(seed_int: int, player_count: int) -> Dictionary:
	if player_count != 2:
		return {"ok": false, "error": "generate_outburst v1 supports player_count=2 only (got %d)" % player_count}
	var last_carve_fail: int = 0
	var last_val_err: String = ""
	for attempt in MAX_ATTEMPTS:
		var rng := RandomNumberGenerator.new()
		rng.seed = (seed_int ^ (int(attempt) * 2654435761))
		var dict := _try_outburst_2p(rng, seed_int, attempt)
		if dict.is_empty():
			last_carve_fail += 1
			continue
		var validation: Dictionary = MapLoader.validate(dict)
		if validation.get("ok", false):
			return {"ok": true, "map": validation["map"], "attempts": attempt + 1}
		last_val_err = String(validation.get("error", "?"))
	return {
		"ok": false,
		"error": "generate_outburst: no valid 2p map after %d attempts (carve_fails=%d, last_val_err=%s)" % [MAX_ATTEMPTS, last_carve_fail, last_val_err],
	}

static func _try_outburst_2p(rng: RandomNumberGenerator, seed_int: int, attempt: int) -> Dictionary:
	var north_chain: Array = _carve_outburst_route(rng, OB_SPAWN, 1, -1)
	var south_chain: Array = _carve_outburst_route(rng, OB_SPAWN, OB_HEIGHT - 2, 1)
	if north_chain.is_empty() or south_chain.is_empty():
		return {}
	if north_chain.size() < OB_MIN_ROUTE_LENGTH or south_chain.size() < OB_MIN_ROUTE_LENGTH:
		return {}
	# Cross-adjacency check: no north tile (other than spawn) shares a
	# cardinal neighbor with any south tile (other than spawn). Keeps the
	# rendering clean and matches the curated battleground_test design.
	var south_set: Dictionary = {}
	for p in south_chain:
		if p != OB_SPAWN:
			south_set[p] = true
	for p in north_chain:
		if p == OB_SPAWN:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if south_set.has((p as Vector2i) + d):
				return {}
	# Build ASCII tile grid.
	var grid: Array = []
	for r in OB_HEIGHT:
		var row := PackedByteArray()
		row.resize(OB_WIDTH)
		for c in OB_WIDTH:
			row[c] = ASCII_B
		grid.append(row)
	for p in north_chain:
		grid[p.y][p.x] = ASCII_P
	for p in south_chain:
		grid[p.y][p.x] = ASCII_P
	grid[OB_SPAWN.y][OB_SPAWN.x] = ASCII_S
	var north_end: Vector2i = north_chain[north_chain.size() - 1]
	var south_end: Vector2i = south_chain[south_chain.size() - 1]
	grid[north_end.y][north_end.x] = ASCII_C
	grid[south_end.y][south_end.x] = ASCII_C
	var tiles := PackedStringArray()
	for r in OB_HEIGHT:
		tiles.append((grid[r] as PackedByteArray).get_string_from_ascii())
	return {
		"id": "rand_outburst_2p_%08x_%d" % [seed_int & 0xFFFFFFFF, attempt],
		"name": "Co-op Storm · %08X" % (seed_int & 0xFFFFFFFF),
		"version": 2,
		"topology": "outburst",
		"width": OB_WIDTH,
		"height": OB_HEIGHT,
		"tile_size": TILE_SIZE,
		"origin": ORIGIN,
		"tiles": Array(tiles),
		"routes": [
			{"id": "north", "core_label": "Player 1 (N)", "path_chain": _chain_to_arrays(north_chain)},
			{"id": "south", "core_label": "Player 2 (S)", "path_chain": _chain_to_arrays(south_chain)},
		],
	}

static func _carve_outburst_route(rng: RandomNumberGenerator, spawn: Vector2i, target_y: int, y_step: int) -> Array:
	var chain: Array = [spawn]
	var current: Vector2i = spawn
	var visited: Dictionary = {spawn: true}
	var safety: int = 0
	while current.y != target_y:
		safety += 1
		if safety > OB_MAX_CARVE_STEPS:
			return []
		var fwd: Vector2i = Vector2i(0, y_step)
		var lat: Vector2i = Vector2i(-1, 0) if rng.randi() % 2 == 0 else Vector2i(1, 0)
		var pick: Vector2i = lat if rng.randf() < OB_BEND_CHANCE else fwd
		var nxt: Vector2i = current + pick
		# Bounds (keep 1-tile border free).
		if nxt.x < 1 or nxt.x >= OB_WIDTH - 1:
			pick = fwd
			nxt = current + pick
		# Half-plane: north stays y <= spawn.y - 1 after leaving the spawn.
		# south stays y >= spawn.y + 1.
		if current != spawn:
			if y_step < 0 and nxt.y > spawn.y - 1:
				return []
			if y_step > 0 and nxt.y < spawn.y + 1:
				return []
		if visited.has(nxt):
			# Lateral bent into an already-visited tile — force forward.
			pick = fwd
			nxt = current + pick
			if visited.has(nxt):
				return []
		# Bounds + half-plane re-check after the forward-fallback.
		if nxt.x < 1 or nxt.x >= OB_WIDTH - 1:
			return []
		if y_step < 0 and nxt.y < 1:
			return []
		if y_step > 0 and nxt.y > OB_HEIGHT - 2:
			return []
		chain.append(nxt)
		visited[nxt] = true
		current = nxt
	return chain

static func _chain_to_arrays(chain: Array) -> Array:
	# MapLoader expects path_chain entries as [x,y] arrays (JSON-friendly),
	# not Vector2i — the loader's validator converts on read.
	var out: Array = []
	for p in chain:
		out.append([p.x, p.y])
	return out
