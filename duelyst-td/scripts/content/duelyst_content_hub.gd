extends Control

# Duelyst Content Hub — dev-time UI that drives D0 (settings) + D1 (scan) +
# D2 (categorize). Reachable from the main menu via the "Duelyst Content"
# button. D3-D17 will add tabs/sections here as they land.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")
const SCANNER_SCRIPT := preload("res://scripts/content/duelyst_raw_scanner.gd")
const CATEGORIZER_SCRIPT := preload("res://scripts/content/duelyst_categorizer.gd")

@onready var source_field: LineEdit = $Root/SettingsSection/VBox/SourceRow/SourceField
@onready var save_btn: Button = $Root/SettingsSection/VBox/SourceRow/SaveBtn
@onready var validate_btn: Button = $Root/SettingsSection/VBox/SourceRow/ValidateBtn
@onready var source_status: RichTextLabel = $Root/SettingsSection/VBox/SourceStatus
@onready var scan_btn: Button = $Root/ScanSection/VBox/ActionRow/ScanBtn
@onready var categorize_btn: Button = $Root/ScanSection/VBox/ActionRow/CategorizeBtn
@onready var open_output_btn: Button = $Root/ScanSection/VBox/ActionRow/OpenOutputBtn
@onready var result_label: RichTextLabel = $Root/ScanSection/VBox/ResultLabel
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
	back_btn.pressed.connect(_on_back)
	# Auto-validate on entry so the user sees the current state.
	_on_validate()
	_render_last_run_summary()

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
