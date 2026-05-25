extends Node2D

@export var cell_size: float = 64.0
@export var area: Rect2 = Rect2(0, 60, 1280, 580)
@export var color: Color = Color(1, 1, 1, 0.08)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var x := area.position.x
	while x <= area.end.x:
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), color, 1.0)
		x += cell_size
	var y := area.position.y
	while y <= area.end.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), color, 1.0)
		y += cell_size
