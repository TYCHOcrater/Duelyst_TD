extends PathFollow2D

# Data-driven enemy. apply_def(def) is called by EnemyFactory.make_enemy().

signal died(reward: int, enemy_id: String)
signal reached_end(damage: int, enemy_id: String)
# Splitter mechanic: enemy asks the spawner to create a child enemy at its
# current path progress. The spawner attaches signals and increments counters.
signal wants_to_spawn(child_id: String, at_progress: float)

var enemy_id: String = ""
var display_name: String = ""
var family: String = "swarm"

var max_hp: int = 25
var hp: int = 25
var move_speed: float = 70.0
var armor: int = 0
var physical_resist: float = 0.0
var magic_resist: float = 0.0
var regen_per_sec: float = 0.0
var max_shield_hp: int = 0
var shield_hp: int = 0
var gold_reward: int = 5
var damage_to_base: int = 1

var base_modulate: Color = Color.WHITE
var dying: bool = false
var _slow_until: float = -1.0
var _slow_factor: float = 1.0
var _regen_accum: float = 0.0
var _pending_def: Dictionary = {}
var _on_death_events: Array = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: Node2D = $HealthBar
@onready var status_icons: Node2D = $StatusIcons

func apply_def(def: Dictionary) -> void:
	_pending_def = def
	enemy_id = def.get("id", "")
	display_name = def.get("display_name", enemy_id)
	family = def.get("family", "swarm")
	max_hp = int(float(def.get("hp", 25)) * ModifierTotals.product_float("enemy_hp_mult"))
	hp = max_hp
	move_speed = float(def.get("speed", 70.0)) * ModifierTotals.product_float("enemy_speed_mult")
	armor = int(def.get("armor", 0))
	physical_resist = float(def.get("physical_resist", 0.0))
	magic_resist = float(def.get("magic_resist", 0.0))
	regen_per_sec = float(def.get("regen_per_sec", 0.0))
	max_shield_hp = int(def.get("shield_hp", 0))
	shield_hp = max_shield_hp
	gold_reward = int(def.get("gold_reward", 5))
	damage_to_base = int(def.get("leak_damage", 1))
	_on_death_events = def.get("on_death", [])
	if def.has("scale"):
		var s := float(def["scale"])
		scale = Vector2(s, s)
	if def.has("tint"):
		var t = def["tint"]
		base_modulate = Color(float(t[0]), float(t[1]), float(t[2]))
	_apply_sprite_frames()
	_apply_hp_bar_config(def)

func _apply_hp_bar_config(def: Dictionary) -> void:
	if not is_node_ready():
		return
	if def.has("hp_bar_offset"):
		hp_bar.position = Vector2(0, float(def["hp_bar_offset"]))
		# Float status icons just above the HP bar.
		status_icons.position = Vector2(0, float(def["hp_bar_offset"]) - 17.0)
	if def.has("hp_bar_width"):
		hp_bar.bar_size = Vector2(float(def["hp_bar_width"]), 5)
	hp_bar.set_ratio(1.0)
	status_icons.enemy = self
	status_icons.queue_redraw()

func _apply_sprite_frames() -> void:
	if not is_node_ready():
		return
	var sf := EnemyFactory.sprite_frames_for(enemy_id)
	if sf:
		sprite.sprite_frames = sf
	sprite.modulate = base_modulate
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("run"):
		sprite.play("run")
	elif sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _ready() -> void:
	add_to_group("enemies")
	# Defensively lock orientation. PathFollow2D.rotates=false alone proved
	# unreliable on some seeds — enemies still ended up tilted at sharp curve
	# corners. Force rotation to 0 here AND in _process so the sprite always
	# faces the camera plane.
	rotates = false
	rotation = 0.0
	loop = false
	_apply_sprite_frames()
	if not _pending_def.is_empty():
		_apply_hp_bar_config(_pending_def)

func _process(delta: float) -> void:
	if dying:
		return
	# Regen.
	if regen_per_sec > 0.0 and hp < max_hp:
		_regen_accum += regen_per_sec * delta
		if _regen_accum >= 1.0:
			var heal: int = int(_regen_accum)
			_regen_accum -= heal
			hp = min(max_hp, hp + heal)
			_refresh_hp_bar()
	# Speed (with slow).
	var now := _now()
	var speed_mult := 1.0
	var slowed := now < _slow_until
	if slowed:
		speed_mult = _slow_factor
	# Visual: slow tint multiplies into base.
	if slowed:
		sprite.modulate = base_modulate.lerp(Color(0.55, 0.8, 1.4), 0.55)
	else:
		sprite.modulate = base_modulate
	var prev_x := global_position.x
	progress += move_speed * speed_mult * delta
	# Re-lock orientation each frame. Godot 4.6 occasionally drifts rotation
	# on PathFollow2D even with rotates=false (most visible at sharp 90° curve
	# corners) — keeping rotation pinned to 0 here is the only thing that
	# fully prevents the sprite from tilting between segments.
	rotation = 0.0
	if global_position.x < prev_x:
		sprite.flip_h = true
	elif global_position.x > prev_x:
		sprite.flip_h = false
	if progress_ratio >= 1.0:
		reached_end.emit(damage_to_base, enemy_id)
		queue_free()

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func apply_slow(duration: float, factor: float) -> void:
	if duration <= 0.0 or factor >= 1.0:
		return
	var now := _now()
	var new_until := now + duration
	if factor < _slow_factor or now >= _slow_until:
		_slow_factor = factor
	if new_until > _slow_until:
		_slow_until = new_until

func take_damage(amount: int, damage_type: String = "strike", source_id: String = "", source_instance_id: String = "") -> void:
	if dying:
		return
	# Apply type-based mitigation.
	var applied: int = amount
	match damage_type:
		"strike", "siege":
			applied = max(1, int(round(applied * (1.0 - physical_resist))) - armor)
		"arcane", "spirit", "frost":
			applied = max(1, int(round(applied * (1.0 - magic_resist))))
		"true":
			pass
		_:
			applied = max(1, int(round(applied * (1.0 - physical_resist))) - armor)
	# Shield absorbs first.
	var absorbed_by_shield: int = 0
	if shield_hp > 0:
		absorbed_by_shield = min(shield_hp, applied)
		shield_hp -= absorbed_by_shield
		applied -= absorbed_by_shield
	var pre_hp: int = hp
	hp -= applied
	var dealt: int = min(pre_hp, applied) + absorbed_by_shield
	RunLog.add_damage(dealt, source_id)
	if source_instance_id != "":
		RunLog.add_damage_to_instance(source_instance_id, dealt)
	_refresh_hp_bar()
	if dealt >= 15:
		_spawn_damage_popup(dealt, damage_type)
	if hp <= 0:
		_die()
	else:
		_flash_hit()

const _DAMAGE_TYPE_COLOR := {
	"strike": Color(1.0, 0.85, 0.55),
	"siege":  Color(0.95, 0.70, 0.35),
	"arcane": Color(0.75, 0.55, 1.0),
	"spirit": Color(0.85, 0.50, 1.0),
	"frost":  Color(0.55, 0.85, 1.0),
	"true":   Color(1.0, 1.0, 1.0),
}

func _spawn_damage_popup(amt: int, damage_type: String) -> void:
	var popup := Node2D.new()
	popup.set_script(preload("res://scripts/damage_popup.gd"))
	# Spawn slightly above the sprite, in world coords.
	popup.global_position = global_position + Vector2(randi_range(-6, 6), -30)
	get_tree().current_scene.add_child(popup)
	var col: Color = _DAMAGE_TYPE_COLOR.get(damage_type, Color(1, 0.85, 0.5))
	popup.setup(amt, col)

func _refresh_hp_bar() -> void:
	var total_max: float = float(max_hp + max_shield_hp)
	if total_max <= 0:
		return
	var total_cur: float = float(max(0, hp) + max(0, shield_hp))
	hp_bar.set_ratio(total_cur / total_max)

func _flash_hit() -> void:
	sprite.self_modulate = Color(1.6, 0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.15)

func _die() -> void:
	dying = true
	died.emit(gold_reward, enemy_id)
	hp_bar.visible = false
	AudioManager.play("enemy_death", 0.08)
	_process_on_death_events()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	queue_free()

func _process_on_death_events() -> void:
	for evt in _on_death_events:
		var kind: String = evt.get("type", "")
		if kind == "split":
			var child_id: String = evt.get("enemy_id", "")
			var count: int = int(evt.get("count", 0))
			var spread: float = float(evt.get("progress_spread", 18.0))
			for i in count:
				var jitter: float = randf_range(-spread, spread)
				wants_to_spawn.emit(child_id, max(0.0, progress + jitter))
