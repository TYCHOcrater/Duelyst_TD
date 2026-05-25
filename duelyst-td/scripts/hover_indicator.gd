extends Node2D

# Highlights the tile under the mouse and shows its coordinates.

var grid: GridController = null
var hover_pos: Vector2i = Vector2i(-1, -1)

const COLOR_HIGHLIGHT := Color(1, 1, 1, 0.18)
const COLOR_OUTLINE := Color(1, 1, 1, 0.85)
const FONT_SIZE := 12

func set_grid(g: GridController) -> void:
	grid = g

func _process(_d: float) -> void:
	if grid == null:
		return
	var mouse: Vector2 = get_global_mouse_position()
	var gp: Vector2i = grid.world_to_grid(mouse)
	if gp != hover_pos:
		hover_pos = gp
		queue_redraw()

func _draw() -> void:
	if grid == null or not grid.in_bounds(hover_pos.x, hover_pos.y):
		return
	var rect: Rect2 = grid.tile_world_rect(hover_pos.x, hover_pos.y)
	draw_rect(rect, COLOR_HIGHLIGHT, true)
	draw_rect(rect, COLOR_OUTLINE, false, 2.0)
	# Coord label near the tile.
	var label_text := "(%d, %d) %s" % [hover_pos.x, hover_pos.y, grid.get_tile(hover_pos.x, hover_pos.y)]
	var font := ThemeDB.fallback_font
	var pos := rect.position + Vector2(rect.size.x + 6, rect.size.y * 0.5 + FONT_SIZE * 0.4)
	# Shadow + main text for readability.
	draw_string(font, pos + Vector2(1, 1), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.85))
	draw_string(font, pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(1, 1, 1, 0.95))
