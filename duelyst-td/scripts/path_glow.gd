extends Node2D

@export var glow_texture: Texture2D
@export var spacing: float = 70.0
@export var modulate_color: Color = Color(1.0, 0.85, 0.4, 0.65)
@export var scale_factor: float = 0.7

func setup(curve: Curve2D) -> void:
	for c in get_children():
		c.queue_free()
	if not curve or not glow_texture:
		return
	var total: float = curve.get_baked_length()
	var d: float = 0.0
	while d <= total:
		var pos: Vector2 = curve.sample_baked(d)
		var s := Sprite2D.new()
		s.texture = glow_texture
		s.modulate = modulate_color
		s.scale = Vector2(scale_factor, scale_factor)
		s.position = pos
		add_child(s)
		d += spacing
