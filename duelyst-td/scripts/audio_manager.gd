extends Node

const SFX_PATHS := {
	"place_tower": "res://assets/sfx/place_tower.ogg",
	"ui_select": "res://assets/sfx/ui_select.ogg",
	"wave_start": "res://assets/sfx/wave_start.ogg",
	"tower_archer_shoot": "res://assets/sfx/tower_archer_shoot.ogg",
	"tower_caster_shoot": "res://assets/sfx/tower_caster_shoot.ogg",
	"enemy_death": "res://assets/sfx/enemy_death.ogg",
	"base_hit": "res://assets/sfx/base_hit.ogg",
}

const SFX_VOLUMES := {
	"place_tower": -4.0,
	"ui_select": -8.0,
	"wave_start": -2.0,
	"tower_archer_shoot": -10.0,
	"tower_caster_shoot": -6.0,
	"enemy_death": -8.0,
	"base_hit": 0.0,
}

# Pool of players per sound so overlapping plays don't clip each other.
const POOL_SIZE := 4
var _pools: Dictionary = {}
var _next_index: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SFX_PATHS:
		var stream: AudioStream = load(SFX_PATHS[name])
		var pool: Array[AudioStreamPlayer] = []
		for i in POOL_SIZE:
			var player := AudioStreamPlayer.new()
			player.stream = stream
			player.volume_db = SFX_VOLUMES.get(name, 0.0)
			player.bus = "Master"
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(player)
			pool.append(player)
		_pools[name] = pool
		_next_index[name] = 0

func play(name: String, pitch_variance: float = 0.0) -> void:
	if not _pools.has(name):
		push_warning("AudioManager: unknown sfx '%s'" % name)
		return
	var pool: Array[AudioStreamPlayer] = _pools[name]
	var idx: int = _next_index[name]
	var player := pool[idx]
	_next_index[name] = (idx + 1) % pool.size()
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	else:
		player.pitch_scale = 1.0
	player.play()
