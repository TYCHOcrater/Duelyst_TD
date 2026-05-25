class_name ModifierTotals
extends RefCounted

# Aggregates effect totals across all modifier sources (currently pacts +
# relics). Game systems should query this instead of touching the managers
# directly so future modifier types (e.g. unit traits, map tile effects)
# can be added without finding every callsite.

static func sum_int(effect_type: String) -> int:
	return PactManager.sum_int(effect_type) + RelicManager.sum_int(effect_type)

static func product_float(effect_type: String) -> float:
	return PactManager.product_float(effect_type) * RelicManager.product_float(effect_type)

static func has_flag(effect_type: String) -> bool:
	return PactManager.has_flag(effect_type) or RelicManager.has_flag(effect_type)
