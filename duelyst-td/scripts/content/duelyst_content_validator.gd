extends RefCounted

# DuelystContentValidator (D15 of the ingestion milestone).
#
# Checks every loaded content pack for broken references / missing fields /
# unbalanced shells / etc. Designed to run at boot from PackManager and emit
# warnings to the console, plus from a "Validate all packs" hub button that
# surfaces results in the UI.
#
# Validation rules:
#   - Each defender_shell must have id, faction, asset_profile_id, cost,
#     range, damage, fire_rate, damage_type.
#   - Each defender_unit_id must resolve via UnitFactory.get_def().
#   - Each shell's asset_profile_id must point to a real SpriteFrames .tres
#     under res://assets/units/<id>/<id>.tres.
#   - Each enemy_shell_id should appear in the D8 generated shells (if
#     enemy_shells.json exists; otherwise skipped, not an error).
#   - normal_run content (enabled_in_normal_runs=true) must NOT have
#     balance_state="generated_unbalanced" (promotion gate).
#   - No duplicate shell ids across all packs.

const REQUIRED_SHELL_FIELDS := ["id", "faction", "asset_profile_id", "cost", "range", "damage", "fire_rate", "damage_type"]
const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

# Returns {ok, errors: [], warnings: [], stats: {packs, shells, issues}}.
static func validate_all() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var packs_checked: int = 0
	var shells_checked: int = 0
	var all_shell_ids: Dictionary = {}  # id -> pack_id (for dupe detection)
	var enemy_shell_ids: Dictionary = _load_enemy_shell_ids()
	for pack_id in PackManager.all_pack_ids():
		var pack: Dictionary = PackManager.get_pack(String(pack_id))
		packs_checked += 1
		# Check pack-level required fields.
		for fld in ["id", "display_name", "faction", "balance_state"]:
			if not pack.has(fld):
				errors.append("Pack %s: missing required field '%s'" % [pack_id, fld])
		# Curated defender_unit_ids
		for uid in pack.get("defender_unit_ids", []):
			if UnitFactory.get_def(String(uid)).is_empty():
				errors.append("Pack %s: defender_unit_id '%s' has no def" % [pack_id, uid])
		# Inline defender_shells
		for shell in pack.get("defender_shells", []):
			shells_checked += 1
			var sid: String = String(shell.get("id", ""))
			for fld in REQUIRED_SHELL_FIELDS:
				if not shell.has(fld):
					errors.append("Pack %s shell %s: missing field '%s'" % [pack_id, sid, fld])
			# Sprite path
			var asset_id: String = String(shell.get("asset_profile_id", ""))
			if asset_id != "":
				var sf_path: String = "res://assets/units/%s/%s.tres" % [asset_id, asset_id]
				if not ResourceLoader.exists(sf_path):
					errors.append("Pack %s shell %s: SpriteFrames missing at %s (run tools/convert_units.py %s)" % [pack_id, sid, sf_path, asset_id])
			# Duplicate id check
			if sid != "":
				if all_shell_ids.has(sid):
					errors.append("Duplicate shell id '%s' (in '%s' and '%s')" % [sid, all_shell_ids[sid], pack_id])
				all_shell_ids[sid] = String(pack_id)
			# Stat sanity
			var cost: int = int(shell.get("cost", 0))
			if cost < 1 or cost > 25:
				warnings.append("Pack %s shell %s: cost %d outside 1-25 range" % [pack_id, sid, cost])
			var damage: int = int(shell.get("damage", 0))
			if damage < 0 or damage > 50:
				warnings.append("Pack %s shell %s: damage %d outside 0-50 range" % [pack_id, sid, damage])
			var rng: int = int(shell.get("range", 0))
			if rng < 0 or rng > 400:
				warnings.append("Pack %s shell %s: range %d outside 0-400 range" % [pack_id, sid, rng])
		# Enemy shell id refs
		for eid in pack.get("enemy_shell_ids", []):
			if not enemy_shell_ids.is_empty() and not enemy_shell_ids.has(String(eid)):
				warnings.append("Pack %s: enemy_shell_id '%s' not in enemy_shells.json (D8 may need re-run)" % [pack_id, eid])
		# Promotion gate
		var balance: String = pack.get("balance_state", "")
		var enabled_normal: bool = bool(pack.get("enabled_in_normal_runs", false))
		if enabled_normal and balance == "generated_unbalanced":
			errors.append("Pack %s: enabled_in_normal_runs=true but balance_state=generated_unbalanced" % pack_id)
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"stats": {
			"packs_checked": packs_checked,
			"shells_checked": shells_checked,
			"errors": errors.size(),
			"warnings": warnings.size(),
		},
	}

# Load D8's enemy_shells.json if it exists, return id-set for ref-check.
# Empty dict (not failure) if file is absent — enemy_shell_id refs are
# warnings, not errors, because users may not have run D8 yet.
static func _load_enemy_shell_ids() -> Dictionary:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var path: String = settings.output_path_for("enemy_shells.json")
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var ids: Dictionary = {}
	for s in parsed.get("shells", []):
		var id: String = String(s.get("id", ""))
		if id != "":
			ids[id] = true
	return ids
