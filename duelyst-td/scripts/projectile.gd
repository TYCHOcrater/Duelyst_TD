extends Node2D

@export var color: Color = Color(1.0, 0.9, 0.3)
@export var radius: float = 5.0

var target: Node2D
var speed: float = 400.0
var damage: int = 5
var damage_type: String = "strike"
var splash_radius: float = 0.0
var slow_duration: float = 0.0
var slow_factor: float = 1.0
var source_unit_id: String = ""
var source_instance_id: String = ""
var source_tower_ref: WeakRef = null

func setup(t: Node2D, dmg: int, spd: float, col: Color = color,
		splash_r: float = 0.0, slow_d: float = 0.0, slow_f: float = 1.0,
		dmg_type: String = "strike", src_id: String = "",
		src_tower: Node = null) -> void:
	target = t
	damage = dmg
	speed = spd
	color = col
	splash_radius = splash_r
	slow_duration = slow_d
	slow_factor = slow_f
	damage_type = dmg_type
	source_unit_id = src_id
	# Cache the source instance id at fire time. Tower may be sold/destroyed
	# before the projectile lands — instance stats still attribute correctly.
	if src_tower != null and "instance_id" in src_tower:
		source_instance_id = src_tower.instance_id
	source_tower_ref = weakref(src_tower) if src_tower != null else null
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.dying:
		queue_free()
		return
	var to_t: Vector2 = target.global_position - global_position
	var dist := to_t.length()
	var step := speed * delta
	if dist <= step:
		_on_hit()
		queue_free()
		return
	global_position += to_t.normalized() * step

func _on_hit() -> void:
	if splash_radius > 0.0:
		var hit_pos := target.global_position
		_spawn_splash_burst(hit_pos)
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dying:
				continue
			if hit_pos.distance_to(e.global_position) <= splash_radius:
				e.take_damage(damage, damage_type, source_unit_id, source_instance_id)
				if e.dying:
					_credit_kill()
				if slow_duration > 0.0:
					e.apply_slow(slow_duration, slow_factor)
	else:
		target.take_damage(damage, damage_type, source_unit_id, source_instance_id)
		if target.dying:
			_credit_kill()
		if is_instance_valid(target) and not target.dying and slow_duration > 0.0:
			target.apply_slow(slow_duration, slow_factor)

func _credit_kill() -> void:
	if source_tower_ref == null:
		return
	var t = source_tower_ref.get_ref()
	if t and is_instance_valid(t):
		t.add_kill()

func _spawn_splash_burst(at_pos: Vector2) -> void:
	var burst := Node2D.new()
	burst.position = at_pos
	burst.set_script(preload("res://scripts/splash_burst.gd"))
	burst.set_meta("radius", splash_radius)
	burst.set_meta("color", color)
	get_tree().current_scene.add_child(burst)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.95))
