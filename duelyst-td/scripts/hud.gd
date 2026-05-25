extends CanvasLayer

@onready var gold_label: Label = $TopBar/HBox/GoldBox/GoldLabel
@onready var income_floater: RichTextLabel = $IncomeFloater
@onready var lives_label: Label = $TopBar/HBox/LivesBox/LivesLabel
@onready var wave_label: Label = $TopBar/HBox/WaveLabel
@onready var seed_label: Label = $TopBar/HBox/SeedLabel
@onready var growth_label: Label = $TopBar/HBox/GrowthLabel
@onready var players_label: Label = $TopBar/HBox/PlayersLabel
@onready var pause_btn: Button = $TopBar/HBox/PauseButton
@onready var speed_btn: Button = $TopBar/HBox/SpeedButton

@onready var offer_btns: Array[Button] = [
	$BottomBar/VBox/DraftRow/OfferBox1/Inner/OfferBtn1,
	$BottomBar/VBox/DraftRow/OfferBox2/Inner/OfferBtn2,
	$BottomBar/VBox/DraftRow/OfferBox3/Inner/OfferBtn3,
]
@onready var offer_chips: Array[Label] = [
	$BottomBar/VBox/DraftRow/OfferBox1/Inner/TypeChip1,
	$BottomBar/VBox/DraftRow/OfferBox2/Inner/TypeChip2,
	$BottomBar/VBox/DraftRow/OfferBox3/Inner/TypeChip3,
]
@onready var offer_trait_chips: Array[Label] = [
	$BottomBar/VBox/DraftRow/OfferBox1/Inner/TraitChip1,
	$BottomBar/VBox/DraftRow/OfferBox2/Inner/TraitChip2,
	$BottomBar/VBox/DraftRow/OfferBox3/Inner/TraitChip3,
]
@onready var offer_descs: Array[Label] = [
	$BottomBar/VBox/DraftRow/OfferBox1/Inner/OfferDesc1,
	$BottomBar/VBox/DraftRow/OfferBox2/Inner/OfferDesc2,
	$BottomBar/VBox/DraftRow/OfferBox3/Inner/OfferDesc3,
]
@onready var offer_portraits: Array[TextureRect] = [
	$BottomBar/VBox/DraftRow/OfferBox1/Inner/OfferPortrait1,
	$BottomBar/VBox/DraftRow/OfferBox2/Inner/OfferPortrait2,
	$BottomBar/VBox/DraftRow/OfferBox3/Inner/OfferPortrait3,
]
@onready var offer_boxes: Array[PanelContainer] = [
	$BottomBar/VBox/DraftRow/OfferBox1,
	$BottomBar/VBox/DraftRow/OfferBox2,
	$BottomBar/VBox/DraftRow/OfferBox3,
]
@onready var reroll_btn: Button = $BottomBar/VBox/DraftRow/ControlCol/RerollButton
@onready var start_wave_btn: Button = $BottomBar/VBox/DraftRow/ControlCol/StartWaveButton

@onready var wave_title: Label = $BottomBar/VBox/DraftRow/WavePreview/VBox/WaveTitle
@onready var wave_tags: RichTextLabel = $BottomBar/VBox/DraftRow/WavePreview/VBox/WaveTags
@onready var wave_hint: Label = $BottomBar/VBox/DraftRow/WavePreview/VBox/WaveHint

@onready var active_pacts_label: RichTextLabel = $ActivePactsLabel
@onready var pact_panel: Panel = $PactChoicePanel
@onready var pact_panel_title: Label = $PactChoicePanel/VBox/Title
@onready var pact_panel_subtitle: Label = $PactChoicePanel/VBox/Subtitle
@onready var pact_cards: Array[Button] = [
	$PactChoicePanel/VBox/Cards/Card1,
	$PactChoicePanel/VBox/Cards/Card2,
	$PactChoicePanel/VBox/Cards/Card3,
]

# Tracks whether the modal is currently offering a pact or a relic.
var _current_choice_kind: String = "pact"
var _evolution_base_unit_id: String = ""
const _CHOOSE_EVO_CMD := preload("res://scripts/commands/choose_evolution_command.gd")

@onready var silence_banner: Label = $SilenceBanner
@onready var wave_banner: Label = $WaveBanner
@onready var end_panel: Panel = $EndPanel
@onready var end_label: Label = $EndPanel/VBox/EndLabel
@onready var end_seed: Label = $EndPanel/VBox/EndSeed
@onready var end_run_name: Label = $EndPanel/VBox/RunName
@onready var end_gold_earned: Label = $EndPanel/VBox/StatsGrid/GoldEarnedVal
@onready var end_gold_spent: Label = $EndPanel/VBox/StatsGrid/GoldSpentVal
@onready var end_kills: Label = $EndPanel/VBox/StatsGrid/KillsVal
@onready var end_damage: Label = $EndPanel/VBox/StatsGrid/DamageVal
@onready var end_leaks: Label = $EndPanel/VBox/StatsGrid/LeaksVal
@onready var end_units: Label = $EndPanel/VBox/StatsGrid/UnitsVal
@onready var end_interest: Label = $EndPanel/VBox/StatsGrid/InterestVal
@onready var end_highlights: RichTextLabel = $EndPanel/VBox/Highlights
@onready var end_coach_header: Label = $EndPanel/VBox/CoachHeader
@onready var end_coach: RichTextLabel = $EndPanel/VBox/CoachPanel
@onready var end_pacts: RichTextLabel = $EndPanel/VBox/PactsLabel
@onready var end_relics: RichTextLabel = $EndPanel/VBox/RelicsLabel
@onready var restart_btn: Button = $EndPanel/VBox/Buttons/RestartButton
@onready var new_seed_btn: Button = $EndPanel/VBox/Buttons/NewSeedButton
@onready var menu_btn: Button = $EndPanel/VBox/Buttons/MenuButton
@onready var share_btn: Button = $EndPanel/VBox/Buttons/ShareButton
@onready var daily_badge: Label = $EndPanel/VBox/DailyBadge
@onready var daily_score_label: Label = $EndPanel/VBox/DailyScore
@onready var daily_rank_label: Label = $EndPanel/VBox/DailyRank
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var pause_resume_btn: Button = $PauseOverlay/PausePanel/VBox/ResumeBtn
@onready var pause_menu_btn: Button = $PauseOverlay/PausePanel/VBox/MainMenuBtn
@onready var pause_quit_btn: Button = $PauseOverlay/PausePanel/VBox/QuitBtn
@onready var tower_panel: Panel = $TowerPanel
@onready var tp_name: Label = $TowerPanel/VBox/TowerName
@onready var tp_stats: Label = $TowerPanel/VBox/TowerStats
@onready var tp_upgrade: Button = $TowerPanel/VBox/UpgradeButton
@onready var tp_promote: Button = $TowerPanel/VBox/PromoteButton
@onready var tp_sell: Button = $TowerPanel/VBox/SellButton

var placement: Node2D
var phase_controller: Node
var draft_director: Node
var _banner_tween: Tween
var _shown_tower: Node = null
var _current_offers: Array = []
var _current_wave_in_planning: int = 1
var _counters: Dictionary = {}
var _wave_set_id: String = "act1"
var _income_tween: Tween

const FACTION_COLORS := {
	"lyonar":    Color(1.0, 0.85, 0.4),
	"songhai":   Color(1.0, 0.4, 0.4),
	"vetruvian": Color(0.95, 0.7, 0.35),
	"abyssian":  Color(0.7, 0.4, 1.0),
	"magmar":    Color(1.0, 0.55, 0.25),
	"vanar":     Color(0.55, 0.85, 1.0),
	"neutral":   Color(0.85, 0.85, 0.85),
}

# Damage-type chip colors. Picks should be readable against the dark button bg.
const TYPE_COLORS := {
	"strike": Color(1.0, 0.85, 0.55),
	"siege":  Color(0.95, 0.70, 0.35),
	"arcane": Color(0.75, 0.55, 1.0),
	"spirit": Color(0.85, 0.50, 1.0),
	"frost":  Color(0.55, 0.85, 1.0),
	"true":   Color(1.0, 1.0, 1.0),
}

var _pact_card_labels: Array = []  # RichTextLabel overlays for colored boon/curse text

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_counters()
	for i in pact_cards.size():
		var idx := i
		pact_cards[idx].pressed.connect(func(): _on_pact_card_pressed(idx))
		# Overlay a RichTextLabel on each card so we can render BBCode-colored
		# boon/curse/evolution text (Button.text is plain only). Mouse-ignore
		# so clicks pass through to the Button.
		var rtl := RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
		rtl.offset_left = 12
		rtl.offset_top = 14
		rtl.offset_right = -12
		rtl.offset_bottom = -12
		pact_cards[idx].add_child(rtl)
		_pact_card_labels.append(rtl)
	pact_panel.visible = false
	PactManager.pacts_changed.connect(_refresh_active_pacts)
	RelicManager.relics_changed.connect(_refresh_active_pacts)
	_refresh_active_pacts()
	WaveEffects.effect_started.connect(_on_wave_effect_started)
	WaveEffects.effect_ended.connect(_on_wave_effect_ended)
	silence_banner.visible = false
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.game_over.connect(_on_game_over)
	# C6: route Gate Shield strip. Built lazily as routes report in so
	# single-topology maps never even instantiate the container.
	GameState.gate_shield_changed.connect(_on_gate_shield_changed)
	for i in offer_btns.size():
		var idx := i
		offer_btns[idx].pressed.connect(func(): _on_offer_pressed(idx))
	reroll_btn.pressed.connect(_on_reroll)
	start_wave_btn.pressed.connect(_on_start_wave)
	pause_btn.toggled.connect(_on_pause_toggled)
	speed_btn.toggled.connect(_on_speed_toggled)
	restart_btn.pressed.connect(_on_restart)
	new_seed_btn.pressed.connect(_on_new_seed)
	menu_btn.pressed.connect(_on_main_menu)
	share_btn.pressed.connect(_on_share)
	tp_upgrade.pressed.connect(_on_upgrade)
	tp_promote.pressed.connect(_on_promote)
	tp_sell.pressed.connect(_on_sell)
	end_panel.visible = false
	tower_panel.visible = false
	pause_overlay.visible = false
	pause_resume_btn.pressed.connect(_close_pause_menu)
	pause_menu_btn.pressed.connect(_on_pause_main_menu)
	pause_quit_btn.pressed.connect(_on_pause_quit)
	_on_gold_changed(GameState.gold)
	_on_lives_changed(GameState.lives)
	_on_wave_changed(GameState.wave)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()
		elif event.keycode == KEY_SPACE:
			pause_btn.button_pressed = not pause_btn.button_pressed
		elif event.keycode == KEY_ENTER and start_wave_btn.visible and not start_wave_btn.disabled:
			_on_start_wave()
		elif event.keycode == KEY_R and reroll_btn.visible and not reroll_btn.disabled:
			_on_reroll()
		elif event.keycode == KEY_1:
			_quick_pick(0)
		elif event.keycode == KEY_2:
			_quick_pick(1)
		elif event.keycode == KEY_3:
			_quick_pick(2)

func _toggle_pause_menu() -> void:
	# ESC toggles a hard pause overlay. The top-bar Pause button is a softer
	# space-bar pause; this one also gates running away to the main menu.
	# Don't toggle when end panel is up (the run is over).
	if end_panel.visible:
		return
	pause_overlay.visible = not pause_overlay.visible
	get_tree().paused = pause_overlay.visible

func _close_pause_menu() -> void:
	pause_overlay.visible = false
	get_tree().paused = false

func _on_pause_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_pause_quit() -> void:
	get_tree().quit()

func _quick_pick(idx: int) -> void:
	if idx < _current_offers.size():
		_on_offer_pressed(idx)

func bind_placement(p: Node2D) -> void:
	placement = p

func bind_phase(pc: Node, dd: Node) -> void:
	phase_controller = pc
	draft_director = dd

func set_seed_label(s: String) -> void:
	seed_label.text = s
	end_seed.text = s

func set_growth_mode_label(label: String) -> void:
	growth_label.text = label

func set_players_label(player_count: int, topology: String) -> void:
	if player_count <= 1:
		players_label.visible = false
	else:
		players_label.visible = true
		players_label.text = "%s · %dp" % [topology.capitalize(), player_count]

func _on_gold_changed(v: int) -> void:
	gold_label.text = str(v)
	_refresh_offers_affordability()
	if _shown_tower:
		_refresh_tower_panel()
	if draft_director:
		_refresh_reroll_label()

var _last_lives: int = GameState.START_LIVES
@onready var lives_box: HBoxContainer = $TopBar/HBox/LivesBox

func _on_lives_changed(v: int) -> void:
	lives_label.text = str(v)
	# Mirror the gate-shield row flash for Core damage so leaks that bypass
	# the shield read just as clearly. No flash on heals or initial reset.
	if v < _last_lives and lives_box != null:
		lives_box.modulate = Color(1.7, 0.5, 0.5, 1.0)
		var t := create_tween()
		t.tween_property(lives_box, "modulate", Color.WHITE, 0.45)
		lives_label.scale = Vector2(1.3, 1.3)
		lives_label.pivot_offset = lives_label.size * 0.5
		var s := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		s.tween_property(lives_label, "scale", Vector2.ONE, 0.45)
	_last_lives = v

func _on_wave_changed(v: int) -> void:
	wave_label.text = "Wave %d" % v

func _on_pause_toggled(pressed: bool) -> void:
	get_tree().paused = pressed
	pause_btn.text = "Resume" if pressed else "Pause"

func _on_speed_toggled(pressed: bool) -> void:
	Engine.time_scale = 2.0 if pressed else 1.0
	speed_btn.text = "2x" if pressed else "1x"

var _daily_recorded: bool = false
var _last_daily_score: int = 0

func _on_game_over(victory: bool) -> void:
	# Ensure RunLog has captured final_gold / final_lives before we read it.
	if RunLog.active:
		RunLog.end_run("victory" if victory else "defeat")
	end_panel.visible = true
	end_label.text = "Victory!" if victory else "Defeat"
	end_label.modulate = Color(0.4, 1, 0.5) if victory else Color(1, 0.4, 0.4)
	# Victory/Defeat audio cue.
	AudioManager.play_event("victory" if victory else "defeat")
	# Full-screen vignette flash to match the moment.
	if victory:
		_flash_phase_vignette(Color(0.6, 1.0, 0.7, 1.0), 0.7)
	else:
		_flash_phase_vignette(Color(1.0, 0.3, 0.3, 1.0), 0.85)
	_populate_run_summary()
	_handle_daily_end()

func _populate_run_summary() -> void:
	var s: Dictionary = RunLog.stats
	end_run_name.text = RunNameGenerator.generate(s)
	end_seed.text = "%s  ·  Wave %d / %d  ·  %s" % [
		RunConfig.format_seed(),
		int(s.get("wave_reached", 0)),
		_total_waves(),
		_growth_mode_short(String(s.get("growth_mode", RunConfig.growth_mode))),
	]
	end_gold_earned.text = str(int(s.get("gold_earned", 0)))
	end_gold_spent.text = str(int(s.get("gold_spent", 0)))
	end_kills.text = str(int(s.get("enemies_killed", 0)))
	end_damage.text = str(int(s.get("damage_dealt", 0)))
	end_leaks.text = "%d  ·  %d" % [int(s.get("leaks", 0)), int(s.get("core_damage_taken", 0))]
	end_units.text = "%d  ·  %d  ·  %d" % [
		int(s.get("units_bought", 0)),
		int(s.get("units_sold", 0)),
		int(s.get("units_upgraded", 0)),
	]
	end_interest.text = "%d  ·  %d" % [
		int(s.get("interest_earned", 0)),
		int(s.get("max_gold_floated", 0)),
	]
	end_highlights.text = _format_highlights(s)
	end_coach.text = _format_coach(s)
	end_coach_header.visible = end_coach.text != ""
	end_coach.visible = end_coach.text != ""
	end_pacts.text = _format_pacts(s)
	end_relics.text = _format_relics(s)

func _growth_mode_short(mode: String) -> String:
	match mode:
		"classic_upgrade":        return "Classic"
		"merge_stars":            return "Merge★"
		"merge_evolution_hybrid": return "Merge+Evo"
		_:                        return mode

func _total_waves() -> int:
	var ws: Dictionary = EnemyFactory.get_wave_set(_wave_set_id)
	if ws.is_empty():
		return 0
	return (ws.get("waves", []) as Array).size()

func _format_highlights(s: Dictionary) -> String:
	var lines: Array[String] = []
	# Top damage unit (by base type — sums all copies of e.g. Silverguard Knight).
	var by_unit: Dictionary = s.get("damage_by_unit", {})
	var top_unit := _argmax_str(by_unit)
	if top_unit != "":
		var def: Dictionary = UnitFactory.get_def(top_unit)
		var name_text: String = def.get("display_name", top_unit)
		lines.append("[color=#ffce6c]Top damage[/color]  %s  -  [b]%d[/b]" % [name_text, int(by_unit[top_unit])])
	# A2: Standout INDIVIDUAL unit (one specific placed instance).
	var top_inst: Dictionary = RunLog.top_instance_by_damage()
	if not top_inst.is_empty():
		var inst_def: Dictionary = UnitFactory.get_def(String(top_inst.get("base_unit_id", "")))
		var inst_name: String = inst_def.get("display_name", String(top_inst.get("base_unit_id", "?")))
		var placed_wave: int = int(top_inst.get("placed_at_wave", 0))
		var waves_alive: int = int(top_inst.get("waves_survived", 0))
		var kills: int = int(top_inst.get("kills", 0))
		var dmg: int = int(top_inst.get("damage", 0))
		lines.append("[color=#9cb8ff]Standout unit[/color]  %s  -  [b]%d[/b] dmg / %d kills (placed W%d, %d waves)" % [
			inst_name, dmg, kills, placed_wave, waves_alive,
		])
	# Most kills by enemy type.
	var kills: Dictionary = s.get("kills_by_enemy", {})
	var top_kill := _argmax_str(kills)
	if top_kill != "":
		var def_e: Dictionary = EnemyFactory.get_def(top_kill)
		var name_text2: String = def_e.get("display_name", top_kill)
		lines.append("[color=#ffce6c]Most killed[/color]  %s  -  [b]%d[/b]" % [name_text2, int(kills[top_kill])])
	# Worst (most leaks) wave.
	var by_wave: Dictionary = s.get("leaks_by_wave", {})
	var worst_wave := _argmax_str(by_wave)
	if worst_wave != "":
		lines.append("[color=#ff7a7a]Worst wave[/color]  Wave %s  -  [b]%d[/b] leaks" % [worst_wave, int(by_wave[worst_wave])])
	# Biggest threat (most-leaked enemy).
	var leaks_enemy: Dictionary = s.get("leaks_by_enemy", {})
	var top_leaker := _argmax_str(leaks_enemy)
	if top_leaker != "":
		var def_l: Dictionary = EnemyFactory.get_def(top_leaker)
		var name_text3: String = def_l.get("display_name", top_leaker)
		lines.append("[color=#ff7a7a]Biggest threat[/color]  %s  -  [b]%d[/b] reached the base" % [name_text3, int(leaks_enemy[top_leaker])])
	if lines.is_empty():
		return "[i]No combat data recorded.[/i]"
	return "\n".join(lines)

func _format_coach(s: Dictionary) -> String:
	var insights: Array = FailureCoach.analyze(s)
	if insights.is_empty():
		return ""
	var blocks: Array[String] = []
	for ins in insights:
		var sev: int = int(ins.get("severity", 1))
		var color := "#9cb8ff"  # severity 1 - info blue
		if sev == 2:
			color = "#ffce6c"     # warning gold
		elif sev == 3:
			color = "#ff7a7a"     # primary red
		var title: String = ins.get("title", "")
		var body: String = ins.get("body", "")
		var hint: String = ins.get("hint", "")
		var block := "[color=%s][b]%s[/b][/color]\n%s\n[color=#a0a0a8][i]%s[/i][/color]" % [color, title, body, hint]
		blocks.append(block)
	return "\n\n".join(blocks)

func _format_pacts(s: Dictionary) -> String:
	var ids: Array = s.get("pacts", [])
	if ids.is_empty():
		return "[color=#7a7a82]No pacts taken this run.[/color]"
	var names: Array[String] = []
	for pid in ids:
		var def: Dictionary = PactManager.get_def(pid)
		names.append(def.get("display_name", pid))
	return "[color=#a0a0a8]Pacts:[/color]  [color=#ffce6c]" + "  ·  ".join(names) + "[/color]"

func _format_relics(s: Dictionary) -> String:
	var ids: Array = s.get("relics", [])
	if ids.is_empty():
		return ""
	var names: Array[String] = []
	for rid in ids:
		var def: Dictionary = RelicManager.get_def(rid)
		names.append(def.get("display_name", rid))
	return "[color=#a0a0a8]Relics:[/color]  [color=#8cc8ff]" + "  ·  ".join(names) + "[/color]"

func _argmax_str(d: Dictionary) -> String:
	var best_key := ""
	var best_val: int = -1
	for k in d:
		var v := int(d[k])
		if v > best_val:
			best_val = v
			best_key = String(k)
	return best_key

func _handle_daily_end() -> void:
	# Show the daily badge / score even on a non-daily run if it ever fires twice;
	# but only record once per game-over and only when actually in daily mode.
	daily_badge.visible = RunConfig.is_daily
	daily_score_label.visible = RunConfig.is_daily
	daily_rank_label.visible = RunConfig.is_daily
	share_btn.visible = RunConfig.is_daily
	if not RunConfig.is_daily:
		return
	if _daily_recorded:
		return
	var score: int = Daily.compute_score(RunLog.stats)
	_last_daily_score = score
	Daily.record_run(RunLog.stats, score)
	_daily_recorded = true
	daily_score_label.text = "Score  %d" % score
	# Compute "Run #N today" + comparison vs best.
	var runs: Array = Daily.today_runs()
	var n: int = runs.size()
	var best: int = score
	for r in runs:
		best = max(best, int(r.get("score", 0)))
	if score == best:
		daily_rank_label.text = "Daily run #%d  ·  new personal best for today" % n
	else:
		daily_rank_label.text = "Daily run #%d  ·  best today: %d" % [n, best]

func _on_share() -> void:
	var max_waves: int = _total_waves()
	var text: String = Daily.share_text(RunLog.stats, _last_daily_score, max_waves)
	DisplayServer.clipboard_set(text)
	share_btn.text = "Copied!"
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(share_btn):
		share_btn.text = "Copy Share Text"

func _on_restart() -> void:
	# Same seed (daily mode preserves daily-ness).
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_new_seed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RunConfig.randomize_seed()
	RunConfig.is_daily = false  # leaving the daily seed exits daily mode
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_wave_effect_started(effect_id: String) -> void:
	if effect_id == "silence":
		silence_banner.visible = true
		_pulse_silence_banner()

func _on_wave_effect_ended(effect_id: String) -> void:
	if effect_id == "silence":
		silence_banner.visible = false

func _pulse_silence_banner() -> void:
	# Subtle pulse from 0.6 to 1.0 alpha while silence is active.
	var t := create_tween().set_loops(8)
	t.tween_property(silence_banner, "modulate:a", 0.55, 0.18)
	t.tween_property(silence_banner, "modulate:a", 1.0, 0.18)

func show_wave_banner_planning(wave: int) -> void:
	_current_wave_in_planning = wave
	_update_wave_preview(wave, false)
	_animate_banner("Planning · Wave %d" % wave, Color(1, 1, 1))

func show_wave_banner(wave_num: int) -> void:
	_update_wave_preview(wave_num, true)
	# Highlight in red when this wave has the BOSS tag.
	var tags := _wave_tags(wave_num)
	if "boss" in tags:
		_animate_banner("⚠  Wave %d  ·  BOSS  ⚠" % wave_num, Color(1.0, 0.5, 0.4))
		AudioManager.play_event("boss_warning")
		# Heavier red vignette so the player feels the threat.
		_flash_phase_vignette(Color(1.0, 0.3, 0.25, 1.0), 0.85)
	else:
		_animate_banner("Wave %d" % wave_num, Color(1, 1, 1))

func _wave_tags(wave_num: int) -> Array:
	var ws: Dictionary = EnemyFactory.get_wave_set(_wave_set_id)
	if ws.is_empty():
		return []
	var waves: Array = ws.get("waves", [])
	if wave_num <= 0 or wave_num > waves.size():
		return []
	return (waves[wave_num - 1] as Dictionary).get("tags", [])

func _load_counters() -> void:
	const PATH := "res://data/counters.json"
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_counters = parsed

func _update_wave_preview(wave_num: int, is_active: bool) -> void:
	var wave_set: Dictionary = EnemyFactory.get_wave_set(_wave_set_id)
	if wave_set.is_empty():
		return
	var waves: Array = wave_set.get("waves", [])
	if wave_num <= 0 or wave_num > waves.size():
		return
	var wdef: Dictionary = waves[wave_num - 1]
	var prefix := "Wave %d" % wave_num
	if is_active:
		prefix += " (active)"
	wave_title.text = "%s: %s" % [prefix, wdef.get("name", "")]
	var tags: Array = wdef.get("tags", [])
	wave_tags.text = _format_tag_chips(tags)
	var spawn_line: String = _format_spawn_summary(wdef)
	var hint_body: String = _format_hints(tags)
	if spawn_line != "" and hint_body != "":
		wave_hint.text = spawn_line + "\n" + hint_body
	elif spawn_line != "":
		wave_hint.text = spawn_line
	else:
		wave_hint.text = hint_body

# Aggregate spawn_groups in a wave def into a "Nx Name, Mx Other" summary.
# Falls back to the enemy_id (capitalized) if the def has no display_name.
func _format_spawn_summary(wdef: Dictionary) -> String:
	var groups: Array = wdef.get("spawn_groups", [])
	if groups.is_empty():
		return ""
	var counts: Dictionary = {}
	var order: Array = []
	for g in groups:
		var eid: String = String(g.get("enemy_id", ""))
		if eid == "":
			continue
		var c: int = int(g.get("count", 0))
		if not counts.has(eid):
			counts[eid] = 0
			order.append(eid)
		counts[eid] = counts[eid] + c
	if counts.is_empty():
		return ""
	var parts: Array[String] = []
	for eid in order:
		var def: Dictionary = EnemyFactory.get_def(eid)
		var name: String = String(def.get("display_name", eid.capitalize()))
		parts.append("%d× %s" % [counts[eid], name])
	return "Spawns: " + ", ".join(parts)

func _format_tag_chips(tags: Array) -> String:
	if tags.is_empty():
		return ""
	var parts: Array[String] = []
	for tag in tags:
		var info: Dictionary = _counters.get(tag, {})
		var col: Array = info.get("color", [1, 1, 1])
		var label_text: String = info.get("label", String(tag).capitalize())
		var hex := "%02x%02x%02x" % [int(col[0] * 255), int(col[1] * 255), int(col[2] * 255)]
		parts.append("[color=#%s][b]%s[/b][/color]" % [hex, label_text])
	return "  ·  ".join(parts)

func _format_hints(tags: Array) -> String:
	if tags.is_empty():
		return ""
	var lines: Array[String] = []
	for tag in tags:
		var info: Dictionary = _counters.get(tag, {})
		var hint: String = info.get("hint", "")
		if hint != "" and not (hint in lines):
			lines.append(hint)
	# Cap at 2 lines to keep the panel readable.
	if lines.size() > 2:
		lines = lines.slice(0, 2)
	return "\n".join(lines)

# --- Pact UI ---

func show_pact_choice(options: Array) -> void:
	_show_choice_modal(options, "pact")

func show_relic_choice(options: Array) -> void:
	_show_choice_modal(options, "relic")

func show_evolution_choice(base_unit_id: String, star_level: int) -> void:
	# A6: surface the evolution branch picker for a freshly-promoted tower.
	# Stores the base_unit_id so the dispatch handler can resolve the
	# EvolutionDef back from the click.
	var choices: Array = EvolutionManager.get_choices(base_unit_id, star_level)
	if choices.is_empty():
		return
	_evolution_base_unit_id = base_unit_id
	_show_choice_modal(choices, "evolution")

func _show_choice_modal(options: Array, kind: String) -> void:
	_current_choice_kind = kind
	match kind:
		"relic":
			pact_panel_title.text = "Choose a Relic"
			pact_panel_subtitle.text = "Pure boon. Active for the rest of the run."
		"evolution":
			pact_panel_title.text = "Choose an Evolution"
			pact_panel_subtitle.text = "Permanent for this unit. Picks a behavior branch."
		_:
			pact_panel_title.text = "Choose your Pact"
			pact_panel_subtitle.text = "Boon and curse. Active for the rest of the run."
	for i in pact_cards.size():
		var btn := pact_cards[i]
		var rtl: RichTextLabel = _pact_card_labels[i] if i < _pact_card_labels.size() else null
		# Plain-text fallback in the Button.text stays empty — the RichTextLabel
		# overlay carries the visible text with BBCode coloring.
		btn.text = ""
		if i < options.size():
			# Evolution mode: options is Array of EvolutionDef dicts (not ids).
			if kind == "evolution":
				var def: Dictionary = options[i]
				if rtl:
					rtl.text = "[center][b]" + String(def.get("display_name", "?")) + "[/b][/center]\n\n" \
						+ "[color=#a0c8ff]" + String(def.get("description", "")) + "[/color]"
				btn.visible = true
				btn.set_meta("choice_id", def.get("id", ""))
				continue
			var id: String = options[i]
			var def: Dictionary
			if kind == "relic":
				def = RelicManager.get_def(id)
				if rtl:
					rtl.text = "[center][b]" + String(def.get("display_name", id)) + "[/b][/center]\n\n" \
						+ "[color=#8fff8f][b]Boon:[/b][/color]\n" \
						+ "[color=#cfe8cf]" + String(def.get("boon", "")) + "[/color]"
			else:
				def = PactManager.get_def(id)
				if rtl:
					rtl.text = "[center][b]" + String(def.get("display_name", id)) + "[/b][/center]\n\n" \
						+ "[color=#8fff8f][b]Boon:[/b][/color]\n" \
						+ "[color=#cfe8cf]" + String(def.get("boon", "")) + "[/color]\n\n" \
						+ "[color=#ff8f8f][b]Curse:[/b][/color]\n" \
						+ "[color=#f0c0c0]" + String(def.get("curse", "")) + "[/color]"
			btn.visible = true
			btn.set_meta("choice_id", id)
		else:
			btn.visible = false
			btn.set_meta("choice_id", "")
			if rtl:
				rtl.text = ""
	pact_panel.visible = true

func hide_pact_choice() -> void:
	pact_panel.visible = false

func _on_pact_card_pressed(idx: int) -> void:
	if idx >= pact_cards.size():
		return
	var cid: String = pact_cards[idx].get_meta("choice_id", "")
	if cid == "":
		return
	# Route through the event system so the kind-specific SFX plays.
	# (unit_evolve uses wave_start — heftier — for the evolution moment.)
	var evt: String = "pact_chosen"
	var burst_color: Color = Color(0.7, 0.95, 1.0)
	match _current_choice_kind:
		"relic":
			evt = "relic_chosen"
			burst_color = Color(0.9, 0.7, 1.0)
		"evolution":
			evt = "unit_evolve"
			burst_color = Color(0.6, 0.9, 1.0)
	AudioManager.play_event(evt)
	# Celebration burst at the picked card's center.
	var host: Node = get_tree().current_scene
	var card: Button = pact_cards[idx]
	if host and card and card.is_inside_tree():
		var card_center: Vector2 = card.get_global_rect().get_center()
		CombatFX.burst(host, card_center, burst_color, 22, 1.1)
		CombatFX.placement_pulse(host, card_center, Color(burst_color.r, burst_color.g, burst_color.b, 0.9))
	hide_pact_choice()
	match _current_choice_kind:
		"relic":     CommandBus.dispatch(ChooseRelicCommand.new(cid))
		"evolution": CommandBus.dispatch(_CHOOSE_EVO_CMD.new(cid))
		_:           CommandBus.dispatch(ChoosePactCommand.new(cid))

func show_income_breakdown(breakdown: Dictionary) -> void:
	# Compose a compact "+N" badge with bbcode coloring per component, then fade.
	var base: int = int(breakdown.get("base", 0))
	var interest: int = int(breakdown.get("interest", 0))
	var pact: int = int(breakdown.get("pact", 0))
	var total: int = int(breakdown.get("total", 0))
	if total <= 0:
		return
	var parts: Array[String] = []
	if base > 0:
		parts.append("+%d base" % base)
	if interest > 0:
		parts.append("[color=#ffce6c]+%d interest[/color]" % interest)
	if pact > 0:
		parts.append("[color=#a98cff]+%d pact[/color]" % pact)
	var detail := "  ·  ".join(parts)
	income_floater.text = "[b]+%d[/b]  %s" % [total, detail]
	# Animate: fade in, sit briefly, fade out.
	if _income_tween and _income_tween.is_valid():
		_income_tween.kill()
	income_floater.modulate = Color(1, 1, 1, 0)
	_income_tween = create_tween()
	_income_tween.tween_property(income_floater, "modulate:a", 1.0, 0.2)
	_income_tween.tween_interval(2.0)
	_income_tween.tween_property(income_floater, "modulate:a", 0.0, 0.5)

func _refresh_active_pacts(_unused = null) -> void:
	var pact_parts: Array[String] = []
	for pid in PactManager.active_ids:
		var def: Dictionary = PactManager.get_def(pid)
		pact_parts.append("[b][color=#ffce6c]%s[/color][/b]" % def.get("display_name", pid))
	var relic_parts: Array[String] = []
	for rid in RelicManager.active_ids:
		var def: Dictionary = RelicManager.get_def(rid)
		relic_parts.append("[b][color=#8cc8ff]%s[/color][/b]" % def.get("display_name", rid))
	var lines: Array[String] = []
	if not pact_parts.is_empty():
		lines.append("[color=#8a8a92]Pacts:[/color]  " + "  ·  ".join(pact_parts))
	if not relic_parts.is_empty():
		lines.append("[color=#8a8a92]Relics:[/color]  " + "  ·  ".join(relic_parts))
	active_pacts_label.text = "\n".join(lines)

func _animate_banner(text: String, color: Color) -> void:
	wave_banner.text = text
	wave_banner.modulate = Color(color.r, color.g, color.b, 0)
	wave_banner.scale = Vector2(0.6, 0.6)
	wave_banner.pivot_offset = wave_banner.size * 0.5
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween().set_parallel(true)
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_property(wave_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(0.9)
	_banner_tween.chain().tween_property(wave_banner, "modulate:a", 0.0, 0.5)

func on_phase_changed(phase: String) -> void:
	var planning := phase == "planning"
	# Draft controls only meaningful during planning.
	for b in offer_btns:
		b.disabled = not planning
	reroll_btn.disabled = not planning
	start_wave_btn.disabled = not planning
	start_wave_btn.visible = planning
	# Reroll button visible only during planning.
	reroll_btn.visible = planning
	# Phase flash — soft colored vignette as the phase transitions in.
	if phase == "combat":
		_flash_phase_vignette(Color(1.0, 0.4, 0.3, 1.0), 0.75)
	elif phase == "planning":
		_flash_phase_vignette(Color(0.45, 0.75, 1.0, 1.0), 0.45)

func show_draft_offers(offers: Array) -> void:
	_current_offers = offers.duplicate()
	for i in offer_btns.size():
		if i < offers.size():
			var def: Dictionary = UnitFactory.get_def(offers[i])
			var btn := offer_btns[i]
			var desc := offer_descs[i]
			var chip := offer_chips[i]
			var trait_chip := offer_trait_chips[i]
			var portrait := offer_portraits[i]
			var trait_id: String = draft_director.get_trait_for(i) if draft_director else ""
			var flaw_id: String = draft_director.get_flaw_for(i) if draft_director else ""
			btn.visible = true
			desc.visible = true
			chip.visible = true
			trait_chip.visible = true
			portrait.visible = true
			var fac: String = def.get("faction", "neutral")
			var faction_color: Color = FACTION_COLORS.get(fac, Color.WHITE)
			btn.modulate = faction_color.lerp(Color.WHITE, 0.45)
			var effective_cost: int = UnitFactory.effective_cost(offers[i], trait_id, flaw_id)
			var cost_text: String = "%dg" % effective_cost
			if effective_cost != int(def.get("cost", 0)):
				cost_text += " (was %dg)" % int(def.get("cost", 0))
			btn.text = "[%d] %s\n%s · %s\n%s" % [
				i + 1,
				def.get("display_name", offers[i]),
				cost_text,
				fac.capitalize(),
				_role_summary(def),
			]
			# A4: prepend shard progress line if in merge mode and unit is owned/has shards
			# (OfferDesc is a plain Label — no BBCode here; just terse text).
			var desc_text: String = def.get("description", "")
			if RunConfig.growth_mode in ["merge_stars", "merge_evolution_hybrid"]:
				var shards: int = RunLog.shard_count(offers[i])
				var owns: bool = _player_owns_base(offers[i])
				if owns or shards > 0:
					var progress: String
					if shards < 2:
						progress = "%d/2★" % shards
					elif shards < 5:
						progress = "%d/5★★" % shards
					else:
						progress = "★★★"
					desc_text = "%s · %s\n%s" % [progress, "+1 shard" if owns else "places first", desc_text]
			desc.text = desc_text
			_set_type_chip(chip, def)
			_set_trait_chip(trait_chip, trait_id, flaw_id)
			portrait.texture = _portrait_for(offers[i])
			portrait.modulate = faction_color.lerp(Color.WHITE, 0.25)
			# Tint the card frame itself with a very subtle faction wash so
			# picks are scannable by color even without reading the chip.
			offer_boxes[i].self_modulate = faction_color.lerp(Color.WHITE, 0.78)
			offer_boxes[i].visible = true
		else:
			offer_boxes[i].visible = false
	_refresh_offers_affordability()
	_refresh_reroll_label()

func _player_owns_base(base_unit_id: String) -> bool:
	# A4: helper for shard-progress chip in offer cards.
	for t in get_tree().get_nodes_in_group("towers"):
		if is_instance_valid(t) and "unit_id" in t and t.unit_id == base_unit_id:
			return true
	return false

func _portrait_for(unit_id: String) -> Texture2D:
	var sf: SpriteFrames = UnitFactory.sprite_frames_for(unit_id)
	if sf == null:
		return null
	# Prefer idle / breathing for a calm portrait. Some atlases prefix animation
	# names with the asset id (e.g. "f2_hammonbladeseeker_idle"), so substring-match.
	var names: PackedStringArray = sf.get_animation_names()
	for keyword in ["idle", "breathing", "breathe", "breath", "default"]:
		for n in names:
			if String(n).ends_with(keyword) and sf.get_frame_count(n) > 0:
				return sf.get_frame_texture(n, 0)
	for n in names:
		if sf.get_frame_count(n) > 0:
			return sf.get_frame_texture(n, 0)
	return null

const TRAIT_RARITY_COLOR := {
	"common": Color(0.85, 0.85, 0.9),
	"uncommon": Color(0.55, 1.0, 0.7),
	"rare": Color(0.65, 0.8, 1.0),
}

func _set_trait_chip(chip: Label, trait_id: String, flaw_id: String = "") -> void:
	# Combined "TRAIT · X / FLAW · Y" line. Flaw text is shown in muted red.
	var parts: Array[String] = []
	if trait_id != "":
		var tdef: Dictionary = TraitManager.get_def(trait_id)
		if not tdef.is_empty():
			parts.append("TRAIT · " + tdef.get("display_name", trait_id).to_upper())
	if flaw_id != "":
		var fdef: Dictionary = FlawManager.get_def(flaw_id)
		if not fdef.is_empty():
			parts.append("FLAW · " + fdef.get("display_name", flaw_id).to_upper())
	if parts.is_empty():
		chip.text = ""
		return
	chip.text = "  ·  ".join(parts)
	# Color: red-tinted if flaw present, else rarity color.
	if flaw_id != "":
		chip.modulate = Color(1.0, 0.7, 0.65)
	else:
		var rarity: String = TraitManager.get_def(trait_id).get("rarity", "common")
		chip.modulate = TRAIT_RARITY_COLOR.get(rarity, Color.WHITE)

func _set_type_chip(chip: Label, def: Dictionary) -> void:
	# Aura towers don't deal damage type — surface them as AURA instead.
	if float(def.get("buff_damage_mult", 0.0)) > 0.0 and int(def.get("damage", 0)) <= 0:
		chip.text = "AURA"
		chip.modulate = Color(1.0, 0.85, 0.3)
		return
	var dt: String = def.get("damage_type", "strike")
	chip.text = String(dt).to_upper()
	chip.modulate = TYPE_COLORS.get(dt, Color.WHITE)

func _role_summary(def: Dictionary) -> String:
	var parts: Array[String] = []
	if int(def.get("damage", 0)) > 0:
		parts.append("Dmg %d" % int(def.get("damage", 0)))
		parts.append("Rate %.1f/s" % float(def.get("fire_rate", 0.0)))
	if float(def.get("splash_radius", 0.0)) > 0.0:
		parts.append("Splash")
	if float(def.get("slow_duration", 0.0)) > 0.0:
		parts.append("Slow")
	if float(def.get("buff_damage_mult", 0.0)) > 0.0:
		parts.append("+%d%% Aura" % int(round(float(def["buff_damage_mult"]) * 100)))
	return " · ".join(parts)

func _refresh_offers_affordability() -> void:
	for i in _current_offers.size():
		var def: Dictionary = UnitFactory.get_def(_current_offers[i])
		var c: int = int(def.get("cost", 0))
		var affordable: bool = GameState.gold >= c
		offer_btns[i].disabled = not affordable
		offer_boxes[i].modulate = Color(1, 1, 1, 1) if affordable else Color(0.65, 0.65, 0.7, 0.85)

func _refresh_reroll_label() -> void:
	if not draft_director:
		return
	reroll_btn.text = "Reroll (%dg)" % draft_director.reroll_cost()
	reroll_btn.disabled = GameState.gold < draft_director.reroll_cost()

func _on_offer_pressed(idx: int) -> void:
	if idx >= _current_offers.size():
		return
	AudioManager.play("ui_select")
	CommandBus.dispatch(BuyOfferCommand.new(idx))

func on_preview_changed(unit_id: String) -> void:
	# Highlight which offer corresponds to the active preview.
	for i in offer_btns.size():
		var sel: bool = i < _current_offers.size() and _current_offers[i] == unit_id and unit_id != ""
		offer_btns[i].button_pressed = sel

func _on_reroll() -> void:
	CommandBus.dispatch(RerollShopCommand.new())

func _on_start_wave() -> void:
	if placement:
		placement.cancel_selection()
	CommandBus.dispatch(StartWaveCommand.new())

func show_tower_panel(tower: Node) -> void:
	_shown_tower = tower
	_refresh_tower_panel()
	tower_panel.visible = true
	# A6: if this tower has a pending evolution and we're in hybrid mode,
	# pop the choice modal. Hidden by the player picking or by selecting
	# another tower.
	if tower and "pending_evolution_star" in tower and int(tower.pending_evolution_star) > 0:
		if RunConfig.growth_mode == "merge_evolution_hybrid":
			show_evolution_choice(tower.unit_id, int(tower.pending_evolution_star))

func hide_tower_panel() -> void:
	_shown_tower = null
	tower_panel.visible = false

func _instance_damage_for(instance_id: String) -> int:
	var instances: Dictionary = RunLog.stats.get("instances", {})
	if not instances.has(instance_id):
		return 0
	return int((instances[instance_id] as Dictionary).get("damage", 0))

func _refresh_tower_panel() -> void:
	if not _shown_tower or not is_instance_valid(_shown_tower):
		hide_tower_panel()
		return
	var t = _shown_tower
	var star_text: String = ""
	if t.star_level >= 2:
		star_text = "  " + "★".repeat(t.star_level)
	var name_text: String = "%s  (Lvl %d)%s" % [t.display_name, t.level + 1, star_text]
	# A6: append the chosen evolution branch name (per star) if any.
	if t.has_method("get") and "evolution_choices" in t:
		for star_key in (t.evolution_choices as Dictionary).keys():
			var evo_id: String = String((t.evolution_choices as Dictionary)[star_key])
			var evo_def: Dictionary = EvolutionManager.get_def(t.unit_id, evo_id)
			if not evo_def.is_empty():
				name_text += "  ·  %s" % evo_def.get("display_name", evo_id)
	if t.trait_id != "":
		name_text += "  ·  %s" % t.trait_name
	if t.flaw_id != "":
		name_text += "  /  %s" % t.flaw_name
	tp_name.text = name_text
	if t.is_buff_tower():
		tp_stats.text = "Aura buff +%d%%\nRadius %d" % [int(round(t.buff_damage_mult * 100)), int(t.buff_radius)]
	else:
		var evo: Dictionary = t.evolution_progress()
		var evo_line: String = ""
		if int(evo.tier) > 0:
			evo_line = "\n★%d  %s (%d kills)" % [int(evo.tier), evo.name, int(evo.kills)]
		elif int(evo.next_threshold) > 0:
			evo_line = "\n%d / %d kills to Tempered" % [int(evo.kills), int(evo.next_threshold)]
		# A2 instance stats: damage dealt / kills / waves survived
		# (kills_count == evo.kills already shown above, so only show damage + waves here).
		var inst_line: String = ""
		if t.instance_id != "":
			var inst_damage: int = _instance_damage_for(t.instance_id)
			inst_line = "\n%d dmg this run  ·  %d waves survived" % [inst_damage, int(t.waves_survived)]
		# A4: shard count for this base type, if in merge mode.
		var shard_line: String = ""
		if RunConfig.growth_mode in ["merge_stars", "merge_evolution_hybrid"]:
			var shards: int = RunLog.shard_count(t.unit_id)
			if shards > 0:
				var threshold: String = "2★" if shards < 2 else ("5★★" if shards < 5 else "max")
				shard_line = "\nShards: %d (next: %s)" % [shards, threshold]
		tp_stats.text = "Dmg %d  ·  Range %d  ·  %.1f/s%s%s%s" % [
			t.effective_damage(), int(t.range_radius), t.fire_rate, evo_line, inst_line, shard_line
		]
	var u_cost: int = t.upgrade_cost()
	tp_upgrade.text = "Upgrade (%dg)" % u_cost
	# A3: classic upgrades are only available in modes that include the
	# classic upgrade path. merge_stars mode replaces them with star levels
	# (A5); the upgrade button hides so the inspect panel doesn't lie about
	# what's possible.
	var classic_allowed: bool = RunConfig.growth_mode in ["classic_upgrade", "merge_evolution_hybrid"]
	tp_upgrade.visible = classic_allowed
	tp_upgrade.disabled = GameState.gold < u_cost or t.level >= 4
	# A5: star promotion button (visible in merge modes only)
	var merge_mode: bool = RunConfig.growth_mode in ["merge_stars", "merge_evolution_hybrid"]
	tp_promote.visible = merge_mode and t.star_level < 3
	if tp_promote.visible:
		var p_cost: int = t.star_promotion_cost()
		var have: int = RunLog.shard_count(t.unit_id)
		var next_star: int = t.star_level + 1
		tp_promote.text = "Promote to %d★ (%d/%d shards)" % [next_star, have, p_cost]
		tp_promote.disabled = have < p_cost
	tp_sell.text = "Sell (+%dg)" % t.sell_value()

func _on_upgrade() -> void:
	CommandBus.dispatch(UpgradeUnitCommand.new())

const _PROMOTE_CMD := preload("res://scripts/commands/promote_unit_command.gd")
func _on_promote() -> void:
	CommandBus.dispatch(_PROMOTE_CMD.new())

func _on_sell() -> void:
	CommandBus.dispatch(SellUnitCommand.new())

# Phase-flash vignette: lazily-built TextureRect full-screen overlay with a
# soft radial gradient (transparent middle, opaque edges). Tinted + faded by
# on_phase_changed.
var _phase_flash: TextureRect = null

func _ensure_phase_flash() -> void:
	if _phase_flash != null:
		return
	_phase_flash = TextureRect.new()
	_phase_flash.name = "PhaseFlash"
	_phase_flash.texture = _build_vignette_texture(256)
	_phase_flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_phase_flash.stretch_mode = TextureRect.STRETCH_SCALE
	_phase_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_phase_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_flash.modulate = Color(1, 1, 1, 0)
	_phase_flash.z_index = -1
	add_child(_phase_flash)
	# Send it behind other HUD children but keep it within the CanvasLayer.
	move_child(_phase_flash, 0)

func _flash_phase_vignette(color: Color, peak_alpha: float) -> void:
	_ensure_phase_flash()
	if _phase_flash == null:
		return
	_phase_flash.modulate = Color(color.r, color.g, color.b, peak_alpha)
	var t := create_tween()
	t.tween_property(_phase_flash, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _build_vignette_texture(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(size, size) * 0.5
	var max_d: float = c.length()
	var inner_frac := 0.55
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c) / max_d
			if d <= inner_frac:
				continue
			var t: float = (d - inner_frac) / (1.0 - inner_frac)
			t = t * t
			img.set_pixel(x, y, Color(1, 1, 1, clamp(t, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

# C6: gate shield UI. Built lazily so single-topology maps never create it.
const _GATE_SHIELD_COLORS := [
	Color(0.55, 0.85, 1.0, 1.0),   # P1 / route 0 — frost blue
	Color(1.00, 0.85, 0.45, 1.0),  # P2 / route 1 — gold
	Color(1.00, 0.55, 0.55, 1.0),  # P3 / route 2 — coral
	Color(0.60, 1.00, 0.65, 1.0),  # P4 / route 3 — green
]
var _gate_strip: VBoxContainer = null
var _gate_rows: Dictionary = {}  # route_id -> Dictionary{label, bar}
var _gate_route_order: Array = []

func _ensure_gate_strip() -> void:
	if _gate_strip != null:
		return
	_gate_strip = VBoxContainer.new()
	_gate_strip.name = "GateShieldStrip"
	_gate_strip.add_theme_constant_override("separation", 4)
	_gate_strip.position = Vector2(12, 56)  # just below the TopBar
	_gate_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gate_strip)

func _ensure_gate_row(route_id: String, max_hp: int) -> void:
	if _gate_rows.has(route_id):
		return
	_ensure_gate_strip()
	var idx: int = _gate_route_order.size()
	_gate_route_order.append(route_id)
	var color: Color = _GATE_SHIELD_COLORS[idx % _GATE_SHIELD_COLORS.size()]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = "%s gate" % route_id.capitalize()
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(80, 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_hp
	bar.value = max_hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(110, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	row.add_child(bar)
	_gate_strip.add_child(row)
	_gate_rows[route_id] = {"label": label, "bar": bar, "row": row, "color": color}

func _on_gate_shield_changed(route_id: String, current: int, max_hp: int) -> void:
	if route_id == "":
		return
	_ensure_gate_row(route_id, max_hp)
	var entry: Dictionary = _gate_rows[route_id]
	var bar: ProgressBar = entry["bar"]
	bar.max_value = max_hp
	bar.value = current
	# Flash the row briefly to call attention to the damaged lane.
	var row: HBoxContainer = entry["row"]
	row.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var t := create_tween()
	t.tween_property(row, "modulate", Color.WHITE, 0.35)
	if current <= 0:
		# Broken: dim the row so the player sees the lane is now bleeding into Core.
		var col: Color = entry["color"]
		entry["label"].add_theme_color_override("font_color", Color(col.r * 0.5, col.g * 0.5, col.b * 0.5, 1.0))
