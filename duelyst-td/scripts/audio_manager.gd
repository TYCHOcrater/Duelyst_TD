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

const EVENTS_PATH := "res://data/duelyst/sfx_events.json"
var _events: Dictionary = {}                    # event_id -> {sfx_id, priority, cooldown_ms, max_simultaneous}
var _last_fire_ms: Dictionary = {}              # event_id -> Time.get_ticks_msec() of last play
var _in_flight: Dictionary = {}                 # event_id -> int active voice count

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in SFX_PATHS:
		if not ResourceLoader.exists(SFX_PATHS[name]):
			# Skip missing files gracefully; play_event() will route around them.
			continue
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
	_load_events()

func _load_events() -> void:
	if not FileAccess.file_exists(EVENTS_PATH):
		return
	var f := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var events: Dictionary = parsed.get("events", {})
	for event_id in events:
		_events[event_id] = events[event_id]

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

# Event-driven dispatch (D9). Looks up sfx_id from data/duelyst/sfx_events.json,
# applies per-event throttle (cooldown_ms + max_simultaneous), and routes to
# the existing pooled play() — so per-sound voice pooling still applies on top.
# Events with sfx_id=null (planned but no audio yet) silently succeed; events
# without an entry get a warning.
func play_event(event_id: String, pitch_variance: float = 0.0) -> bool:
	if not _events.has(event_id):
		push_warning("AudioManager: unknown event '%s'" % event_id)
		return false
	var cfg: Dictionary = _events[event_id]
	var sfx_id: Variant = cfg.get("sfx_id", null)
	if sfx_id == null or String(sfx_id) == "":
		# Planned event without audio yet — successful no-op so call sites
		# don't crash and the routing flow still records the intent.
		return true
	# Cooldown gate.
	var now: int = Time.get_ticks_msec()
	var last: int = int(_last_fire_ms.get(event_id, 0))
	var cooldown: int = int(cfg.get("cooldown_ms", 0))
	if now - last < cooldown:
		return false
	# Voice cap gate.
	var max_simul: int = int(cfg.get("max_simultaneous", 4))
	var current: int = int(_in_flight.get(event_id, 0))
	if current >= max_simul:
		return false
	_last_fire_ms[event_id] = now
	_in_flight[event_id] = current + 1
	# Decrement in-flight after the typical SFX length (~1.2s default).
	# Cheap fixed-duration approximation — we don't track per-stream lengths.
	get_tree().create_timer(1.2).timeout.connect(func(): _in_flight[event_id] = max(0, int(_in_flight.get(event_id, 1)) - 1))
	play(String(sfx_id), pitch_variance)
	return true
