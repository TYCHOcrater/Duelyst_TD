extends Node2D

@onready var hp_bar: Node2D = $HealthBar
var _last_lives: int = GameState.START_LIVES

func _ready() -> void:
	GameState.lives_changed.connect(_on_lives_changed)
	_last_lives = GameState.lives
	_on_lives_changed(GameState.lives)

func _on_lives_changed(v: int) -> void:
	var ratio := float(v) / float(GameState.START_LIVES)
	hp_bar.set_ratio(ratio)
	# Flash + small impact burst when the Core actually takes damage so the
	# base node reads as hit on the map (not just in the HUD LivesBox).
	if v < _last_lives:
		hp_bar.modulate = Color(1.7, 0.5, 0.5, 1.0)
		var tw := create_tween()
		tw.tween_property(hp_bar, "modulate", Color.WHITE, 0.5)
		var host: Node = get_tree().current_scene
		if host:
			CombatFX.burst(host, global_position, Color(1.0, 0.4, 0.3), 12, 1.2)
	_last_lives = v
