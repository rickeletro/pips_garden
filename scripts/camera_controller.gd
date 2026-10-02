extends Camera3D
class_name GardenCameraController

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var base_offset: Vector3 = Vector3(0.0, 14.5, 10.5)

@export var min_zoom: float = 0.35
@export var max_zoom: float = 2.8
@export var zoom_step: float = 0.18

var current_zoom: float = 1.0
var target_zoom: float = 1.0
var target_node: Node3D = null

func _ready() -> void:
	if has_node(target_path):
		target_node = get_node(target_path)
	elif GameManager.heroine:
		target_node = GameManager.heroine
	elif is_inside_tree() and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_node = players[0]
			
	# Tilted top-down 55° pitch
	rotation_degrees = Vector3(-55.0, 0.0, 0.0)

func _process(delta: float) -> void:
	# Smooth zoom interpolation
	current_zoom = lerp(current_zoom, target_zoom, delta * 8.0)
	var active_offset = base_offset * current_zoom
	
	if not target_node or not is_instance_valid(target_node):
		if GameManager.heroine:
			target_node = GameManager.heroine
		elif is_inside_tree() and get_tree():
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				target_node = players[0]
		return
		
	var target_pos = target_node.global_position + active_offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse Wheel Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_out()
			
	# Keyboard +/- / PageUp/PageDown Zoom
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD or event.keycode == KEY_PAGEUP:
			zoom_in()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_PAGEDOWN:
			zoom_out()

func zoom_in(amount: float = -1.0) -> void:
	var step = zoom_step if amount < 0 else amount
	target_zoom = clampf(target_zoom - step, min_zoom, max_zoom)

func zoom_out(amount: float = -1.0) -> void:
	var step = zoom_step if amount < 0 else amount
	target_zoom = clampf(target_zoom + step, min_zoom, max_zoom)

func set_zoom_immediate(zoom_val: float) -> void:
	target_zoom = clampf(zoom_val, min_zoom, max_zoom)
	current_zoom = target_zoom
	if target_node and is_instance_valid(target_node):
		global_position = target_node.global_position + (base_offset * current_zoom)
