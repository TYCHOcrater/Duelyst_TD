extends Node

# Deterministic RNG keyed off a session seed. Use for ALL gameplay randomness
# (draft offers, wave variants, pacts, map gen) so a seed reproduces a run.
# UI randomness (banner shake, hit flash etc.) can use the global RNG.

var seed: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	# Default to time-based seed; can be overridden via set_seed() per run.
	set_seed(Time.get_unix_time_from_system())

func set_seed(s: int) -> void:
	# Critical: setting `seed` already derives a seed-specific PCG state.
	# Do NOT also assign `_rng.state = 0` — that clobbers the seed-derived
	# state and lands every seed on the same RNG starting point (bug:
	# wave-1 offers were identical across all seeds).
	seed = s
	_rng.seed = s

func reset() -> void:
	# Re-seed with the same seed; this re-derives the seed-specific state.
	_rng.seed = seed

func randi() -> int:
	return _rng.randi()

func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)

func randf() -> float:
	return _rng.randf()

func randf_range(a: float, b: float) -> float:
	return _rng.randf_range(a, b)

func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[_rng.randi() % arr.size()]

func pick_weighted(items: Array, weights: Array):
	# items: any array. weights: parallel array of floats. Returns chosen item.
	var total: float = 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return pick(items)
	var r := _rng.randf() * total
	var acc := 0.0
	for i in items.size():
		acc += weights[i]
		if r <= acc:
			return items[i]
	return items[items.size() - 1]

func shuffle(arr: Array) -> Array:
	var copy: Array = arr.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy

func format_seed(s: int = -1) -> String:
	if s < 0:
		s = seed
	return "SHARD-%08X" % (s & 0xFFFFFFFF)
