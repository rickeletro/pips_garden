extends CharacterBody3D
class_name EnemyBase

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")

signal enemy_died(enemy: Node3D)

@export var enemy_data: EnemyData = null
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
var terrain_check_timer: float = 0.0
var in_wet_puddle: bool = false

var dot_timer: float = 0.0
var dot_damage_rate: float = 0.0

var path_waypoints: PackedVector3Array = PackedVector3Array()
var current_waypoint_idx: int = 0
var target_flower: Node3D = null
var attack_timer: float = 0.0
var is_currently_attacking: bool = false
var tower_scan_timer: float = 0.0
var cached_target_tower: Node3D = null

@onready var visual_root: Node3D = $Visuals
var grid_manager: GridManager = null

@export var use_25d_sprites: bool = true
var sprite_25d: DirectionalSprite3D = null

# Resource drop packed scene
@export var pickup_scene: PackedScene

func _ready() -> void:
	add_to_group("enemies")
	if enemy_data:
		max_hp = enemy_data.max_hp
		base_speed = enemy_data.base_speed
		attack_damage = enemy_data.attack_damage
		attack_interval = enemy_data.attack_interval
		xp_reward = enemy_data.xp_reward
		is_flying = enemy_data.is_flying
	hp = max_hp
	current_speed = base_speed
	GameManager.register_enemy_spawned()
	if GameEvents:
		GameEvents.enemy_spawned.emit(self)
	tree_exited.connect(func():
		GameManager.check_wave_cleared_status()
	)
	
	if use_25d_sprites:
		_setup_25d_enemy_visuals()
		
	init_references()
	setup_3d_boss_health_bar()

func _setup_25d_enemy_visuals() -> void:
	var enemy_folder = ""
	var s_name = scene_file_path.to_lower()
	var n_name = name.to_lower()
	
	var offset_y: float = 0.35
	var pixel_size: float = 0.016
	var shadow_sz: Vector3 = Vector3(0.9, 0.9, 0.9)
	
	# Bosses (avaliar antes para não conflitar com substrings)
	if self is BossSnail or s_name.contains("snail") or n_name.contains("snail") or n_name.contains("caramujo"):
		enemy_folder = "res://textures/sprites/enemies/boss_snail"
		offset_y = 2.20
		pixel_size = 0.046
		shadow_sz = Vector3(5.0, 1.0, 5.0)
	elif self is BossMoth or s_name.contains("moth") or n_name.contains("moth") or n_name.contains("mariposa"):
		enemy_folder = "res://textures/sprites/enemies/boss_moth"
		offset_y = 0.0
		pixel_size = 0.068
		shadow_sz = Vector3(4.8, 1.0, 4.8)
	elif self is BossMantis or s_name.contains("mantis") or n_name.contains("mantis") or n_name.contains("louva"):
		enemy_folder = "res://textures/sprites/enemies/boss_mantis"
		offset_y = 2.50
		pixel_size = 0.052
		shadow_sz = Vector3(3.0, 1.0, 3.0)
	elif self is BossWaspQueen or s_name.contains("queen") or n_name.contains("queen") or n_name.contains("imperatriz"):
		enemy_folder = "res://textures/sprites/enemies/boss_wasp_queen"
		offset_y = 0.0
		pixel_size = 0.070
		shadow_sz = Vector3(4.4, 1.0, 4.4)
	elif self is BossSpider or s_name.contains("spider") or n_name.contains("spider") or n_name.contains("aranha"):
		enemy_folder = "res://textures/sprites/enemies/boss_spider"
		offset_y = 1.70
		pixel_size = 0.058
		shadow_sz = Vector3(5.6, 1.0, 5.6)
	elif self is BossScorpion or s_name.contains("scorpion") or n_name.contains("scorpion") or n_name.contains("escorpiao"):
		enemy_folder = "res://textures/sprites/enemies/boss_scorpion"
		offset_y = 1.90
		pixel_size = 0.062
		shadow_sz = Vector3(5.6, 1.0, 6.0)
	# Inimigos Regulares
	elif self is Aphid or s_name.contains("aphid") or n_name.contains("aphid"):
		enemy_folder = "res://textures/sprites/enemies/aphid"
		offset_y = 0.54
		pixel_size = 0.018
		shadow_sz = Vector3(1.30, 1.30, 1.30)
	elif self is Beetle or s_name.contains("beetle") or n_name.contains("beetle"):
		enemy_folder = "res://textures/sprites/enemies/beetle"
		offset_y = 0.76
		pixel_size = 0.027
		shadow_sz = Vector3(1.90, 1.90, 1.90)
	elif self is Caterpillar or s_name.contains("caterpillar") or n_name.contains("caterpillar") or n_name.contains("lagarta"):
		enemy_folder = "res://textures/sprites/enemies/caterpillar"
		offset_y = 0.64
		pixel_size = 0.031
		shadow_sz = Vector3(2.6, 1.6, 2.6)
	elif self is Wasp or s_name.contains("wasp") or n_name.contains("wasp") or n_name.contains("abelha"):
		enemy_folder = "res://textures/sprites/enemies/wasp"
		offset_y = 0.0
		pixel_size = 0.028
		shadow_sz = Vector3(1.50, 1.50, 1.50)
	elif self is Firefly or s_name.contains("firefly") or n_name.contains("firefly") or n_name.contains("vagalume"):
		enemy_folder = "res://textures/sprites/enemies/firefly"
		offset_y = 0.0
		pixel_size = 0.025
		shadow_sz = Vector3(1.30, 1.30, 1.30)
		
	if enemy_folder == "" or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(enemy_folder)):
		return
		
	if visual_root:
		for m in visual_root.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).visible = false
			
	sprite_25d = DirectionalSprite3D.new()
	sprite_25d.name = "Sprite25D"
	sprite_25d.sprite_offset_y = offset_y
	sprite_25d.sprite_pixel_size = pixel_size
	sprite_25d.shadow_scale = shadow_sz
	add_child(sprite_25d)
	
	sprite_25d.load_sprites_from_dir(enemy_folder)
	sprite_25d.play("walk", true, 8.0)


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
	
	check_attack_target(delta)
	
	if not is_currently_attacking:
		if is_flying:
			process_flying_movement(delta)
		else:
			process_ground_movement(delta)
	else:
		velocity = velocity.lerp(Vector3.ZERO, delta * 8.0)
		move_and_slide()

func check_attack_target(delta: float) -> void:
	attack_timer -= delta
	is_currently_attacking = false
	
	# 1. Alvo prioritário corpo-a-corpo: Pip (Heroína)
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip):
		var dist_pip = global_position.distance_to(pip.global_position)
		var attack_range_pip = 2.4 if is_flying else 1.65
		if dist_pip <= attack_range_pip:
			is_currently_attacking = true
			if attack_timer <= 0.0:
				perform_attack_on_pip(pip)
				attack_timer = attack_interval
			return
			
	# 2. Torre de Defesa no caminho (scan otimizado a cada 0.15s)
	tower_scan_timer -= delta
	if cached_target_tower and is_instance_valid(cached_target_tower) and cached_target_tower.get("is_broken") != true:
		var dist_cached = global_position.distance_to(cached_target_tower.global_position)
		if dist_cached <= 1.85:
			is_currently_attacking = true
			if attack_timer <= 0.0:
				perform_attack_on_tower(cached_target_tower)
				attack_timer = attack_interval
			return
		elif dist_cached > 3.0:
			cached_target_tower = null
	else:
		cached_target_tower = null

	if tower_scan_timer <= 0.0:
		tower_scan_timer = 0.15 + randf() * 0.05
		var tree = get_tree()
		if tree:
			var towers = tree.get_nodes_in_group("towers")
			for tw in towers:
				if is_instance_valid(tw) and tw.get("is_broken") != true:
					var dist_tw = global_position.distance_to(tw.global_position)
					if dist_tw <= 1.85:
						cached_target_tower = tw
						is_currently_attacking = true
						if attack_timer <= 0.0:
							perform_attack_on_tower(tw)
							attack_timer = attack_interval
						return

	# 3. Flor Central do Jardim (Objetivo final)
	if not target_flower or not is_instance_valid(target_flower):
		if GameManager.flower:
			target_flower = GameManager.flower
	if target_flower and is_instance_valid(target_flower):
		var dist_fl = global_position.distance_to(target_flower.global_position)
		if dist_fl <= 2.3:
			is_currently_attacking = true
			if attack_timer <= 0.0:
				perform_attack_on_flower()
				attack_timer = attack_interval
			return

func perform_attack_on_pip(pip: Node3D) -> void:
	if visual_root:
		play_lunge_visual(pip.global_position)
	if pip.has_method("take_damage"):
		pip.take_damage(attack_damage, global_position)

func perform_attack_on_tower(tw: Node3D) -> void:
	if visual_root:
		play_lunge_visual(tw.global_position)
	if tw.has_method("take_damage"):
		tw.take_damage(attack_damage)

func perform_attack_on_flower() -> void:
	if visual_root and target_flower:
		play_lunge_visual(target_flower.global_position)
	if target_flower and target_flower.has_method("take_damage"):
		target_flower.take_damage(attack_damage)
	else:
		GameManager.damage_flower(attack_damage)

func play_lunge_visual(target_pos: Vector3) -> void:
	var tree = get_tree()
	if not tree or not visual_root:
		return
	var dir = (target_pos - global_position).normalized()
	dir.y = 0.0
	if sprite_25d:
		sprite_25d.set_facing(dir)
		sprite_25d.play("attack", false, 12.0)
	var tween = tree.create_tween()
	tween.tween_property(visual_root, "position", dir * 0.35, 0.08)
	tween.tween_property(visual_root, "position", Vector3.ZERO, 0.12)

func handle_status_effects(delta: float) -> void:
	terrain_check_timer -= delta
	if terrain_check_timer <= 0.0:
		terrain_check_timer = 0.15
		if not is_flying:
			if not grid_manager:
				init_references()
			if grid_manager:
				var cell = grid_manager.world_to_grid(global_position)
				grass_slow_factor = 0.60 if grid_manager.get_tile_type(cell) == GridManager.TileType.GRASS else 1.0
			else:
				grass_slow_factor = 1.0
				
			in_wet_puddle = false
			var tree = get_tree()
			if tree:
				var puddles = tree.get_nodes_in_group("wet_puddles")
				for pud in puddles:
					if is_instance_valid(pud):
						var r = pud.get_meta("radius", 3.0)
						if global_position.distance_to(pud.global_position) <= r:
							in_wet_puddle = true
							break
		else:
			grass_slow_factor = 1.0
			in_wet_puddle = false
	
	# Status Slow (ex: veneno de torre)
	var poison_slow = 1.0
	if slow_timer > 0.0:
		slow_timer -= delta
		poison_slow = slow_factor
		if slow_timer <= 0.0:
			slow_factor = 1.0
	
	var total_grass_slow = grass_slow_factor * (0.80 if (in_wet_puddle and not is_flying) else 1.0)
	
	# Velocidade efetiva combinando veneno, terreno de grama e poças
	current_speed = base_speed * poison_slow * total_grass_slow
		
	# Corrosive DoT (+30% de dano se estiver sobre poça de orvalho)
	if dot_timer > 0.0:
		dot_timer -= delta
		var dot_mult = 1.30 if in_wet_puddle else 1.0
		take_damage(dot_damage_rate * dot_mult * delta, Vector3.ZERO, true)

func recalculate_path() -> void:
	if is_flying:
		return
	if not grid_manager:
		init_references()
	if grid_manager:
		path_waypoints = grid_manager.get_path_to_flower(global_position)
		current_waypoint_idx = 0

var last_pos: Vector3 = Vector3.ZERO
var stuck_timer: float = 0.0

func process_ground_movement(delta: float) -> void:
	if path_waypoints.is_empty() or current_waypoint_idx >= path_waypoints.size():
		if target_flower and is_instance_valid(target_flower):
			move_towards_point(target_flower.global_position, delta)
		return
	
	var target_wp = path_waypoints[current_waypoint_idx]
	target_wp.y = global_position.y
	
	if global_position.distance_to(target_wp) < 1.3:
		current_waypoint_idx += 1
		if current_waypoint_idx < path_waypoints.size():
			target_wp = path_waypoints[current_waypoint_idx]
			target_wp.y = global_position.y
			
	# Stuck detection: se bloqueado por colisão ou relevo, avança waypoint ou recalcula
	if global_position.distance_squared_to(last_pos) < 0.02:
		stuck_timer += delta
		if stuck_timer > 1.0:
			stuck_timer = 0.0
			current_waypoint_idx += 1
			if current_waypoint_idx >= path_waypoints.size():
				recalculate_path()
	else:
		stuck_timer = 0.0
		last_pos = global_position
		
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
	
	if dir.length_squared() > 0.01:
		if visual_root:
			var target_rot = atan2(dir.x, dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 10.0 * delta)
		if sprite_25d:
			sprite_25d.set_facing(dir)
			if not is_currently_attacking:
				sprite_25d.play("walk", true, 10.0)


var is_dead: bool = false
var health_bar_3d: Node3D = null
var health_fill_mesh: MeshInstance3D = null
var health_fill_mat: StandardMaterial3D = null

func setup_3d_boss_health_bar() -> void:
	if max_hp < 400.0 and not is_in_group("bosses"):
		return
	health_bar_3d = Node3D.new()
	health_bar_3d.name = "HealthBar3D"
	add_child(health_bar_3d)
	health_bar_3d.position = Vector3(0, 1.8 if is_flying else 1.5, 0)
	
	# Fundo preto
	var bg = MeshInstance3D.new()
	var bg_quad = QuadMesh.new()
	bg_quad.size = Vector2(1.6, 0.16)
	bg.mesh = bg_quad
	var bg_mat = StandardMaterial3D.new()
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.albedo_color = Color(0.08, 0.08, 0.1, 0.85)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg.material_override = bg_mat
	health_bar_3d.add_child(bg)
	
	# Barra de preenchimento vermelha/dourada
	health_fill_mesh = MeshInstance3D.new()
	var fill_quad = QuadMesh.new()
	fill_quad.size = Vector2(1.52, 0.11)
	health_fill_mesh.mesh = fill_quad
	health_fill_mat = StandardMaterial3D.new()
	health_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	health_fill_mat.albedo_color = Color(0.95, 0.2, 0.25)
	health_fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	health_fill_mesh.material_override = health_fill_mat
	health_fill_mesh.position.z = 0.01
	health_bar_3d.add_child(health_fill_mesh)

func update_3d_health_bar() -> void:
	if not health_fill_mesh or max_hp <= 0.0:
		return
	var pct = clampf(hp / max_hp, 0.0, 1.0)
	health_fill_mesh.scale.x = pct
	health_fill_mesh.position.x = -0.76 * (1.0 - pct)
	if health_fill_mat:
		if pct > 0.5:
			health_fill_mat.albedo_color = Color(0.95, 0.25, 0.25).lerp(Color(1.0, 0.75, 0.2), (1.0 - pct) * 2.0)
		else:
			health_fill_mat.albedo_color = Color(1.0, 0.75, 0.2).lerp(Color(0.85, 0.1, 0.15), (0.5 - pct) * 2.0)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, _armor_pierce: float = 0.0) -> void:
	if is_dead:
		return
		
	hp -= amount
	update_3d_health_bar()
	if GameEvents:
		GameEvents.enemy_damaged.emit(self, amount, hp, max_hp)
	
	if GameManager.active_boss == self or is_in_group("bosses"):
		GameManager.update_active_boss_hp(hp, max_hp)
	
	if not is_dot:
		spawn_hit_blood_particles()
		flash_damage()
		if sprite_25d:
			sprite_25d.flash_hit()
	
	if hp <= 0.0 and not is_dead:
		is_dead = true
		if health_bar_3d:
			health_bar_3d.visible = false
		if GameManager.active_boss == self:
			GameManager.unregister_active_boss(self)
		die()

var original_mesh_materials: Dictionary = {}
var is_flashing: bool = false
var last_splat_tick: int = 0
static var flash_damage_mat: StandardMaterial3D = null
static var shared_splat_mesh_small: SphereMesh = null
static var shared_splat_mesh_boss: SphereMesh = null
static var shared_mat_blood_red: StandardMaterial3D = null
static var shared_mat_blood_amber: StandardMaterial3D = null
static var shared_mat_moth_dust: StandardMaterial3D = null

func _init_splat_shared_resources() -> void:
	if shared_splat_mesh_small == null:
		shared_splat_mesh_small = SphereMesh.new()
		shared_splat_mesh_small.radius = 0.04
		shared_splat_mesh_small.height = 0.08
		shared_splat_mesh_small.radial_segments = 6
		shared_splat_mesh_small.rings = 3
		
		shared_splat_mesh_boss = SphereMesh.new()
		shared_splat_mesh_boss.radius = 0.06
		shared_splat_mesh_boss.height = 0.12
		shared_splat_mesh_boss.radial_segments = 6
		shared_splat_mesh_boss.rings = 3
		
		shared_mat_blood_red = StandardMaterial3D.new()
		shared_mat_blood_red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shared_mat_blood_red.albedo_color = Color(0.85, 0.15, 0.2, 0.9)
		
		shared_mat_blood_amber = StandardMaterial3D.new()
		shared_mat_blood_amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shared_mat_blood_amber.albedo_color = Color(0.9, 0.65, 0.1, 0.9)
		
		shared_mat_moth_dust = StandardMaterial3D.new()
		shared_mat_moth_dust.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shared_mat_moth_dust.albedo_color = Color(0.9, 0.95, 1.0, 0.95)

func spawn_hit_blood_particles() -> void:
	var now = Time.get_ticks_msec()
	if now - last_splat_tick < 75:
		return
	last_splat_tick = now
	
	var parent_node = get_parent()
	if not parent_node:
		return
		
	_init_splat_shared_resources()
	
	var splat = Node3D.new()
	parent_node.add_child(splat)
	splat.global_position = global_position + Vector3(0, 0.4 if is_flying else 0.25, 0)
	
	var is_boss = (max_hp >= 400.0 or is_in_group("bosses"))
	var count = 4 if is_boss else 2
	var mesh = shared_splat_mesh_boss if is_boss else shared_splat_mesh_small
	var mat = shared_mat_moth_dust if self is BossMoth else (shared_mat_blood_red if randf() < 0.6 else shared_mat_blood_amber)
	
	for i in range(count):
		var drop = MeshInstance3D.new()
		drop.mesh = mesh
		drop.material_override = mat
		splat.add_child(drop)
		
		var angle = randf() * TAU
		var elevation = randf_range(0.2, 0.7)
		var dist = randf_range(0.3, 0.9)
		var dest = Vector3(cos(angle) * dist, elevation, sin(angle) * dist)
		
		var tw = drop.create_tween()
		tw.tween_property(drop, "position", dest, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(drop, "scale", Vector3.ZERO, 0.22).set_delay(0.06)
		
	var timer = splat.get_tree().create_timer(0.30)
	timer.timeout.connect(splat.queue_free)

func flash_damage() -> void:
	if not visual_root:
		return
		
	if flash_damage_mat == null:
		flash_damage_mat = StandardMaterial3D.new()
		flash_damage_mat.albedo_color = Color(1.0, 0.35, 0.35)
		flash_damage_mat.emission_enabled = true
		flash_damage_mat.emission = Color(1.0, 0.2, 0.2)
		flash_damage_mat.emission_energy_multiplier = 1.0
		
	if original_mesh_materials.is_empty():
		for node in visual_root.find_children("*", "MeshInstance3D"):
			var m = node as MeshInstance3D
			if m:
				original_mesh_materials[m] = m.material_override if m.material_override else m.get_active_material(0)
				
	for m in original_mesh_materials.keys():
		if is_instance_valid(m):
			(m as MeshInstance3D).material_override = flash_damage_mat
			
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(0.09)
		timer.timeout.connect(func():
			for m in original_mesh_materials.keys():
				if is_instance_valid(m):
					(m as MeshInstance3D).material_override = original_mesh_materials[m]
		)

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = min(slow_factor, factor)
	slow_timer = max(slow_timer, duration)

func apply_corrosive_dot(damage_per_sec: float, duration: float) -> void:
	dot_damage_rate = damage_per_sec
	dot_timer = max(dot_timer, duration)

func die() -> void:
	if GameEvents:
		GameEvents.enemy_defeated.emit(self, xp_reward)
	GameManager.add_xp(xp_reward)
	GameManager.register_enemy_killed(self)
	spawn_drop()
	queue_free()

func spawn_drop() -> void:
	var roll = randf()
	var drop_type = ""
	# 18% de chance de drop total por inimigo comum (10% Twig, 5% Seed, 3% Gear)
	if roll < 0.10:
		drop_type = "TWIG"
	elif roll < 0.15:
		drop_type = "SEED"
	elif roll < 0.18:
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
