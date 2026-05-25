extends Control

# Duelyst Content Hub — dev-time UI that drives D0 (settings) + D1 (scan) +
# D2 (categorize). Reachable from the main menu via the "Duelyst Content"
# button. D3-D17 will add tabs/sections here as they land.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")
const SCANNER_SCRIPT := preload("res://scripts/content/duelyst_raw_scanner.gd")
const CATEGORIZER_SCRIPT := preload("res://scripts/content/duelyst_categorizer.gd")
const IMPORTER_SCRIPT := preload("res://scripts/content/duelyst_importer.gd")
const UNIT_CATALOG_SCRIPT := preload("res://scripts/content/duelyst_unit_catalog_builder.gd")
const SHELL_GENERATOR_SCRIPT := preload("res://scripts/content/duelyst_unit_shell_generator.gd")
const ENEMY_SHELL_GENERATOR_SCRIPT := preload("res://scripts/content/duelyst_enemy_shell_generator.gd")

@onready var source_field: LineEdit = $Root/SettingsSection/VBox/SourceRow/SourceField
@onready var save_btn: Button = $Root/SettingsSection/VBox/SourceRow/SaveBtn
@onready var validate_btn: Button = $Root/SettingsSection/VBox/SourceRow/ValidateBtn
@onready var source_status: RichTextLabel = $Root/SettingsSection/VBox/SourceStatus
@onready var scan_btn: Button = $Root/ScanSection/VBox/ActionRow/ScanBtn
@onready var categorize_btn: Button = $Root/ScanSection/VBox/ActionRow/CategorizeBtn
@onready var open_output_btn: Button = $Root/ScanSection/VBox/ActionRow/OpenOutputBtn
@onready var open_browser_btn: Button = $Root/ScanSection/VBox/ActionRow/OpenBrowserBtn
@onready var import_btn: Button = $Root/ScanSection/VBox/ActionRow/ImportBtn
@onready var build_unit_catalog_btn: Button = $Root/ScanSection/VBox/ActionRow/BuildUnitCatalogBtn
@onready var generate_shells_btn: Button = $Root/ScanSection/VBox/ActionRow/GenerateShellsBtn
@onready var generate_enemy_shells_btn: Button = $Root/ScanSection/VBox/ActionRow/GenerateEnemyShellsBtn
@onready var result_label: RichTextLabel = $Root/ScanSection/VBox/ResultLabel
@onready var pack_list: VBoxContainer = $Root/PacksSection/VBox/PackList
@onready var validate_packs_btn: Button = $Root/PacksSection/VBox/ValidateRow/ValidateBtn
@onready var validate_packs_result: Label = $Root/PacksSection/VBox/ValidateRow/ValidateResult

const VALIDATOR_SCRIPT := preload("res://scripts/content/duelyst_content_validator.gd")
@onready var back_btn: Button = $Root/TopBar/BackBtn

var _settings: RefCounted

func _ready() -> void:
	_settings = SETTINGS_SCRIPT.new()
	source_field.text = _settings.source_root
	save_btn.pressed.connect(_on_save_settings)
	validate_btn.pressed.connect(_on_validate)
	scan_btn.pressed.connect(_on_scan)
	categorize_btn.pressed.connect(_on_categorize)
	open_output_btn.pressed.connect(_on_show_outputs)
	open_browser_btn.pressed.connect(_on_open_browser)
	import_btn.pressed.connect(_on_import)
	build_unit_catalog_btn.pressed.connect(_on_build_unit_catalog)
	generate_shells_btn.pressed.connect(_on_generate_shells)
	generate_enemy_shells_btn.pressed.connect(_on_generate_enemy_shells)
	back_btn.pressed.connect(_on_back)
	# Auto-validate on entry so the user sees the current state.
	_on_validate()
	_render_last_run_summary()
	_render_pack_list()
	PackManager.packs_changed.connect(_render_pack_list)
	validate_packs_btn.pressed.connect(_on_validate_packs)

func _on_validate_packs() -> void:
	var res: Dictionary = VALIDATOR_SCRIPT.validate_all()
	var stats: Dictionary = res.get("stats", {})
	var summary: String = "%d packs · %d shells · %d errors · %d warnings" % [
		int(stats.get("packs_checked", 0)),
		int(stats.get("shells_checked", 0)),
		int(stats.get("errors", 0)),
		int(stats.get("warnings", 0)),
	]
	validate_packs_result.text = summary
	if res.get("ok", false):
		validate_packs_result.modulate = Color(0.55, 1.0, 0.65, 1)
	else:
		validate_packs_result.modulate = Color(1.0, 0.65, 0.65, 1)
	# Dump details to the right-hand result panel so users see specifics.
	var lines: Array[String] = []
	lines.append("[b]Pack validator (D15) — %s[/b]" % summary)
	if res.get("errors", []).size() > 0:
		lines.append("[color=#ff8f8f][b]Errors:[/b][/color]")
		for e in res["errors"]:
			lines.append("  ✗ %s" % e)
	if res.get("warnings", []).size() > 0:
		lines.append("[color=#ffce6c][b]Warnings:[/b][/color]")
		for w in res["warnings"]:
			lines.append("  ! %s" % w)
	if res.get("errors", []).is_empty() and res.get("warnings", []).is_empty():
		lines.append("[color=#8fff8f]All packs validate cleanly.[/color]")
	result_label.text = "\n".join(lines)

func _render_pack_list() -> void:
	for child in pack_list.get_children():
		child.queue_free()
	var pack_ids: Array = PackManager.all_pack_ids()
	if pack_ids.is_empty():
		var lbl := Label.new()
		lbl.text = "  No packs found in res://data/content_packs/duelyst/"
		lbl.modulate = Color(0.7, 0.7, 0.78, 1)
		pack_list.add_child(lbl)
		return
	pack_ids.sort()
	for pid in pack_ids:
		pack_list.add_child(_make_pack_row(String(pid)))

func _make_pack_row(pack_id: String) -> Control:
	var pack: Dictionary = PackManager.get_pack(pack_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var toggle := CheckBox.new()
	toggle.text = ""
	toggle.button_pressed = PackManager.is_enabled(pack_id)
	toggle.toggled.connect(func(state: bool): PackManager.set_enabled(pack_id, state))
	row.add_child(toggle)
	var name_lbl := Label.new()
	name_lbl.text = pack.get("display_name", pack_id)
	name_lbl.custom_minimum_size = Vector2(220, 0)
	row.add_child(name_lbl)
	var counts := Label.new()
	var n_def: int = int(pack.get("defender_unit_ids", []).size()) + int(pack.get("defender_shells", []).size())
	var n_enemy: int = int(pack.get("enemy_shell_ids", []).size())
	counts.text = "%d defenders · %d enemies · %s" % [n_def, n_enemy, pack.get("balance_state", "?")]
	counts.modulate = Color(0.75, 0.75, 0.82, 1)
	counts.add_theme_font_size_override("font_size", 11)
	row.add_child(counts)
	return row

func _on_save_settings() -> void:
	_settings.source_root = source_field.text.strip_edges()
	if _settings.save_to_disk():
		source_status.text = "[color=#8fff8f]Saved.[/color]  %s" % _settings.source_root
	else:
		source_status.text = "[color=#ff8f8f]Could not save settings.[/color]"

func _on_validate() -> void:
	_settings.source_root = source_field.text.strip_edges()
	var v: Dictionary = _settings.validate_source()
	if v.get("ok", false):
		source_status.text = "[color=#8fff8f][b]Valid source.[/b][/color]  %s" % v.get("message", "")
	else:
		source_status.text = "[color=#ff8f8f][b]Invalid.[/b][/color]  %s" % v.get("message", "")

func _on_scan() -> void:
	# Persist whatever's in the field first.
	_settings.source_root = source_field.text.strip_edges()
	_settings.save_to_disk()
	result_label.text = "[i]Scanning %s …[/i]" % _settings.source_root
	# Defer one frame so the label paints before the (potentially long) walk.
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = SCANNER_SCRIPT.scan()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]Scan failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var counts: Dictionary = res.get("counts", {})
	result_label.text = "[color=#8fff8f][b]D1 scan complete.[/b][/color]  %d files in %d ms.\n" % [
		int(counts.get("total_files", 0)), elapsed,
	] + _format_counts(counts) + "\n" + _format_outputs()

func _on_categorize() -> void:
	result_label.text = "[i]Categorizing …[/i]"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = CATEGORIZER_SCRIPT.categorize()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]Categorize failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var counts: Dictionary = res.get("counts", {})
	result_label.text = "[color=#8fff8f][b]D2 categorize complete.[/b][/color]  %d entries in %d ms (overrides: %d).\n" % [
		int(counts.get("total", 0)), elapsed, int(res.get("override_count", 0)),
	] + _format_category_counts(counts) + "\n" + _format_outputs()

func _on_show_outputs() -> void:
	result_label.text = _format_outputs()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_open_browser() -> void:
	get_tree().change_scene_to_file("res://scenes/duelyst_content_browser.tscn")

func _on_import() -> void:
	result_label.text = "[i]Importing safe categories (icon, ui_image, map_tile, map_background, font) into res://assets/duelyst/ …[/i]"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = IMPORTER_SCRIPT.import_categories()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]Import failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var imported: Dictionary = res.get("imported", {})
	var skipped: Dictionary = res.get("skipped", {})
	var failed: Dictionary = res.get("failed", {})
	var total_imp := 0
	for k in imported: total_imp += int(imported[k])
	var total_skip := 0
	for k in skipped: total_skip += int(skipped[k])
	var lines: Array[String] = []
	lines.append("[color=#8fff8f][b]D3 import complete.[/b][/color]  %d imported / %d skipped in %d ms" % [total_imp, total_skip, elapsed])
	lines.append("[color=#a0a0a8]Dest:[/color] %s" % res.get("dest_root", "?"))
	lines.append("[color=#a0a0a8]Imported:[/color] %s" % JSON.stringify(imported))
	lines.append("[color=#a0a0a8]Skipped (already up-to-date):[/color] %s" % JSON.stringify(skipped))
	if failed.size() > 0:
		lines.append("[color=#ffce6c]Failed:[/color] %s" % JSON.stringify(failed))
	lines.append("")
	lines.append("[color=#7a7a82]Restart the editor to let Godot auto-import the new files as proper resources.[/color]")
	result_label.text = "\n".join(lines)

func _on_build_unit_catalog() -> void:
	result_label.text = "[i]Building unit catalog from categorized entries …[/i]"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = UNIT_CATALOG_SCRIPT.build()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]D6 build failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var lines: Array[String] = []
	lines.append("[color=#8fff8f][b]D6 unit catalog built.[/b][/color]  %d units in %d ms" % [int(res.get("total_units", 0)), elapsed])
	lines.append("  with animations:        %d" % int(res.get("with_animations", 0)))
	lines.append("  SpriteFrames already ready: %d" % int(res.get("sprite_frames_ready", 0)))
	lines.append("[color=#a0a0a8]By faction:[/color]")
	var by_faction: Dictionary = res.get("by_faction", {})
	var keys: Array = by_faction.keys()
	keys.sort()
	for k in keys:
		var label: String = k if k != "" else "(unset)"
		lines.append("  %-12s  %d" % [label, int(by_faction[k])])
	lines.append("")
	lines.append("[color=#a0a0a8]Output:[/color]  %s" % res.get("out_path", "?"))
	result_label.text = "\n".join(lines)

func _on_generate_shells() -> void:
	result_label.text = "[i]Generating unit shells from D6 catalog …[/i]"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = SHELL_GENERATOR_SCRIPT.generate()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]D7 generate failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var lines: Array[String] = []
	lines.append("[color=#8fff8f][b]D7 unit shells generated.[/b][/color]  %d shells in %d ms" % [int(res.get("total_shells", 0)), elapsed])
	lines.append("[color=#a0a0a8]By role:[/color]")
	var by_role: Dictionary = res.get("by_role", {})
	var role_keys: Array = by_role.keys()
	role_keys.sort_custom(func(a, b): return int(by_role[a]) > int(by_role[b]))
	for k in role_keys:
		lines.append("  %-18s  %d" % [k, int(by_role[k])])
	lines.append("[color=#a0a0a8]By faction:[/color]")
	var by_faction: Dictionary = res.get("by_faction", {})
	var faction_keys: Array = by_faction.keys()
	faction_keys.sort()
	for k in faction_keys:
		var label: String = k if k != "" else "(unset)"
		lines.append("  %-12s  %d" % [label, int(by_faction[k])])
	lines.append("")
	lines.append("[color=#a0a0a8]Output:[/color]  %s" % res.get("out_path", "?"))
	lines.append("[color=#7a7a82]All shells are debug-only (enabled_in_normal_runs=false). Promote to normal runs via the future D14 content pack manager.[/color]")
	result_label.text = "\n".join(lines)

func _on_generate_enemy_shells() -> void:
	result_label.text = "[i]Generating enemy shells from D6 catalog …[/i]"
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var res: Dictionary = ENEMY_SHELL_GENERATOR_SCRIPT.generate()
	var elapsed: int = Time.get_ticks_msec() - t0
	if not res.get("ok", false):
		result_label.text = "[color=#ff8f8f][b]D8 generate failed.[/b][/color]  %s" % res.get("message", "?")
		return
	var lines: Array[String] = []
	lines.append("[color=#8fff8f][b]D8 enemy shells generated.[/b][/color]  %d shells in %d ms" % [int(res.get("total_shells", 0)), elapsed])
	lines.append("  Sprite-frames ready (spawnable in debug):  [b]%d[/b]" % int(res.get("spawn_ready_count", 0)))
	lines.append("[color=#a0a0a8]By family:[/color]")
	var by_family: Dictionary = res.get("by_family", {})
	var fam_keys: Array = by_family.keys()
	fam_keys.sort_custom(func(a, b): return int(by_family[a]) > int(by_family[b]))
	for k in fam_keys:
		lines.append("  %-12s  %d" % [k, int(by_family[k])])
	lines.append("[color=#a0a0a8]By faction:[/color]")
	var by_faction: Dictionary = res.get("by_faction", {})
	var fac_keys: Array = by_faction.keys()
	fac_keys.sort()
	for k in fac_keys:
		var label: String = k if k != "" else "(unset)"
		lines.append("  %-12s  %d" % [label, int(by_faction[k])])
	lines.append("")
	lines.append("[color=#a0a0a8]Output:[/color]  %s" % res.get("out_path", "?"))
	lines.append("[color=#7a7a82]Press F4 in a run to spawn a random sprite-ready enemy at the path start.[/color]")
	result_label.text = "\n".join(lines)

func _render_last_run_summary() -> void:
	var lines: Array[String] = []
	lines.append("[b]Pipeline status:[/b]")
	lines.append("  D0 source root:    [color=#9cb8ff]%s[/color]" % (_settings.source_root if _settings.source_root != "" else "(unset)"))
	lines.append("  D1 last scan:      %s" % (_settings.last_scan_at if _settings.last_scan_at != "" else "[color=#7a7a82]never[/color]"))
	lines.append("  D2 last categorize:%s" % (_settings.last_categorize_at if _settings.last_categorize_at != "" else " [color=#7a7a82]never[/color]"))
	lines.append("")
	lines.append("[i]Press Run D1 to walk the source folder. Then Run D2 to refine the catalog.[/i]")
	result_label.text = "\n".join(lines)

func _format_counts(counts: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[color=#a0a0a8]By section:[/color]")
	var by_section: Dictionary = counts.get("by_section", {})
	for k in _sorted_keys_desc(by_section):
		lines.append("  %-12s  %d" % [k, int(by_section[k])])
	lines.append("[color=#a0a0a8]By extension (top 10):[/color]")
	var by_ext: Dictionary = counts.get("by_extension", {})
	var top: int = 0
	for k in _sorted_keys_desc(by_ext):
		lines.append("  %-12s  %d" % [k, int(by_ext[k])])
		top += 1
		if top >= 10:
			break
	return "\n".join(lines)

func _format_category_counts(counts: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[color=#a0a0a8]By category:[/color]")
	var by_cat: Dictionary = counts.get("by_category", {})
	for k in _sorted_keys_desc(by_cat):
		lines.append("  %-22s  %d" % [k, int(by_cat[k])])
	lines.append("[color=#a0a0a8]By faction (heuristic):[/color]")
	var by_fac: Dictionary = counts.get("by_faction", {})
	for k in _sorted_keys_desc(by_fac):
		lines.append("  %-22s  %d" % [k, int(by_fac[k])])
	lines.append("  [color=#7a7a82]Unit atlas pairs:    %d[/color]" % int(counts.get("unit_atlases_paired", 0)))
	return "\n".join(lines)

func _format_outputs() -> String:
	var lines: Array[String] = []
	lines.append("[color=#a0a0a8]Output files (in %s):[/color]" % _settings.output_root)
	for name in ["catalog_raw.json", "report_raw.json", "catalog_categorized.json", "report_categorized.json", "manual_overrides.json", "settings.json"]:
		var path: String = _settings.output_path_for(name)
		var marker: String = "✓" if FileAccess.file_exists(path) else "·"
		lines.append("  %s  %s" % [marker, name])
	return "\n".join(lines)

func _sorted_keys_desc(d: Dictionary) -> Array:
	var keys: Array = d.keys()
	keys.sort_custom(func(a, b): return int(d[a]) > int(d[b]))
	return keys
