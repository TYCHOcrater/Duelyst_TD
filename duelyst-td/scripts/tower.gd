extends Node2D

# Generic data-driven tower. Configure via apply_def(unit_def).

signal selected(tower: Node)

const PROJECTILE_SCENE := preload("res://scenes/projectile_basic.tscn")

# Stats (set from UnitDef).
var unit_id: String = ""
var display_name: String = "Tower"
var faction: String = "neutral"
var cost: int = 5
var range_radius: float = 180.0
var damage: int = 4
var fire_rate: float = 1.2
var projectile_speed: float = 450.0
var projectile_color: Color = Color(1.0, 0.9, 0.3)
var splash_radius: float = 0.0
var slow_duration: float = 0.0
var slow_factor: float = 1.0
var buff_radius: float = 0.0
var buff_damage_mult: float = 0.0
var shoot_sfx: String = "tower_archer_shoot"
var targeting: String = "first"  # first | strongest | weakest
var damage_type: String = "strike"  # strike | arcane | spirit | frost | siege | true

# Runtime
var fire_cooldown: float = 0.0
var current_target: Node2D = null
var show_range: bool = false
var show_target_line: bool = false
var is_preview: bool = false
var level: int = 0
var total_spent: int = 0
var trait_id: String = ""
var trait_name: String = ""
var flaw_id: String = ""
var flaw_name: String = ""
var kills_count: int = 0
var evolution_tier: int = 0   # 0 = vanilla; 1 = Tempered; 2 = Veteran; 3 = Legendary

# A2 unit-instance identity. Each placed tower gets a unique instance_id
# so RunLog can track per-instance stats (damage / kills / waves survived)
# rather than aggregating by base unit type only.
var instance_id: String = ""
var placed_at_wave: int = 0
var waves_survived: int = 0
var damage_dealt: int = 0  # mirrors RunLog instances[instance_id].damage; cheap accessor for inspect panel

# A5 star levels. 1 = base, 2 = 2★ (consumed 2 shards), 3 = 3★ (consumed 5 total).
var star_level: int = 1
const SHARDS_FOR_2STAR := 2
const SHARDS_FOR_3STAR := 3  # additional shards on top of the 2 spent for 2★

# A6 evolution choices (merge_evolution_hybrid only).
# pending_evolution_star: > 0 means the tower just promoted to this star and
# is awaiting an evolution pick. evolution_choices: star_level -> evolution_id
# (records what was chosen for inspect display + run summary).
var pending_evolution_star: int = 0
var evolution_choices: Dictionary = {}

const EVO_THRESHOLDS := [15, 40, 80]
const EVO_NAMES := ["", "Tempered", "Veteran", "Legendary"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Polish: silhouette shadow + halo highlight, built lazily as siblings of
# the main sprite. They share the same SpriteFrames + current animation
# so the silhouette matches the unit's pose every frame.
var _shadow_sprite: AnimatedSprite2D = null
var _highlight_sprite: AnimatedSprite2D = null

func apply_def(def: Dictionary) -> void:
	unit_id = def.get("id", "")
	display_name = def.get("display_name", unit_id)
	faction = def.get("faction", "neutral")
	cost = int(def.get("cost", 5))
	range_radius = float(def.get("range", 180.0))
	damage = int(def.get("damage", 4))
	fire_rate = float(def.get("fire_rate", 1.2))
	projectile_speed = float(def.get("projectile_speed", 450.0))
	var c = def.get("projectile_color", [1.0, 0.9, 0.3])
	projectile_color = Color(c[0], c[1], c[2])
	splash_radius = float(def.get("splash_radius", 0.0))
	slow_duration = float(def.get("slow_duration", 0.0))
	slow_factor = float(def.get("slow_factor", 1.0))
	buff_radius = float(def.get("buff_radius", 0.0))
	buff_damage_mult = float(def.get("buff_damage_mult", 0.0))
	shoot_sfx = def.get("shoot_sfx", "tower_archer_shoot")
	targeting = def.get("targeting", "first")
	damage_type = def.get("damage_type", "strike")
	# Apply sprite frames now if sprite is ready, else queued in _ready.
	_apply_sprite_frames()

func _apply_sprite_frames() -> void:
	if not is_node_ready():
		return
	var sf := UnitFactory.sprite_frames_for(unit_id)
	if sf:
		sprite.sprite_frames = sf
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	if not is_preview:
		_ensure_decorative_sprites()

func _ensure_decorative_sprites() -> void:
	# Lazily build the shadow + highlight overlay sprites. They share the
	# main sprite's frames so the silhouette/halo matches the unit's pose.
	# z_index < 0 places them behind the main sprite within this Node2D.
	if sprite.sprite_frames == null:
		return
	if _shadow_sprite == null:
		_shadow_sprite = AnimatedSprite2D.new()
		_shadow_sprite.sprite_frames = sprite.sprite_frames
		_shadow_sprite.z_index = -2
		_shadow_sprite.position = Vector2(0, 18)
		_shadow_sprite.scale = Vector2(0.95, 0.38)   # squashed silhouette on the ground
		_shadow_sprite.modulate = Color(0.0, 0.0, 0.0, 0.40)
		_shadow_sprite.play(sprite.animation)
		add_child(_shadow_sprite)
	if _highlight_sprite == null:
		_highlight_sprite = AnimatedSprite2D.new()
		_highlight_sprite.sprite_frames = sprite.sprite_frames
		_highlight_sprite.z_index = -1
		# Bigger halo + brighter base so the player notices it from across
		# the board. Was 1.10x with alpha 0.35-0.65 — too subtle on small
		# Duelyst sprites.
		_highlight_sprite.scale = Vector2(1.20, 1.20)
		_highlight_sprite.modulate = Color(1.0, 0.92, 0.45, 0.0)
		_highlight_sprite.visible = false
		_highlight_sprite.play(sprite.animation)
		add_child(_highlight_sprite)

func _ready() -> void:
	if not is_preview:
		add_to_group("towers")
		_register_instance()
	if total_spent == 0:
		total_spent = cost
	_apply_sprite_frames()

func _register_instance() -> void:
	# Lazy-register with RunLog after the tower is actually placed (not the
	# placement-preview ghost). RunLog returns the assigned instance_id and
	# tracks per-instance damage/kills/waves from this point on.
	if RunLog == null or not RunLog.has_method("register_unit_instance"):
		return
	placed_at_wave = int(RunLog.stats.get("wave_reached", 0))
	if placed_at_wave <= 0:
		placed_at_wave = 1  # placement during planning of wave N is recorded as wave N
	instance_id = RunLog.register_unit_instance(unit_id, placed_at_wave, trait_id, flaw_id)

func _exit_tree() -> void:
	# Sold OR died; the placement controller emits sell_unit before queue_free,
	# so anything reaching here without a prior unregister is a "lost" instance.
	if instance_id != "" and RunLog != null and RunLog.has_method("finalize_unit_instance"):
		RunLog.finalize_unit_instance(instance_id, "removed")

func apply_trait(def: Dictionary) -> void:
	# Used for both traits and flaws; the caller writes trait_id/flaw_id.
	trait_id = def.get("id", "")
	trait_name = def.get("display_name", trait_id)
	_apply_stat_mods(def.get("stat_mods", {}))

func apply_flaw(def: Dictionary) -> void:
	flaw_id = def.get("id", "")
	flaw_name = def.get("display_name", flaw_id)
	_apply_stat_mods(def.get("stat_mods", {}))

func _apply_stat_mods(mods: Dictionary) -> void:
	# Stat multipliers. Order: read first, then write, so order doesn't matter.
	if mods.has("damage_mult"):
		damage = max(1, int(round(damage * float(mods["damage_mult"]))))
	if mods.has("fire_rate_mult"):
		fire_rate = fire_rate * float(mods["fire_rate_mult"])
	if mods.has("range_mult"):
		range_radius = range_radius * float(mods["range_mult"])
	if mods.has("cost_mult"):
		cost = int(round(cost * float(mods["cost_mult"])))
	if mods.has("splash_radius_mult") and splash_radius > 0.0:
		splash_radius = splash_radius * float(mods["splash_radius_mult"])
	# Slow add-ons: trait can grant a slow even if the unit doesn't have one
	# (slow_duration_add), or strengthen the slow factor (slow_factor_min).
	if mods.has("slow_duration_add"):
		slow_duration = slow_duration + float(mods["slow_duration_add"])
		if slow_factor >= 1.0:
			slow_factor = 0.75
	if mods.has("slow_factor_min") and slow_factor > float(mods["slow_factor_min"]):
		slow_factor = float(mods["slow_factor_min"])
	# A6 additional mults used by evolutions.
	if mods.has("slow_duration_mult"):
		slow_duration = slow_duration * float(mods["slow_duration_mult"])
	if mods.has("slow_factor_mult") and slow_factor < 1.0:
		# Multiply toward zero to amplify (slow_factor is the speed multiplier
		# while slowed, so smaller = more slowed; mult < 1.0 strengthens).
		slow_factor = max(0.1, slow_factor * float(mods["slow_factor_mult"]))
	if mods.has("buff_damage_mult_mult") and buff_damage_mult > 0.0:
		buff_damage_mult = buff_damage_mult * float(mods["buff_damage_mult_mult"])
	if mods.has("buff_radius_mult") and buff_radius > 0.0:
		buff_radius = buff_radius * float(mods["buff_radius_mult"])
	# Veteran start_level: apply N upgrades up front.
	if mods.has("start_level"):
		var jumps: int = int(mods["start_level"])
		for i in jumps:
			upgrade()
	# Re-emit cost into total_spent so sell value reflects the mods.
	total_spent = cost

func is_buff_tower() -> bool:
	return buff_damage_mult > 0.0 and buff_radius > 0.0

func set_preview(p: bool) -> void:
	is_preview = p
	show_range = p
	modulate.a = 0.55 if p else 1.0
	if p:
		set_process(false)
	queue_redraw()

func set_show_range(s: bool) -> void:
	show_range = s
	queue_redraw()

func set_show_target_line(s: bool) -> void:
	show_target_line = s
	queue_redraw()

func upgrade() -> void:
	level += 1
	damage = int(round(damage * 1.5))
	range_radius *= 1.15
	fire_rate *= 1.10
	if buff_damage_mult > 0.0:
		buff_damage_mult *= 1.4
		buff_radius *= 1.10
	total_spent += upgrade_cost()
	queue_redraw()

func star_promotion_cost() -> int:
	# Shards required to reach the next star, or 0 if at max (3★).
	match star_level:
		1: return SHARDS_FOR_2STAR
		2: return SHARDS_FOR_3STAR
		_: return 0

func can_promote_star() -> bool:
	if star_level >= 3:
		return false
	return RunLog.shard_count(unit_id) >= star_promotion_cost()

func promote_star() -> bool:
	# Consumes the required shards and applies the stat bonus.
	# Stat scaling per addendum line 528 (mapped to TD context):
	#   2★: +35% damage, +20% buff strength (for aura towers)
	#   3★: +80% damage, +40% buff strength
	# We apply the DELTA from current level, not the absolute multiplier.
	if star_level >= 3:
		return false
	var cost: int = star_promotion_cost()
	if not RunLog.consume_shards(unit_id, cost):
		return false
	var new_star: int = star_level + 1
	match new_star:
		2:
			damage = int(round(damage * 1.35))
			buff_damage_mult *= 1.20
			fire_rate *= 1.10
		3:
			# +80% from base ≈ +33% from 2★ values (since 2★ is +35%).
			damage = int(round(damage * (1.80 / 1.35)))
			buff_damage_mult *= (1.40 / 1.20)
			fire_rate *= 1.10
	star_level = new_star
	RunLog.record("star_promoted", {
		"unit": unit_id,
		"instance_id": instance_id,
		"star_level": star_level,
		"shards_consumed": cost,
	})
	# A6: in hybrid mode, if evolution branches exist for this base unit at
	# the new star, mark the tower as pending an evolution pick. HUD reads
	# this flag and surfaces the choice modal when the tower is inspected.
	if RunConfig.growth_mode == "merge_evolution_hybrid":
		if EvolutionManager.has_choices(unit_id, star_level):
			pending_evolution_star = star_level
	queue_redraw()
	return true

func apply_evolution(evo_def: Dictionary) -> void:
	# A6: applies an EvolutionDef chosen by the player. Stat mods are the
	# same shape as trait stat_mods (damage_mult, fire_rate_mult, range_mult,
	# slow_duration_mult, slow_factor_mult, splash_radius_mult, buff_*_mult).
	_apply_stat_mods(evo_def.get("stat_mods", {}))
	# Record what the player picked at this star (for inspect display + summary).
	evolution_choices[str(star_level)] = String(evo_def.get("id", ""))
	pending_evolution_star = 0
	RunLog.record("evolution_chosen", {
		"unit": unit_id,
		"instance_id": instance_id,
		"star_level": star_level,
		"evolution_id": evo_def.get("id", ""),
	})
	queue_redraw()

func upgrade_cost() -> int:
	var base_cost: float = cost * 0.75 * pow(1.4, level)
	return max(1, int(round(base_cost * ModifierTotals.product_float("upgrade_cost_mult"))))

func sell_value() -> int:
	return int(round(total_spent * 0.6))

func add_kill() -> void:
	kills_count += 1
	if instance_id != "" and RunLog != null and RunLog.has_method("add_kill_to_instance"):
		RunLog.add_kill_to_instance(instance_id)
	_check_evolution()

func notify_wave_survived() -> void:
	# Called by main.gd at wave-clear for every tower still alive.
	waves_survived += 1
	if instance_id != "" and RunLog != null and RunLog.has_method("bump_waves_survived"):
		RunLog.bump_waves_survived(instance_id)

func _check_evolution() -> void:
	var new_tier: int = evolution_tier
	for i in range(EVO_THRESHOLDS.size() - 1, -1, -1):
		if kills_count >= EVO_THRESHOLDS[i]:
			new_tier = i + 1
			break
	if new_tier > evolution_tier:
		_promote_to(new_tier)

func _promote_to(tier: int) -> void:
	while evolution_tier < tier:
		evolution_tier += 1
		match evolution_tier:
			1:
				damage = int(round(damage * 1.20))
			2:
				range_radius *= 1.10
			3:
				fire_rate *= 1.10
	RunLog.record("tower_evolved", {"unit": unit_id, "tier": evolution_tier, "kills": kills_count})
	queue_redraw()

func evolution_progress() -> Dictionary:
	# Returns {tier, name, kills, next_threshold} for HUD display.
	var next_threshold: int = -1
	if evolution_tier < EVO_THRESHOLDS.size():
		next_threshold = EVO_THRESHOLDS[evolution_tier]
	return {
		"tier": evolution_tier,
		"name": EVO_NAMES[evolution_tier] if evolution_tier < EVO_NAMES.size() else "",
		"kills": kills_count,
		"next_threshold": next_threshold,
	}

func _process(delta: float) -> void:
	fire_cooldown -= delta
	# Polish: keep shadow + halo synced with the main sprite's frame so the
	# silhouette / glow tracks attack/idle/death animations. Cheap if not
	# in-tree (early return).
	if not is_preview and _shadow_sprite != null:
		_sync_decorative_sprites()
		_update_upgrade_halo()
	if buff_damage_mult > 0.0 and damage <= 0:
		queue_redraw()
		return
	_refresh_target()
	if show_target_line:
		queue_redraw()
	if current_target and fire_cooldown <= 0.0:
		_fire()
		# Corruption: -30% effective rate while on a corrupted tile.
		var rate: float = fire_rate
		if WaveEffects.is_position_corrupted(global_position):
			rate *= 0.7
		fire_cooldown = 1.0 / max(0.1, rate)

func effective_damage() -> int:
	if buff_damage_mult > 0.0:
		return damage
	var buff_pct := 0.0
	for t in get_tree().get_nodes_in_group("towers"):
		if t == self or not t.is_buff_tower():
			continue
		if global_position.distance_to(t.global_position) <= t.buff_radius:
			buff_pct += t.buff_damage_mult
	return int(round(damage * (1.0 + buff_pct)))

func _refresh_target() -> void:
	if current_target and is_instance_valid(current_target) and not current_target.dying:
		if global_position.distance_to(current_target.global_position) <= range_radius:
			sprite.flip_h = current_target.global_position.x < global_position.x
			return
	current_target = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	match targeting:
		"strongest":
			var best_hp := -1
			var best_d := range_radius
			for e in enemies:
				if e.dying:
					continue
				var d: float = global_position.distance_to(e.global_position)
				if d > best_d:
					continue
				if int(e.hp) > best_hp:
					best_hp = int(e.hp)
					current_target = e
		"weakest":
			var weakest_hp := 99999
			for e in enemies:
				if e.dying:
					continue
				var d: float = global_position.distance_to(e.global_position)
				if d > range_radius:
					continue
				if int(e.hp) < weakest_hp:
					weakest_hp = int(e.hp)
					current_target = e
		_:
			# "first" = closest to its destination (highest progress_ratio).
			var best_progress := -1.0
			for e in enemies:
				if e.dying:
					continue
				var d: float = global_position.distance_to(e.global_position)
				if d > range_radius:
					continue
				var p: float = e.progress_ratio if "progress_ratio" in e else 0.0
				if p > best_progress:
					best_progress = p
					current_target = e
	if current_target:
		sprite.flip_h = current_target.global_position.x < global_position.x

func _fire() -> void:
	if not current_target:
		return
	if damage <= 0:
		return  # buff-only tower
	if WaveEffects.is_silenced():
		# Cooldown still ticks; first volley after silence ends fires in sync.
		return
	var proj: Node2D = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector2(0, -20)
	var eff_slow_duration: float = slow_duration * ModifierTotals.product_float("slow_duration_mult")
	proj.setup(
		current_target,
		effective_damage(),
		projectile_speed,
		projectile_color,
		splash_radius,
		eff_slow_duration,
		slow_factor,
		damage_type,
		unit_id,
		self,
	)
	if shoot_sfx != "":
		AudioManager.play(shoot_sfx, 0.05)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		await sprite.animation_finished
		if is_instance_valid(self) and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _draw() -> void:
	# Shadow + upgrade-available halo are now rendered by sibling
	# AnimatedSprite2D nodes (_shadow_sprite / _highlight_sprite) built in
	# _ensure_decorative_sprites(). They follow the unit's silhouette
	# automatically. Old polygon-based fallbacks removed.
	if show_range:
		var range_color := Color(0.2, 0.7, 1.0, 0.12)
		var border_color := Color(0.2, 0.7, 1.0, 0.5)
		if is_buff_tower():
			range_color = Color(1.0, 0.85, 0.3, 0.10)
			border_color = Color(1.0, 0.85, 0.3, 0.55)
		if range_radius > 0:
			draw_circle(Vector2.ZERO, range_radius, range_color)
			draw_arc(Vector2.ZERO, range_radius, 0, TAU, 64, border_color, 2.0)
	if is_buff_tower() and not is_preview:
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0)
		var aura := Color(1.0, 0.85, 0.3, 0.15 + 0.1 * pulse)
		draw_circle(Vector2.ZERO, buff_radius, Color(aura.r, aura.g, aura.b, 0.05))
		draw_arc(Vector2.ZERO, buff_radius, 0, TAU, 48, aura, 2.0)
	# Target line: thin line from tower to its current target while hovered.
	if show_target_line and current_target and is_instance_valid(current_target) and not is_preview:
		var local_target: Vector2 = current_target.global_position - global_position
		draw_line(Vector2.ZERO, local_target, Color(1.0, 0.85, 0.45, 0.65), 2.0)
		draw_circle(local_target, 4.0, Color(1.0, 0.85, 0.45, 0.8))
	# Evolution stars: one gold star per tier, drawn above the sprite.
	if evolution_tier > 0 and not is_preview:
		var star_y: float = -56.0
		var star_color := Color(1.0, 0.9, 0.45)
		var spacing: float = 9.0
		var total_w: float = (evolution_tier - 1) * spacing
		for i in evolution_tier:
			var sx: float = -total_w * 0.5 + i * spacing
			_draw_star(Vector2(sx, star_y), 4.0, star_color)

func _sync_decorative_sprites() -> void:
	# Match the main sprite's current animation + frame + flip on the
	# shadow/highlight layers. Animation handoff (e.g. idle → attack) is
	# rare enough that the .play() call is cheap.
	if _shadow_sprite:
		if _shadow_sprite.animation != sprite.animation and sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation):
			_shadow_sprite.play(sprite.animation)
		_shadow_sprite.frame = sprite.frame
		_shadow_sprite.flip_h = sprite.flip_h
	if _highlight_sprite:
		if _highlight_sprite.animation != sprite.animation and sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation):
			_highlight_sprite.play(sprite.animation)
		_highlight_sprite.frame = sprite.frame
		_highlight_sprite.flip_h = sprite.flip_h

func _update_upgrade_halo() -> void:
	# Sprite-based replacement for the old polygon ring. Pulses the
	# highlight sprite's alpha when the player has an action available.
	if _highlight_sprite == null:
		return
	var has_action: bool = _has_upgrade_available()
	if not has_action:
		_highlight_sprite.visible = false
		return
	_highlight_sprite.visible = true
	# Stronger pulse + higher base alpha so the highlight reads from a few
	# tiles away. Range was 0.35-0.65; now 0.65-0.95.
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 280.0)
	var alpha: float = 0.65 + 0.30 * pulse
	_highlight_sprite.modulate = Color(1.0, 0.92, 0.45, alpha)

func _draw_unit_shadow() -> void:
	# Squashed ellipse approximated via two stacked circles to avoid needing a
	# texture asset. Radii sized to roughly match the unit footprint.
	var shadow := Color(0.0, 0.0, 0.0, 0.22)
	# Center near the feet of the sprite. Sprite origin is at the unit center
	# (~16px above ground), so y +18 offsets to ground.
	var c := Vector2(0, 18)
	# Squash: render as a horizontal ellipse using two arcs.
	# Cheap path: just draw a filled ellipse as 32 triangle slices.
	var rx: float = 22.0
	var ry: float = 7.0
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c)
	var segs := 24
	for i in segs + 1:
		var a: float = TAU * i / segs
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polygon(pts, PackedColorArray([shadow]))

func _has_upgrade_available() -> bool:
	# True if the player has at least one action available on this unit right now.
	# (Doesn't gate on phase — the highlight is informational; commands still
	# enforce planning_only.)
	var mode: String = RunConfig.growth_mode
	# Classic-upgrade-eligible modes: have enough gold AND not at max level
	if mode in ["classic_upgrade", "merge_evolution_hybrid"]:
		if level < 4 and GameState.gold >= upgrade_cost():
			return true
	# Merge-mode shard promotion
	if mode in ["merge_stars", "merge_evolution_hybrid"]:
		if can_promote_star():
			return true
	# Pending evolution choice (hybrid only)
	if pending_evolution_star > 0:
		return true
	return false

func _draw_upgrade_highlight() -> void:
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 320.0)
	var color := Color(1.0, 0.95, 0.55, 0.55 + 0.30 * pulse)
	var inner_color := Color(1.0, 0.95, 0.55, 0.10 + 0.06 * pulse)
	var radius: float = 28.0
	draw_circle(Vector2(0, 4), radius, inner_color)
	draw_arc(Vector2(0, 4), radius, 0, TAU, 40, color, 3.0)

func _draw_star(center: Vector2, size: float, color: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -size),
		center + Vector2(size * 0.4, -size * 0.3),
		center + Vector2(size, 0),
		center + Vector2(size * 0.4, size * 0.3),
		center + Vector2(0, size),
		center + Vector2(-size * 0.4, size * 0.3),
		center + Vector2(-size, 0),
		center + Vector2(-size * 0.4, -size * 0.3),
	])
	draw_colored_polygon(pts, color)
