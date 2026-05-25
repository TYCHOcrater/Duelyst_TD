extends Node

signal gold_changed(value: int)
signal lives_changed(value: int)
signal wave_changed(value: int)
signal game_over(victory: bool)

const START_GOLD := 20
const START_LIVES := 20

var gold: int = START_GOLD
var lives: int = START_LIVES
var wave: int = 0
var game_running: bool = true

func reset() -> void:
	gold = START_GOLD
	lives = START_LIVES
	wave = 0
	game_running = true
	gold_changed.emit(gold)
	lives_changed.emit(lives)
	wave_changed.emit(wave)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func take_damage(amount: int) -> void:
	if not game_running:
		return
	lives = max(0, lives - amount)
	lives_changed.emit(lives)
	if lives <= 0:
		game_running = false
		game_over.emit(false)

func set_wave(w: int) -> void:
	wave = w
	wave_changed.emit(wave)

func declare_victory() -> void:
	if not game_running:
		return
	game_running = false
	game_over.emit(true)
