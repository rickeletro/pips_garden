extends CharacterBody3D
class_name Heroine

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")

# ==============================================================================
# 🗡️ PIP (HEROÍNA) — FINITE STATE MACHINE (FSM) & COMBATE
# ==============================================================================
# - Heroína em miniatura estilo Arrietty / Chibi (~0.7m de altura).
# - Máquina de Estados Finita (FSM) modular:
#   * IDLE / MOVE: Locomoção com inclinação Arrietty e oscilação de rabo de cavalo.
#   * DASH: Investida rápida com invulnerabilidade e hitbox frontal.
#   * ATTACK: Combo de 4 tempos (Corte, Estocada, Giro 360°, Dash Perfurante Carmesim).
#   * PLANT / BUILD / WATER: Ações contextuais de suporte botânico.
#   * RECOIL / KNOCKED_OUT: Reações a dano com recuo e recuperação suave.
# ==============================================================================

signal health_changed(current_hp: float, max_hp: float)
signal animation_triggered(anim_name: String)

enum State {
	IDLE,
	MOVE,
	DASH,
	ATTACK,
	PLANT,
	BUILD,
	WATER,
	RECOIL,
	KNOCKED_OUT
}

var current_state: State = State.IDLE
var controls_enabled: bool = true

# Backward-compatibility properties
var is_dashing: bool:
	get: return current_state == State.DASH
var is_attacking: bool:
	get: return current_state == State.ATTACK
var is_planting: bool:
	get: return current_state == State.PLANT
var is_building: bool:
	get: return current_state == State.BUILD
var is_recoiling: bool:
	get: return current_state == State.RECOIL
var is_knocked_out: bool:
	get: return current_state == State.KNOCKED_OUT

@export var move_speed: float = 6.0
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.25
@export var dash_cooldown: float = 1.2

var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD
var dash_hit_targets: Array[Node] = []

func get_forward_vector() -> Vector3:
	if not visual_root:
		return Vector3.FORWARD
	return Vector3(sin(visual_root.rotation.y), 0.0, cos(visual_root.rotation.y)).normalized()
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

# Combat combo system
var combo_step: int = 0
var combo_reset_timer: float = 0.0
var attack_anim_timer: float = 0.0

# Slime Slow effect (Boss Snail)
var slime_slow_timer: float = 0.0
var is_hopping: bool = false

# Node References
@onready var visual_root: Node3D = $Visuals
@onready var body_root: Node3D = $Visuals/Body
@onready var head_pivot: Node3D = $Visuals/HeadPivot
@onready var hair_ponytail: MeshInstance3D = $Visuals/HeadPivot/HairPonytail
@onready var needle_pivot: Node3D = $Visuals/NeedlePivot
@onready var needle_mesh: MeshInstance3D = $Visuals/NeedlePivot/Needle
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/CollisionShape3D
@onready var slash_fx: MeshInstance3D = $Visuals/SlashFX

var base_ponytail_x: float = 0.5
var grid_manager: GridManager = null

@export var use_25d_sprites: bool = true
var sprite_25d: DirectionalSprite3D = null

func _ready() -> void:
	GameManager.heroine = self
	controls_enabled = not GameManager.is_in_intro and not GameManager.is_in_cutscene
	axis_lock_linear_y = false
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(55.0)
	if attack_area:
		attack_area.monitoring = false
	if slash_fx:
		slash_fx.visible = false
	if hair_ponytail:
		base_ponytail_x = hair_ponytail.rotation.x
	
	if use_25d_sprites:
		_setup_25d_visuals()
		
	init_grid_reference()
	_connect_game_signals()

func _setup_25d_visuals() -> void:
	# Keep nodes existing for external/test references, but hide 3D procedural meshes
	for node in [body_root, head_pivot, needle_pivot]:
		if node:
			for m in node.find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).visible = false
				
	sprite_25d = DirectionalSprite3D.new()
	sprite_25d.name = "Sprite25D"
	sprite_25d.sprite_offset_y = 0.72
	sprite_25d.sprite_pixel_size = 0.023
	sprite_25d.shadow_scale = Vector3(1.10, 1.10, 1.10)
	add_child(sprite_25d)
	
	sprite_25d.load_sprites_from_dir("res://textures/sprites/heroine")
	sprite_25d.play("idle", true, 6.0)


func init_grid_reference() -> void:
	if GameManager.grid_manager:
		grid_manager = GameManager.grid_manager as GridManager
	elif is_inside_tree() and get_tree():
		grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _connect_game_signals() -> void:
	GameManager.request_plant_grass.connect(try_plant_grass)
	GameManager.request_build_tower.connect(try_build_tower)
	GameManager.request_attack.connect(func():
		if can_act():
			execute_attack_combo()
	)
	GameManager.request_dash.connect(func():
		if dash_cd_timer <= 0.0 and current_state != State.DASH:
			start_dash()
	)
	GameManager.request_cycle_poison.connect(try_switch_nearby_tower_poison)
	GameManager.request_repair.connect(try_interact_or_repair)
	GameManager.request_water.connect(try_water_nearby_target)
	GameManager.request_water_target.connect(try_water_nearby_target)

func can_act() -> bool:
	return controls_enabled and current_state != State.KNOCKED_OUT and current_state != State.DASH and current_state != State.RECOIL

func set_control_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector3.ZERO
		if current_state == State.DASH or current_state == State.ATTACK:
			change_state(State.IDLE)
		if attack_area:
			attack_area.monitoring = false
		if slash_fx:
			slash_fx.visible = false

# ==============================================================================
# FSM STATE TRANSITIONS
# ==============================================================================

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)

func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			velocity = Vector3.ZERO
		State.MOVE:
			pass
		State.DASH:
			is_invulnerable = true
			dash_timer = dash_duration
			dash_cd_timer = dash_cooldown
			dash_hit_targets.clear()
			# Desativa colisão física com corpos de Inimigos (Layer 4 = bit 3) para atravessar livremente no dash
			set_collision_mask_value(3, false)
			if attack_area:
				attack_area.set_deferred("monitoring", true)
			animation_triggered.emit("dash")
			var move_dir = velocity.normalized()
			if move_dir.length_squared() < 0.1:
				move_dir = get_forward_vector()
			dash_direction = move_dir
			visual_root.rotation.y = atan2(dash_direction.x, dash_direction.z)
			if needle_pivot:
				needle_pivot.rotation_degrees = Vector3(-85, 0, 0)
			create_dynamic_slash_arc(Color(1.0, 1.0, 0.85, 0.9), 1.3, -0.5, 0.5)
			SoundManager.play_wind_dash(1.0, 0.0)
		State.ATTACK:
			pass
		State.PLANT:
			animation_triggered.emit("plant")
			spawn_leaf_puff_fx(global_position)
		State.BUILD:
			animation_triggered.emit("build")
		State.WATER:
			pass
		State.RECOIL:
			is_invulnerable = true
			animation_triggered.emit("hurt")
			flash_damage_visuals()
		State.KNOCKED_OUT:
			controls_enabled = false
			is_invulnerable = true
			velocity = Vector3.ZERO
			animation_triggered.emit("hurt")

func _exit_state(state: State) -> void:
	match state:
		State.DASH:
			is_invulnerable = false
			# Reativa colisão física com corpos de Inimigos
			set_collision_mask_value(3, true)
			if attack_area:
				attack_area.set_deferred("monitoring", false)
			_prevent_boss_overlap()
		State.ATTACK:
			if attack_area:
				attack_area.monitoring = false
			if slash_fx:
				slash_fx.visible = false
			if needle_pivot:
				needle_pivot.rotation = Vector3.ZERO
				needle_pivot.position = Vector3(0.24, 0.28, 0.05)
		State.RECOIL:
			pass
		State.KNOCKED_OUT:
			pass

func _prevent_boss_overlap() -> void:
	var tree = get_tree()
	if not tree:
		return
	var enemies = tree.get_nodes_in_group("enemies")
	for en in enemies:
		if is_instance_valid(en) and not en.get("is_dead") and not en.get("_death_handled"):
			var offset = global_position - en.global_position
			offset.y = 0.0
			var dist = offset.length()
			var min_dist = 2.0 if en.name.begins_with("BossSnail") or en is BossSnail else 1.2
			if dist < min_dist:
				var push_dir = dash_direction.normalized() if dash_direction.length_squared() > 0.01 else offset.normalized()
				if push_dir.length_squared() < 0.01:
					push_dir = get_forward_vector()
				global_position = en.global_position + push_dir * (min_dist + 0.2)
			controls_enabled = true

# ==============================================================================
# FSM MAIN UPDATE
# ==============================================================================

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	
	match current_state:
		State.IDLE, State.MOVE:
			_process_locomotion(delta)
		State.DASH:
			_process_dash(delta)
		State.ATTACK:
			_process_attack_state(delta)
		State.PLANT, State.BUILD, State.WATER, State.RECOIL:
			_process_stationary_action(delta)
		State.KNOCKED_OUT:
			pass

	_clamp_world_bounds()

func _process_locomotion(delta: float) -> void:
	if not controls_enabled or GameManager.is_in_intro or GameManager.is_in_cutscene:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= 19.6 * delta
		else:
			velocity.y = -0.5
		if sprite_25d and current_state != State.ATTACK:
			sprite_25d.play("idle", true, 6.0)
		animate_locomotion(delta)
		move_and_slide()
		return
		
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_up", "move_down")
	var move_dir = Vector3(input_x, 0.0, input_z).normalized()
	move_dir.y = 0.0
	
	var effective_speed = move_speed * (0.45 if slime_slow_timer > 0.0 else 1.0)
	
	if move_dir.length_squared() > 0.01:
		change_state(State.MOVE)
		velocity.x = move_dir.x * effective_speed
		velocity.y = 0.0
		velocity.z = move_dir.z * effective_speed
		
		var target_rot = atan2(move_dir.x, move_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 16.0 * delta)
		
		if sprite_25d:
			sprite_25d.set_facing(move_dir)
			if current_state != State.ATTACK:
				sprite_25d.play("run", true, 12.0)
	else:
		change_state(State.IDLE)
		velocity.x = move_toward(velocity.x, 0.0, effective_speed * 12.0 * delta)
		velocity.y = 0.0
		velocity.z = move_toward(velocity.z, 0.0, effective_speed * 12.0 * delta)
		
		if sprite_25d and current_state != State.ATTACK:
			sprite_25d.play("idle", true, 6.0)
		
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = -0.5
		
	animate_locomotion(delta)
	move_and_slide()

func _process_dash(delta: float) -> void:
	dash_direction.y = 0.0
	var h_vel = dash_direction.normalized() * dash_speed
	velocity.x = h_vel.x
	velocity.z = h_vel.z
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	check_dash_hits()
	
	dash_timer -= delta
	if dash_timer <= 0.0:
		change_state(State.IDLE)

func _process_attack_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	
	attack_anim_timer -= delta
	if attack_anim_timer <= 0.0:
		change_state(State.IDLE)

func _process_stationary_action(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 15.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 15.0 * delta)
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = -0.5
	move_and_slide()

func _clamp_world_bounds() -> void:
	global_position.x = clampf(global_position.x, -48.0, 48.0)
	global_position.z = clampf(global_position.z, -48.0, 48.0)
	if global_position.y < -5.0:
		global_position.y = 0.0
		velocity.y = 0.0

func handle_timers(delta: float) -> void:
	if dash_cd_timer > 0.0:
		dash_cd_timer -= delta
	if slime_slow_timer > 0.0:
		slime_slow_timer -= delta
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

# ==============================================================================
# LOCOMOTION & VISUAL ANIMATION
# ==============================================================================

func animate_locomotion(delta: float) -> void:
	var speed = velocity.length()
	var t = Time.get_ticks_msec() * 0.001
	
	if speed > 0.5:
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.28, delta * 12.0)
		if not is_hopping:
			visual_root.position.y = abs(sin(t * 18.0)) * 0.08
		
		if hair_ponytail:
			hair_ponytail.rotation.x = lerp(hair_ponytail.rotation.x, base_ponytail_x + 0.35 + sin(t * 18.0) * 0.12, delta * 10.0)
			
		if current_state != State.ATTACK and needle_pivot:
			needle_pivot.rotation.z = sin(t * 18.0) * 0.15
			needle_pivot.rotation.x = cos(t * 18.0) * 0.10
	else:
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.0, delta * 8.0)
		if not is_hopping:
			visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 3.0)
			visual_root.scale.y = 1.0 + sin(t * 3.5) * 0.025
			visual_root.scale.x = 1.0 - sin(t * 3.5) * 0.012
			visual_root.scale.z = visual_root.scale.x
			
		if hair_ponytail:
			hair_ponytail.rotation.x = lerp(hair_ponytail.rotation.x, base_ponytail_x + sin(t * 2.8) * 0.08, delta * 6.0)
			
		if current_state != State.ATTACK and needle_pivot:
			needle_pivot.rotation = needle_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)

# ==============================================================================
# INPUT HANDLING
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or GameManager.is_in_cutscene or GameManager.is_in_intro:
		return
	if GameManager.wave_state == GameManager.WaveState.DEFEAT:
		return
		
	if event.is_action_pressed("attack") and can_act():
		execute_attack_combo()
	elif event.is_action_pressed("dash") and dash_cd_timer <= 0.0 and current_state != State.DASH:
		start_dash()
	elif event.is_action_pressed("plant_grass"):
		try_plant_grass()
	elif event.is_action_pressed("build_tower"):
		try_build_tower()
	elif event.is_action_pressed("interact"):
		try_interact_or_repair()
	elif (event is InputEventKey and event.pressed and event.keycode == KEY_F) or (event.is_action_type() and event.is_action_pressed("water_plant")):
		try_water_nearby_target()
	elif event.is_action_pressed("switch_poison"):
		try_switch_nearby_tower_poison()
	elif event.is_action_pressed("start_wave"):
		if GameManager.wave_state == GameManager.WaveState.PREPARATION:
			GameManager.start_next_wave()
	elif event.is_action_pressed("restart_game"):
		if GameManager.wave_state == GameManager.WaveState.DEFEAT:
			if GameManager.has_night_2_checkpoint:
				GameManager.load_night_2_checkpoint()
			else:
				GameManager.reset_game()
		elif GameManager.wave_state == GameManager.WaveState.VICTORY:
			GameManager.reset_game()

# ==============================================================================
# COMBAT SYSTEM (4-HIT NEEDLE COMBO)
# ==============================================================================

func execute_attack_combo() -> void:
	change_state(State.ATTACK)
	combo_step = (combo_step % 4) + 1
	combo_reset_timer = 1.05
	animation_triggered.emit("attack")
	if sprite_25d:
		var f_dir = Vector3(sin(visual_root.rotation.y), 0, cos(visual_root.rotation.y))
		sprite_25d.set_facing(f_dir)
		sprite_25d.play("attack", false, 14.0, true)
	
	var base_dmg = 18.0 + GameManager.pip_damage_bonus
	var attack_radius = 2.2
	
	match combo_step:
		1:
			attack_anim_timer = 0.26
			base_dmg = 18.0 + GameManager.pip_damage_bonus
			create_dynamic_slash_arc(Color(0.95, 0.98, 1.0, 0.95), 1.0, -0.4, 0.6)
			var tw = create_tween()
			tw.tween_property(needle_pivot, "position", Vector3(0.12, 0.32, 0.48), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-65, -35, 20), 0.10)
			tw.tween_property(needle_pivot, "position", Vector3(0.24, 0.28, 0.05), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.16)
			SoundManager.play_hit_flesh(1.0, -4.0)
		2:
			attack_anim_timer = 0.28
			base_dmg = 22.0 + GameManager.pip_damage_bonus
			create_dynamic_slash_arc(Color(1.0, 0.85, 0.35, 0.95), 1.25, 0.5, -0.3)
			var tw = create_tween()
			tw.tween_property(needle_pivot, "position", Vector3(0.18, 0.38, 0.52), 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-40, 55, -30), 0.11)
			tw.tween_property(needle_pivot, "position", Vector3(0.24, 0.28, 0.05), 0.17)
			tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.17)
			SoundManager.play_hit_flesh(1.1, -3.5)
		3:
			attack_anim_timer = 0.34
			base_dmg = 28.0 + GameManager.pip_damage_bonus
			attack_radius = 2.6
			create_dynamic_slash_arc(Color(0.35, 0.92, 1.0, 1.0), 1.6, -1.2, 1.2)
			var tw = create_tween()
			tw.tween_property(visual_root, "rotation:y", visual_root.rotation.y + TAU, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-15, 90, 0), 0.14)
			tw.tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.10)
			SoundManager.play_sparkle(-3.0, 0.2)
		4:
			attack_anim_timer = 0.42
			base_dmg = (36.0 + GameManager.pip_damage_bonus) * 1.05
			attack_radius = 3.2
			execute_crimson_finisher_dash()
			SoundManager.play_wind_dash(1.15, 1.0)
			SoundManager.play_sparkle(-3.0, 0.2)
			
	apply_melee_hits(base_dmg, attack_radius, combo_step)

func apply_melee_hits(base_dmg: float, attack_radius: float, step: int) -> void:
	var tree = get_tree()
	if not tree:
		return
		
	var forward = get_forward_vector()
		
	var hit_targets: Array[Node3D] = []
	var enemies = tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue
		if enemy.get("is_dead") == true:
			continue
			
		var enemy_pos = enemy.global_position
		var flat_offset = Vector2(enemy_pos.x - global_position.x, enemy_pos.z - global_position.z)
		var flat_dist = flat_offset.length()
		var height_diff = abs(enemy_pos.y - global_position.y)
		
		if height_diff <= 3.6:
			var is_hit = false
			if step == 3:
				if flat_dist <= (attack_radius + 0.6): is_hit = true
			elif step == 4:
				if flat_dist <= 4.2:
					var to_enemy = Vector3(enemy_pos.x - global_position.x, 0, enemy_pos.z - global_position.z).normalized()
					if forward.dot(to_enemy) >= 0.1 or flat_dist <= 1.8: is_hit = true
			else:
				if flat_dist <= attack_radius:
					var to_enemy = Vector3(enemy_pos.x - global_position.x, 0, enemy_pos.z - global_position.z).normalized()
					if forward.dot(to_enemy) >= -0.2 or flat_dist <= 1.4: is_hit = true
					
			if is_hit and not hit_targets.has(enemy):
				hit_targets.append(enemy)
				if enemy.has_method("take_damage"):
					var knock_force = 4.0 if step == 4 else (2.8 if step == 3 else 1.2)
					var knock_dir = forward * knock_force
					enemy.take_damage(base_dmg, knock_dir)
				spawn_combo_hit_spark(enemy.global_position + Vector3(0, 0.35, 0), step)

	var dandelions = tree.get_nodes_in_group("dandelion")
	for dand in dandelions:
		if is_instance_valid(dand) and global_position.distance_to(dand.global_position) <= (attack_radius + 1.4):
			if dand.has_method("on_attack_hit"):
				dand.on_attack_hit(global_position)
				
	var dewdrops = tree.get_nodes_in_group("dew_drop") + tree.get_nodes_in_group("dewdrops")
	for dew in dewdrops:
		if is_instance_valid(dew) and global_position.distance_to(dew.global_position) <= (attack_radius + 1.8):
			if dew.has_method("on_attack_hit"):
				dew.on_attack_hit(global_position)

	var gnomes = tree.get_nodes_in_group("gnome")
	for gnome in gnomes:
		if is_instance_valid(gnome) and not hit_targets.has(gnome):
			var g_pos = gnome.global_position
			var dist = Vector2(g_pos.x - global_position.x, g_pos.z - global_position.z).length()
			if dist <= (attack_radius + 1.0):
				hit_targets.append(gnome)
				if gnome.has_method("take_damage"):
					var knock_dir = forward * 2.0
					gnome.take_damage(base_dmg, knock_dir)
				spawn_combo_hit_spark(g_pos + Vector3(0, 0.35, 0), step)

func execute_crimson_finisher_dash() -> void:
	set_needle_crimson_glow(true)
	create_dynamic_slash_arc(Color(1.0, 0.18, 0.22, 1.0), 2.2, -0.6, 0.8)
	
	var forward = get_forward_vector()
		
	var target_dash_pos = global_position + forward * 3.4
	target_dash_pos.x = clampf(target_dash_pos.x, -48.0, 48.0)
	target_dash_pos.z = clampf(target_dash_pos.z, -48.0, 48.0)
	
	var dash_tw = create_tween()
	dash_tw.tween_property(self, "global_position", target_dash_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dash_tw.parallel().tween_property(needle_pivot, "position", Vector3(0.0, 0.35, 0.7), 0.18)
	dash_tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-90, 0, 0), 0.18)
	spawn_crimson_streak_fx(global_position, target_dash_pos)
	
	dash_tw.tween_property(needle_pivot, "position", Vector3(0.24, 0.28, 0.05), 0.20).set_trans(Tween.TRANS_SINE)
	dash_tw.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.20)
	dash_tw.tween_callback(func():
		set_needle_crimson_glow(false)
	)

func set_needle_crimson_glow(active: bool) -> void:
	if not needle_mesh:
		return
	if active:
		var red_mat = StandardMaterial3D.new()
		red_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		red_mat.albedo_color = Color(1.0, 0.25, 0.3)
		red_mat.emission_enabled = true
		red_mat.emission = Color(1.0, 0.1, 0.18)
		red_mat.emission_energy_multiplier = 3.5
		needle_mesh.material_override = red_mat
	else:
		needle_mesh.material_override = null

func start_dash() -> void:
	change_state(State.DASH)

func check_dash_hits() -> void:
	if not attack_area or not attack_area.monitoring:
		return
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body) or body == self or dash_hit_targets.has(body):
			continue
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			dash_hit_targets.append(body)
			var knock = dash_direction * 3.5
			body.take_damage(20.0 + GameManager.pip_damage_bonus, knock)
		elif body.is_in_group("gnome"):
			dash_hit_targets.append(body)
			if body.has_method("take_damage"):
				body.take_damage(20.0)
			elif body.has_method("on_attack_hit"):
				body.on_attack_hit(global_position)
		elif body.has_method("on_attack_hit"):
			dash_hit_targets.append(body)
			body.on_attack_hit(global_position)

# ==============================================================================
# SPECIAL ACTIONS (PLANT, BUILD, WATER, REPAIR)
# ==============================================================================

func try_plant_grass() -> void:
	if not can_act():
		return
	if not grid_manager:
		init_grid_reference()
	if not grid_manager:
		return
		
	var cell = grid_manager.world_to_grid(global_position)
	if GameManager.seeds <= 0:
		GameManager.notify("Você precisa de sementes para plantar grama!", Tokens.PERIGO)
		return
		
	var planted = grid_manager.plant_grass(cell)
	if not planted:
		return
		
	change_state(State.PLANT)
	var plant_tween = create_tween()
	plant_tween.tween_property(visual_root, "position:y", -0.15, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	plant_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(45, 0, 0), 0.18)
	plant_tween.tween_property(visual_root, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	plant_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.22)
	plant_tween.tween_callback(func():
		change_state(State.IDLE)
	)

func try_build_tower() -> void:
	if not can_act():
		return
	if not grid_manager:
		init_grid_reference()
	if not grid_manager:
		return
		
	var cell = grid_manager.world_to_grid(global_position)
	if GameManager.twigs < 3 or GameManager.gears < 2:
		GameManager.notify("Requer 3 gravetos e 2 engrenagens!", Tokens.PERIGO)
		return
		
	var built = grid_manager.build_tower_at(cell)
	if not built:
		return
		
	change_state(State.BUILD)
	var build_tween = create_tween()
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-95, 0, 0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	build_tween.tween_callback(func(): spawn_dust_puff_fx(global_position + Vector3(0, 0.05, 0.3), Tokens.LATAO_ENGRENAGEM))
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-20, 0, 0), 0.08)
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-95, 0, 0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	build_tween.tween_callback(func(): spawn_dust_puff_fx(global_position + Vector3(0, 0.05, 0.3), Tokens.MARROM_CASCA))
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE)
	build_tween.tween_callback(func():
		change_state(State.IDLE)
	)

func play_collect_hop() -> void:
	if is_hopping or not can_act():
		return
	is_hopping = true
	animation_triggered.emit("collect")
	
	var hop_tween = create_tween()
	hop_tween.tween_property(visual_root, "position:y", 0.22, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.parallel().tween_property(visual_root, "scale", Vector3(0.9, 1.15, 0.9), 0.12)
	hop_tween.tween_property(visual_root, "position:y", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hop_tween.parallel().tween_property(visual_root, "scale", Vector3(1.12, 0.88, 1.12), 0.10)
	hop_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.08)
	hop_tween.tween_callback(func():
		is_hopping = false
	)

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
					try_build_tower()
					break
	if not repaired:
		GameManager.notify("Nenhuma torre danificada por perto.", Color(0.7, 0.7, 0.7))

func try_water_nearby_target() -> void:
	var tree = get_tree()
	if not tree:
		return
	if GameManager.flower and is_instance_valid(GameManager.flower):
		if global_position.distance_to(GameManager.flower.global_position) <= 3.5:
			GameManager.water_flower()
			return
	var dandelions = tree.get_nodes_in_group("dandelion")
	for dand in dandelions:
		if is_instance_valid(dand) and global_position.distance_to(dand.global_position) <= 2.5:
			if dand.has_method("water_dandelion"):
				dand.water_dandelion()
				return
	GameManager.notify("Aproxime-se da Flor Central ou de um Dente-de-Leão para regar (F)!", Tokens.CREME_PERGAMINHO)

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

# ==============================================================================
# DAMAGE & KNOCKOUT RECOVERY
# ==============================================================================

func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_invulnerable:
		return
	GameManager.damage_pip(amount)
	change_state(State.RECOIL)
	
	var recoil_dir = -get_forward_vector()
	if source_pos != Vector3.ZERO:
		recoil_dir = (global_position - source_pos).normalized()
		recoil_dir.y = 0.0
	
	velocity = recoil_dir * 5.0
	spawn_dust_puff_fx(global_position, Tokens.PERIGO)
	
	var recoil_tween = create_tween()
	recoil_tween.tween_property(visual_root, "position", recoil_dir * 0.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.14)
	recoil_tween.tween_callback(func():
		if current_state == State.RECOIL:
			change_state(State.IDLE)
	)
	
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(0.4)
		timer.timeout.connect(func():
			if current_state != State.KNOCKED_OUT:
				is_invulnerable = false
		)

func trigger_knockout() -> void:
	if current_state == State.KNOCKED_OUT:
		return
	change_state(State.KNOCKED_OUT)
	combo_step = 0
	set_needle_crimson_glow(false)
	if needle_pivot:
		needle_pivot.rotation = Vector3.ZERO
		needle_pivot.position = Vector3(0.24, 0.28, 0.05)
	
	if visual_root:
		var ko_tween = create_tween()
		ko_tween.tween_property(visual_root, "rotation_degrees:z", 85.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ko_tween.parallel().tween_property(visual_root, "position:y", -0.22, 0.25)
		
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(2.2)
		timer.timeout.connect(func():
			var flower_pos = Vector3(0, 0, 2.8)
			if GameManager.flower and is_instance_valid(GameManager.flower):
				flower_pos = GameManager.flower.global_position + Vector3(0, 0, 2.8)
			global_position = flower_pos
			velocity = Vector3.ZERO
			
			GameManager.pip_hp = GameManager.pip_max_hp * 0.35
			GameManager.pip_stats_changed.emit(GameManager.pip_hp, GameManager.pip_max_hp, GameManager.pip_xp, GameManager.pip_level)
			
			if visual_root:
				var stand_tween = create_tween()
				stand_tween.tween_property(visual_root, "rotation_degrees:z", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				stand_tween.parallel().tween_property(visual_root, "position:y", 0.0, 0.35)
				
			var t2 = tree.create_timer(0.4)
			t2.timeout.connect(func():
				change_state(State.IDLE)
				var t3 = tree.create_timer(1.5)
				t3.timeout.connect(func():
					is_invulnerable = false
				)
			)
		)

func play_checkpoint_glow() -> void:
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.88, 0.35)
	light.light_energy = 4.5
	light.omni_range = 6.0
	add_child(light)
	
	spawn_combo_hit_spark(global_position + Vector3(0, 0.5, 0), 3)
	SoundManager.play_fairy_dust(0.0)
	
	var tw = create_tween()
	tw.tween_property(light, "light_energy", 0.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(light.queue_free)

# ==============================================================================
# VISUAL EFFECTS & PARTICLES
# ==============================================================================

static var pip_flash_mat: StandardMaterial3D = null
static var shared_arc_mesh: CylinderMesh = null
static var shared_leaf_mesh: BoxMesh = null
static var shared_leaf_mat: StandardMaterial3D = null
static var shared_dust_mesh: SphereMesh = null
static var shared_streak_mesh: BoxMesh = null

static var shared_slash_mats: Dictionary = {}
static var shared_dust_mats: Dictionary = {}

func _init_fx_shared_resources() -> void:
	if shared_arc_mesh == null:
		shared_arc_mesh = CylinderMesh.new()
		shared_arc_mesh.top_radius = 0.55
		shared_arc_mesh.bottom_radius = 0.58
		shared_arc_mesh.height = 0.025
		shared_arc_mesh.radial_segments = 8
		
		shared_leaf_mesh = BoxMesh.new()
		shared_leaf_mesh.size = Vector3(0.08, 0.02, 0.14)
		
		shared_leaf_mat = StandardMaterial3D.new()
		shared_leaf_mat.albedo_color = Tokens.VERDE_FOLHA
		shared_leaf_mat.roughness = 0.5
		
		shared_dust_mesh = SphereMesh.new()
		shared_dust_mesh.radius = 0.05
		shared_dust_mesh.height = 0.10
		shared_dust_mesh.radial_segments = 6
		shared_dust_mesh.rings = 3

func flash_damage_visuals() -> void:
	if sprite_25d:
		sprite_25d.flash_hit()
	if pip_flash_mat == null:
		pip_flash_mat = StandardMaterial3D.new()
		pip_flash_mat.albedo_color = Color(1.0, 0.25, 0.25, 1.0)
		pip_flash_mat.emission_enabled = true
		pip_flash_mat.emission = Color(1.0, 0.4, 0.4)
		pip_flash_mat.emission_energy_multiplier = 1.2
	
	var original_materials: Dictionary = {}
	for mesh in visual_root.find_children("*", "MeshInstance3D"):
		var m = mesh as MeshInstance3D
		if m and m != slash_fx:
			original_materials[m] = m.material_override
			m.material_override = pip_flash_mat
			
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(0.18)
		timer.timeout.connect(func():
			for mesh in original_materials.keys():
				if is_instance_valid(mesh):
					(mesh as MeshInstance3D).material_override = original_materials[mesh]
		)

func create_dynamic_slash_arc(tint: Color, scale_mult: float, rot_start: float, rot_end: float) -> void:
	_init_fx_shared_resources()
	var arc_root = Node3D.new()
	visual_root.add_child(arc_root)
	arc_root.position = Vector3(0.0, 0.30, 0.42)
	arc_root.rotation.y = rot_start
	
	var arc_mesh_inst = MeshInstance3D.new()
	arc_mesh_inst.mesh = shared_arc_mesh
	arc_mesh_inst.scale = Vector3(scale_mult, 1.0, scale_mult)
	
	var col_key = tint.to_html()
	if not shared_slash_mats.has(col_key):
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = tint
		shared_slash_mats[col_key] = mat
	arc_mesh_inst.material_override = shared_slash_mats[col_key]
	arc_root.add_child(arc_mesh_inst)
	
	var tw = arc_root.create_tween()
	tw.tween_property(arc_root, "rotation:y", rot_end, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(arc_root, "scale", Vector3(1.2, 1.2, 1.2), 0.15)
	tw.parallel().tween_property(arc_mesh_inst, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(arc_root.queue_free)

func spawn_combo_hit_spark(pos: Vector3, step: int) -> void:
	var spark_color = Color(1.0, 0.2, 0.25) if step == 4 else (Color(0.4, 0.95, 1.0) if step == 3 else Color(1.0, 0.9, 0.4))
	spawn_dust_puff_fx(pos, spark_color)

func spawn_crimson_streak_fx(start_pos: Vector3, end_pos: Vector3) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var flat_delta = Vector3(end_pos.x - start_pos.x, 0.0, end_pos.z - start_pos.z)
	if flat_delta.length_squared() < 0.04:
		return
	var streak = MeshInstance3D.new()
	var box = BoxMesh.new()
	var dist = start_pos.distance_to(end_pos)
	box.size = Vector3(0.35, 0.15, dist)
	streak.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.15, 0.2, 0.85)
	streak.material_override = mat
	
	parent_node.add_child(streak)
	streak.global_position = (start_pos + end_pos) * 0.5 + Vector3(0, 0.3, 0)
	streak.look_at(end_pos + Vector3(0, 0.3, 0))
	
	var tw = streak.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(streak, "scale:x", 0.1, 0.20)
	tw.tween_callback(streak.queue_free)

func spawn_leaf_puff_fx(spawn_pos: Vector3) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	_init_fx_shared_resources()
	var puff = Node3D.new()
	parent_node.add_child(puff)
	puff.global_position = spawn_pos + Vector3(0, 0.1, 0)
	
	for i in range(4):
		var leaf = MeshInstance3D.new()
		leaf.mesh = shared_leaf_mesh
		leaf.material_override = shared_leaf_mat
		puff.add_child(leaf)
		
		var angle = (i / 4.0) * TAU
		var target_offset = Vector3(cos(angle) * 0.4, 0.30 + randf() * 0.15, sin(angle) * 0.4)
		var tween = leaf.create_tween()
		tween.tween_property(leaf, "position", target_offset, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(leaf, "scale", Vector3.ZERO, 0.30)
		
	var timer = puff.get_tree().create_timer(0.32)
	timer.timeout.connect(puff.queue_free)

func spawn_dust_puff_fx(spawn_pos: Vector3, tint: Color) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	_init_fx_shared_resources()
	var puff = Node3D.new()
	parent_node.add_child(puff)
	puff.global_position = spawn_pos
	
	var col_key = tint.to_html()
	if not shared_dust_mats.has(col_key):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.75
		shared_dust_mats[col_key] = mat
	var mat = shared_dust_mats[col_key]
	
	for i in range(3):
		var particle = MeshInstance3D.new()
		particle.mesh = shared_dust_mesh
		particle.material_override = mat
		puff.add_child(particle)
		
		var angle = (i / 3.0) * TAU
		var target_offset = Vector3(cos(angle) * 0.3, 0.20, sin(angle) * 0.3)
		var tween = particle.create_tween()
		tween.tween_property(particle, "position", target_offset, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(particle, "scale", Vector3.ZERO, 0.25)
		
	var timer = puff.get_tree().create_timer(0.28)
	timer.timeout.connect(puff.queue_free)

func apply_slime_slow(duration: float = 2.5) -> void:
	if slime_slow_timer <= 0.0:
		GameManager.notify("Gosma pegajosa! Movimento reduzido.", Color(0.4, 1.0, 0.6))
	slime_slow_timer = max(slime_slow_timer, duration)
	spawn_dust_puff_fx(global_position + Vector3(0, 0.15, 0), Color(0.3, 0.9, 0.5))

func show_revenge_dialog(dialog_text: String, duration: float = 3.0) -> void:
	show_speech_bubble(dialog_text, duration, true)

func show_speech_bubble(dialog_text: String, duration: float = 3.5, is_revenge: bool = false) -> void:
	for child in get_children():
		if child.is_in_group("speech_bubble"):
			child.queue_free()

	var bubble_anchor = Node3D.new()
	bubble_anchor.name = "PipSpeechBubble"
	bubble_anchor.add_to_group("speech_bubble")
	bubble_anchor.position = Vector3(0.0, 1.05, 0.0)
	add_child(bubble_anchor)

	var vp = SubViewport.new()
	vp.transparent_bg = true
	vp.size = Vector2i(380, 130)
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	bubble_anchor.add_child(vp)

	var root_ctrl = Control.new()
	root_ctrl.custom_minimum_size = Vector2(380, 130)
	root_ctrl.size = Vector2(380, 130)
	vp.add_child(root_ctrl)

	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(165, 80),
		Vector2(205, 80),
		Vector2(155, 122)
	])
	tail.color = Color(1.0, 1.0, 1.0)
	root_ctrl.add_child(tail)
	
	var tail_outline = Line2D.new()
	tail_outline.points = PackedVector2Array([
		Vector2(165, 80),
		Vector2(155, 122),
		Vector2(205, 80)
	])
	tail_outline.width = 4.0
	tail_outline.default_color = Color(0.0, 0.0, 0.0)
	root_ctrl.add_child(tail_outline)

	var panel = PanelContainer.new()
	panel.position = Vector2(10, 8)
	panel.size = Vector2(360, 75)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", style)
	root_ctrl.add_child(panel)

	var label = Label.new()
	label.text = dialog_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_font_size_override("font_size", 18)
	
	var comic_font = SystemFont.new()
	comic_font.font_names = ["Chalkboard SE", "Comic Sans MS", "Arial Rounded MT Bold", "Impact", "sans-serif"]
	comic_font.font_weight = 800
	label.add_theme_font_override("font", comic_font)
	panel.add_child(label)

	var sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = 15
	sprite.pixel_size = 0.0045
	sprite.texture = vp.get_texture()
	bubble_anchor.add_child(sprite)

	bubble_anchor.scale = Vector3(0.1, 0.1, 0.1)
	var tw_in = create_tween()
	tw_in.tween_property(bubble_anchor, "scale", Vector3(1.12, 1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(bubble_anchor, "scale", Vector3(1.0, 1.0, 1.0), 0.08)

	if is_revenge:
		for i in range(4):
			var tear = MeshInstance3D.new()
			var sph = SphereMesh.new()
			sph.radius = 0.03
			sph.height = 0.06
			tear.mesh = sph
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.8, 1.0, 0.85)
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.85, 1.0)
			tear.material_override = mat
			add_child(tear)
			tear.position = Vector3((randf() - 0.5) * 0.2, 0.8, 0.15)
			var tw = create_tween()
			tw.tween_property(tear, "position:y", 0.1, 0.6 + randf() * 0.4)
			tw.parallel().tween_property(tear, "scale", Vector3.ZERO, 0.8)
			tw.tween_callback(tear.queue_free)

	var tree = get_tree()
	if tree:
		var tw_b = tree.create_tween()
		tw_b.tween_interval(duration)
		tw_b.tween_property(bubble_anchor, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw_b.tween_callback(bubble_anchor.queue_free)
