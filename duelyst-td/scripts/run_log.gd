extends Node

# RunLog: records every event in a run. Foundation for run identity,
# failure coach, balance reports, daily seed scoring, replays.

signal event_recorded(event: Dictionary)
signal stats_changed(stats: Dictionary)

const MAX_EVENTS := 10000  # safety cap

var events: Array = []
var run_start_time_unix: float = 0.0
var stats: Dictionary = {}
var active: bool = false

func start_run(seed_value: int) -> void:
	events.clear()
	run_start_time_unix = Time.get_unix_time_from_system()
	stats = {
		"seed": seed_value,
		"growth_mode": RunConfig.growth_mode,
		"map_source": RunConfig.map_source,
		"map_id": RunConfig.custom_map_id,
		"player_count": RunConfig.player_count,
		"session_topology": RunConfig.session_topology,
		"player_slots": [],  # populated by SessionController via record_player_slots()
		"started_at": run_start_time_unix,
		"wave_reached": 0,
		"gold_earned": 0,
		"gold_spent": 0,
		"units_bought": 0,
		"units_sold": 0,
		"units_upgraded": 0,
		"rerolls": 0,
		"enemies_killed": 0,
		"leaks": 0,
		"damage_dealt": 0,
		"core_damage_taken": 0,
		"interest_earned": 0,
		"max_gold_floated": 0,
		"result": "in_progress",
		# Breakdown dicts (populated in record()).
		"damage_by_unit": {},
		"kills_by_enemy": {},
		"leaks_by_enemy": {},
		"leaks_by_wave": {},
		"placements_by_faction": {},
		"placements_by_unit": {},
		"pacts": [],
		"relics": [],
		"traits_taken": {},
		"flaws_taken": {},
		"evolutions_by_tier": {"1": 0, "2": 0, "3": 0},
		# A2 per-unit-instance tracking. Each placed tower gets an entry keyed
		# by its instance_id; values record per-instance damage, kills, waves
		# survived, traits/flaws, and a final disposition.
		"instances": {},
		"_instance_counter": 0,
		# A4 duplicate-shard system. base_unit_id -> shard count. Shards
		# accumulate from duplicate purchases and (A5) feed star upgrades.
		"shards": {},
	}
	active = true
	record("run_start", {"seed": seed_value})
	stats_changed.emit(stats)

func end_run(result: String) -> void:
	if not active:
		return
	stats["result"] = result
	stats["ended_at"] = Time.get_unix_time_from_system()
	stats["final_gold"] = GameState.gold
	stats["final_lives"] = GameState.lives
	record("run_end", {"result": result, "stats": stats.duplicate()})
	active = false
	save_to_file()
	Mastery.record_run(stats)
	stats_changed.emit(stats)

func record(event_type: String, data: Dictionary = {}) -> void:
	if events.size() >= MAX_EVENTS:
		return
	var e := {
		"t": Time.get_unix_time_from_system() - run_start_time_unix,
		"type": event_type,
		"data": data,
	}
	events.append(e)
	match event_type:
		"buy_offer":
			stats["units_bought"] += 1
			stats["gold_spent"] += int(data.get("cost", 0))
			stats["gold_spent_on_units"] = int(stats.get("gold_spent_on_units", 0)) + int(data.get("cost", 0))
			var unit_id := String(data.get("unit", ""))
			if unit_id != "":
				var by_unit: Dictionary = stats["placements_by_unit"]
				by_unit[unit_id] = int(by_unit.get(unit_id, 0)) + 1
			var faction := String(data.get("faction", ""))
			if faction != "":
				var by_fac: Dictionary = stats["placements_by_faction"]
				by_fac[faction] = int(by_fac.get(faction, 0)) + 1
			var trait_id := String(data.get("trait", ""))
			if trait_id != "":
				var traits_taken: Dictionary = stats["traits_taken"]
				traits_taken[trait_id] = int(traits_taken.get(trait_id, 0)) + 1
			var flaw_id := String(data.get("flaw", ""))
			if flaw_id != "":
				var flaws_taken: Dictionary = stats["flaws_taken"]
				flaws_taken[flaw_id] = int(flaws_taken.get(flaw_id, 0)) + 1
		"sell_unit":
			stats["units_sold"] += 1
			stats["gold_earned"] += int(data.get("refund", 0))
		"upgrade_unit":
			stats["units_upgraded"] += 1
			stats["gold_spent"] += int(data.get("cost", 0))
			stats["gold_spent_on_growth"] = int(stats.get("gold_spent_on_growth", 0)) + int(data.get("cost", 0))
		"reroll":
			stats["rerolls"] += 1
			stats["gold_spent"] += int(data.get("cost", 0))
			stats["gold_spent_on_rerolls"] = int(stats.get("gold_spent_on_rerolls", 0)) + int(data.get("cost", 0))
		"shard_purchased":
			# A4 shard buy: BuyOfferCommand calls GameState.spend_gold directly
			# (not through buy_offer), so neither gold_spent nor the per-bucket
			# breakdown was updating. Mirror both here.
			stats["gold_spent"] = int(stats.get("gold_spent", 0)) + int(data.get("cost", 0))
			stats["gold_spent_on_growth"] = int(stats.get("gold_spent_on_growth", 0)) + int(data.get("cost", 0))
		"star_promoted":
			stats["star_promotions"] = int(stats.get("star_promotions", 0)) + 1
		"evolution_chosen":
			stats["evolutions_chosen"] = int(stats.get("evolutions_chosen", 0)) + 1
		"enemy_killed":
			stats["enemies_killed"] += 1
			stats["gold_earned"] += int(data.get("reward", 0))
			var ek_id := String(data.get("enemy_id", ""))
			if ek_id != "":
				var k: Dictionary = stats["kills_by_enemy"]
				k[ek_id] = int(k.get(ek_id, 0)) + 1
		"leak":
			stats["leaks"] += 1
			stats["core_damage_taken"] += int(data.get("damage", 0))
			var lk_id := String(data.get("enemy_id", ""))
			if lk_id != "":
				var le: Dictionary = stats["leaks_by_enemy"]
				le[lk_id] = int(le.get(lk_id, 0)) + 1
			var lk_wave := int(data.get("wave", 0))
			if lk_wave > 0:
				var lw: Dictionary = stats["leaks_by_wave"]
				lw[str(lk_wave)] = int(lw.get(str(lk_wave), 0)) + 1
		"damage_dealt":
			stats["damage_dealt"] += int(data.get("amount", 0))
		"wave_start":
			stats["wave_reached"] = max(stats.get("wave_reached", 0), int(data.get("wave", 0)))
		"pact_chosen":
			var pid := String(data.get("pact_id", ""))
			if pid != "":
				var pacts: Array = stats["pacts"]
				pacts.append(pid)
		"tower_evolved":
			var tier := int(data.get("tier", 0))
			if tier > 0:
				var key: String = str(tier)
				var by_tier: Dictionary = stats["evolutions_by_tier"]
				by_tier[key] = int(by_tier.get(key, 0)) + 1
		"relic_chosen":
			var rid := String(data.get("relic_id", ""))
			if rid != "":
				var rl: Array = stats["relics"]
				rl.append(rid)
		"planning_income":
			stats["gold_earned"] = int(stats.get("gold_earned", 0)) + int(data.get("total", 0))
			stats["interest_earned"] = int(stats.get("interest_earned", 0)) + int(data.get("interest", 0))
			var floated := int(data.get("floated_before", 0))
			if floated > int(stats.get("max_gold_floated", 0)):
				stats["max_gold_floated"] = floated
	event_recorded.emit(e)
	stats_changed.emit(stats)

# --- A2 unit-instance API ---

func register_unit_instance(base_unit_id: String, placed_wave: int, trait_id: String = "", flaw_id: String = "") -> String:
	# Generate a deterministic, human-readable id: "<base>#<n>". Counter
	# survives across waves within the run; resets at start_run.
	if not active:
		return ""
	var n: int = int(stats.get("_instance_counter", 0)) + 1
	stats["_instance_counter"] = n
	var id: String = "%s#%d" % [base_unit_id, n]
	var instances: Dictionary = stats.get("instances", {})
	instances[id] = {
		"base_unit_id": base_unit_id,
		"placed_at_wave": placed_wave,
		"trait_id": trait_id,
		"flaw_id": flaw_id,
		"damage": 0,
		"kills": 0,
		"waves_survived": 0,
		"final_state": "active",
	}
	stats["instances"] = instances
	stats_changed.emit(stats)
	return id

func add_damage_to_instance(instance_id: String, amount: int) -> void:
	if not active or amount <= 0 or instance_id == "":
		return
	var instances: Dictionary = stats.get("instances", {})
	if not instances.has(instance_id):
		return
	var inst: Dictionary = instances[instance_id]
	inst["damage"] = int(inst.get("damage", 0)) + amount

func add_kill_to_instance(instance_id: String) -> void:
	if not active or instance_id == "":
		return
	var instances: Dictionary = stats.get("instances", {})
	if not instances.has(instance_id):
		return
	var inst: Dictionary = instances[instance_id]
	inst["kills"] = int(inst.get("kills", 0)) + 1

func bump_waves_survived(instance_id: String) -> void:
	if not active or instance_id == "":
		return
	var instances: Dictionary = stats.get("instances", {})
	if not instances.has(instance_id):
		return
	var inst: Dictionary = instances[instance_id]
	inst["waves_survived"] = int(inst.get("waves_survived", 0)) + 1

func finalize_unit_instance(instance_id: String, reason: String) -> void:
	# reason: "sold", "removed", "victory_alive" — recorded so the summary
	# can distinguish a unit that was sold for refund vs one that survived.
	if not active or instance_id == "":
		return
	var instances: Dictionary = stats.get("instances", {})
	if not instances.has(instance_id):
		return
	var inst: Dictionary = instances[instance_id]
	inst["final_state"] = reason
	inst["ended_at_wave"] = int(stats.get("wave_reached", 0))

func top_instance_by_damage() -> Dictionary:
	# Returns the single highest-damage instance entry plus its id, or {} if
	# no instances. Used by the run-summary panel.
	var best_id: String = ""
	var best_damage: int = -1
	var instances: Dictionary = stats.get("instances", {})
	for id in instances:
		var d: int = int((instances[id] as Dictionary).get("damage", 0))
		if d > best_damage:
			best_damage = d
			best_id = String(id)
	if best_id == "":
		return {}
	var out: Dictionary = (instances[best_id] as Dictionary).duplicate()
	out["instance_id"] = best_id
	return out

# --- A4 duplicate-shard system ---

func add_shard(base_unit_id: String, amount: int = 1) -> int:
	# Returns the new shard count for this base unit. No-op (returns 0) if
	# the run isn't active.
	if not active or base_unit_id == "":
		return 0
	var shards: Dictionary = stats.get("shards", {})
	var current: int = int(shards.get(base_unit_id, 0)) + amount
	shards[base_unit_id] = current
	stats["shards"] = shards
	record("shard_added", {"unit": base_unit_id, "count": current})
	return current

func shard_count(base_unit_id: String) -> int:
	var shards: Dictionary = stats.get("shards", {})
	return int(shards.get(base_unit_id, 0))

func consume_shards(base_unit_id: String, amount: int) -> bool:
	if not active:
		return false
	var shards: Dictionary = stats.get("shards", {})
	var current: int = int(shards.get(base_unit_id, 0))
	if current < amount:
		return false
	shards[base_unit_id] = current - amount
	stats["shards"] = shards
	return true

func record_player_slots(slots: Array) -> void:
	# Called once by SessionController after it configures the slot list.
	if not active:
		return
	stats["player_slots"] = slots
	stats_changed.emit(stats)

func add_damage(amount: int, source_id: String = "") -> void:
	# Lightweight stats-only update for high-frequency events; no per-hit event.
	if not active or amount <= 0:
		return
	stats["damage_dealt"] = int(stats.get("damage_dealt", 0)) + amount
	if source_id != "":
		var by_unit: Dictionary = stats.get("damage_by_unit", {})
		by_unit[source_id] = int(by_unit.get(source_id, 0)) + amount
		stats["damage_by_unit"] = by_unit
	stats_changed.emit(stats)

func recent_events(count: int = 20) -> Array:
	var n := events.size()
	if n <= count:
		return events.duplicate()
	return events.slice(n - count, n)

func export_string() -> String:
	return JSON.stringify({
		"stats": stats,
		"events": events,
	}, "  ")

func save_to_file(path: String = "") -> String:
	if path == "":
		var ts := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		path = "user://run_log_%s.json" % ts
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(export_string())
		f.close()
		print("RunLog: saved to %s" % path)
	return path
