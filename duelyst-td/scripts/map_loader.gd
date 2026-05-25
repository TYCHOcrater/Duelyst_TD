class_name MapLoader
extends RefCounted

# Loads + validates a MapDef JSON file.
#
# Schema (v1):
#   {
#     "id":         "starter_neutral",
#     "name":       "Starter Plains",
#     "version":    1,
#     "width":      20,
#     "height":     8,
#     "tile_size":  64,
#     "origin":     [0, 56],            # world pixel offset of (col 0, row 0)
#     "tiles":      [ "BBBB...", ... ]  # rows top-down
#   }
#
# Tile chars:
#   B = Buildable
#   P = Path
#   X = Blocked
#   S = Spawn (counts as path)
#   C = Core  (counts as path)

const TILE_CHARS := "BPXSC"

static func load_path(res_path: String) -> Dictionary:
	# Returns {ok: true, map: {...}} or {ok: false, error: "..."}.
	if not FileAccess.file_exists(res_path):
		return _err("File not found: %s" % res_path)
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return _err("Could not open: %s" % res_path)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _err("Invalid JSON (expected object) in %s" % res_path)
	return validate(parsed)

static func validate(map: Dictionary) -> Dictionary:
	# Schema checks.
	for key in ["id", "name", "width", "height", "tile_size", "tiles"]:
		if not map.has(key):
			return _err("Missing required field: '%s'" % key)
	var w: int = int(map["width"])
	var h: int = int(map["height"])
	var tile_size: int = int(map["tile_size"])
	if w <= 0 or h <= 0:
		return _err("width and height must be positive (got %dx%d)" % [w, h])
	if tile_size <= 0:
		return _err("tile_size must be positive (got %d)" % tile_size)
	var tiles: Array = map["tiles"]
	if tiles.size() != h:
		return _err("tiles has %d rows, expected %d" % [tiles.size(), h])
	# Tile content checks.
	var spawn_pos: Vector2i = Vector2i(-1, -1)
	var core_pos: Vector2i = Vector2i(-1, -1)
	for r in h:
		var row = tiles[r]
		if typeof(row) != TYPE_STRING:
			return _err("Row %d is not a string" % r)
		if row.length() != w:
			return _err("Row %d has %d chars, expected %d" % [r, row.length(), w])
		for c in w:
			var ch: String = row.substr(c, 1)
			if not TILE_CHARS.contains(ch):
				return _err("Unknown tile char '%s' at (%d,%d). Allowed: %s" % [ch, c, r, TILE_CHARS])
			if ch == "S":
				if spawn_pos != Vector2i(-1, -1):
					return _err("More than one 'S' (spawn) found")
				spawn_pos = Vector2i(c, r)
			elif ch == "C":
				if core_pos != Vector2i(-1, -1):
					return _err("More than one 'C' (core) found")
				core_pos = Vector2i(c, r)
	if spawn_pos == Vector2i(-1, -1):
		return _err("No spawn tile ('S') found")
	if core_pos == Vector2i(-1, -1):
		return _err("No core tile ('C') found")
	# Path connectivity: BFS from spawn, must reach core, all path tiles reachable.
	var connect := _check_path_connectivity(tiles, w, h, spawn_pos, core_pos)
	if not connect.ok:
		return _err(connect.error)
	# Normalized output. Origin may arrive as Array (raw JSON) or Vector2 (already-validated dict).
	var origin_raw = map.get("origin", [0, 56])
	var origin: Vector2
	if origin_raw is Vector2:
		origin = origin_raw
	else:
		origin = Vector2(float(origin_raw[0]), float(origin_raw[1]))
	return {
		"ok": true,
		"map": {
			"id": map["id"],
			"name": map["name"],
			"version": int(map.get("version", 1)),
			"width": w,
			"height": h,
			"tile_size": tile_size,
			"origin": origin,
			"tiles": tiles,
			"spawn": spawn_pos,
			"core": core_pos,
			"path_chain": connect.path_chain,  # ordered Array[Vector2i] from spawn to core
		},
	}

static func _is_path_char(ch: String) -> bool:
	return ch == "P" or ch == "S" or ch == "C"

static func _check_path_connectivity(tiles: Array, w: int, h: int, spawn: Vector2i, core: Vector2i) -> Dictionary:
	# Walk from spawn through path neighbors; verify it reaches core and chain is unambiguous.
	# (Each intermediate path tile must have exactly 2 path neighbors; endpoints exactly 1.)
	# This enforces a single, well-formed path - good for v1.
	var chain: Array = []
	var visited: Dictionary = {}
	var current: Vector2i = spawn
	var prev: Vector2i = Vector2i(-9999, -9999)
	var safety := 0
	while true:
		safety += 1
		if safety > w * h + 1:
			return {"ok": false, "error": "Pathfinding ran away - likely a loop in path tiles"}
		chain.append(current)
		visited[_key(current)] = true
		if current == core:
			break
		# Find unvisited path neighbors.
		var neighbors: Array = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = current + d
			if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h:
				continue
			if not _is_path_char(tiles[n.y].substr(n.x, 1)):
				continue
			if n == prev:
				continue
			if visited.has(_key(n)):
				continue
			neighbors.append(n)
		if neighbors.size() == 0:
			return {"ok": false, "error": "Path dead-end at (%d,%d) before reaching core" % [current.x, current.y]}
		if neighbors.size() > 1:
			return {"ok": false, "error": "Path branches at (%d,%d) - v1 maps require a single linear path" % [current.x, current.y]}
		prev = current
		current = neighbors[0]
	# Verify every P/S/C in the grid was visited (no orphan path tiles).
	for r in h:
		var row: String = tiles[r]
		for c in w:
			if _is_path_char(row.substr(c, 1)):
				if not visited.has(_key(Vector2i(c, r))):
					return {"ok": false, "error": "Orphan path tile at (%d,%d) not connected to spawn->core chain" % [c, r]}
	return {"ok": true, "path_chain": chain}

static func _key(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]

static func _err(msg: String) -> Dictionary:
	push_warning("MapLoader: %s" % msg)
	return {"ok": false, "error": msg}
