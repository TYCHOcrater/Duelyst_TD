extends Node2D

@export var bar_size: Vector2 = Vector2(50, 5)
var ratio: float = 1.0

func set_ratio(r: float) -> void:
	ratio = clampf(r, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var bg := Rect2(-bar_size.x * 0.5, -bar_size.y * 0.5, bar_size.x, bar_size.y)
	draw_rect(bg, Color(0.05, 0.05, 0.05, 0.85))
	var fg := Rect2(-bar_size.x * 0.5, -bar_size.y * 0.5, bar_size.x * ratio, bar_size.y)
	var color := Color(0.2, 0.85, 0.3)
	if ratio < 0.5:
		color = Color(0.95, 0.8, 0.2)
	if ratio < 0.25:
		color = Color(0.9, 0.25, 0.2)
	draw_rect(fg, color)
	draw_rect(bg, Color(0, 0, 0, 0.8), false, 1.0)
