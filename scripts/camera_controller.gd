extends Camera3D
class_name GardenCameraController

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var base_offset: Vector3 = Vector3(0.0, 14.5, 10.5)

@export var min_zoom: float = 0.35
@export var max_zoom: float = 2.8
@export var zoom_step: float = 0.18

var current_zoom: float = 2.5
var target_zoom: float = 2.5
var target_node: Node3D = null
var default_target_node: Node3D = null
var is_cinematic_focus: bool = false
var active_follow_speed: float = 6.0

func _ready() -> void:
	if has_node(target_path):
		default_target_node = get_node(target_path)
	elif GameManager.heroine:
		default_target_node = GameManager.heroine
	elif is_inside_tree() and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			default_target_node = players[0]
			
	target_node = default_target_node
	
	# Start in high overview zoom if in intro menu
	if GameManager.is_in_intro:
		current_zoom = 2.5
		target_zoom = 2.5
	else:
		current_zoom = 1.0
		target_zoom = 1.0
		
	# Tilted top-down 55° pitch
	rotation_degrees = Vector3(-55.0, 0.0, 0.0)

func _process(delta: float) -> void:
	# Smooth zoom interpolation
	current_zoom = lerp(current_zoom, target_zoom, delta * 6.0)
	var active_offset = base_offset * current_zoom
	
	if not target_node or not is_instance_valid(target_node):
		if GameManager.heroine:
			target_node = GameManager.heroine
			default_target_node = GameManager.heroine
		elif is_inside_tree() and get_tree():
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				target_node = players[0]
				default_target_node = players[0]
		return
		
	var target_pos = target_node.global_position + active_offset
	global_position = global_position.lerp(target_pos, active_follow_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_in_intro or GameManager.is_in_cutscene:
		return
		
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

func focus_target(node: Node3D, zoom: float = 1.15, speed: float = 4.0) -> void:
	if not node or not is_instance_valid(node):
		return
	is_cinematic_focus = true
	target_node = node
	target_zoom = clampf(zoom, min_zoom, max_zoom)
	active_follow_speed = speed

func reset_focus(zoom: float = 1.0, speed: float = 4.5) -> void:
	is_cinematic_focus = false
	if default_target_node and is_instance_valid(default_target_node):
		target_node = default_target_node
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		target_node = GameManager.heroine
	target_zoom = clampf(zoom, min_zoom, max_zoom)
	active_follow_speed = speed

func zoom_to_gameplay(duration: float = 2.0) -> void:
	target_zoom = 1.0
	active_follow_speed = 3.5
	if default_target_node and is_instance_valid(default_target_node):
		target_node = default_target_node
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		target_node = GameManager.heroine
	
	var tree = get_tree()
	if tree:
		var t = tree.create_timer(duration)
		t.timeout.connect(func():
			active_follow_speed = follow_speed
		)

func start_credits_slow_zoom_out(duration: float = 20.0) -> void:
	is_cinematic_focus = true
	if GameManager.flower and is_instance_valid(GameManager.flower):
		target_node = GameManager.flower
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		target_node = GameManager.heroine
		
	target_zoom = 2.4
	active_follow_speed = 0.6
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_property(self, "target_zoom", 2.6, duration).set_trans(Tween.TRANS_SINE)
