extends Control

# In-game map editor.
#
# Workflow:
#   - Pick a tile type from the palette.
#   - Click (or click+drag) cells in the grid to paint.
#   - "Validate" runs MapLoader.validate against the in-memory MapDef.
#   - "Save" writes user://maps/<filename>.json (sanitized).
#   - "Load" opens any map saved under user://maps/.
#   - "Test Play" saves to user://maps/_playtest.json, sets RunConfig to
#     custom-map mode pointing at _playtest, and switches to main.tscn.
#
# Same MapDef format as starter_neutral.json and the procgen output.

const WIDTH := 20
const HEIGHT := 8
const TILE_SIZE := 64
const ORIGIN := [0, 56]
const CELL_PX := 28
const MAP_DIR := "user://maps/"
const PLAYTEST_ID := "_playtest"

const COLORS := {
	"B": Color(0.18, 0.22, 0.30),   # buildable - dark navy
	"P": Color(0.62, 0.50, 0.30),   # path - tan
	"X": Color(0.08, 0.08, 0.10),   # blocked - near-black
	"S": Color(0.45, 1.00, 0.55),   # spawn - bright green
	"C": Color(1.00, 0.55, 0.45),   # core - red-orange
}

const LABELS := {
	"B": "·",
	"P": "█",
	"X": "■",
	"S": "S",
	"C": "C",
}

@onready var filename_field: LineEdit = $Root/TopBar/FilenameField
@onready var new_btn: Button = $Root/TopBar/NewBtn
@onready var load_option: OptionButton = $Root/TopBar/LoadOption
@onready var load_btn: Button = $Root/TopBar/LoadBtn
@onready var save_btn: Button = $Root/TopBar/SaveBtn
@onready var validate_btn: Button = $Root/TopBar/ValidateBtn
@onready var testplay_btn: Button = $Root/TopBar/TestPlayBtn
@onready var back_btn: Button = $Root/TopBar/BackBtn
@onready var grid_container: GridContainer = $Root/GridFrame/GridCenter/Grid
@onready var status_label: RichTextLabel = $Root/StatusLabel
@onready var palette_b: Button = $Root/PaletteBar/PaletteB
@onready var palette_p: Button = $Root/PaletteBar/PaletteP
@onready var palette_x: Button = $Root/PaletteBar/PaletteX
@onready var palette_s: Button = $Root/PaletteBar/PaletteS
@onready var palette_c: Button = $Root/PaletteBar/PaletteC

var _tiles: Array = []  # Array[Array[String]] (rows of single chars)
var _tile_buttons: Array = []  # parallel to _tiles
var _palette_buttons: Array[Button] = []
var _selected_char: String = "P"
var _hold_paint: bool = false  # true between mouse-down and mouse-up over the grid

func _ready() -> void:
	_palette_buttons = [palette_b, palette_p, palette_x, palette_s, palette_c]
	_init_blank_tiles()
	_build_tile_grid()
	_select_palette("P")
	# Wire palette toggles.
	palette_b.pressed.connect(func(): _select_palette("B"))
	palette_p.pressed.connect(func(): _select_palette("P"))
	palette_x.pressed.connect(func(): _select_palette("X"))
	palette_s.pressed.connect(func(): _select_palette("S"))
	palette_c.pressed.connect(func(): _select_palette("C"))
	# Wire toolbar.
	new_btn.pressed.connect(_on_new_blank)
	load_btn.pressed.connect(_on_load)
	save_btn.pressed.connect(_on_save)
	validate_btn.pressed.connect(_on_validate)
	testplay_btn.pressed.connect(_on_testplay)
	back_btn.pressed.connect(_on_back)
	# Seed a starter pattern so the canvas isn't blank.
	_load_starter_template()
	_refresh_load_options()
	_redraw()

func _input(event: InputEvent) -> void:
	# Mouse-up ends drag-paint. Use _input (not _gui_input) so we catch the event
	# before child Buttons consume it; otherwise drag-paint sticks on after release.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_hold_paint = false

# --- Tile model ---

func _init_blank_tiles() -> void:
	_tiles = []
	for r in HEIGHT:
		var row: Array = []
		row.resize(WIDTH)
		for c in WIDTH:
			row[c] = "B"
		_tiles.append(row)

func _load_starter_template() -> void:
	# A simple S-shape so the canvas isn't empty and Validate succeeds out of the box.
	_init_blank_tiles()
	var path_y: int = HEIGHT / 2
	for x in WIDTH:
		_tiles[path_y][x] = "P"
	_tiles[path_y][0] = "S"
	_tiles[path_y][WIDTH - 1] = "C"

# --- Grid view ---

func _build_tile_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_tile_buttons = []
	for r in HEIGHT:
		var row_buttons: Array = []
		for c in WIDTH:
			var b := Button.new()
			b.custom_minimum_size = Vector2(CELL_PX, CELL_PX)
			b.focus_mode = Control.FOCUS_NONE
			b.flat = false
			b.toggle_mode = false
			b.mouse_filter = Control.MOUSE_FILTER_STOP
			var coord := Vector2i(c, r)
			b.mouse_entered.connect(func(): _on_tile_hover(coord))
			b.button_down.connect(func(): _start_drag_paint(coord))
			grid_container.add_child(b)
			row_buttons.append(b)
		_tile_buttons.append(row_buttons)

func _redraw() -> void:
	for r in HEIGHT:
		for c in WIDTH:
			var ch: String = _tiles[r][c]
			var btn: Button = _tile_buttons[r][c]
			btn.text = LABELS.get(ch, "?")
			var color: Color = COLORS.get(ch, Color.MAGENTA)
			# Manually style the flat button via theme override.
			var style := StyleBoxFlat.new()
			style.bg_color = color
			style.corner_radius_top_left = 2
			style.corner_radius_top_right = 2
			style.corner_radius_bottom_left = 2
			style.corner_radius_bottom_right = 2
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_stylebox_override("focus", style)
			btn.add_theme_color_override("font_color", _readable_text_color(color))

func _readable_text_color(bg: Color) -> Color:
	var luma: float = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b
	return Color(0.05, 0.05, 0.05, 1) if luma > 0.55 else Color(0.95, 0.95, 0.97, 1)

# --- Palette ---

func _select_palette(ch: String) -> void:
	_selected_char = ch
	for b in _palette_buttons:
		b.button_pressed = false
	match ch:
		"B": palette_b.button_pressed = true
		"P": palette_p.button_pressed = true
		"X": palette_x.button_pressed = true
		"S": palette_s.button_pressed = true
		"C": palette_c.button_pressed = true

# --- Paint ---

func _start_drag_paint(coord: Vector2i) -> void:
	_hold_paint = true
	_paint(coord)

func _on_tile_hover(coord: Vector2i) -> void:
	if _hold_paint:
		_paint(coord)

func _paint(coord: Vector2i) -> void:
	# When painting S or C, clear the previous occurrence so the map stays valid-able.
	if _selected_char == "S" or _selected_char == "C":
		for r in HEIGHT:
			for c in WIDTH:
				if _tiles[r][c] == _selected_char:
					_tiles[r][c] = "B"
	_tiles[coord.y][coord.x] = _selected_char
	_redraw()

# --- Validate ---

func _build_map_dict(map_id: String) -> Dictionary:
	var rows: Array[String] = []
	for r in HEIGHT:
		rows.append((_tiles[r] as Array).reduce(func(acc, ch): return acc + ch, ""))
	return {
		"id": map_id,
		"name": map_id.replace("_", " ").replace("-", " ").capitalize(),
		"version": 1,
		"width": WIDTH,
		"height": HEIGHT,
		"tile_size": TILE_SIZE,
		"origin": ORIGIN,
		"tiles": rows,
	}

func _on_validate() -> Dictionary:
	var d: Dictionary = _build_map_dict("_validate")
	var v: Dictionary = MapLoader.validate(d)
	if v.get("ok", false):
		var chain: Array = v["map"]["path_chain"]
		status_label.text = "[color=#8fff8f][b]Valid.[/b][/color]  Path length [b]%d[/b]  ·  ready to Save / Test Play." % chain.size()
	else:
		status_label.text = "[color=#ff8f8f][b]Invalid.[/b][/color]  %s" % v.get("error", "unknown")
	return v

# --- Save / Load ---

func _sanitize_name(text: String) -> String:
	var out := ""
	for c in text:
		if c.is_valid_identifier() or c == "-" or c.is_valid_int():
			out += c
		elif c == " ":
			out += "_"
	# Strip leading dots/underscores so we don't shadow our internal _playtest etc.
	while out.length() > 0 and (out.begins_with("_") or out.begins_with(".")):
		out = out.substr(1)
	return out

func _ensure_map_dir() -> bool:
	if DirAccess.dir_exists_absolute(MAP_DIR):
		return true
	var err := DirAccess.make_dir_recursive_absolute(MAP_DIR)
	if err != OK:
		status_label.text = "[color=#ff8f8f]Could not create %s (error %d)[/color]" % [MAP_DIR, err]
		return false
	return true

func _on_save() -> void:
	var raw_name: String = filename_field.text.strip_edges()
	if raw_name == "":
		status_label.text = "[color=#ff8f8f]Pick a name first.[/color]"
		return
	var safe: String = _sanitize_name(raw_name)
	if safe == "":
		status_label.text = "[color=#ff8f8f]Name has no usable characters.[/color]"
		return
	var v: Dictionary = _on_validate()
	if not v.get("ok", false):
		status_label.text += "  [color=#ffce6c](Saved anyway? No — fix errors first.)[/color]"
		return
	if not _ensure_map_dir():
		return
	var path: String = MAP_DIR + safe + ".json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		status_label.text = "[color=#ff8f8f]Could not write %s (error %d)[/color]" % [path, FileAccess.get_open_error()]
		return
	f.store_string(JSON.stringify(_build_map_dict(safe), "  "))
	f.close()
	status_label.text = "[color=#8fff8f]Saved.[/color]  %s" % path
	filename_field.text = safe
	_refresh_load_options()

func _refresh_load_options() -> void:
	load_option.clear()
	load_option.add_item("(pick a saved map)")
	if not DirAccess.dir_exists_absolute(MAP_DIR):
		return
	var dir := DirAccess.open(MAP_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var names: Array[String] = []
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if fname.ends_with(".json") and not fname.begins_with("_"):
			names.append(fname.get_basename())
	dir.list_dir_end()
	names.sort()
	for n in names:
		load_option.add_item(n)

func _on_load() -> void:
	if load_option.selected <= 0:
		status_label.text = "[color=#ffce6c]Pick a map from the dropdown first.[/color]"
		return
	var name: String = load_option.get_item_text(load_option.selected)
	var path: String = MAP_DIR + name + ".json"
	var result := MapLoader.load_path(path)
	if not result.get("ok", false):
		status_label.text = "[color=#ff8f8f]Load failed:[/color] %s" % result.get("error", "")
		return
	var m: Dictionary = result["map"]
	if int(m.get("width", 0)) != WIDTH or int(m.get("height", 0)) != HEIGHT:
		status_label.text = "[color=#ff8f8f]This map is %dx%d; editor is fixed %dx%d.[/color]" % [int(m.get("width",0)), int(m.get("height",0)), WIDTH, HEIGHT]
		return
	_tiles = []
	for r in HEIGHT:
		var row_str: String = m["tiles"][r]
		var row: Array = []
		for c in WIDTH:
			row.append(row_str.substr(c, 1))
		_tiles.append(row)
	filename_field.text = name
	status_label.text = "[color=#8fff8f]Loaded.[/color]  %s" % name
	_redraw()

# --- Test play ---

func _on_testplay() -> void:
	var v: Dictionary = _on_validate()
	if not v.get("ok", false):
		return
	if not _ensure_map_dir():
		return
	var path: String = MAP_DIR + PLAYTEST_ID + ".json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		status_label.text = "[color=#ff8f8f]Could not write playtest file.[/color]"
		return
	f.store_string(JSON.stringify(_build_map_dict(PLAYTEST_ID), "  "))
	f.close()
	RunConfig.map_source = "custom"
	RunConfig.custom_map_id = PLAYTEST_ID
	if RunConfig.seed == 0:
		RunConfig.randomize_seed()
	SessionRng.set_seed(RunConfig.seed)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_new_blank() -> void:
	_init_blank_tiles()
	filename_field.text = ""
	status_label.text = "[i]Blank canvas. Paint S, C, and a path before Validate.[/i]"
	_redraw()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
