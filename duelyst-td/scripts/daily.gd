extends Node

# Daily Storm: same seed for everyone today, persisted local scoreboard,
# score formula derived from RunLog stats, copy-pastable share text.

const SCOREBOARD_PATH := "user://daily_scores.json"

var _scoreboard: Dictionary = {}  # "YYYY-MM-DD" -> Array of entry dicts

func _ready() -> void:
	_load()

# --- Seed derivation ---

func today_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d.year * 10000 + d.month * 100 + d.day)

func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func today_seed_text() -> String:
	return "SHARD-%08X" % (today_seed() & 0xFFFFFFFF)

# --- Score formula ---

func compute_score(stats: Dictionary) -> int:
	var waves: int = int(stats.get("wave_reached", 0))
	var final_lives: int = int(stats.get("final_lives", 0))
	var final_gold: int = int(stats.get("final_gold", 0))
	var kills: int = int(stats.get("enemies_killed", 0))
	var damage: int = int(stats.get("damage_dealt", 0))
	var leaks: int = int(stats.get("leaks", 0))
	var pacts: int = (stats.get("pacts", []) as Array).size()
	var relics: int = (stats.get("relics", []) as Array).size()
	var interest: int = int(stats.get("interest_earned", 0))
	var result := String(stats.get("result", "defeat"))
	var score := 0
	score += waves * 500
	score += final_lives * 100
	score += final_gold * 5
	score += kills * 5
	score += int(damage / 10)
	score += pacts * 200
	score += relics * 150
	score += interest * 5
	score -= leaks * 50
	if result == "victory":
		score += 1500
	return max(0, score)

func score_breakdown(stats: Dictionary) -> Array:
	# Returns Array of "label: value" strings for display.
	var lines: Array[String] = []
	lines.append("Waves cleared  ×500  =  %d" % (int(stats.get("wave_reached", 0)) * 500))
	lines.append("Core lives  ×100  =  %d" % (int(stats.get("final_lives", 0)) * 100))
	lines.append("Gold unspent  ×5  =  %d" % (int(stats.get("final_gold", 0)) * 5))
	lines.append("Kills  ×5  =  %d" % (int(stats.get("enemies_killed", 0)) * 5))
	lines.append("Damage  ÷10  =  %d" % int(int(stats.get("damage_dealt", 0)) / 10))
	lines.append("Pacts taken  ×200  =  %d" % ((stats.get("pacts", []) as Array).size() * 200))
	lines.append("Relics taken  ×150  =  %d" % ((stats.get("relics", []) as Array).size() * 150))
	lines.append("Interest  ×5  =  %d" % (int(stats.get("interest_earned", 0)) * 5))
	lines.append("Leaks  ×-50  =  %d" % (int(stats.get("leaks", 0)) * -50))
	if String(stats.get("result", "")) == "victory":
		lines.append("Victory bonus  =  +1500")
	return lines

# --- Scoreboard persistence ---

func record_run(stats: Dictionary, score: int) -> Dictionary:
	var key := today_key()
	var entry: Dictionary = {
		"seed": int(stats.get("seed", 0)),
		"score": score,
		"run_name": RunNameGenerator.generate(stats),
		"result": stats.get("result", "defeat"),
		"waves": int(stats.get("wave_reached", 0)),
		"leaks": int(stats.get("leaks", 0)),
		"kills": int(stats.get("enemies_killed", 0)),
		"pacts": stats.get("pacts", []),
		"relics": stats.get("relics", []),
		"timestamp": Time.get_datetime_string_from_system(),
	}
	if not _scoreboard.has(key):
		_scoreboard[key] = []
	(_scoreboard[key] as Array).append(entry)
	_save()
	return entry

func today_runs() -> Array:
	return _scoreboard.get(today_key(), [])

func today_best() -> Dictionary:
	var runs: Array = today_runs()
	if runs.is_empty():
		return {}
	var best: Dictionary = runs[0]
	for r in runs:
		if int(r.get("score", 0)) > int(best.get("score", 0)):
			best = r
	return best

func recent_dates(limit: int = 5) -> Array:
	# Returns Array of {date, best_score, best_entry} for the most recent days
	# with at least one recorded run.
	var keys: Array = _scoreboard.keys()
	keys.sort()
	keys.reverse()
	var out: Array = []
	for k in keys:
		if out.size() >= limit:
			break
		var runs: Array = _scoreboard[k]
		if runs.is_empty():
			continue
		var best: Dictionary = runs[0]
		for r in runs:
			if int(r.get("score", 0)) > int(best.get("score", 0)):
				best = r
		out.append({"date": k, "best_score": int(best.get("score", 0)), "best": best})
	return out

# --- Share text ---

func share_text(stats: Dictionary, score: int, max_waves: int = 10) -> String:
	var lines: Array[String] = []
	lines.append("Shardstorm TD - Daily %s" % today_key())
	lines.append("Score: %d" % score)
	lines.append("%s - %s" % [
		RunNameGenerator.generate(stats),
		String(stats.get("result", "")).capitalize(),
	])
	lines.append("Wave %d/%d  ·  %d kills  ·  %d leaks" % [
		int(stats.get("wave_reached", 0)),
		max_waves,
		int(stats.get("enemies_killed", 0)),
		int(stats.get("leaks", 0)),
	])
	var pacts: Array = stats.get("pacts", [])
	if pacts.size() > 0:
		var names: Array[String] = []
		for pid in pacts:
			names.append(PactManager.get_def(pid).get("display_name", pid))
		lines.append("Pacts: " + ", ".join(names))
	var relics: Array = stats.get("relics", [])
	if relics.size() > 0:
		var names: Array[String] = []
		for rid in relics:
			names.append(RelicManager.get_def(rid).get("display_name", rid))
		lines.append("Relics: " + ", ".join(names))
	lines.append(today_seed_text())
	return "\n".join(lines)

# --- I/O ---

func _load() -> void:
	if not FileAccess.file_exists(SCOREBOARD_PATH):
		return
	var f := FileAccess.open(SCOREBOARD_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_scoreboard = parsed

func _save() -> void:
	var f := FileAccess.open(SCOREBOARD_PATH, FileAccess.WRITE)
	if not f:
		push_warning("Daily: could not open %s for writing" % SCOREBOARD_PATH)
		return
	f.store_string(JSON.stringify(_scoreboard, "  "))
	f.close()
