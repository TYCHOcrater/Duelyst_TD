extends Node2D

@onready var hp_bar: Node2D = $HealthBar

func _ready() -> void:
	GameState.lives_changed.connect(_on_lives_changed)
	_on_lives_changed(GameState.lives)

func _on_lives_changed(v: int) -> void:
	var ratio := float(v) / float(GameState.START_LIVES)
	hp_bar.set_ratio(ratio)
