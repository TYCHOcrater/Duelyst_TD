extends Node2D

# Draws the grid tiles in a single _draw() call, colored by tile type.

var grid: GridController = null

const COLOR_BUILDABLE := Color(0.45, 0.7, 0.45, 0.10)
const COLOR_BUILDABLE_BORDER := Color(1, 1, 1, 0.10)
const COLOR_PATH := Color(1.0, 0.85, 0.45, 0.30)
const COLOR_PATH_BORDER := Color(1.0, 0.85, 0.4, 0.50)
const COLOR_BLOCKED := Color(0.05, 0.05, 0.08, 0.55)
const COLOR_BLOCKED_BORDER := Color(0, 0, 0, 0.50)
const COLOR_SPAWN := Color(0.95, 0.4, 0.25, 0.55)
const COLOR_SPAWN_BORDER := Color(1.0, 0.55, 0.3, 0.95)
const COLOR_CORE := Color(0.45, 0.65, 1.0, 0.55)
const COLOR_CORE_BORDER := Color(0.65, 0.85, 1.0, 0.95)

func set_grid(g: GridController) -> void:
	if grid and grid.corruption_changed.is_connected(_on_corruption_changed):
		grid.corruption_changed.disconnect(_on_corruption_changed)
	grid = g
	if grid:
		grid.corruption_changed.connect(_on_corruption_changed)
	queue_redraw()

func _on_corruption_changed() -> void:
	queue_redraw()

func _draw() -> void:
	if grid == null:
		return
	var ts: int = grid.tile_size
	for r in grid.height:
		for c in grid.width:
			var tile: String = grid.get_tile(c, r)
			var rect: Rect2 = grid.tile_world_rect(c, r)
			var fill: Color
			var border: Color
			match tile:
				GridController.TILE_P:
					fill = COLOR_PATH
					border = COLOR_PATH_BORDER
				GridController.TILE_X:
					fill = COLOR_BLOCKED
					border = COLOR_BLOCKED_BORDER
				GridController.TILE_S:
					fill = COLOR_SPAWN
					border = COLOR_SPAWN_BORDER
				GridController.TILE_C:
					fill = COLOR_CORE
					border = COLOR_CORE_BORDER
				_:
					fill = COLOR_BUILDABLE
					border = COLOR_BUILDABLE_BORDER
			draw_rect(rect, fill, true)
			draw_rect(rect, border, false, 1.0)
			# Extra accent for spawn/core: inset highlight.
			if tile == GridController.TILE_S or tile == GridController.TILE_C:
				var inset := Rect2(rect.position + Vector2(6, 6), rect.size - Vector2(12, 12))
				draw_rect(inset, border, false, 2.0)
	# Corruption overlay (dynamic state). Drawn last so it sits on top of
	# the static tile fills.
	for gp in grid.corrupted_tiles:
		var crect: Rect2 = grid.tile_world_rect(gp.x, gp.y)
		draw_rect(crect, Color(0.55, 0.25, 0.85, 0.40), true)
		draw_rect(crect, Color(0.7, 0.4, 0.95, 0.85), false, 2.0)
		# Small swirl marker in the center.
		var cpos: Vector2 = crect.position + crect.size * 0.5
		draw_circle(cpos, 6.0, Color(0.85, 0.55, 1.0, 0.9))
		draw_circle(cpos, 3.0, Color(0.15, 0.05, 0.25, 0.95))
