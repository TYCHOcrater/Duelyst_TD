extends Node

# Loads EnemyDefs from data/enemies/*.json and waves from data/waves/*.json.

const ENEMIES_DIR := "res://data/enemies/"
const WAVES_DIR := "res://data/waves/"
const ENEMY_TEMPLATE := "res://scenes/enemy.tscn"

var enemies: Dictionary = {}      # id -> def dict
var enemy_ids: Array[String] = []
var wave_sets: Dictionary = {}    # id -> wave-set dict {id, name, waves: [...]}

func _ready() -> void:
	_load_enemies()
	_load_wave_sets()

func _load_enemies() -> void:
	var dir := DirAccess.open(ENEMIES_DIR)
	if not dir:
		push_error("EnemyFactory: directory %s not accessible" % ENEMIES_DIR)
		return
	dir.list_dir_begin()
	var files: Array[String] = []
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if fname.ends_with(".json"):
			files.append(fname)
	dir.list_dir_end()
	files.sort()
	for fname in files:
		var path := ENEMIES_DIR + fname
		var f := FileAccess.open(path, FileAccess.READ)
		if not f:
			push_warning("EnemyFactory: failed to open %s" % path)
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("EnemyFactory: failed to parse %s" % path)
			continue
		var eid: String = parsed.get("id", fname.get_basename())
		enemies[eid] = parsed
		enemy_ids.append(eid)
	print("EnemyFactory: loaded %d enemies" % enemies.size())

func _load_wave_sets() -> void:
	var dir := DirAccess.open(WAVES_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if not fname.ends_with(".json"):
			continue
		var path := WAVES_DIR + fname
		var f := FileAccess.open(path, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			push_warning("EnemyFactory: failed to parse wave set %s" % path)
			continue
		var wid: String = parsed.get("id", fname.get_basename())
		wave_sets[wid] = parsed
	dir.list_dir_end()
	print("EnemyFactory: loaded %d wave-set(s)" % wave_sets.size())

func get_def(id: String) -> Dictionary:
	return enemies.get(id, {})

func get_wave_set(id: String) -> Dictionary:
	return wave_sets.get(id, {})

func sprite_frames_for(id: String) -> SpriteFrames:
	var def := get_def(id)
	var asset_id: String = def.get("asset_profile_id", "")
	if asset_id == "":
		return null
	var path := "res://assets/units/%s/%s.tres" % [asset_id, asset_id]
	if not ResourceLoader.exists(path):
		push_warning("EnemyFactory: missing %s" % path)
		return null
	return load(path)

func make_enemy(id: String) -> Node:
	var def := get_def(id)
	if def.is_empty():
		push_error("EnemyFactory: unknown enemy '%s'" % id)
		return null
	var template := load(ENEMY_TEMPLATE) as PackedScene
	var e: Node = template.instantiate()
	e.apply_def(def)
	return e
