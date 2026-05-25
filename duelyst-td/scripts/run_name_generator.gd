class_name RunNameGenerator
extends RefCounted

# Builds a "<Adjective> <Faction> <Theme>" title from a RunLog stats dict.

const FACTION_THEMES := {
	"lyonar":    "Citadel",
	"songhai":   "Rooftop",
	"vetruvian": "Bazaar",
	"abyssian":  "Choir",
	"magmar":    "Stampede",
	"vanar":     "Frostpass",
	"neutral":   "Crew",
}

const FACTION_DISPLAY := {
	"lyonar":    "Lyonar",
	"songhai":   "Songhai",
	"vetruvian": "Vetruvian",
	"abyssian":  "Abyssian",
	"magmar":    "Magmar",
	"vanar":     "Vanar",
	"neutral":   "Neutral",
}

static func generate(stats: Dictionary) -> String:
	# Dominant faction by placements.
	var by_faction: Dictionary = stats.get("placements_by_faction", {})
	var dominant := "neutral"
	var best: int = -1
	for f in by_faction:
		var n := int(by_faction[f])
		if n > best:
			best = n
			dominant = f
	# Adjective: first pact wins; if no pacts but a relic was taken, use that.
	var adj := "Wandering"
	var pact_ids: Array = stats.get("pacts", [])
	if pact_ids.size() > 0:
		var def: Dictionary = PactManager.get_def(pact_ids[0])
		adj = def.get("run_adjective", "Bound")
	else:
		var relic_ids: Array = stats.get("relics", [])
		if relic_ids.size() > 0:
			var rdef: Dictionary = RelicManager.get_def(relic_ids[0])
			adj = rdef.get("run_adjective", "Blessed")
	# Special case: no units bought at all → very different title.
	if best <= 0:
		return "%s Wanderer" % adj
	var faction_label: String = FACTION_DISPLAY.get(dominant, dominant.capitalize())
	var theme: String = FACTION_THEMES.get(dominant, "Crew")
	return "%s %s %s" % [adj, faction_label, theme]
