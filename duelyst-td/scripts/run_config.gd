extends Node

# RunConfig: the parameters for the upcoming/current run.
# Set on the main menu, consumed by main.gd on run start.

const DEFAULT_MAX_WAVES := 10
const DEFAULT_START_GOLD := 20
const DEFAULT_START_LIVES := 20

var seed: int = 0
var max_waves: int = DEFAULT_MAX_WAVES
var start_gold: int = DEFAULT_START_GOLD
var start_lives: int = DEFAULT_START_LIVES
var is_daily: bool = false

# Map source: "fixed" (builtin starter map), "generated" (procgen from seed),
# or "custom" (file in user://maps/<custom_map_id>.json). Set by the main menu
# before changing scene to main.tscn.
var map_source: String = "fixed"
var custom_map_id: String = ""

# Growth mode (Milestone A bake-off). Plumbing only for A1 — selects how units
# will grow during a run once the actual upgrade systems land in A3-A6:
#   "classic_upgrade"        — current per-unit gold upgrades (default; existing behavior)
#   "merge_stars"            — duplicate purchases promote star level (A4 + A5)
#   "merge_evolution_hybrid" — star levels also gate evolution branch picks (A6)
# Storing the mode now lets every later iteration check RunConfig.growth_mode
# instead of plumbing the flag through 6 separate scenes again.
const GROWTH_MODES := ["classic_upgrade", "merge_stars", "merge_evolution_hybrid"]
var growth_mode: String = "classic_upgrade"

# Co-op plumbing (Milestone C of the co-op/MP/arena addendum). For C0 these are
# data-only — real multi-route maps + per-slot economies land in C1+. Single
# player is just session_topology = "solo" with player_count = 1.
#   - player_count = 1..4
#   - session_topology:
#       "solo"     — one slot, existing single-board behavior
#       "starbase" — N slots routed into one shared Core (built starting at C1)
#       "debug"    — N slots but visible game still runs single-board for C0
const MIN_PLAYER_COUNT := 1
const MAX_PLAYER_COUNT := 4
const SESSION_TOPOLOGIES := ["solo", "starbase", "debug"]
var player_count: int = 1
var session_topology: String = "solo"

func set_player_count(n: int) -> void:
	player_count = clamp(n, MIN_PLAYER_COUNT, MAX_PLAYER_COUNT)
	# Auto-pick topology from player_count if the caller hasn't overridden.
	if player_count == 1:
		session_topology = "solo"
	elif session_topology == "solo":
		# Promote out of solo automatically when the user picks >1 players.
		session_topology = "debug"

func set_session_topology(topo: String) -> void:
	if topo in SESSION_TOPOLOGIES:
		session_topology = topo
	else:
		push_warning("RunConfig: unknown session_topology '%s'; keeping '%s'" % [topo, session_topology])

func set_growth_mode(mode: String) -> void:
	if mode in GROWTH_MODES:
		growth_mode = mode
	else:
		push_warning("RunConfig: unknown growth_mode '%s'; keeping '%s'" % [mode, growth_mode])

func growth_mode_label() -> String:
	match growth_mode:
		"classic_upgrade":        return "Classic Upgrade"
		"merge_stars":            return "Merge Stars"
		"merge_evolution_hybrid": return "Merge + Evolution"
		_:                        return growth_mode

func _ready() -> void:
	randomize_seed()

func randomize_seed() -> void:
	seed = randi()

func set_seed(s: int) -> void:
	seed = int(s)

func format_seed() -> String:
	return "SHARD-%08X" % (seed & 0xFFFFFFFF)

func parse_seed_text(text: String) -> int:
	# Accept "SHARD-XXXXXXXX", "0xHEX", "HEX" (8 hex chars), or plain decimal.
	var t := text.strip_edges().to_upper()
	if t.begins_with("SHARD-"):
		t = t.substr(6)
	if t.begins_with("0X"):
		t = t.substr(2)
	# All-hex 8-char string?
	var is_hex := t.length() > 0
	for c in t:
		if not (c in "0123456789ABCDEF"):
			is_hex = false
			break
	if is_hex and t.length() <= 8:
		return ("0x" + t).hex_to_int()
	if t.is_valid_int():
		return int(t)
	return -1  # signal parse failure
