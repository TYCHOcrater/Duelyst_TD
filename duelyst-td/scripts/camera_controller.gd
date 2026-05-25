extends Camera2D

# Camera controller for the play board. Handles mouse-wheel zoom (anchored at
# the cursor) and RMB-drag pan. Background stays fixed because it lives on a
# separate CanvasLayer; only world-space contents (board, units, enemies)
# scale and pan with the camera.

@export var zoom_step: float = 1.15
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var pan_button: MouseButton = MOUSE_BUTTON_RIGHT

var _panning: bool = false
# C5: optional board reference. When bound, number keys 1..4 focus the
# camera on the matching route and TAB pulls back to a framed overview.
var _board: Node = null
var _focus_tween: Tween = null
const FOCUS_ROUTE_ZOOM := 1.4
const FOCUS_TWEEN_TIME := 0.35

func _ready() -> void:
	# Position camera so the default view matches the pre-camera layout: the
	# 1280×720 viewport is anchored at the world origin. With Godot 4's
	# Camera2D, screen center maps to camera.position, so to keep the
	# pre-camera visual we set position to the viewport center.
	position = Vector2(get_viewport_rect().size) * 0.5
	zoom = Vector2.ONE
	make_current()

func bind_board(board: Node) -> void:
	_board = board

func _unhandled_input(event: InputEvent) -> void:
	# C5: number keys 1..4 focus on the matching route; TAB frames the
	# whole map for a co-op overview. Silently no-op if board isn't bound
	# or the requested route doesn't exist on the current map.
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _focus_route_index(0); get_viewport().set_input_as_handled(); return
			KEY_2: _focus_route_index(1); get_viewport().set_input_as_handled(); return
			KEY_3: _focus_route_index(2); get_viewport().set_input_as_handled(); return
			KEY_4: _focus_route_index(3); get_viewport().set_input_as_handled(); return
			KEY_TAB: focus_overview(); get_viewport().set_input_as_handled(); return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_at(event.position, zoom_step)
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_at(event.position, 1.0 / zoom_step)
				get_viewport().set_input_as_handled()
		elif event.button_index == pan_button:
			_panning = event.pressed
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _panning:
		# Camera pans opposite the cursor drag (drag the world).
		position -= event.relative / zoom.x
		get_viewport().set_input_as_handled()

func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	# Keep the world point under the cursor stationary across the zoom step.
	var viewport_size: Vector2 = Vector2(get_viewport_rect().size)
	var world_before: Vector2 = position + (screen_pos - viewport_size * 0.5) / zoom
	var new_zoom_value: float = clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(new_zoom_value, new_zoom_value)
	var world_after: Vector2 = position + (screen_pos - viewport_size * 0.5) / zoom
	position += world_before - world_after

# C5: tween to the centroid of route `index` at FOCUS_ROUTE_ZOOM. If the
# route doesn't exist on the current map this is a no-op.
func _focus_route_index(index: int) -> void:
	if _board == null or _board.routes.size() <= index or _board.grid == null:
		return
	var route: Dictionary = _board.routes[index]
	var chain: Array = route.get("path_chain", [])
	if chain.is_empty():
		return
	var centroid: Vector2 = Vector2.ZERO
	for pt in chain:
		centroid += _board.grid.grid_to_world(pt.x, pt.y)
	centroid /= chain.size()
	_tween_to(centroid, FOCUS_ROUTE_ZOOM)

# C5: zoom out to fit the whole grid in the viewport (with a small margin).
func focus_overview() -> void:
	if _board == null or _board.grid == null:
		_tween_to(Vector2(get_viewport_rect().size) * 0.5, 1.0)
		return
	var grid = _board.grid
	var top_left: Vector2 = grid.grid_to_world(0, 0)
	var bot_right: Vector2 = grid.grid_to_world(grid.width - 1, grid.height - 1)
	var world_size: Vector2 = bot_right - top_left
	var center: Vector2 = (top_left + bot_right) * 0.5
	var viewport_size: Vector2 = Vector2(get_viewport_rect().size)
	# Fit-zoom = viewport / world, with a 10% margin and clamped to camera limits.
	var fit_x: float = viewport_size.x / max(world_size.x, 1.0)
	var fit_y: float = viewport_size.y / max(world_size.y, 1.0)
	var z: float = clampf(min(fit_x, fit_y) * 0.9, min_zoom, max_zoom)
	_tween_to(center, z)

func _tween_to(target_pos: Vector2, target_zoom: float) -> void:
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()
	_focus_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel(true)
	_focus_tween.tween_property(self, "position", target_pos, FOCUS_TWEEN_TIME)
	_focus_tween.tween_property(self, "zoom", Vector2(target_zoom, target_zoom), FOCUS_TWEEN_TIME)
