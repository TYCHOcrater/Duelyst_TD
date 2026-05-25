class_name BuyOfferCommand
extends Command

# In the current 2-step UX, "buying" an offer just selects it for placement
# preview; gold is spent on PlaceUnitCommand. This makes the action explicit
# and revertable (cancel/right-click).

var offer_index: int

func _init(idx: int) -> void:
	offer_index = idx

func execute(main: Node) -> bool:
	var draft = main.draft_director
	var placement = main.placement
	if draft == null or placement == null:
		reason = "scene not bound"
		return false
	if main.phase_controller.phase != main.phase_controller.Phase.PLANNING:
		reason = "not in planning phase"
		return false
	if offer_index < 0 or offer_index >= draft.current_offers.size():
		reason = "offer index out of range"
		return false
	var unit_id: String = draft.current_offers[offer_index]
	var trait_id: String = draft.get_trait_for(offer_index)
	var flaw_id: String = draft.get_flaw_for(offer_index)
	# Toggle: clicking the same offer cancels.
	if placement.current_unit_id == unit_id and placement.current_trait_id == trait_id and placement.current_flaw_id == flaw_id:
		placement.cancel_selection()
	else:
		placement.select_unit_for_placement(unit_id, trait_id, flaw_id)
	success = true
	var suffix := ""
	if trait_id != "":
		suffix = " + " + trait_id
	if flaw_id != "":
		suffix += " / " + flaw_id
	reason = "selected offer #%d (%s%s)" % [offer_index, unit_id, suffix]
	return true

func describe() -> String:
	return "BuyOffer #%d" % offer_index
