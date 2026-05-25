extends Node2D

# AmbientFX: cheap atmospheric effects added on top of the board to make the
# play space feel alive without depending on hand-painted assets.
#
#   - Drifting dust motes across the viewport (CPUParticles2D)
#   - Soft pulsing glow at each Core position
#   - Swirling pulse at the central spawn tile (multi-route maps only)
#
# All visuals are procedural: circle textures are generated at runtime so
# this file is the only thing needed for the effect to ship.

const DUST_AMOUNT := 70
const DUST_LIFETIME := 9.0
const PULSE_PERIOD := 2.4

# Each entry: {sprite: Sprite2D, base_color: Color, base_scale: Vector2,
#              phase: float, spin_rate: float}
var _pulses: Array = []
var _circle_tex_cache: Dictionary = {}  # size -> ImageTexture

func setup(board: Node, viewport_size: Vector2) -> void:
	if board == null or board.grid == null:
		return
	_make_dust(viewport_size)
	# Core glow(s). Outburst maps populate `cores`; single-topology maps don't,
	# so fall back to grid.core.
	var cores: Array = board.cores
	if cores.is_empty():
		cores = [board.grid.core]
	for c in cores:
		var pos: Vector2 = board.grid.grid_to_world(c.x, c.y)
		_add_pulse(pos, Color(1.0, 0.85, 0.45, 0.55), 56.0, 0.0)
	# Spawn portal — only on multi-route maps (single-topology spawn is at
	# the edge of the path, already visually obvious).
	if board.routes.size() > 1:
		var first: Dictionary = board.routes[0]
		var chain: Array = first.get("path_chain", [])
		if not chain.is_empty():
			var spawn_tile: Vector2i = chain[0]
			var pos: Vector2 = board.grid.grid_to_world(spawn_tile.x, spawn_tile.y)
			_add_pulse(pos, Color(0.55, 0.35, 0.95, 0.65), 40.0, 1.0)

func _make_dust(viewport_size: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.name = "Dust"
	p.amount = DUST_AMOUNT
	p.lifetime = DUST_LIFETIME
	p.preprocess = DUST_LIFETIME * 0.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = viewport_size * 0.65
	p.position = viewport_size * 0.5
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 18.0
	p.direction = Vector2(1, -0.15)
	p.spread = 30.0
	p.scale_amount_min = 0.45
	p.scale_amount_max = 1.25
	p.color = Color(1.0, 0.95, 0.85, 0.22)
	p.texture = _circle_texture(8)
	p.z_index = 4
	add_child(p)

func _add_pulse(pos: Vector2, color: Color, base_radius: float, spin_rate: float) -> void:
	var node := Node2D.new()
	node.position = pos
	add_child(node)
	var sprite := Sprite2D.new()
	sprite.texture = _circle_texture(64)
	var s: float = (base_radius * 2.0) / 64.0
	sprite.scale = Vector2(s, s)
	sprite.modulate = color
	sprite.z_index = -2  # behind units, in front of background
	node.add_child(sprite)
	_pulses.append({
		"sprite": sprite,
		"base_color": color,
		"base_scale": Vector2(s, s),
		"phase": randf() * PULSE_PERIOD,
		"spin_rate": spin_rate,
		"node": node,
	})

func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for p in _pulses:
		var s: float = (sin((t + p.phase) * TAU / PULSE_PERIOD) + 1.0) * 0.5
		var c: Color = p.base_color
		p.sprite.modulate = Color(c.r, c.g, c.b, c.a * (0.55 + 0.45 * s))
		p.sprite.scale = p.base_scale * (0.92 + 0.14 * s)
		if p.spin_rate != 0.0:
			p.node.rotation += p.spin_rate * delta

func _circle_texture(size: int) -> ImageTexture:
	if _circle_tex_cache.has(size):
		return _circle_tex_cache[size]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size, size) * 0.5
	var r: float = size * 0.5
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= r:
				var t: float = 1.0 - (d / r)
				t = t * t  # quadratic soft edge
				img.set_pixel(x, y, Color(1, 1, 1, t))
	var tex := ImageTexture.create_from_image(img)
	_circle_tex_cache[size] = tex
	return tex
