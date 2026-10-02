extends Camera3D

@export var target_path: NodePath
@export var follow_speed: float = 6.0
@export var camera_offset: Vector3 = Vector3(0.0, 14.5, 10.5)

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
	if not target_node or not is_instance_valid(target_node):
		if GameManager.heroine:
			target_node = GameManager.heroine
		elif is_inside_tree() and get_tree():
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				target_node = players[0]
		return
		
	var target_pos = target_node.global_position + camera_offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
