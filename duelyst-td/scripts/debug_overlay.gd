extends CanvasLayer

@onready var stats_panel: Panel = $StatsPanel
@onready var stats_text: Label = $StatsPanel/VBox/StatsText
@onready var export_btn: Button = $StatsPanel/VBox/ExportButton
@onready var cmd_panel: Panel = $CmdPanel
@onready var cmd_text: Label = $CmdPanel/VBox/CmdText

var _spawner: Node = null
var _enemy_shells: Array = []   # cached shells with sprite_frames_ready=true
var _shells_loaded: bool = false

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stats_panel.visible = false
	cmd_panel.visible = false
	export_btn.pressed.connect(_on_export)
	RunLog.stats_changed.connect(_refresh_stats)
	CommandBus.command_dispatched.connect(_refresh_cmds)

func bind_spawner(spawner: Node) -> void:
	_spawner = spawner

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			stats_panel.visible = not stats_panel.visible
			if stats_panel.visible:
				_refresh_stats(RunLog.stats)
		elif event.keycode == KEY_F2:
			cmd_panel.visible = not cmd_panel.visible
			if cmd_panel.visible:
				_refresh_cmds({})
		elif event.keycode == KEY_F4:
			_debug_spawn_random_shell()

func _debug_spawn_random_shell() -> void:
	# Spawns a random sprite-ready generated enemy at the path start. Useful
	# for visually verifying that Duelyst units land on the board as enemies
	# without committing to a full wave. Silent no-op if shells don't exist
	# yet (run D6 + D8 first) or spawner is offline.
	if _spawner == null:
		return
	if not _shells_loaded:
		_load_shells()
	if _enemy_shells.is_empty():
		return
	var shell: Dictionary = _enemy_shells[randi() % _enemy_shells.size()]
	if _spawner.has_method("debug_spawn_shell"):
		_spawner.debug_spawn_shell(shell)

func _load_shells() -> void:
	_shells_loaded = true
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var path: String = settings.output_path_for("enemy_shells.json")
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var all: Array = parsed.get("shells", [])
	for s in all:
		if s.get("sprite_frames_ready", false) and s.get("enabled_in_debug", false):
			_enemy_shells.append(s)

func _refresh_stats(_s: Dictionary) -> void:
	if not stats_panel.visible:
		return
	var s := RunLog.stats
	var lines: Array[String] = []
	lines.append("Seed:   SHARD-%08X" % (int(s.get("seed", 0)) & 0xFFFFFFFF))
	lines.append("Wave:   %d" % int(s.get("wave_reached", 0)))
	lines.append("Result: %s" % str(s.get("result", "—")))
	lines.append("Growth: %s" % str(s.get("growth_mode", "—")))
	lines.append("Players: %d  ·  topology: %s" % [int(s.get("player_count", 1)), str(s.get("session_topology", "solo"))])
	lines.append("")
	lines.append("Gold earned: %d" % int(s.get("gold_earned", 0)))
	lines.append("Gold spent:  %d" % int(s.get("gold_spent", 0)))
	lines.append("Units bought:    %d" % int(s.get("units_bought", 0)))
	lines.append("Units sold:      %d" % int(s.get("units_sold", 0)))
	lines.append("Units upgraded:  %d" % int(s.get("units_upgraded", 0)))
	lines.append("Rerolls: %d" % int(s.get("rerolls", 0)))
	lines.append("")
	lines.append("Enemies killed: %d" % int(s.get("enemies_killed", 0)))
	lines.append("Leaks:          %d" % int(s.get("leaks", 0)))
	lines.append("Damage dealt:   %d" % int(s.get("damage_dealt", 0)))
	stats_text.text = "\n".join(lines)

func _refresh_cmds(_r: Dictionary) -> void:
	if not cmd_panel.visible:
		return
	var recent := CommandBus.recent(15)
	var lines: Array[String] = []
	for r in recent:
		var mark := "✓" if r.get("success", false) else "✗"
		var line := "%s %s" % [mark, r.get("describe", "?")]
		if not r.get("success", false):
			line += "  — %s" % r.get("reason", "")
		lines.append(line)
	if lines.is_empty():
		cmd_text.text = "(no commands yet)"
	else:
		cmd_text.text = "\n".join(lines)

func _on_export() -> void:
	var path := RunLog.save_to_file()
	# Visual confirmation in the stats text.
	var prev := stats_text.text
	stats_text.text = "Exported to %s\n\n%s" % [path, prev]
