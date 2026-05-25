extends Node

signal offers_changed(offers: Array)  # Array of unit_id strings

const BASE_SHOP_SIZE := 3  # number of offers per wave (before pact deltas)
const REROLL_BASE := 2
const REROLL_INCREMENT := 1

func effective_shop_size() -> int:
	return max(1, BASE_SHOP_SIZE + ModifierTotals.sum_int("shop_size_delta"))

var current_offers: Array[String] = []
var current_traits: Array[String] = []  # parallel; "" = no trait
var current_flaws: Array[String] = []   # parallel; "" = no flaw
var rerolls_this_phase: int = 0

func generate_offers(wave: int) -> void:
	rerolls_this_phase = 0
	_roll_offers(wave)

func reroll_cost() -> int:
	return REROLL_BASE + rerolls_this_phase * REROLL_INCREMENT + ModifierTotals.sum_int("reroll_cost_delta")

func try_reroll(wave: int) -> bool:
	var cost := reroll_cost()
	if not GameState.spend_gold(cost):
		return false
	rerolls_this_phase += 1
	_roll_offers(wave)
	return true

func _roll_offers(wave: int) -> void:
	current_offers = _make_offers(wave)
	current_traits = []
	current_flaws = []
	for unit_id in current_offers:
		var udef: Dictionary = UnitFactory.get_def(unit_id)
		var tid := TraitManager.maybe_roll(udef, wave)
		var fid := FlawManager.maybe_roll(udef, wave, tid)
		current_traits.append(tid)
		current_flaws.append(fid)
	offers_changed.emit(current_offers)

func get_trait_for(idx: int) -> String:
	if idx < 0 or idx >= current_traits.size():
		return ""
	return current_traits[idx]

func get_flaw_for(idx: int) -> String:
	if idx < 0 or idx >= current_flaws.size():
		return ""
	return current_flaws[idx]

func consume_offer(unit_id: String) -> void:
	# Called after a unit is purchased. Remove from current_offers.
	for i in current_offers.size():
		if current_offers[i] == unit_id:
			current_offers.remove_at(i)
			if i < current_traits.size():
				current_traits.remove_at(i)
			if i < current_flaws.size():
				current_flaws.remove_at(i)
			break
	offers_changed.emit(current_offers)

func _make_offers(wave: int) -> Array[String]:
	# Weighted draft: at least one affordable, mix of factions, act-based scaling.
	var all := UnitFactory.all_ids()
	if all.is_empty():
		return [] as Array[String]
	var picks: Array[String] = []
	var pool: Array[String] = all.duplicate() as Array[String]
	# Guarantee one affordable offer.
	var affordable: Array[String] = []
	for id in pool:
		var def: Dictionary = UnitFactory.get_def(id)
		if int(def.get("cost", 0)) <= GameState.gold:
			affordable.append(id)
	if not affordable.is_empty():
		var pick: String = SessionRng.pick(affordable)
		picks.append(pick)
		pool.erase(pick)
	# Fill remaining slots with weighted picks.
	while picks.size() < effective_shop_size() and not pool.is_empty():
		var weights: Array[float] = []
		for id in pool:
			weights.append(_weight_for(id, wave))
		var pick: String = SessionRng.pick_weighted(pool, weights)
		picks.append(pick)
		pool.erase(pick)
	return picks

func _weight_for(unit_id: String, wave: int) -> float:
	var def: Dictionary = UnitFactory.get_def(unit_id)
	var cost: int = int(def.get("cost", 5))
	# Earlier waves favor cheap units; later waves open up.
	var ideal_cost: float = clampf(3.0 + wave * 0.6, 4.0, 12.0)
	var dist: float = abs(float(cost) - ideal_cost)
	var weight: float = 1.0 / (1.0 + dist * 0.3)
	# Pity rule: if the player has no AoE in current_offers, bump AoE weights.
	var ts: Array = def.get("tags", [])
	if "aoe" in ts and wave >= 3:
		weight *= 1.4
	if "control" in ts and wave >= 2:
		weight *= 1.2
	return weight
