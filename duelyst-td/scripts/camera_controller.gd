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

func _ready() -> void:
	# Position camera so the default view matches the pre-camera layout: the
	# 1280×720 viewport is anchored at the world origin. With Godot 4's
	# Camera2D, screen center maps to camera.position, so to keep the
	# pre-camera visual we set position to the viewport center.
	position = Vector2(get_viewport_rect().size) * 0.5
	zoom = Vector2.ONE
	make_current()

func _unhandled_input(event: InputEvent) -> void:
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
