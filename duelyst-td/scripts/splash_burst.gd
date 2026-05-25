extends Node2D

var t: float = 0.0
const DURATION := 0.35

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	if t >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var r: float = get_meta("radius", 60.0)
	var c: Color = get_meta("color", Color(1, 0.5, 0.2))
	var progress := t / DURATION
	var current_r: float = r * (0.3 + 0.9 * progress)
	var alpha: float = 0.55 * (1.0 - progress)
	draw_circle(Vector2.ZERO, current_r, Color(c.r, c.g, c.b, alpha * 0.45))
	draw_arc(Vector2.ZERO, current_r, 0, TAU, 48, Color(c.r, c.g, c.b, alpha), 3.0)
