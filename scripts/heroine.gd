extends CharacterBody3D
class_name Heroine

signal health_changed(current_hp: float, max_hp: float)
signal animation_triggered(anim_name: String)

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

# Special Action States
var is_planting: bool = false
var is_building: bool = false
var is_hopping: bool = false
var is_recoiling: bool = false

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

func _ready() -> void:
	GameManager.heroine = self
	attack_area.monitoring = false
	if slash_fx:
		slash_fx.visible = false
	if hair_ponytail:
		base_ponytail_x = hair_ponytail.rotation.x
	
	init_grid_reference()
	
	# Connect to action slot signals from HUD
	GameManager.request_plant_grass.connect(try_plant_grass)
	GameManager.request_build_tower.connect(try_build_tower)
	GameManager.request_attack.connect(func():
		if can_act():
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

func can_act() -> bool:
	return not is_dashing and not is_recoiling

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		check_dash_hits()
		return
	
	# Lock movement during stationary special actions
	if is_planting or is_building or is_recoiling:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 15.0 * delta)
		move_and_slide()
		return
	
	# Movement input
	var input_x = Input.get_axis("move_left", "move_right")
	var input_z = Input.get_axis("move_up", "move_down")
	var move_dir = Vector3(input_x, 0.0, input_z).normalized()
	
	if move_dir.length_squared() > 0.01:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		
		# Rotate visual towards movement if not attacking
		if not is_attacking:
			var target_rot = atan2(move_dir.x, move_dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 16.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 12.0 * delta)
		
	# Apply animations (Idle breathing / Arrietty Run tilt)
	animate_locomotion(delta)
	
	move_and_slide()

func animate_locomotion(delta: float) -> void:
	var speed = velocity.length()
	var t = Time.get_ticks_msec() * 0.001
	
	if speed > 0.5:
		# Correndo (estilo Arrietty: inclinada para frente ~16°, pés batem rápido)
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.28, delta * 12.0)
		if not is_hopping:
			visual_root.position.y = abs(sin(t * 18.0)) * 0.08
		
		# Ponytail trails back behind runner
		if hair_ponytail:
			hair_ponytail.rotation.x = lerp(hair_ponytail.rotation.x, base_ponytail_x + 0.35 + sin(t * 18.0) * 0.12, delta * 10.0)
			
		# Needle sways gently on hip
		if not is_attacking and needle_pivot:
			needle_pivot.rotation.z = sin(t * 18.0) * 0.15
			needle_pivot.rotation.x = cos(t * 18.0) * 0.10
	else:
		# Idle: respiração sutil (escala Y oscila 2.5%), mecha de cabelo balança suavemente
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.0, delta * 8.0)
		if not is_hopping:
			visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 3.0)
			visual_root.scale.y = 1.0 + sin(t * 3.5) * 0.025
			visual_root.scale.x = 1.0 - sin(t * 3.5) * 0.012
			visual_root.scale.z = visual_root.scale.x
			
		if hair_ponytail:
			hair_ponytail.rotation.x = lerp(hair_ponytail.rotation.x, base_ponytail_x + sin(t * 2.8) * 0.08, delta * 6.0)
			
		if not is_attacking and needle_pivot:
			needle_pivot.rotation = needle_pivot.rotation.lerp(Vector3.ZERO, delta * 8.0)

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.wave_state == GameManager.WaveState.DEFEAT:
		return
		
	if event.is_action_pressed("attack") and can_act():
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
			if needle_pivot:
				needle_pivot.rotation = Vector3.ZERO
				needle_pivot.position = Vector3(0.24, 0.28, 0.05)

# 1. ATACANDO COM AGULHA (Estocada rápida 0.15s + recuperação 0.15s + rastro prateado)
func execute_attack_combo() -> void:
	is_attacking = true
	combo_step = (combo_step % 3) + 1
	combo_reset_timer = 0.85
	animation_triggered.emit("attack")
	
	var base_dmg = 16.0 + GameManager.pip_damage_bonus
	var attack_radius = 1.6
	
	match combo_step:
		1:
			# Estocada rápida para frente (Thrust / Jab)
			attack_anim_timer = 0.30
			create_slash_effect(Color(0.92, 0.95, 1.0, 0.9), 0.9)
			var thrust_tween = create_tween()
			thrust_tween.tween_property(needle_pivot, "position", Vector3(0.1, 0.30, 0.55), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			thrust_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-80, 0, 0), 0.14)
			thrust_tween.tween_property(needle_pivot, "position", Vector3(0.24, 0.28, 0.05), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			thrust_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.16)
		2:
			# Corte cruzado diagonal (Cross Slash)
			attack_anim_timer = 0.32
			base_dmg = 24.0 + GameManager.pip_damage_bonus
			create_slash_effect(Color(1.0, 0.82, 0.4, 0.9), 1.25)
			var cross_tween = create_tween()
			cross_tween.tween_property(needle_pivot, "position", Vector3(0.2, 0.34, 0.45), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			cross_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-45, 60, -25), 0.15)
			cross_tween.tween_property(needle_pivot, "position", Vector3(0.24, 0.28, 0.05), 0.17)
			cross_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.17)
		3:
			# Giro 360 de varredura final (Spin Sweep Finisher)
			attack_anim_timer = 0.38
			base_dmg = 38.0 + GameManager.pip_damage_bonus
			attack_radius = 2.4
			create_slash_effect(Color(0.4, 0.95, 1.0, 1.0), 1.8)
			var spin_tween = create_tween()
			spin_tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y + TAU, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			spin_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(-20, 90, 0), 0.15)
			spin_tween.tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.12)
			
	# Hit detection
	attack_area.monitoring = true
	await get_tree().create_timer(0.08).timeout
	
	var hits = attack_area.get_overlapping_bodies()
	for body in hits:
		if body != self and body.is_in_group("enemies"):
			var knock_dir = (body.global_position - global_position).normalized()
			if body.has_method("take_damage"):
				body.take_damage(base_dmg, knock_dir * (3.8 if combo_step == 3 else 1.6))
		elif body.has_method("on_attack_hit"):
			body.on_attack_hit(global_position)
			
	var areas = attack_area.get_overlapping_areas()
	for a in areas:
		var parent = a.get_parent()
		if parent and parent.has_method("on_attack_hit"):
			parent.on_attack_hit(global_position)
		elif a.has_method("on_attack_hit"):
			a.on_attack_hit(global_position)
			
	# Checagem de proximidade direta para soprar/colher dentes-de-leão (Dandelion Clock)
	var tree = get_tree()
	if tree:
		var dandelions = tree.get_nodes_in_group("dandelion")
		for dand in dandelions:
			if is_instance_valid(dand):
				if global_position.distance_to(dand.global_position) <= attack_radius + 1.2:
					if dand.has_method("on_attack_hit"):
						dand.on_attack_hit(global_position)

func create_slash_effect(tint: Color, scale_mult: float) -> void:
	if not slash_fx:
		return
	slash_fx.visible = true
	slash_fx.scale = Vector3(scale_mult, scale_mult, scale_mult)
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	slash_fx.material_override = mat

# 2. PLANTANDO GRAMA (Agacha rápido, toca o chão, partícula verde sobe, levanta)
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
		
	is_planting = true
	animation_triggered.emit("plant")
	spawn_leaf_puff_fx(global_position)
	
	# Crouch & touch ground animation
	var plant_tween = create_tween()
	plant_tween.tween_property(visual_root, "position:y", -0.15, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	plant_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3(45, 0, 0), 0.10)
	plant_tween.tween_property(visual_root, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	plant_tween.parallel().tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.12)
	plant_tween.tween_callback(func():
		is_planting = false
	)

# 3. CONSTRUINDO TORRE (Bate com a agulha como martelo 2x no chão, torre surge)
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
		
	is_building = true
	animation_triggered.emit("build")
	
	# Hammer strikes with needle 2x ("tap! tap!")
	var build_tween = create_tween()
	# Strike 1
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-95, 0, 0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	build_tween.tween_callback(func(): spawn_dust_puff_fx(global_position + Vector3(0, 0.05, 0.3), Tokens.LATAO_ENGRENAGEM))
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-20, 0, 0), 0.08)
	# Strike 2
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3(-95, 0, 0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	build_tween.tween_callback(func(): spawn_dust_puff_fx(global_position + Vector3(0, 0.05, 0.3), Tokens.MARROM_CASCA))
	# Recovery
	build_tween.tween_property(needle_pivot, "rotation_degrees", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE)
	build_tween.tween_callback(func():
		is_building = false
	)

# 4. COLETANDO RECURSO (Pequeno pulo de alegria: hop de 0.22 unidades com squash & stretch)
func play_collect_hop() -> void:
	if is_hopping or not can_act():
		return
	is_hopping = true
	animation_triggered.emit("collect")
	
	var hop_tween = create_tween()
	# Ascent: hop +0.22 and stretch Y
	hop_tween.tween_property(visual_root, "position:y", 0.22, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.parallel().tween_property(visual_root, "scale", Vector3(0.9, 1.15, 0.9), 0.12)
	# Descent: land with gentle squash
	hop_tween.tween_property(visual_root, "position:y", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hop_tween.parallel().tween_property(visual_root, "scale", Vector3(1.12, 0.88, 1.12), 0.10)
	# Settle to normal
	hop_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.08)
	hop_tween.tween_callback(func():
		is_hopping = false
	)

# 5. TOMANDO DANO (Pisca em vermelho/branco, recua 0.3 unidades, poeira sobe)
func take_damage(amount: float, source_pos: Vector3 = Vector3.ZERO) -> void:
	if is_invulnerable:
		return
	GameManager.damage_pip(amount)
	is_invulnerable = true
	is_recoiling = true
	animation_triggered.emit("hurt")
	
	# Recoil direction away from source
	var recoil_dir = -visual_root.global_transform.basis.z
	if source_pos != Vector3.ZERO:
		recoil_dir = (global_position - source_pos).normalized()
		recoil_dir.y = 0.0
	
	velocity = recoil_dir * 5.0
	spawn_dust_puff_fx(global_position, Tokens.PERIGO)
	
	# Flash red/white
	flash_damage_visuals()
	
	var recoil_tween = create_tween()
	recoil_tween.tween_property(visual_root, "position", recoil_dir * 0.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.14)
	recoil_tween.tween_callback(func():
		is_recoiling = false
	)
	
	await get_tree().create_timer(0.4).timeout
	is_invulnerable = false

func flash_damage_visuals() -> void:
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.25, 0.25, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.4, 0.4)
	flash_mat.emission_energy_multiplier = 1.2
	
	var original_materials: Dictionary = {}
	for mesh in visual_root.find_children("*", "MeshInstance3D"):
		var m = mesh as MeshInstance3D
		if m and m != slash_fx:
			original_materials[m] = m.material_override
			m.material_override = flash_mat
			
	var tree = get_tree()
	if tree:
		await tree.create_timer(0.18).timeout
		for mesh in original_materials.keys():
			if is_instance_valid(mesh):
				(mesh as MeshInstance3D).material_override = original_materials[mesh]

func start_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	animation_triggered.emit("dash")
	
	var move_dir = velocity.normalized()
	if move_dir.length_squared() < 0.1:
		move_dir = -visual_root.global_transform.basis.z
		move_dir.y = 0.0
		move_dir = move_dir.normalized()
	
	dash_direction = move_dir
	visual_root.rotation.y = atan2(dash_direction.x, dash_direction.z)
	
	# Needle points forward for lance charge
	needle_pivot.rotation_degrees = Vector3(-85, 0, 0)
	create_slash_effect(Color(1.0, 1.0, 0.85, 0.9), 1.5)

func check_dash_hits() -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var knock = dash_direction * 3.5
			body.take_damage(20.0 + GameManager.pip_damage_bonus, knock)
		elif body.has_method("on_attack_hit"):
			body.on_attack_hit(global_position)
			
	var tree = get_tree()
	if tree:
		var dandelions = tree.get_nodes_in_group("dandelion")
		for dand in dandelions:
			if is_instance_valid(dand):
				if global_position.distance_to(dand.global_position) <= 2.2:
					if dand.has_method("on_attack_hit"):
						dand.on_attack_hit(global_position)

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
					# Play mini hammer tap on repair
					try_build_tower()
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

# Helper visual particle effects
func spawn_leaf_puff_fx(spawn_pos: Vector3) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var puff = Node3D.new()
	parent_node.add_child(puff)
	puff.global_position = spawn_pos + Vector3(0, 0.1, 0)
	
	for i in range(5):
		var leaf = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.08, 0.02, 0.14)
		leaf.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Tokens.VERDE_FOLHA
		mat.roughness = 0.5
		leaf.material_override = mat
		puff.add_child(leaf)
		
		var angle = (i / 5.0) * TAU
		var target_offset = Vector3(cos(angle) * 0.45, 0.35 + randf() * 0.2, sin(angle) * 0.45)
		var tween = leaf.create_tween()
		tween.tween_property(leaf, "position", target_offset, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(leaf, "scale", Vector3.ZERO, 0.35)
		
	var timer = puff.get_tree().create_timer(0.4)
	timer.timeout.connect(puff.queue_free)

func spawn_dust_puff_fx(spawn_pos: Vector3, tint: Color) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var puff = Node3D.new()
	parent_node.add_child(puff)
	puff.global_position = spawn_pos
	
	for i in range(4):
		var particle = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.05
		mesh.height = 0.10
		particle.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.75
		particle.material_override = mat
		puff.add_child(particle)
		
		var angle = (i / 4.0) * TAU
		var target_offset = Vector3(cos(angle) * 0.35, 0.25, sin(angle) * 0.35)
		var tween = particle.create_tween()
		tween.tween_property(particle, "position", target_offset, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(particle, "scale", Vector3.ZERO, 0.30)
		
	var timer = puff.get_tree().create_timer(0.35)
	timer.timeout.connect(puff.queue_free)
