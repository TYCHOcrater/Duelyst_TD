extends Node2D

# Renders a horizontal row of state chips for the parent enemy
# (armor / shield / regen / resists / active slow). Updates each frame.

const CHIP_W: int = 28
const CHIP_H: int = 14
const SPACING: int = 3
const FONT_SIZE: int = 10

const COLOR_ARMOR     := Color(0.45, 0.45, 0.50, 0.95)
const COLOR_PHYS_RES  := Color(0.65, 0.45, 0.30, 0.95)
const COLOR_MAGIC_RES := Color(0.55, 0.40, 0.85, 0.95)
const COLOR_SHIELD    := Color(0.45, 0.75, 1.00, 0.95)
const COLOR_REGEN     := Color(0.40, 0.85, 0.45, 0.95)
const COLOR_SLOW      := Color(0.55, 0.85, 1.20, 0.95)
const COLOR_BORDER    := Color(0, 0, 0, 0.7)
const COLOR_TEXT      := Color(1, 1, 1, 1)

var enemy: Node = null
var _last_signature: String = ""

func _process(_d: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	# Cheap change-detection so we redraw only when the chip set changes.
	var sig := _signature()
	if sig != _last_signature:
		_last_signature = sig
		queue_redraw()

func _signature() -> String:
	# Build a short string that flips whenever any displayed value changes.
	var slowed: bool = enemy._now() < enemy._slow_until if "_slow_until" in enemy else false
	return "%d|%d|%d|%.0f|%.0f|%d|%s" % [
		int(enemy.armor),
		int(enemy.shield_hp),
		int(enemy.max_shield_hp),
		float(enemy.physical_resist) * 100.0,
		float(enemy.magic_resist) * 100.0,
		int(round(float(enemy.regen_per_sec))),
		"S" if slowed else "_",
	]

func _gather_chips() -> Array:
	# Returns array of {color, text}.
	if enemy == null:
		return []
	var chips: Array = []
	if int(enemy.armor) > 0:
		chips.append({"color": COLOR_ARMOR, "text": "A%d" % int(enemy.armor)})
	if int(enemy.shield_hp) > 0:
		chips.append({"color": COLOR_SHIELD, "text": "S%d" % int(enemy.shield_hp)})
	if float(enemy.physical_resist) >= 0.10:
		chips.append({"color": COLOR_PHYS_RES, "text": "P%d" % int(round(float(enemy.physical_resist) * 100.0))})
	if float(enemy.magic_resist) >= 0.10:
		chips.append({"color": COLOR_MAGIC_RES, "text": "M%d" % int(round(float(enemy.magic_resist) * 100.0))})
	if float(enemy.regen_per_sec) >= 1.0:
		chips.append({"color": COLOR_REGEN, "text": "R%d" % int(round(float(enemy.regen_per_sec)))})
	# Slow only when actively slowed.
	if "_slow_until" in enemy and enemy._now() < enemy._slow_until:
		chips.append({"color": COLOR_SLOW, "text": "SLO"})
	return chips

func _draw() -> void:
	var chips: Array = _gather_chips()
	if chips.is_empty():
		return
	var total_w: int = chips.size() * CHIP_W + max(0, chips.size() - 1) * SPACING
	var start_x: float = -total_w * 0.5
	var font := ThemeDB.fallback_font
	for i in chips.size():
		var c: Dictionary = chips[i]
		var x: float = start_x + i * (CHIP_W + SPACING)
		var rect := Rect2(x, 0, CHIP_W, CHIP_H)
		draw_rect(rect, c.get("color", Color.WHITE), true)
		draw_rect(rect, COLOR_BORDER, false, 1.0)
		var t: String = c.get("text", "")
		draw_string(font, Vector2(x + 3, CHIP_H - 3), t,
			HORIZONTAL_ALIGNMENT_LEFT, CHIP_W - 6, FONT_SIZE, COLOR_TEXT)
