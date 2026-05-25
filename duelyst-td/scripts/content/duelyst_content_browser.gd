extends Control

# Duelyst Content Browser (D4 of the ingestion milestone).
# Reads catalog_categorized.json (D2 output) and presents tabs by category
# with search, image previews, and audio playback.
#
# Path-agnostic previewing: uses Image.load_from_file for images and
# AudioStreamOggVorbis/MP3.load_from_buffer for audio. Reads straight from
# the catalog's `abs_path` field, so no D3 (importer) prerequisite — every
# file in the source folder is browseable as soon as D1+D2 have run.

const SETTINGS_SCRIPT := preload("res://scripts/content/duelyst_content_settings.gd")

const CATEGORIES := [
	"all",
	"unit_sprite",
	"unit_animation_data",
	"fx_sprite",
	"fx_animation_data",
	"sfx",
	"music",
	"ui_image",
	"icon",
	"map_tile",
	"map_background",
	"font",
	"unknown",
]

const FACTION_COLORS := {
	"lyonar": Color(1.0, 0.85, 0.4),
	"songhai": Color(1.0, 0.4, 0.4),
	"vetruvian": Color(0.95, 0.7, 0.35),
	"abyssian": Color(0.7, 0.4, 1.0),
	"magmar": Color(1.0, 0.55, 0.25),
	"vanar": Color(0.55, 0.85, 1.0),
	"neutral": Color(0.85, 0.85, 0.85),
	"": Color(0.7, 0.7, 0.75),
}

@onready var status_label: Label = $Root/StatusLabel
@onready var category_row: HBoxContainer = $Root/CategoryRow
@onready var search_field: LineEdit = $Root/SearchRow/SearchField
@onready var clear_search_btn: Button = $Root/SearchRow/ClearSearchBtn
@onready var result_count: Label = $Root/SearchRow/ResultCount
@onready var entry_list: ItemList = $Root/Split/EntryList
@onready var preview_title: Label = $Root/Split/PreviewPanel/PreviewBox/PreviewTitle
@onready var preview_meta: RichTextLabel = $Root/Split/PreviewPanel/PreviewBox/PreviewMeta
@onready var preview_image: TextureRect = $Root/Split/PreviewPanel/PreviewBox/PreviewImage
@onready var anim_row: HBoxContainer = $Root/Split/PreviewPanel/PreviewBox/AnimRow
@onready var anim_option: OptionButton = $Root/Split/PreviewPanel/PreviewBox/AnimRow/AnimOption
@onready var anim_play_btn: Button = $Root/Split/PreviewPanel/PreviewBox/AnimRow/AnimPlayBtn
@onready var anim_stop_btn: Button = $Root/Split/PreviewPanel/PreviewBox/AnimRow/AnimStopBtn
@onready var anim_status: Label = $Root/Split/PreviewPanel/PreviewBox/AnimRow/AnimStatus
@onready var audio_row: HBoxContainer = $Root/Split/PreviewPanel/PreviewBox/AudioRow
@onready var play_btn: Button = $Root/Split/PreviewPanel/PreviewBox/AudioRow/PlayBtn
@onready var stop_btn: Button = $Root/Split/PreviewPanel/PreviewBox/AudioRow/StopBtn
@onready var audio_status: Label = $Root/Split/PreviewPanel/PreviewBox/AudioRow/AudioStatus
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var reload_btn: Button = $Root/TopBar/ReloadBtn
@onready var back_btn: Button = $Root/TopBar/BackBtn

var _all_entries: Array = []           # full categorized catalog
var _filtered_entries: Array = []      # current view (after category + search)
var _category: String = "all"
var _category_buttons: Dictionary = {} # category → Button
var _query: String = ""
var _selected_entry: Dictionary = {}

# Animation playback state for D5.
var _current_sprite_frames: SpriteFrames = null
var _current_anim_name: String = ""
var _anim_frame_index: int = 0
var _anim_frame_t: float = 0.0
var _anim_playing: bool = false

func _ready() -> void:
	_build_category_buttons()
	reload_btn.pressed.connect(_load_catalog)
	back_btn.pressed.connect(_on_back)
	search_field.text_changed.connect(_on_search_changed)
	clear_search_btn.pressed.connect(func(): search_field.text = ""; _on_search_changed(""))
	entry_list.item_selected.connect(_on_entry_selected)
	play_btn.pressed.connect(_on_play_audio)
	stop_btn.pressed.connect(func(): audio_player.stop())
	anim_play_btn.pressed.connect(_on_anim_play)
	anim_stop_btn.pressed.connect(_on_anim_stop)
	anim_option.item_selected.connect(_on_anim_changed)
	set_process(true)
	_load_catalog()

func _process(delta: float) -> void:
	if not _anim_playing or _current_sprite_frames == null or _current_anim_name == "":
		return
	var fps: float = _current_sprite_frames.get_animation_speed(_current_anim_name)
	if fps <= 0.0:
		fps = 12.0
	_anim_frame_t += delta * fps
	while _anim_frame_t >= 1.0:
		_anim_frame_t -= 1.0
		_anim_frame_index = (_anim_frame_index + 1) % max(1, _current_sprite_frames.get_frame_count(_current_anim_name))
		var tex: Texture2D = _current_sprite_frames.get_frame_texture(_current_anim_name, _anim_frame_index)
		if tex:
			preview_image.texture = tex

func _build_category_buttons() -> void:
	for c in CATEGORIES:
		var b := Button.new()
		b.text = c.replace("_", " ").capitalize()
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: String = c
		b.pressed.connect(func(): _set_category(captured))
		category_row.add_child(b)
		_category_buttons[c] = b
	_category_buttons["all"].button_pressed = true

func _load_catalog() -> void:
	var settings: RefCounted = SETTINGS_SCRIPT.new()
	var path: String = settings.output_path_for("catalog_categorized.json")
	if not FileAccess.file_exists(path):
		status_label.text = "Catalog not found at %s — open Duelyst Content hub and run D1 + D2 first." % path
		_all_entries = []
		_apply_filters()
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		status_label.text = "Could not read %s" % path
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		status_label.text = "Catalog JSON is malformed."
		return
	_all_entries = parsed.get("entries", [])
	status_label.text = "Loaded %d entries from %s (categorized %s)." % [
		_all_entries.size(), path, parsed.get("categorized_at", "?"),
	]
	_apply_filters()

func _set_category(c: String) -> void:
	_category = c
	for k in _category_buttons.keys():
		_category_buttons[k].button_pressed = (k == c)
	_apply_filters()

func _on_search_changed(text: String) -> void:
	_query = text.strip_edges().to_lower()
	_apply_filters()

func _apply_filters() -> void:
	_filtered_entries = []
	for e in _all_entries:
		var entry: Dictionary = e
		if _category != "all" and entry.get("category", "") != _category:
			continue
		if _query != "":
			var hay: String = ("%s %s %s %s" % [
				entry.get("rel_path", ""),
				entry.get("category", ""),
				entry.get("faction", ""),
				entry.get("id", ""),
			]).to_lower()
			if not _query in hay:
				continue
		_filtered_entries.append(entry)
	# Cap displayed list at 2000 entries to keep ItemList responsive; user can
	# search to narrow further. Full counts always show in the result label.
	var display: Array = _filtered_entries
	var truncated: bool = false
	if display.size() > 2000:
		display = display.slice(0, 2000)
		truncated = true
	_populate_list(display)
	var suffix: String = "  (showing first 2000)" if truncated else ""
	result_count.text = "%d entries%s" % [_filtered_entries.size(), suffix]

func _populate_list(items: Array) -> void:
	entry_list.clear()
	for entry in items:
		var rel: String = entry.get("rel_path", "")
		var faction: String = entry.get("faction", "")
		var cat: String = entry.get("category", "?")
		var prefix: String = ""
		if faction != "":
			prefix = "[%s] " % faction[0].to_upper()
		var text: String = "%s%s  ·  %s" % [prefix, rel, cat]
		var idx: int = entry_list.add_item(text)
		var color: Color = FACTION_COLORS.get(faction, FACTION_COLORS[""])
		entry_list.set_item_custom_fg_color(idx, color.lerp(Color.WHITE, 0.3))

func _on_entry_selected(idx: int) -> void:
	if idx < 0 or idx >= _filtered_entries.size():
		return
	_selected_entry = _filtered_entries[idx]
	_render_preview()

func _render_preview() -> void:
	var e: Dictionary = _selected_entry
	if e.is_empty():
		preview_title.text = "Select an entry"
		preview_meta.text = "[i]No selection.[/i]"
		preview_image.texture = null
		audio_row.visible = false
		return
	preview_title.text = String(e.get("rel_path", "?"))
	var lines: Array[String] = []
	lines.append("[b]Category:[/b]    %s" % e.get("category", "?"))
	if e.get("faction", "") != "":
		var fc: Color = FACTION_COLORS.get(e["faction"], Color.WHITE)
		var hex := "%02x%02x%02x" % [int(fc.r*255), int(fc.g*255), int(fc.b*255)]
		lines.append("[b]Faction:[/b]     [color=#%s]%s[/color]" % [hex, e["faction"]])
	lines.append("[b]Section hint:[/b] %s" % e.get("section_hint", "?"))
	lines.append("[b]Extension:[/b]   %s" % e.get("extension", "?"))
	lines.append("[b]Size:[/b]        %d bytes" % int(e.get("size_bytes", 0)))
	lines.append("[b]Readiness:[/b]  %d" % int(e.get("readiness_level", 0)))
	lines.append("[b]ID:[/b]          [color=#8aa]%s[/color]" % e.get("id", "?"))
	lines.append("[b]Abs path:[/b]    %s" % e.get("abs_path", "?"))
	preview_meta.text = "\n".join(lines)
	var cat: String = e.get("category", "")
	var abs_path: String = e.get("abs_path", "")
	# Stop any prior animation
	_stop_animation()
	# Try image preview
	if cat in ["unit_sprite", "fx_sprite", "ui_image", "icon", "map_tile", "map_background"]:
		_show_image(abs_path)
	else:
		preview_image.texture = null
	# Animation preview for unit sprites where a SpriteFrames .tres exists
	if cat == "unit_sprite":
		_try_setup_animation(e)
	else:
		anim_row.visible = false
	# Try audio preview
	if cat in ["sfx", "music"]:
		_setup_audio(abs_path)
	else:
		audio_row.visible = false
		audio_player.stop()

func _show_image(path: String) -> void:
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		preview_image.texture = null
		return
	preview_image.texture = ImageTexture.create_from_image(img)

func _setup_audio(path: String) -> void:
	audio_row.visible = true
	audio_player.stop()
	var ext: String = String(_selected_entry.get("extension", "")).to_lower()
	if ext == ".ogg":
		var stream: AudioStream = AudioStreamOggVorbis.load_from_file(path)
		if stream:
			audio_player.stream = stream
			audio_status.text = "OGG loaded"
		else:
			audio_status.text = "OGG load failed"
	elif ext == ".mp3":
		# AudioStreamMP3.load_from_file requires file in res:// or user://.
		# For external paths we read bytes and construct stream manually.
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			audio_status.text = "MP3 read failed"
			return
		var bytes := f.get_buffer(f.get_length())
		f.close()
		var stream := AudioStreamMP3.new()
		stream.data = bytes
		audio_player.stream = stream
		audio_status.text = "MP3 loaded"
	elif ext == ".wav":
		var stream: AudioStream = AudioStreamWAV.load_from_file(path)
		if stream:
			audio_player.stream = stream
			audio_status.text = "WAV loaded"
		else:
			audio_status.text = "WAV load failed"
	else:
		audio_player.stream = null
		audio_status.text = "Preview unavailable (%s — Godot needs OGG/MP3/WAV; Duelyst ships .m4a)" % ext

func _on_play_audio() -> void:
	if audio_player.stream:
		audio_player.play()

func _try_setup_animation(entry: Dictionary) -> void:
	# Map a unit sprite entry to a converted SpriteFrames if one exists.
	# Path pattern: rel_path "units/f1_silverguardsquire.png"
	# Asset id    : "f1_silverguardsquire"
	# SpriteFrames: res://assets/units/f1_silverguardsquire/f1_silverguardsquire.tres
	var rel: String = String(entry.get("rel_path", ""))
	if not (rel.begins_with("units/") and rel.ends_with(".png")):
		anim_row.visible = false
		return
	var asset_id: String = rel.substr(6, rel.length() - 6 - 4)  # strip "units/" and ".png"
	# Frame-named sub-PNGs (e.g. "f1_silverguardsquire_attack_001.png") have an
	# underscore + 3-digit index suffix. Those are atlas frames, not whole-unit
	# sprites — skip animation lookup for them.
	var stripped: String = asset_id
	if stripped.length() > 4 and stripped.right(4).is_valid_int():
		anim_row.visible = false
		return
	var tres_path: String = "res://assets/units/%s/%s.tres" % [asset_id, asset_id]
	if not ResourceLoader.exists(tres_path):
		anim_row.visible = true
		anim_option.clear()
		anim_option.add_item("(no SpriteFrames yet — run `python tools/convert_units.py %s`)" % asset_id)
		anim_option.disabled = true
		anim_play_btn.disabled = true
		anim_stop_btn.disabled = true
		anim_status.text = ""
		_current_sprite_frames = null
		return
	var sf := load(tres_path) as SpriteFrames
	if sf == null:
		anim_row.visible = false
		return
	_current_sprite_frames = sf
	anim_row.visible = true
	anim_option.disabled = false
	anim_play_btn.disabled = false
	anim_stop_btn.disabled = false
	anim_option.clear()
	var names: PackedStringArray = sf.get_animation_names()
	var preferred_idx: int = 0
	for i in names.size():
		anim_option.add_item(names[i])
		if names[i] in ["idle", "breathing"]:
			preferred_idx = i
	anim_option.selected = preferred_idx
	_on_anim_changed(preferred_idx)
	anim_status.text = "%d animations · %s" % [names.size(), asset_id]

func _on_anim_changed(idx: int) -> void:
	if _current_sprite_frames == null:
		return
	var names: PackedStringArray = _current_sprite_frames.get_animation_names()
	if idx < 0 or idx >= names.size():
		return
	_current_anim_name = names[idx]
	_anim_frame_index = 0
	_anim_frame_t = 0.0
	var tex: Texture2D = _current_sprite_frames.get_frame_texture(_current_anim_name, 0)
	if tex:
		preview_image.texture = tex

func _on_anim_play() -> void:
	if _current_sprite_frames == null or _current_anim_name == "":
		return
	_anim_playing = true

func _on_anim_stop() -> void:
	_anim_playing = false

func _stop_animation() -> void:
	_anim_playing = false
	_current_sprite_frames = null
	_current_anim_name = ""
	_anim_frame_index = 0
	_anim_frame_t = 0.0

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/duelyst_content_hub.tscn")
