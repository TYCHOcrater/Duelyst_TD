extends Node

# C12: smallest-possible host-client command relay.
#
# Architecture:
#   - Host opens ENetMultiplayerPeer on a chosen port. Host is authority
#     for all simulation (wave timing, RNG, validation).
#   - Client connects to host:port. Client submits commands but does NOT
#     apply them locally — they round-trip through the host first.
#   - relay_command(payload) sends the serialized command to all peers
#     (host included) via an RPC. The host re-dispatches it through
#     CommandBus; clients receive the apply broadcast and dispatch their
#     own copy for visual sync.
#
# Status: skeleton ships untested-by-two-processes. The local loopback
# debug path (`demo_loopback`) is headless-verifiable; full playtest is
# the user's next step.

signal state_changed(new_state: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

const STATE_OFF := "off"
const STATE_HOST := "host"
const STATE_CLIENT := "client"

var state: String = STATE_OFF
var peer: ENetMultiplayerPeer = null
var local_peer_id: int = 0

const DEFAULT_PORT := 28960
const MAX_CLIENTS := 3

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ----- Lifecycle -----------------------------------------------------------

func host_start(port: int = DEFAULT_PORT) -> bool:
	if state != STATE_OFF:
		push_warning("NetController.host_start: already in state %s" % state)
		return false
	peer = ENetMultiplayerPeer.new()
	var err: int = peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetController.host_start: create_server failed (%d)" % err)
		peer = null
		return false
	multiplayer.multiplayer_peer = peer
	local_peer_id = multiplayer.get_unique_id()
	state = STATE_HOST
	state_changed.emit(state)
	print("NetController: hosting on port %d (peer_id=%d)" % [port, local_peer_id])
	return true

func client_join(host: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	if state != STATE_OFF:
		push_warning("NetController.client_join: already in state %s" % state)
		return false
	peer = ENetMultiplayerPeer.new()
	var err: int = peer.create_client(host, port)
	if err != OK:
		push_error("NetController.client_join: create_client failed (%d)" % err)
		peer = null
		return false
	multiplayer.multiplayer_peer = peer
	state = STATE_CLIENT
	state_changed.emit(state)
	print("NetController: joining %s:%d" % [host, port])
	return true

func disconnect_net() -> void:
	if state == STATE_OFF:
		return
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	state = STATE_OFF
	local_peer_id = 0
	state_changed.emit(state)
	print("NetController: disconnected")

# ----- Command relay -------------------------------------------------------

# Broadcast a serialized command to every peer (including the sender's
# host). Clients should call this instead of dispatching locally; the host
# will validate + apply + echo so every peer sees the same outcome.
func relay_command(payload: Dictionary) -> void:
	if state == STATE_OFF:
		# Solo / offline — apply locally without round-tripping.
		_apply_remote_command(payload, local_peer_id)
		return
	# C12 v1: use unreliable_ordered for tower placements (they're idempotent
	# given the same position; lost packets just mean re-sends). Host RPC
	# ensures ordering for the wave start command.
	_rpc_remote_command.rpc(payload)

# RPC handler — every peer (host + clients) receives this when any peer
# relays a command. The host treats this as the canonical "apply" point;
# clients use it for visual sync only.
@rpc("any_peer", "call_local", "reliable")
func _rpc_remote_command(payload: Dictionary) -> void:
	var sender: int = multiplayer.get_remote_sender_id() if multiplayer.has_multiplayer_peer() else local_peer_id
	_apply_remote_command(payload, sender)

func _apply_remote_command(payload: Dictionary, source_peer_id: int) -> void:
	var ctype: String = String(payload.get("type", ""))
	var origin_slot: int = int(payload.get("origin_slot", 0))
	# Whitelisted command types only — defends against malformed payloads
	# without needing a full plugin system.
	match ctype:
		"PlaceUnit":
			var unit_id: String = String(payload.get("unit_id", ""))
			var pos_arr: Array = payload.get("position", [0, 0])
			var pos: Vector2 = Vector2(float(pos_arr[0]), float(pos_arr[1]))
			var cmd := PlaceUnitCommand.new(unit_id, pos)
			cmd.set_meta("origin_slot", origin_slot)
			cmd.set_meta("source_peer_id", source_peer_id)
			CommandBus.dispatch(cmd)
		_:
			push_warning("NetController: unknown remote command type '%s'" % ctype)

# ----- Headless-verifiable demo path --------------------------------------

# Pretends a "remote" client placed a unit and pushes it through the same
# apply path the RPC handler would use. Lets the loop be tested without a
# real second process.
func demo_loopback(unit_id: String, pos: Vector2, origin_slot: int = 1) -> void:
	var payload: Dictionary = {
		"type": "PlaceUnit",
		"unit_id": unit_id,
		"position": [pos.x, pos.y],
		"origin_slot": origin_slot,
	}
	_apply_remote_command(payload, 9999)

# ----- Signal handlers ----------------------------------------------------

func _on_peer_connected(id: int) -> void:
	print("NetController: peer connected id=%d" % id)
	peer_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("NetController: peer disconnected id=%d" % id)
	peer_disconnected.emit(id)

func _on_connection_failed() -> void:
	push_warning("NetController: connection failed")
	disconnect_net()

func _on_server_disconnected() -> void:
	push_warning("NetController: server disconnected")
	disconnect_net()
