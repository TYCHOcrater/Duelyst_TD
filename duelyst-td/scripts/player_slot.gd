extends RefCounted

# PlayerSlot: per-player state holder. For C0 (plumbing) most fields are
# placeholders that C1+ fills in:
#   - C1 adds route_id pointing at a route in the CoopMapDef.
#   - C2 wires per-route enemy spawning into the slot.
#   - C3 enforces placement zone ownership against this slot.
#   - C6 reads gate_shield for the route's UI.
#
# In solo (player_count = 1), slot 0 is a thin proxy over the existing
# GameState autoload — gold/lives etc. still live on GameState. Once C2+
# moves per-route state here, GameState becomes a slot-0 convenience accessor.

const DEFAULT_COLORS := [
	Color(0.55, 0.85, 1.0, 1.0),   # P1 — frost blue
	Color(1.00, 0.85, 0.45, 1.0),  # P2 — gold
	Color(1.00, 0.55, 0.55, 1.0),  # P3 — coral
	Color(0.60, 1.00, 0.65, 1.0),  # P4 — green
]

var slot_id: int = 0
var display_name: String = "P1"
var color: Color = Color.WHITE
var route_id: String = ""        # populated by C1 once CoopMapDef exists; C3 may join multiple ids with ","
var gate_shield: int = 0         # populated by C6
var ready_for_wave: bool = false  # C4 uses this for synced phases
var aid_tokens: int = 0          # C7 — granted by SessionController.configure
# C3: keyset of Vector2i tile coordinates this slot is allowed to build on.
# Populated by SessionController.assign_routes() at map-load time.
# Empty dict => no zone yet known (caller should treat as "everywhere ok").
var owned_tiles: Dictionary = {}

# Per-slot summary stats. For solo (slot 0), C2+ will source these from the
# existing GameState/RunLog when wave processing is split per route.
var stats: Dictionary = {
	"units_placed": 0,
	"leaks": 0,
	"core_damage_taken": 0,
}

func _init(id: int = 0) -> void:
	slot_id = id
	display_name = "P%d" % (id + 1)
	color = DEFAULT_COLORS[clamp(id, 0, DEFAULT_COLORS.size() - 1)]

func to_dict() -> Dictionary:
	return {
		"slot_id": slot_id,
		"display_name": display_name,
		"route_id": route_id,
		"gate_shield": gate_shield,
		"aid_tokens": aid_tokens,
		"stats": stats.duplicate(),
	}

# C3: returns true if this slot is allowed to place a tower on `gp`.
# Empty owned_tiles dict means ownership has not been assigned yet — treat
# permissively (don't break the run on un-configured maps).
func owns_tile(gp: Vector2i) -> bool:
	if owned_tiles.is_empty():
		return true
	return owned_tiles.has(gp)
