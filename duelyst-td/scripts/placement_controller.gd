extends Node2D

signal tower_selected(tower)
signal tower_deselected()
signal preview_changed(unit_id: String)

const TOWER_HIT_RADIUS := 40.0

var path: Path2D = null
var grid: GridController = null
var current_unit_id: String = ""
var current_trait_id: String = ""
var current_flaw_id: String = ""
var preview: Node2D = null
var preview_valid: bool = true
var picked_tower: Node = null
var hover_tower: Node = null
var placement_locked: bool = false

func bind_grid(g: GridController) -> void:
	grid = g

func _process(_d: float) -> void:
	if preview:
		var snap: Vector2 = _snap_to_grid(get_global_mouse_position())
		preview.global_position = snap
		preview_valid = is_valid_placement(snap) and not placement_locked
		preview.modulate = Color(1, 1, 1, 0.55) if preview_valid else Color(1, 0.3, 0.3, 0.55)
	_update_hover_tower()

func _update_hover_tower() -> void:
	if preview:
		# Placement preview is active; don't fight the cursor.
		_set_hover_tower(null)
		return
	var pos: Vector2 = get_global_mouse_position()
	var best_d := TOWER_HIT_RADIUS
	var best: Node = null
	for t in get_tree().get_nodes_in_group("towers"):
		var d: float = pos.distance_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	_set_hover_tower(best)

func _set_hover_tower(t: Node) -> void:
	if t == hover_tower:
		return
	if hover_tower and is_instance_valid(hover_tower):
		hover_tower.set_show_target_line(false)
	hover_tower = t
	if hover_tower and is_instance_valid(hover_tower):
		hover_tower.set_show_target_line(true)

func _snap_to_grid(world_pos: Vector2) -> Vector2:
	if grid == null:
		return world_pos
	var gp := grid.world_to_grid(world_pos)
	return grid.grid_to_world(gp.x, gp.y)

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.game_running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			cancel_selection()
			_clear_picked_tower()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_unit_id != "":
				var snap: Vector2 = _snap_to_grid(get_global_mouse_position())
				CommandBus.dispatch(PlaceUnitCommand.new(current_unit_id, snap))
			else:
				_try_pick_tower(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_selection()
			_clear_picked_tower()

func set_locked(locked: bool) -> void:
	placement_locked = locked
	if locked:
		cancel_selection()

func select_unit_for_placement(unit_id: String, trait_id: String = "", flaw_id: String = "") -> void:
	_clear_picked_tower()
	if unit_id == current_unit_id and trait_id == current_trait_id and flaw_id == current_flaw_id and preview:
		return
	current_unit_id = unit_id
	current_trait_id = trait_id
	current_flaw_id = flaw_id
	if preview:
		preview.queue_free()
		preview = null
	if unit_id != "":
		preview = UnitFactory.make_tower(unit_id, trait_id, flaw_id)
		if preview:
			preview.set_preview(true)
			add_child(preview)
	preview_changed.emit(current_unit_id)

func cancel_selection() -> void:
	if current_unit_id == "" and preview == null:
		return
	current_unit_id = ""
	current_trait_id = ""
	current_flaw_id = ""
	if preview:
		preview.queue_free()
		preview = null
	preview_changed.emit("")

func _try_pick_tower(pos: Vector2) -> void:
	var best_d := TOWER_HIT_RADIUS
	var best: Node = null
	for t in get_tree().get_nodes_in_group("towers"):
		var d: float = pos.distance_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	if best == picked_tower:
		_clear_picked_tower()
		return
	_clear_picked_tower()
	if best:
		picked_tower = best
		picked_tower.set_show_range(true)
		tower_selected.emit(picked_tower)
	else:
		tower_deselected.emit()

func _clear_picked_tower() -> void:
	if picked_tower and is_instance_valid(picked_tower):
		picked_tower.set_show_range(false)
	picked_tower = null
	tower_deselected.emit()

func is_valid_placement(pos: Vector2) -> bool:
	# Grid-first validation: must be a buildable tile.
	if grid == null:
		return false
	var gp := grid.world_to_grid(pos)
	if not grid.in_bounds(gp.x, gp.y):
		return false
	if not grid.is_buildable(gp.x, gp.y):
		return false
	# Block stacking on existing towers (same tile).
	for child in get_children():
		if child == preview:
			continue
		if child is Node2D:
			var their_gp: Vector2i = grid.world_to_grid(child.global_position)
			if their_gp == gp:
				return false
	return true
