extends Control

# Match History: scans user://run_log_*.json files (each saved by RunLog at
# end of a run) and renders them as a chronological list. Latest first.

@onready var subtitle: Label = $Root/TopBar/Subtitle
@onready var refresh_btn: Button = $Root/TopBar/RefreshBtn
@onready var back_btn: Button = $Root/TopBar/BackBtn
@onready var list_label: RichTextLabel = $Root/ScrollContainer/List

const LOG_PREFIX := "run_log_"

const RESULT_COLOR := {
	"victory":     "#8fff8f",
	"defeat":      "#ff8f8f",
	"abandoned":   "#cccc88",
	"in_progress": "#aaaaaa",
}

func _ready() -> void:
	refresh_btn.pressed.connect(_refresh)
	back_btn.pressed.connect(_on_back)
	_refresh()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _refresh() -> void:
	var runs: Array = _load_all_runs()
	if runs.is_empty():
		subtitle.text = "0 runs recorded yet"
		list_label.text = "[i]No completed runs yet. Play a run from the main menu — its summary will land here when it ends.[/i]"
		return
	# Sort newest-first by ended_at (fallback: started_at).
	runs.sort_custom(func(a, b):
		var a_t: float = float(a.get("ended_at", a.get("started_at", 0.0)))
		var b_t: float = float(b.get("ended_at", b.get("started_at", 0.0)))
		return a_t > b_t
	)
	subtitle.text = "%d runs recorded" % runs.size()
	var lines: Array[String] = []
	# A8: growth bake-off summary at the top, then per-run list.
	lines.append(_bakeoff_section(runs))
	lines.append("")
	lines.append(_header_row())
	for s in runs:
		lines.append(_run_row(s))
	list_label.text = "\n".join(lines)

func _bakeoff_section(runs: Array) -> String:
	# A8 Growth Bake-Off Report: aggregates per-growth-mode stats across all
	# recorded runs so the user can compare classic vs merge vs hybrid.
	const MODES := ["classic_upgrade", "merge_stars", "merge_evolution_hybrid"]
	const LABELS := {
		"classic_upgrade":        "Classic",
		"merge_stars":            "Merge★",
		"merge_evolution_hybrid": "Merge+Evo",
	}
	var by_mode: Dictionary = {}
	for m in MODES:
		by_mode[m] = {
			"runs": 0, "victories": 0, "waves_sum": 0,
			"units_bought": 0, "dup_seen": 0, "dup_bought": 0,
			"upgrades": 0, "star_promos": 0, "evolutions": 0,
			"gold_units": 0, "gold_growth": 0, "gold_rerolls": 0,
			"damage_sum": 0,
		}
	for r in runs:
		var m: String = String(r.get("growth_mode", "classic_upgrade"))
		if not by_mode.has(m):
			continue
		var b: Dictionary = by_mode[m]
		b["runs"] += 1
		if String(r.get("result", "")) == "victory":
			b["victories"] += 1
		b["waves_sum"] += int(r.get("wave_reached", 0))
		b["units_bought"] += int(r.get("units_bought", 0))
		b["dup_seen"] += int(r.get("duplicate_offers_seen", 0))
		b["dup_bought"] += int(r.get("duplicate_offers_bought", 0))
		b["upgrades"] += int(r.get("units_upgraded", 0))
		b["star_promos"] += int(r.get("star_promotions", 0))
		b["evolutions"] += int(r.get("evolutions_chosen", 0))
		b["gold_units"] += int(r.get("gold_spent_on_units", 0))
		b["gold_growth"] += int(r.get("gold_spent_on_growth", 0))
		b["gold_rerolls"] += int(r.get("gold_spent_on_rerolls", 0))
		b["damage_sum"] += int(r.get("damage_dealt", 0))
	var lines: Array[String] = []
	lines.append("[color=#a0a0a8][b]Growth bake-off  ·  per-mode aggregate across recorded runs[/b][/color]")
	lines.append("[color=#5a5a62]" + "─".repeat(110) + "[/color]")
	lines.append("[color=#a0a0a8]" + _pad("Mode", 12) + "  Runs   Win  AvgWave  Bought  DupSee  DupBuy  Upgrd  Star★  G:Unit  G:Grow[/color]")
	for m in MODES:
		var b: Dictionary = by_mode[m]
		var runs_n: int = int(b["runs"])
		if runs_n == 0:
			lines.append(_pad(LABELS[m], 12) + "  [color=#7a7a82]no runs yet[/color]")
			continue
		var win_pct: int = int(round(100.0 * float(b["victories"]) / float(runs_n)))
		var avg_wave: float = float(b["waves_sum"]) / float(runs_n)
		var win_cell: String = ("%3d" % win_pct) + "%"
		lines.append("%s  %4d  %s  %7.1f  %6d  %6d  %6d  %5d  %5d  %6d  %6d" % [
			_pad(LABELS[m], 12), runs_n, win_cell, avg_wave,
			int(b["units_bought"]), int(b["dup_seen"]), int(b["dup_bought"]),
			int(b["upgrades"]), int(b["star_promos"]),
			int(b["gold_units"]), int(b["gold_growth"]),
		])
	# Recommend a winner if at least one of each mode has been played.
	var have_all: bool = true
	for m in MODES:
		if int(by_mode[m]["runs"]) == 0:
			have_all = false
			break
	if have_all:
		var best_mode: String = ""
		var best_score: float = -INF
		for m in MODES:
			var b: Dictionary = by_mode[m]
			# Simple composite: win% × avg waves (depth-weighted survival rate)
			var s: float = (float(b["victories"]) / float(b["runs"])) * (float(b["waves_sum"]) / float(b["runs"]))
			if s > best_score:
				best_score = s
				best_mode = m
		lines.append("")
		lines.append("[color=#8fff8f]Suggested lean (win-rate × avg wave): [b]" + LABELS[best_mode] + "[/b][/color]")
	else:
		lines.append("")
		lines.append("[color=#ffce6c][i]Play at least one run in each mode to see a suggested lean.[/i][/color]")
	return "\n".join(lines)

func _header_row() -> String:
	return "[color=#a0a0a8][b]Date · Result · Seed · Wave · Map · Growth · Top damage · Kills · Gold[/b][/color]\n[color=#5a5a62]" + "─".repeat(110) + "[/color]"

func _run_row(s: Dictionary) -> String:
	var ended_unix: float = float(s.get("ended_at", s.get("started_at", 0.0)))
	var when_text: String = _format_date(ended_unix)
	var result: String = String(s.get("result", "in_progress"))
	var hex: String = RESULT_COLOR.get(result, "#aaaaaa")
	var seed_val: int = int(s.get("seed", 0)) & 0xFFFFFFFF
	var seed_text: String = "SHARD-%08X" % seed_val
	var wave: int = int(s.get("wave_reached", 0))
	var map_src: String = String(s.get("map_source", "fixed"))
	var map_id: String = String(s.get("map_id", ""))
	var map_text: String = map_src
	if map_id != "":
		map_text += ":" + map_id
	var growth: String = String(s.get("growth_mode", "?"))
	var growth_short: String = _growth_short(growth)
	var top_dmg_id: String = _argmax_str(s.get("damage_by_unit", {}))
	var top_dmg_amt: int = int(s.get("damage_by_unit", {}).get(top_dmg_id, 0))
	var top_dmg_text: String = ""
	if top_dmg_id != "":
		top_dmg_text = "%s (%d)" % [_display_name_for(top_dmg_id), top_dmg_amt]
	else:
		top_dmg_text = "—"
	var kills: int = int(s.get("enemies_killed", 0))
	var gold: int = int(s.get("gold_earned", 0))
	var name_text: String = String(s.get("run_name", ""))
	# Build BBCode line. Use fixed-ish column widths via spaces (RichTextLabel
	# isn't a true monospace grid but Lato is close enough for human reading).
	var head: String = "%s  [color=%s][b]%s[/b][/color]  %s  W%2d  %s  %s  %s  %s  %dg" % [
		when_text,
		hex, result.capitalize(),
		seed_text,
		wave,
		_pad(_trunc(map_text, 18), 18),
		_pad(growth_short, 10),
		_pad(_trunc(top_dmg_text, 26), 26),
		_pad("%d" % kills, 6),
		gold,
	]
	if name_text != "":
		head += "\n          [color=#ffce6c][i]%s[/i][/color]" % name_text
	return head

func _format_date(unix: float) -> String:
	if unix <= 0.0:
		return "—"
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]

func _growth_short(mode: String) -> String:
	match mode:
		"classic_upgrade":        return "Classic"
		"merge_stars":            return "Merge★"
		"merge_evolution_hybrid": return "Merge+Evo"
		_: return mode

func _argmax_str(d: Dictionary) -> String:
	var best_key := ""
	var best_val: int = -1
	for k in d:
		var v := int(d[k])
		if v > best_val:
			best_val = v
			best_key = String(k)
	return best_key

func _display_name_for(unit_id: String) -> String:
	var def: Dictionary = UnitFactory.get_def(unit_id)
	return def.get("display_name", unit_id)

func _pad(s: String, width: int) -> String:
	# Manual right-padding because GDScript's % format doesn't support
	# the '-' (left-justify) flag.
	if s.length() >= width:
		return s.substr(0, width)
	return s + " ".repeat(width - s.length())

func _trunc(s: String, n: int) -> String:
	if s.length() <= n:
		return s
	return s.substr(0, n - 1) + "…"

func _load_all_runs() -> Array:
	var dir := DirAccess.open("user://")
	if dir == null:
		return []
	dir.list_dir_begin()
	var out: Array = []
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if not (fname.begins_with(LOG_PREFIX) and fname.ends_with(".json")):
			continue
		var path: String = "user://" + fname
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var stats: Dictionary = parsed.get("stats", {})
		if not stats.is_empty():
			out.append(stats)
	dir.list_dir_end()
	return out
