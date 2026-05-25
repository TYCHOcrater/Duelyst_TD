extends Control

@onready var seed_field: LineEdit = $CenterContainer/VBox/SeedRow/SeedField
@onready var randomize_btn: Button = $CenterContainer/VBox/SeedRow/RandomizeButton
@onready var map_source_option: OptionButton = $CenterContainer/VBox/MapRow/MapSourceOption
@onready var map_editor_btn: Button = $CenterContainer/VBox/MapRow/MapEditorButton
@onready var growth_option: OptionButton = $CenterContainer/VBox/GrowthRow/GrowthOption
@onready var players_option: OptionButton = $CenterContainer/VBox/PlayersRow/PlayersOption
@onready var new_run_btn: Button = $CenterContainer/VBox/NewRunButton
@onready var daily_info: Label = $CenterContainer/VBox/DailyInfo
@onready var daily_best: Label = $CenterContainer/VBox/DailyBest
@onready var play_daily_btn: Button = $CenterContainer/VBox/PlayDailyButton
@onready var recent_label: RichTextLabel = $CenterContainer/VBox/RecentLabel
@onready var determinism_btn: Button = $CenterContainer/VBox/SecondaryRow/DeterminismButton
@onready var determinism_result: Label = $CenterContainer/VBox/DeterminismResult
@onready var mastery_btn: Button = $CenterContainer/VBox/SecondaryRow/MasteryButton
@onready var duelyst_content_btn: Button = $CenterContainer/VBox/SecondaryRow/DuelystContentButton
@onready var quit_btn: Button = $CenterContainer/VBox/SecondaryRow/QuitButton
@onready var mastery_panel: Panel = $MasteryPanel
@onready var mastery_list: RichTextLabel = $MasteryPanel/VBox/Scroll/List
@onready var mastery_close_btn: Button = $MasteryPanel/VBox/CloseButton

func _ready() -> void:
	# Headless smoke test for the procgen pipeline: --test-generator runs N seeds
	# through MapGenerator.generate and prints PASS/FAIL counts, then quits.
	if "--test-generator" in OS.get_cmdline_args():
		_run_generator_smoke_test()
		return
	# --content-scan runs D1 + D2 pipeline non-interactively and prints results.
	if "--content-scan" in OS.get_cmdline_args():
		_run_content_pipeline_smoke_test()
		return
	# --test-offers prints the first-wave offers for a set of seeds, used to
	# diagnose the offers-not-random bug.
	if "--test-offers" in OS.get_cmdline_args():
		_run_offers_smoke_test()
		return
	# Fresh seed each time we land on the menu (after a run, between launches, etc.).
	# RunConfig._ready only fires once per process; without this, returning to the
	# menu post-run would reuse the same seed → identical first-wave offers. The
	# user can still type a specific seed before pressing New Run if they want to
	# replay a particular run, and the end-panel "Replay (same seed)" path
	# bypasses the menu so its semantics are unaffected.
	RunConfig.randomize_seed()
	seed_field.text = RunConfig.format_seed()
	seed_field.text_submitted.connect(_on_seed_submitted)
	randomize_btn.pressed.connect(_on_randomize)
	new_run_btn.pressed.connect(_on_new_run)
	play_daily_btn.pressed.connect(_on_play_daily)
	determinism_btn.pressed.connect(_on_determinism_test)
	mastery_btn.pressed.connect(_on_open_mastery)
	mastery_close_btn.pressed.connect(_on_close_mastery)
	quit_btn.pressed.connect(_on_quit)
	map_editor_btn.pressed.connect(_on_open_editor)
	duelyst_content_btn.pressed.connect(_on_open_duelyst_content)
	mastery_panel.visible = false
	_populate_map_sources()
	_populate_growth_modes()
	_populate_player_counts()
	_refresh_daily_info()

const MAP_OPTIONS := [
	{"label": "Starter (built-in)", "source": "fixed", "id": ""},
	{"label": "Random (procgen)", "source": "generated", "id": ""},
]
const CUSTOM_MAP_DIR := "user://maps/"

func _populate_map_sources() -> void:
	map_source_option.clear()
	for opt in MAP_OPTIONS:
		map_source_option.add_item(opt.label)
	# Append custom maps if present.
	var dir := DirAccess.open(CUSTOM_MAP_DIR)
	if dir:
		dir.list_dir_begin()
		var customs: Array[String] = []
		while true:
			var fname := dir.get_next()
			if fname == "":
				break
			if fname.ends_with(".json") and not fname.begins_with("_"):
				customs.append(fname.get_basename())
		dir.list_dir_end()
		customs.sort()
		for cid in customs:
			map_source_option.add_item("Custom: %s" % cid)
	# Restore previous selection.
	for i in map_source_option.item_count:
		if i < MAP_OPTIONS.size():
			if MAP_OPTIONS[i].source == RunConfig.map_source and (MAP_OPTIONS[i].source != "custom" or MAP_OPTIONS[i].id == RunConfig.custom_map_id):
				map_source_option.selected = i
				return
	# If saved was a custom map, find it.
	if RunConfig.map_source == "custom":
		for i in range(MAP_OPTIONS.size(), map_source_option.item_count):
			var label: String = map_source_option.get_item_text(i)
			if label.ends_with(RunConfig.custom_map_id):
				map_source_option.selected = i
				return
	map_source_option.selected = 0

func _apply_map_source_selection() -> void:
	var idx: int = map_source_option.selected
	if idx < MAP_OPTIONS.size():
		RunConfig.map_source = MAP_OPTIONS[idx].source
		RunConfig.custom_map_id = ""
	else:
		var label: String = map_source_option.get_item_text(idx)
		# Strip the "Custom: " prefix.
		RunConfig.map_source = "custom"
		RunConfig.custom_map_id = label.replace("Custom: ", "")

func _populate_growth_modes() -> void:
	growth_option.clear()
	for mode in RunConfig.GROWTH_MODES:
		growth_option.add_item(_growth_mode_label(mode))
	# Restore previous selection.
	for i in RunConfig.GROWTH_MODES.size():
		if RunConfig.GROWTH_MODES[i] == RunConfig.growth_mode:
			growth_option.selected = i
			return
	growth_option.selected = 0

func _growth_mode_label(mode: String) -> String:
	match mode:
		"classic_upgrade":        return "Classic Upgrade"
		"merge_stars":            return "Merge Stars"
		"merge_evolution_hybrid": return "Merge + Evolution"
		_:                        return mode

func _apply_growth_mode_selection() -> void:
	var idx: int = growth_option.selected
	if idx >= 0 and idx < RunConfig.GROWTH_MODES.size():
		RunConfig.set_growth_mode(RunConfig.GROWTH_MODES[idx])

func _populate_player_counts() -> void:
	players_option.clear()
	players_option.add_item("1  ·  Solo")
	players_option.add_item("2  ·  Starbase co-op")
	players_option.add_item("3  ·  Starbase co-op")
	players_option.add_item("4  ·  Starbase co-op")
	var sel: int = clamp(RunConfig.player_count - 1, 0, 3)
	players_option.selected = sel

func _apply_player_count_selection() -> void:
	var n: int = players_option.selected + 1
	RunConfig.set_player_count(n)
	# Topology: solo for 1, debug for 2+ (the visible game is still single-board
	# until C1 lands CoopMapDef). User overrides via dropdown are a later
	# iteration; for now set_player_count handles the auto-promote.

func _refresh_daily_info() -> void:
	daily_info.text = "Today: %s  ·  %s" % [Daily.today_seed_text(), Daily.today_key()]
	var best: Dictionary = Daily.today_best()
	if best.is_empty():
		daily_best.text = "No runs today yet."
	else:
		daily_best.text = "Best today: %d  ·  %s  ·  %s" % [
			int(best.get("score", 0)),
			best.get("run_name", ""),
			String(best.get("result", "")).capitalize(),
		]
	# Recent days summary.
	var recent: Array = Daily.recent_dates(5)
	if recent.is_empty():
		recent_label.text = ""
	else:
		var lines: Array[String] = ["[color=#8a8a92]Recent dailies:[/color]"]
		for r in recent:
			var mark: String = "✓" if String(r.best.get("result", "")) == "victory" else "✗"
			lines.append("  %s  %s  [b]%d[/b]  [color=#9a9aa0]%s[/color]" % [
				r.date, mark, int(r.best_score), r.best.get("run_name", ""),
			])
		recent_label.text = "\n".join(lines)

func _on_randomize() -> void:
	RunConfig.randomize_seed()
	seed_field.text = RunConfig.format_seed()
	determinism_result.text = ""

func _on_seed_submitted(_text: String) -> void:
	_apply_seed_from_field()

func _apply_seed_from_field() -> void:
	var parsed: int = RunConfig.parse_seed_text(seed_field.text)
	if parsed < 0:
		determinism_result.text = "Invalid seed format. Use SHARD-XXXXXXXX or a number."
		determinism_result.modulate = Color(1, 0.5, 0.5)
		return
	RunConfig.set_seed(parsed)
	seed_field.text = RunConfig.format_seed()
	determinism_result.text = ""

func _on_new_run() -> void:
	_apply_seed_from_field()
	_apply_map_source_selection()
	_apply_growth_mode_selection()
	_apply_player_count_selection()
	RunConfig.is_daily = false
	SessionRng.set_seed(RunConfig.seed)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_play_daily() -> void:
	RunConfig.set_seed(Daily.today_seed())
	RunConfig.is_daily = true
	RunConfig.map_source = "fixed"  # daily is always on starter map for fair comparison
	RunConfig.custom_map_id = ""
	RunConfig.set_player_count(1)  # daily is solo for fair score comparison
	SessionRng.set_seed(RunConfig.seed)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_open_editor() -> void:
	get_tree().change_scene_to_file("res://scenes/map_editor.tscn")

func _on_open_duelyst_content() -> void:
	get_tree().change_scene_to_file("res://scenes/duelyst_content_hub.tscn")

func _on_determinism_test() -> void:
	const N := 200
	SessionRng.set_seed(123)
	var a: Array[int] = []
	for i in N:
		a.append(SessionRng.randi() % 10000)
	SessionRng.set_seed(123)
	var a2: Array[int] = []
	for i in N:
		a2.append(SessionRng.randi() % 10000)
	SessionRng.set_seed(456)
	var b: Array[int] = []
	for i in N:
		b.append(SessionRng.randi() % 10000)
	SessionRng.set_seed(RunConfig.seed)
	var same := a == a2
	var differ := a != b
	if same and differ:
		determinism_result.text = "PASS  ·  seed 123 stable across %d draws  ·  seed 456 differs" % N
		determinism_result.modulate = Color(0.5, 1, 0.5)
	else:
		determinism_result.text = "FAIL  ·  same=%s  differ=%s" % [str(same), str(differ)]
		determinism_result.modulate = Color(1, 0.4, 0.4)

func _on_open_mastery() -> void:
	_refresh_mastery_list()
	mastery_panel.visible = true

func _on_close_mastery() -> void:
	mastery_panel.visible = false

const TIER_COLORS := {
	0: "#5a5a62",
	1: "#aaaaaa",
	2: "#7cce6c",
	3: "#6ccef0",
	4: "#a98cff",
	5: "#ffce6c",
}

func _refresh_mastery_list() -> void:
	var rows: Array = Mastery.sorted_entries()
	mastery_list.clear()
	if rows.is_empty():
		mastery_list.append_text("[color=#7a7a82]No runs recorded yet. Play a run and your units will appear here.[/color]")
		return
	mastery_list.append_text("[color=#a0a0a8]    Unit  ·  Tier  ·  Kills (est.)  ·  Wins  ·  Placements  ·  Best wave[/color]\n")
	for row in rows:
		var uid: String = row.unit_id
		var e: Dictionary = row.entry
		var level: int = int(row.level)
		var udef: Dictionary = UnitFactory.get_def(uid)
		var name_text: String = udef.get("display_name", uid)
		var faction: String = udef.get("faction", "neutral")
		var hex: String = TIER_COLORS.get(level, "#aaaaaa")
		var tier_name: String = Mastery.tier_name(level)
		var tier_text: String = "Lv %d %s" % [level, tier_name] if level > 0 else "Lv 0"
		# Inline unit portrait if a SpriteFrames exists for this unit.
		var icon: Texture2D = _portrait_for(uid)
		if icon != null:
			mastery_list.add_image(icon, 28, 28)
			mastery_list.append_text(" ")
		else:
			mastery_list.append_text("     ")  # alignment placeholder
		mastery_list.append_text(
			"[color=%s][b]%s[/b][/color]  [color=#7a7a82](%s)[/color]  ·  [color=%s]%s[/color]  ·  %d kills  ·  %d wins  ·  %d placements  ·  best W%d\n" % [
				hex,
				name_text,
				faction.capitalize(),
				hex,
				tier_text,
				int(e.get("kills", 0)),
				int(e.get("wins", 0)),
				int(e.get("placements", 0)),
				int(e.get("max_wave", 0)),
			]
		)

func _portrait_for(unit_id: String) -> Texture2D:
	# Mirrors the helper in hud.gd: prefer idle/breathing animations, fall
	# back to the first non-empty animation, return null if no SpriteFrames.
	var sf: SpriteFrames = UnitFactory.sprite_frames_for(unit_id)
	if sf == null:
		return null
	var names: PackedStringArray = sf.get_animation_names()
	for keyword in ["idle", "breathing", "breathe", "breath", "default"]:
		for n in names:
			if String(n).ends_with(keyword) and sf.get_frame_count(n) > 0:
				return sf.get_frame_texture(n, 0)
	for n in names:
		if sf.get_frame_count(n) > 0:
			return sf.get_frame_texture(n, 0)
	return null

func _run_generator_smoke_test() -> void:
	const MapGen = preload("res://scripts/map_generator.gd")
	var ok: int = 0
	var fail: int = 0
	var sample_seeds: Array[int] = [1, 2, 3, 42, 123, 999, 1024, 65535, 0xDEAD, 0xBEEF, 0x12345678, 0xCAFEBABE]
	for s in sample_seeds:
		var res: Dictionary = MapGen.generate_forgiving(s)
		if res.get("ok", false):
			ok += 1
			var m: Dictionary = res["map"]
			var chain: Array = m.get("path_chain", [])
			print("seed=%08x  PASS  path_len=%d  attempts=%d  used_seed=%08x" % [
				s & 0xFFFFFFFF, chain.size(), int(res.get("attempts", 0)), int(res.get("seed_used", s)) & 0xFFFFFFFF
			])
		else:
			fail += 1
			print("seed=%08x  FAIL  %s" % [s & 0xFFFFFFFF, res.get("error", "?")])
	# Determinism check: same seed twice must give same tiles.
	var s2: int = 1234567
	var a: Dictionary = MapGen.generate(s2)
	var b: Dictionary = MapGen.generate(s2)
	var det := "DETERMINISM: "
	if a.get("ok", false) and b.get("ok", false) and a["map"]["tiles"] == b["map"]["tiles"]:
		det += "PASS"
	else:
		det += "FAIL"
	print("%s   total ok=%d  fail=%d" % [det, ok, fail])
	get_tree().quit()

func _run_content_pipeline_smoke_test() -> void:
	const Scanner = preload("res://scripts/content/duelyst_raw_scanner.gd")
	const Categorizer = preload("res://scripts/content/duelyst_categorizer.gd")
	const UnitCatalogBuilder = preload("res://scripts/content/duelyst_unit_catalog_builder.gd")
	var t0: int = Time.get_ticks_msec()
	var scan_res: Dictionary = Scanner.scan()
	var scan_ms: int = Time.get_ticks_msec() - t0
	if not scan_res.get("ok", false):
		print("D1 SCAN FAIL: %s" % scan_res.get("message", "?"))
		get_tree().quit(1)
		return
	var c: Dictionary = scan_res.get("counts", {})
	print("D1 scan PASS: %d files in %d ms" % [int(c.get("total_files", 0)), scan_ms])
	print("  by_section: %s" % JSON.stringify(c.get("by_section", {})))
	t0 = Time.get_ticks_msec()
	var cat_res: Dictionary = Categorizer.categorize()
	var cat_ms: int = Time.get_ticks_msec() - t0
	if not cat_res.get("ok", false):
		print("D2 CATEGORIZE FAIL: %s" % cat_res.get("message", "?"))
		get_tree().quit(1)
		return
	var cc: Dictionary = cat_res.get("counts", {})
	print("D2 categorize PASS: %d entries in %d ms" % [int(cc.get("total", 0)), cat_ms])
	print("  by_category: %s" % JSON.stringify(cc.get("by_category", {})))
	print("  by_faction: %s" % JSON.stringify(cc.get("by_faction", {})))
	t0 = Time.get_ticks_msec()
	var uc_res: Dictionary = UnitCatalogBuilder.build()
	var uc_ms: int = Time.get_ticks_msec() - t0
	if not uc_res.get("ok", false):
		print("D6 BUILD FAIL: %s" % uc_res.get("message", "?"))
		get_tree().quit(1)
		return
	print("D6 unit catalog PASS: %d units in %d ms" % [int(uc_res.get("total_units", 0)), uc_ms])
	print("  with_animations: %d  ·  sprite_frames_ready: %d" % [
		int(uc_res.get("with_animations", 0)), int(uc_res.get("sprite_frames_ready", 0)),
	])
	print("  by_faction: %s" % JSON.stringify(uc_res.get("by_faction", {})))
	const ShellGenerator = preload("res://scripts/content/duelyst_unit_shell_generator.gd")
	t0 = Time.get_ticks_msec()
	var shell_res: Dictionary = ShellGenerator.generate()
	var shell_ms: int = Time.get_ticks_msec() - t0
	if not shell_res.get("ok", false):
		print("D7 SHELLS FAIL: %s" % shell_res.get("message", "?"))
		get_tree().quit(1)
		return
	print("D7 unit shells PASS: %d shells in %d ms" % [int(shell_res.get("total_shells", 0)), shell_ms])
	print("  by_role: %s" % JSON.stringify(shell_res.get("by_role", {})))
	print("  by_faction: %s" % JSON.stringify(shell_res.get("by_faction", {})))
	get_tree().quit()

func _run_offers_smoke_test() -> void:
	# Simulate the same call chain main.gd → phase_controller → draft_director
	# would do at wave 1, for several seeds, and print the picked offers.
	const DraftDirector = preload("res://scripts/draft_director.gd")
	var test_seeds: Array[int] = [1, 2, 3, 42, 0xDEAD, 0xBEEF, 0xCAFEBABE, 1, 0xCAFEBABE]
	# Force a known starting gold so the affordability filter is consistent.
	GameState.reset()
	# DraftDirector is a Node that needs to live in the tree to use SessionRng helpers.
	var dd = DraftDirector.new()
	add_child(dd)
	for s in test_seeds:
		SessionRng.set_seed(s)
		# Reach into the private _make_offers directly so we exercise the exact
		# code path the live game uses.
		var offers: Array = dd.call("_make_offers", 1)
		var fmt: String = ", ".join(offers as PackedStringArray)
		print("seed=0x%08x  wave1 offers: %s" % [s & 0xFFFFFFFF, fmt])
	dd.queue_free()
	get_tree().quit()

func _on_quit() -> void:
	get_tree().quit()
