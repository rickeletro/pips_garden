extends CharacterBody3D
class_name EnemyBase

signal enemy_died(enemy: Node3D)

@export var max_hp: float = 40.0
@export var base_speed: float = 3.0
@export var attack_damage: float = 6.0
@export var attack_interval: float = 1.0
@export var xp_reward: int = 15
@export var is_flying: bool = false

var hp: float = 40.0
var current_speed: float = 3.0
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var grass_slow_factor: float = 1.0

var dot_timer: float = 0.0
var dot_damage_rate: float = 0.0

var path_waypoints: PackedVector3Array = PackedVector3Array()
var current_waypoint_idx: int = 0
var target_flower: Node3D = null
var attack_timer: float = 0.0

@onready var visual_root: Node3D = $Visuals
var grid_manager: GridManager = null

# Resource drop packed scene
@export var pickup_scene: PackedScene

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	current_speed = base_speed
	GameManager.register_enemy_spawned()
	
	init_references()

func init_references() -> void:
	if GameManager.grid_manager:
		grid_manager = GameManager.grid_manager as GridManager
	elif is_inside_tree() and get_tree():
		grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager
		
	if GameManager.flower:
		target_flower = GameManager.flower
	elif is_inside_tree() and get_tree():
		target_flower = get_tree().get_first_node_in_group("flower")
		
	if grid_manager and not grid_manager.path_updated.is_connected(recalculate_path):
		grid_manager.path_updated.connect(recalculate_path)
		
	recalculate_path()

func _physics_process(delta: float) -> void:
	handle_status_effects(delta)
	
	if is_flying:
		process_flying_movement(delta)
	else:
		process_ground_movement(delta)
		
	check_attack_target(delta)

func handle_status_effects(delta: float) -> void:
	# Grass deceleration effect:
	# A grama desacelera as hordas terrestres (40% de redução na velocidade).
	# Aéreos (Vespas / Abelhas) voam por cima e NÃO sofrem nenhum efeito da grama (grass_slow_factor = 1.0).
	if not is_flying:
		if not grid_manager:
			init_references()
		if grid_manager:
			var cell = grid_manager.world_to_grid(global_position)
			if grid_manager.get_tile_type(cell) == GridManager.TileType.GRASS:
				grass_slow_factor = 0.60
			else:
				grass_slow_factor = 1.0
		else:
			grass_slow_factor = 1.0
	else:
		grass_slow_factor = 1.0
	
	# Status Slow (ex: veneno de torre)
	var poison_slow = 1.0
	if slow_timer > 0.0:
		slow_timer -= delta
		poison_slow = slow_factor
		if slow_timer <= 0.0:
			slow_factor = 1.0
	
	# Velocidade efetiva combinando veneno e terreno de grama
	current_speed = base_speed * poison_slow * grass_slow_factor
		
	# Corrosive DoT
	if dot_timer > 0.0:
		dot_timer -= delta
		take_damage(dot_damage_rate * delta, Vector3.ZERO, true)

func recalculate_path() -> void:
	if is_flying:
		return
	if not grid_manager:
		init_references()
	if grid_manager:
		path_waypoints = grid_manager.get_path_to_flower(global_position)
		current_waypoint_idx = 0

func process_ground_movement(delta: float) -> void:
	if path_waypoints.is_empty() or current_waypoint_idx >= path_waypoints.size():
		if target_flower and is_instance_valid(target_flower):
			move_towards_point(target_flower.global_position, delta)
		return
	
	var target_wp = path_waypoints[current_waypoint_idx]
	target_wp.y = global_position.y
	
	if global_position.distance_to(target_wp) < 0.6:
		current_waypoint_idx += 1
		if current_waypoint_idx < path_waypoints.size():
			target_wp = path_waypoints[current_waypoint_idx]
			target_wp.y = global_position.y
			
	move_towards_point(target_wp, delta)

func process_flying_movement(delta: float) -> void:
	if not target_flower or not is_instance_valid(target_flower):
		if GameManager.flower:
			target_flower = GameManager.flower
	if target_flower and is_instance_valid(target_flower):
		var target_pos = target_flower.global_position + Vector3(0, 1.2, 0)
		move_towards_point(target_pos, delta)

func move_towards_point(target_pos: Vector3, delta: float) -> void:
	var dir = (target_pos - global_position).normalized()
	if not is_flying:
		dir.y = 0.0
		dir = dir.normalized()
		
	velocity = dir * current_speed
	move_and_slide()
	
	if dir.length_squared() > 0.01 and visual_root:
		var target_rot = atan2(dir.x, dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 10.0 * delta)

func check_attack_target(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		if target_flower and is_instance_valid(target_flower):
			if global_position.distance_to(target_flower.global_position) < 2.2:
				perform_attack_on_flower()
				attack_timer = attack_interval

func perform_attack_on_flower() -> void:
	GameManager.damage_flower(attack_damage)
	if visual_root:
		var tree = get_tree()
		if tree:
			var tween = tree.create_tween()
			tween.tween_property(visual_root, "scale", Vector3(1.3, 0.7, 1.3), 0.1)
			tween.tween_property(visual_root, "scale", Vector3.ONE, 0.1)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false) -> void:
	hp -= amount
	
	if knockback.length_squared() > 0.1 and not is_flying:
		velocity += knockback
		move_and_slide()
		
	flash_damage()
	
	if hp <= 0.0:
		die()

func flash_damage() -> void:
	if not visual_root:
		return
	for mesh in visual_root.find_children("*", "MeshInstance3D"):
		if mesh.material_override:
			var mat = mesh.material_override.duplicate()
			mat.albedo_color = Color(1.0, 0.2, 0.2)
			mesh.material_override = mat

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = min(slow_factor, factor)
	slow_timer = max(slow_timer, duration)

func apply_corrosive_dot(damage_per_sec: float, duration: float) -> void:
	dot_damage_rate = damage_per_sec
	dot_timer = max(dot_timer, duration)

func die() -> void:
	GameManager.add_xp(xp_reward)
	GameManager.register_enemy_killed(self)
	spawn_drop()
	queue_free()

func spawn_drop() -> void:
	var roll = randf()
	var drop_type = ""
	if roll < 0.45:
		drop_type = "TWIG"
	elif roll < 0.75:
		drop_type = "SEED"
	elif roll < 0.95:
		drop_type = "GEAR"
	else:
		return
		
	var drop_scn = load("res://scenes/pickup.tscn")
	if drop_scn:
		var p = drop_scn.instantiate()
		p.item_type = drop_type
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(p)
			p.global_position = global_position + Vector3(0, 0.2, 0)
