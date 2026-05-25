extends Node

# VfxRouter (D10 of the ingestion milestone) — event-driven VFX dispatch with
# the same throttling shape as AudioManager.play_event. Mirrors D9 deliberately
# so call sites learn one pattern.
#
# play_event(event_id, world_pos: Vector2 = Vector2.ZERO, parent: Node = null)
#   Looks up data/duelyst/vfx_events.json, applies cooldown + max_simultaneous,
#   and (when an archetype is wired) spawns the visual at world_pos parented to
#   `parent`. For now every archetype is null — call sites can wire events
#   today and the visuals land when concrete archetypes register via
#   register_archetype(id, PackedScene).
#
# Why an autoload Node: shared cooldown/in-flight state across the run.

const EVENTS_PATH := "res://data/duelyst/vfx_events.json"
const DEFAULT_LIFETIME_MS := 800  # how long a spawned VFX counts toward max_simultaneous

var _events: Dictionary = {}              # event_id -> cfg
var _archetypes: Dictionary = {}          # vfx_id -> PackedScene (registered at runtime)
var _last_fire_ms: Dictionary = {}        # event_id -> Time.get_ticks_msec()
var _in_flight: Dictionary = {}           # event_id -> active voice count

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func register_archetype(vfx_id: String, scene: PackedScene) -> void:
	# Lets feature code register a PackedScene at runtime so the router can
	# spawn it on the matching event. Future iterations may auto-register
	# from a res://assets/duelyst/vfx/<vfx_id>.tscn convention.
	_archetypes[vfx_id] = scene

func play_event(event_id: String, world_pos: Vector2 = Vector2.ZERO, parent: Node = null) -> bool:
	if not _events.has(event_id):
		push_warning("VfxRouter: unknown event '%s'" % event_id)
		return false
	var cfg: Dictionary = _events[event_id]
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
	get_tree().create_timer(DEFAULT_LIFETIME_MS / 1000.0).timeout.connect(func():
		_in_flight[event_id] = max(0, int(_in_flight.get(event_id, 1)) - 1)
	)
	# Actually spawn the visual if an archetype is registered.
	var vfx_id: Variant = cfg.get("vfx_id", null)
	if vfx_id == null or String(vfx_id) == "":
		# Planned event, no asset — silent success.
		return true
	if not _archetypes.has(String(vfx_id)):
		# Asset id named but not registered — silent (caller didn't load it yet).
		return true
	var scene: PackedScene = _archetypes[String(vfx_id)]
	var inst: Node = scene.instantiate()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(inst)
	if inst is Node2D:
		(inst as Node2D).global_position = world_pos
	return true
