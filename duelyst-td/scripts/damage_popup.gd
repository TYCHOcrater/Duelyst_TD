extends Node2D

# Tiny floating "+N" text that drifts up and fades. Spawned by enemy.gd
# for hits at or above a threshold so screens don't flood at high tower density.

const DURATION := 0.7
const RISE_PIXELS := 18.0
const FONT_SIZE := 11

var amount: int = 0
var color: Color = Color(1, 0.85, 0.5, 1)
var t: float = 0.0
var prefix: String = ""

func setup(amt: int, col: Color = color, prefix_str: String = "") -> void:
	amount = amt
	color = col
	prefix = prefix_str
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	if t >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress: float = t / DURATION
	var y_offset: float = -RISE_PIXELS * progress
	var alpha: float = 1.0 - progress * progress  # ease-out fade
	var c := Color(color.r, color.g, color.b, alpha)
	var text := prefix + str(amount)
	var font := ThemeDB.fallback_font
	# Shadow then text for readability.
	draw_string(font, Vector2(1, y_offset + 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, Color(0, 0, 0, alpha * 0.9))
	draw_string(font, Vector2(0, y_offset), text, HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, c)
