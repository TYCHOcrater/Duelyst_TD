class_name CombatFX

# One-shot procedural VFX helpers. Both methods spawn self-cleaning nodes
# parented to `host` (typically the Main scene) so they survive the death
# of whatever triggered them — an enemy queue_freeing mid-burst, etc.

static var _ring_tex: ImageTexture = null
static var _dot_tex: ImageTexture = null

# Outward particle burst — used for enemy death.
static func burst(host: Node, world_pos: Vector2, color: Color, count: int = 14, speed_scale: float = 1.0) -> void:
	if host == null or not host.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = world_pos
	p.amount = count
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 70.0 * speed_scale
	p.initial_velocity_max = 150.0 * speed_scale
	p.spread = 180.0
	p.direction = Vector2.UP
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.4
	p.color = color
	p.texture = _dot_texture()
	p.z_index = 6
	host.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# Outward ring pulse — used for tower placement.
static func placement_pulse(host: Node, world_pos: Vector2, color: Color) -> void:
	if host == null or not host.is_inside_tree():
		return
	var sprite := Sprite2D.new()
	sprite.position = world_pos
	sprite.texture = _ring_texture()
	sprite.modulate = color
	sprite.scale = Vector2(0.35, 0.35)
	sprite.z_index = 6
	host.add_child(sprite)
	var tween: Tween = host.create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(2.4, 2.4), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(sprite.queue_free)

static func _dot_texture() -> ImageTexture:
	if _dot_tex != null:
		return _dot_tex
	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size, size) * 0.5
	var r: float = size * 0.5
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r:
				var t: float = 1.0 - (d / r)
				t = t * t
				img.set_pixel(x, y, Color(1, 1, 1, t))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex

static func _ring_texture() -> ImageTexture:
	if _ring_tex != null:
		return _ring_tex
	var size := 96
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size, size) * 0.5
	var outer: float = size * 0.5
	var inner: float = outer * 0.78
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= outer and d >= inner:
				# Smooth falloff at both edges of the ring.
				var t: float
				if d >= (outer + inner) * 0.5:
					t = (outer - d) / (outer - inner) * 2.0
				else:
					t = (d - inner) / (outer - inner) * 2.0
				img.set_pixel(x, y, Color(1, 1, 1, clamp(t, 0.0, 1.0)))
	_ring_tex = ImageTexture.create_from_image(img)
	return _ring_tex
