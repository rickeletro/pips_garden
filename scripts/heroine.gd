extends CharacterBody3D
class_name Heroine

signal health_changed(current_hp: float, max_hp: float)

@export var move_speed: float = 6.0
@export var dash_speed: float = 16.0
@export var dash_duration: float = 0.22
@export var dash_cooldown: float = 0.65

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD
var is_invulnerable: bool = false

# Combat combo system
var combo_step: int = 0
var combo_reset_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

@onready var visual_root: Node3D = $Visuals
@onready var needle_pivot: Node3D = $Visuals/NeedlePivot
@onready var needle_mesh: MeshInstance3D = $Visuals/NeedlePivot/Needle
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/CollisionShape3D
@onready var slash_fx: MeshInstance3D = $Visuals/SlashFX

var grid_manager: GridManager = null

func _ready() -> void:
	GameManager.heroine = self
	attack_area.monitoring = false
	if slash_fx:
		slash_fx.visible = false
	
	init_grid_reference()
	
	# Connect to action slot signals from HUD
	GameManager.request_plant_grass.connect(try_plant_grass)
	GameManager.request_build_tower.connect(try_build_tower)
	GameManager.request_attack.connect(func():
		if not is_dashing and not is_attacking:
			execute_attack_combo()
	)
	GameManager.request_dash.connect(func():
		if dash_cd_timer <= 0.0 and not is_dashing:
			start_dash()
	)
	GameManager.request_cycle_poison.connect(try_switch_nearby_tower_poison)
	GameManager.request_repair.connect(try_interact_or_repair)

func init_grid_reference() -> void:
	if GameManager.grid_manager:
		grid_manager = GameManager.grid_manager as GridManager
	elif is_inside_tree() and get_tree():
		grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		check_dash_hits()
		return
	
	# Movement input
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_up", "move_down")
	var input_dir = Vector3(input_x, 0.0, input_z).normalized()
	
	# Rotate input relative to camera angle (tilted top-down)
	var cam = get_viewport().get_camera_3d()
	var cam_forward = Vector3.FORWARD
	var cam_right = Vector3.RIGHT
	if cam:
		cam_forward = -cam.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()
	
	var move_dir = (cam_right * input_x + cam_forward * (-input_z if input_z != 0.0 else 0.0)).normalized()
	if input_x != 0.0 or input_z != 0.0:
		move_dir = Vector3(input_x, 0.0, input_z).normalized()
	
	if move_dir.length_squared() > 0.01:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		
		# Rotate visual towards movement if not attacking
		if not is_attacking:
			var target_rot = atan2(move_dir.x, move_dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 15.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 10.0 * delta)
	
	# Subtle walking bobbing animation
	if velocity.length() > 0.5:
		visual_root.position.y = abs(sin(Time.get_ticks_msec() * 0.015)) * 0.12
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 2.0)
		
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.wave_state == GameManager.WaveState.DEFEAT:
		return
		
	if event.is_action_pressed("attack") and not is_dashing and not is_attacking:
		execute_attack_combo()
	elif event.is_action_pressed("dash") and dash_cd_timer <= 0.0 and not is_dashing:
		start_dash()
	elif event.is_action_pressed("plant_grass"):
		try_plant_grass()
	elif event.is_action_pressed("build_tower"):
		try_build_tower()
	elif event.is_action_pressed("interact"):
		try_interact_or_repair()
	elif event.is_action_pressed("switch_poison"):
		try_switch_nearby_tower_poison()
	elif event.is_action_pressed("start_wave"):
		if GameManager.wave_state == GameManager.WaveState.PREPARATION:
			GameManager.start_next_wave()
	elif event.is_action_pressed("restart_game"):
		if GameManager.wave_state == GameManager.WaveState.DEFEAT or GameManager.wave_state == GameManager.WaveState.VICTORY:
			GameManager.reset_game()

func handle_timers(delta: float) -> void:
	if dash_cd_timer > 0.0:
		dash_cd_timer -= delta
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			is_invulnerable = false
	
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0
	
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			is_attacking = false
			attack_area.monitoring = false
			if slash_fx:
				slash_fx.visible = false
			needle_pivot.rotation_degrees = Vector3.ZERO

func execute_attack_combo() -> void:
	is_attacking = true
	combo_step = (combo_step % 3) + 1
	combo_reset_timer = 0.85
	
	var base_dmg = 15.0 + GameManager.pip_damage_bonus
	var attack_radius = 1.6
	
	match combo_step:
		1:
			# Combo 1: Quick Jab
			attack_anim_timer = 0.22
			needle_pivot.rotation_degrees = Vector3(-65, 0, 0)
			needle_pivot.position = Vector3(0.0, 0.4, 0.4)
			base_dmg = 16.0 + GameManager.pip_damage_bonus
			create_slash_effect(Color(1.0, 0.9, 0.5), 0.9)
		2:
			# Combo 2: Cross Slash
			attack_anim_timer = 0.24
			needle_pivot.rotation_degrees = Vector3(-40, 75, -20)
			needle_pivot.position = Vector3(0.2, 0.4, 0.3)
			base_dmg = 24.0 + GameManager.pip_damage_bonus
			create_slash_effect(Color(1.0, 0.7, 0.3), 1.2)
		3:
			# Combo 3: 360 Spin Sweep finisher!
			attack_anim_timer = 0.35
			needle_pivot.rotation_degrees = Vector3(0, 180, 0)
			base_dmg = 38.0 + GameManager.pip_damage_bonus
			attack_radius = 2.4
			create_slash_effect(Color(0.4, 0.95, 1.0), 2.0)
			
	# Detect hits in front or area
	attack_area.monitoring = true
	await get_tree().create_timer(0.05).timeout
	
	var hits = attack_area.get_overlapping_bodies()
	for body in hits:
		if body != self and body.is_in_group("enemies"):
			var knock_dir = (body.global_position - global_position).normalized()
			if body.has_method("take_damage"):
				body.take_damage(base_dmg, knock_dir * (4.0 if combo_step == 3 else 1.5))
	
	await get_tree().create_timer(attack_anim_timer).timeout
	if is_instance_valid(needle_pivot):
		needle_pivot.position = Vector3(0.3, 0.3, 0.0)
		needle_pivot.rotation_degrees = Vector3.ZERO

func create_slash_effect(tint: Color, scale_mult: float) -> void:
	if not slash_fx:
		return
	slash_fx.visible = true
	slash_fx.scale = Vector3(scale_mult, scale_mult, scale_mult)
	if slash_fx.material_override:
		var mat = slash_fx.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = tint

func start_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	
	# Dash towards movement direction or forward
	var move_dir = velocity.normalized()
	if move_dir.length_squared() < 0.1:
		move_dir = -visual_root.global_transform.basis.z
		move_dir.y = 0.0
		move_dir = move_dir.normalized()
	
	dash_direction = move_dir
	visual_root.rotation.y = atan2(dash_direction.x, dash_direction.z)
	
	# Needle points forward for thrust!
	needle_pivot.rotation_degrees = Vector3(-80, 0, 0)
	create_slash_effect(Color(1.0, 1.0, 0.8), 1.5)

func check_dash_hits() -> void:
	# Piercing damage during dash
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var knock = dash_direction * 3.0
			body.take_damage(20.0 + GameManager.pip_damage_bonus, knock)

func try_plant_grass() -> void:
	if not grid_manager:
		init_grid_reference()
	if not grid_manager:
		return
	var cell = grid_manager.world_to_grid(global_position)
	grid_manager.plant_grass(cell)

func try_build_tower() -> void:
	if not grid_manager:
		init_grid_reference()
	if not grid_manager:
		return
	var cell = grid_manager.world_to_grid(global_position)
	grid_manager.build_tower_at(cell)

func try_interact_or_repair() -> void:
	var tree = get_tree()
	if not tree:
		return
	var towers = tree.get_nodes_in_group("towers")
	var repaired = false
	for tw in towers:
		if is_instance_valid(tw) and global_position.distance_to(tw.global_position) < 2.5:
			if tw.has_method("repair"):
				if tw.repair():
					repaired = true
					break
	if not repaired:
		GameManager.notify("Nenhuma torre danificada por perto.", Color(0.7, 0.7, 0.7))

func try_switch_nearby_tower_poison() -> void:
	var tree = get_tree()
	if not tree:
		return
	var towers = tree.get_nodes_in_group("towers")
	var switched = false
	for tw in towers:
		if is_instance_valid(tw) and global_position.distance_to(tw.global_position) < 2.5:
			if tw.has_method("cycle_poison_type"):
				tw.cycle_poison_type()
				switched = true
				break
	if not switched:
		GameManager.notify("Aproxime-se de uma torre para mudar seu veneno (T).", Color(0.7, 0.7, 0.7))

func take_damage(amount: float) -> void:
	if is_invulnerable:
		return
	GameManager.damage_pip(amount)
	
	# Flash red
	is_invulnerable = true
	var orig_color = visual_root.modulate if "modulate" in visual_root else null
	for child in visual_root.find_children("*", "MeshInstance3D"):
		if child.material_override:
			var mat = child.material_override.duplicate()
			mat.albedo_color = Color(1.0, 0.2, 0.2)
			child.material_override = mat
	
	await get_tree().create_timer(0.4).timeout
	is_invulnerable = false
