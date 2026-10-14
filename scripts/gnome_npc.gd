extends CharacterBody3D
class_name GnomeNPC

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")

# ==============================================================================
# GNOMO LADRÃO NOTURNO (NIGHT GNOME)
# ==============================================================================
# - Aparece à noite quando a 1ª onda está quase terminando.
# - Roupas azuis, gorro pontudo, barba e um grande saco nas costas.
# - Corre mais rápido que a Pip e coleta todos os itens do chão.
# - Fica parado caso não haja itens no chão; volta a correr ao surgirem novos itens.
# - 1º Golpe da Pip: Brilha, faz barulhinho de coelho e acelera a corrida.
# - 2º Golpe da Pip: Solta todo o saco de itens em explosão de loot e foge do jardim.
# ==============================================================================

enum GnomeState {
	ENTERING,
	FORAGING,
	WAITING_FOR_ITEMS,
	PANIC_FLEE
}

var current_state: GnomeState = GnomeState.ENTERING
var hits_taken: int = 0

var base_speed: float = 5.8 # Mais rápido que Pip (5.0)
var current_speed: float = 5.8
var flee_speed: float = 9.2

var stolen_items: Array[String] = []
var target_pickup: Node3D = null

# Referências visuais
var visual_root: Node3D = null
var sack_node: Node3D = null
var sack_mesh: MeshInstance3D = null
var hat_node: Node3D = null
var beard_node: MeshInstance3D = null
var glow_light: OmniLight3D = null
var sprite_25d: DirectionalSprite3D = null

var search_timer: float = 0.0
var idle_anim_timer: float = 0.0
var flee_target_pos: Vector3 = Vector3(55.0, 0.0, 0.0)
var is_fleeing: bool = false

func _ready() -> void:
	add_to_group("gnome")
	add_to_group("npcs")
	
	_build_visuals()
	
	current_speed = base_speed
	flee_target_pos = Vector3(55.0 if global_position.x > 0 else -55.0, 0.0, global_position.z)
	
	# Inicia música do Gnomo
	SoundManager.play_gnome_sneaks_music(1.5, -3.5)

func _build_visuals() -> void:
	# Cria colisor
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.24
	cap.height = 0.72
	col.shape = cap
	col.position.y = 0.36
	add_child(col)
	
	visual_root = Node3D.new()
	visual_root.name = "Visuals"
	add_child(visual_root)
	
	# Materiais
	var mat_skin = StandardMaterial3D.new()
	mat_skin.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_skin.albedo_color = Color(0.98, 0.86, 0.74)
	
	var mat_blue_tunic = StandardMaterial3D.new()
	mat_blue_tunic.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_blue_tunic.albedo_color = Color(0.18, 0.36, 0.72)
	mat_blue_tunic.roughness = 0.7
	
	var mat_belt = StandardMaterial3D.new()
	mat_belt.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_belt.albedo_color = Color(0.42, 0.26, 0.14)
	
	var mat_boots = StandardMaterial3D.new()
	mat_boots.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_boots.albedo_color = Color(0.32, 0.20, 0.12)
	
	var mat_beard = StandardMaterial3D.new()
	mat_beard.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_beard.albedo_color = Color(0.92, 0.94, 0.96)
	
	var mat_sack = StandardMaterial3D.new()
	mat_sack.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat_sack.albedo_color = Color(0.66, 0.52, 0.35)
	mat_sack.roughness = 0.85
	
	# Corpo & Túnica Azul
	var body_node = Node3D.new()
	visual_root.add_child(body_node)
	
	var tunic = MeshInstance3D.new()
	var cyl_tunic = CylinderMesh.new()
	cyl_tunic.top_radius = 0.12
	cyl_tunic.bottom_radius = 0.21
	cyl_tunic.height = 0.29
	tunic.mesh = cyl_tunic
	tunic.material_override = mat_blue_tunic
	tunic.position.y = 0.22
	body_node.add_child(tunic)
	
	var belt = MeshInstance3D.new()
	var torus_belt = TorusMesh.new()
	torus_belt.inner_radius = 0.12
	torus_belt.outer_radius = 0.155
	belt.mesh = torus_belt
	belt.material_override = mat_belt
	belt.position.y = 0.29
	body_node.add_child(belt)
	
	# Botas
	var foot_l = MeshInstance3D.new()
	var cap_foot = CapsuleMesh.new()
	cap_foot.radius = 0.05
	cap_foot.height = 0.14
	foot_l.mesh = cap_foot
	foot_l.material_override = mat_boots
	foot_l.position = Vector3(-0.08, 0.06, 0.01)
	body_node.add_child(foot_l)
	
	var foot_r = MeshInstance3D.new()
	foot_r.mesh = cap_foot
	foot_r.material_override = mat_boots
	foot_r.position = Vector3(0.08, 0.06, 0.01)
	body_node.add_child(foot_r)
	
	# Cabeça, Barba e Gorro Azul
	var head_pivot = Node3D.new()
	head_pivot.position.y = 0.44
	visual_root.add_child(head_pivot)
	
	var head = MeshInstance3D.new()
	var sph_head = SphereMesh.new()
	sph_head.radius = 0.15
	sph_head.height = 0.30
	head.mesh = sph_head
	head.material_override = mat_skin
	head_pivot.add_child(head)
	
	# Nariz de Gnomo
	var nose = MeshInstance3D.new()
	var sph_nose = SphereMesh.new()
	sph_nose.radius = 0.045
	sph_nose.height = 0.08
	nose.mesh = sph_nose
	var mat_nose = mat_skin.duplicate() as StandardMaterial3D
	mat_nose.albedo_color = Color(0.96, 0.65, 0.58)
	nose.material_override = mat_nose
	nose.position = Vector3(0, 0.01, 0.15)
	head_pivot.add_child(nose)
	
	# Barba Branca
	beard_node = MeshInstance3D.new()
	var cone_beard = CylinderMesh.new()
	cone_beard.top_radius = 0.14
	cone_beard.bottom_radius = 0.02
	cone_beard.height = 0.24
	beard_node.mesh = cone_beard
	beard_node.material_override = mat_beard
	beard_node.position = Vector3(0, -0.09, 0.10)
	beard_node.rotation_degrees.x = -25.0
	head_pivot.add_child(beard_node)
	
	# Gorro Azul Pontudo
	hat_node = Node3D.new()
	head_pivot.add_child(hat_node)
	hat_node.position = Vector3(0, 0.12, 0)
	
	var hat_mesh = MeshInstance3D.new()
	var cone_hat = CylinderMesh.new()
	cone_hat.top_radius = 0.01
	cone_hat.bottom_radius = 0.17
	cone_hat.height = 0.32
	hat_mesh.mesh = cone_hat
	hat_mesh.material_override = mat_blue_tunic
	hat_mesh.rotation_degrees.x = -20.0
	hat_mesh.position = Vector3(0, 0.14, -0.05)
	hat_node.add_child(hat_mesh)
	
	# Grande Saco nas Costas
	sack_node = Node3D.new()
	visual_root.add_child(sack_node)
	sack_node.position = Vector3(0, 0.28, -0.22)
	
	sack_mesh = MeshInstance3D.new()
	var sph_sack = SphereMesh.new()
	sph_sack.radius = 0.22
	sph_sack.height = 0.40
	sack_mesh.mesh = sph_sack
	sack_mesh.material_override = mat_sack
	sack_mesh.rotation_degrees.x = 25.0
	sack_node.add_child(sack_mesh)
	
	# Luz suave de destaque
	glow_light = OmniLight3D.new()
	glow_light.light_color = Color(0.4, 0.7, 1.0)
	glow_light.light_energy = 1.2
	glow_light.omni_range = 3.5
	add_child(glow_light)
	
	# Visual 2.5D Pixel Art Ragnarok
	var gnome_folder = "res://textures/sprites/npcs/gnome"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(gnome_folder)):
		sprite_25d = DirectionalSprite3D.new()
		sprite_25d.name = "Sprite25D"
		sprite_25d.sprite_offset_y = 0.72
		sprite_25d.sprite_pixel_size = 0.023
		sprite_25d.shadow_scale = Vector3(1.20, 1.20, 1.20)
		add_child(sprite_25d)
		sprite_25d.load_sprites_from_dir(gnome_folder)
		sprite_25d.play("idle", true, 6.0)
		for m in visual_root.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).visible = false

func _physics_process(delta: float) -> void:
	# Se a noite acabou e virou dia, foge do jardim
	if GameManager.current_period == "DAY" and not is_fleeing:
		start_flee(false)
		
	match current_state:
		GnomeState.ENTERING:
			process_entering(delta)
		GnomeState.FORAGING:
			process_foraging(delta)
		GnomeState.WAITING_FOR_ITEMS:
			process_waiting(delta)
		GnomeState.PANIC_FLEE:
			process_fleeing(delta)
			
	_animate_locomotion(delta)

func process_entering(delta: float) -> void:
	var center_dest = Vector3.ZERO
	var to_center = center_dest - global_position
	to_center.y = 0.0
	
	if to_center.length() > 5.0:
		velocity = to_center.normalized() * current_speed
		move_and_slide()
		_look_towards(center_dest, delta)
	else:
		current_state = GnomeState.FORAGING

func process_foraging(delta: float) -> void:
	search_timer -= delta
	if search_timer <= 0.0 or not target_pickup or not is_instance_valid(target_pickup):
		search_timer = 0.35
		target_pickup = find_closest_pickup()
		
	if not target_pickup or not is_instance_valid(target_pickup):
		current_state = GnomeState.WAITING_FOR_ITEMS
		velocity = Vector3.ZERO
		return
		
	var target_pos = target_pickup.global_position
	target_pos.y = 0.0
	var my_pos = Vector3(global_position.x, 0.0, global_position.z)
	var diff = target_pos - my_pos
	var dist = diff.length()
	
	if dist <= 0.85:
		# Coleta o item para dentro do saco
		collect_pickup(target_pickup)
		target_pickup = null
		search_timer = 0.0
	else:
		velocity = diff.normalized() * current_speed
		move_and_slide()
		_look_towards(target_pos, delta)

func process_waiting(delta: float) -> void:
	velocity = velocity.lerp(Vector3.ZERO, delta * 6.0)
	move_and_slide()
	
	search_timer -= delta
	if search_timer <= 0.0:
		search_timer = 0.5
		var item = find_closest_pickup()
		if item and is_instance_valid(item):
			target_pickup = item
			current_state = GnomeState.FORAGING

func process_fleeing(delta: float) -> void:
	var diff = flee_target_pos - global_position
	diff.y = 0.0
	
	if diff.length() > 2.0 and abs(global_position.x) < 52.0 and abs(global_position.z) < 52.0:
		velocity = diff.normalized() * flee_speed
		move_and_slide()
		_look_towards(flee_target_pos, delta)
	else:
		# Chegou na borda e desapareceu
		_despawn()

func find_closest_pickup() -> Node3D:
	var tree = get_tree()
	if not tree:
		return null
		
	var pickups = tree.get_nodes_in_group("pickups")
	var closest: Node3D = null
	var min_dist = 9999.0
	
	for p in pickups:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			var d = global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				closest = p
	return closest

func collect_pickup(pickup_node: Node3D) -> void:
	if not pickup_node or not is_instance_valid(pickup_node):
		return
		
	var item_type = "TWIG"
	if "item_type" in pickup_node:
		item_type = str(pickup_node.get("item_type"))
	stolen_items.append(item_type)
	
	SoundManager.play_leaf_pickup(-2.0)
	
	# Efeito de sacudida no saco e crescimento sutil
	if sack_node:
		var tw = create_tween()
		tw.tween_property(sack_node, "scale", Vector3(1.2, 1.25, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sack_node, "scale", Vector3(1.0 + min(stolen_items.size() * 0.02, 0.4), 1.0 + min(stolen_items.size() * 0.02, 0.4), 1.0 + min(stolen_items.size() * 0.02, 0.4)), 0.15)
		
	pickup_node.queue_free()

# --- REAÇÃO AO RECEBER ATAQUE DA PIP ---
func on_attack_hit(_attacker_pos: Vector3) -> void:
	take_damage(1.0)

func take_damage(_amount: float = 1.0, knockback: Vector3 = Vector3.ZERO, _is_dot: bool = false, _armor_pierce: float = 0.0) -> void:
	if is_fleeing:
		return
		
	if sprite_25d:
		sprite_25d.flash_hit(Color(2.5, 2.2, 0.5), 0.2)
		
	hits_taken += 1
	
	# Som de coelhinho assustado e faísca
	SoundManager.play_rabbit_squeak(minf(hits_taken * 0.8, 3.0))
	SoundManager.play_sparkle(1.5, 0.1)
	
	# Brilho radiante e animação de sobressalto
	_play_hit_flash_glow(Color(1.0, 0.9, 0.3))
	
	# Aplica leve repulsão de impacto
	if knockback.length_squared() > 0.01:
		velocity += knockback.normalized() * 3.5
	
	# Aumenta velocidade de corrida a cada golpe
	current_speed = minf(base_speed + float(hits_taken) * 2.0, flee_speed)
	
	# Regra Obrigatória: O gnomo ladrão deve receber ataque e dropar o ÚLTIMO item que pegou!
	if not stolen_items.is_empty():
		var last_item = stolen_items.pop_back()
		_drop_specific_item(last_item)
		_update_sack_visual()
		
		var item_name_str = _format_item_name(last_item)
		GameManager.notify("🦹‍♂️ O Gnomo levou um golpe e soltou o último item roubado (%s)!" % item_name_str, Color(1.0, 0.85, 0.3))
	else:
		GameManager.notify("🦹‍♂️ O Gnomo não tem mais itens no saco e fugiu em pânico!", Color(1.0, 0.7, 0.3))
		start_flee(true)
		return
		
	# Caso tenha acumulado 3 ou mais golpes, ele desiste e foge em disparada
	if hits_taken >= 3:
		start_flee(true)
		GameManager.notify("🎉 O Gnomo levou vários golpes e fugiu em disparada do jardim!", Color(0.3, 1.0, 0.6))

func _format_item_name(item_type: String) -> String:
	match item_type:
		"TWIG": return "Graveto"
		"GEAR": return "Engrenagem"
		"SEED": return "Semente"
		"DEW_DROP", "DEWDROP": return "Gota de Orvalho"
		"FAIRY_TEAR": return "Lágrima de Fada"
		_: return "Recurso"

func _drop_specific_item(item_type: String) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var drop_scn = load("res://scenes/pickup.tscn")
	if not drop_scn:
		return
	_spawn_single_drop(parent_node, drop_scn, item_type)

func _update_sack_visual() -> void:
	if sack_node:
		var target_scale = 1.0 + minf(float(stolen_items.size()) * 0.02, 0.4)
		var tw = create_tween()
		tw.tween_property(sack_node, "scale", Vector3(target_scale, target_scale, target_scale), 0.15)

func _play_hit_flash_glow(color: Color) -> void:
	if glow_light:
		glow_light.light_color = color
		glow_light.light_energy = 4.5
		var tw = create_tween()
		tw.tween_property(glow_light, "light_energy", 1.2, 0.45)
		
	# Efeito de salto/pulo assustado
	if visual_root:
		var tw2 = create_tween()
		tw2.tween_property(visual_root, "position:y", 0.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.tween_property(visual_root, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE)

func _drop_items(count: int) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var drop_scn = load("res://scenes/pickup.tscn")
	if not drop_scn:
		return
		
	for i in range(count):
		if stolen_items.is_empty():
			break
		var item_type = stolen_items.pop_back()
		_spawn_single_drop(parent_node, drop_scn, item_type)

func _drop_all_stolen_items_with_bonus() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var drop_scn = load("res://scenes/pickup.tscn")
	if not drop_scn:
		return
		
	# Solta tudo que foi roubado
	while not stolen_items.is_empty():
		var it = stolen_items.pop_back()
		_spawn_single_drop(parent_node, drop_scn, it)
		
	# Bônus do saco do Gnomo: 4 Gravetos, 3 Engrenagens, 3 Sementes
	for i in range(4):
		_spawn_single_drop(parent_node, drop_scn, "TWIG")
	for i in range(3):
		_spawn_single_drop(parent_node, drop_scn, "GEAR")
	for i in range(3):
		_spawn_single_drop(parent_node, drop_scn, "SEED")

func _spawn_single_drop(parent_node: Node, drop_scn: PackedScene, item_type: String) -> void:
	var p = drop_scn.instantiate()
	p.item_type = item_type
	parent_node.add_child(p)
	
	var angle = randf() * TAU
	var dist = randf_range(1.0, 3.2)
	var spawn_pos = global_position + Vector3(cos(angle) * dist, 0.2, sin(angle) * dist)
	spawn_pos.x = clampf(spawn_pos.x, -46.0, 46.0)
	spawn_pos.z = clampf(spawn_pos.z, -46.0, 46.0)
	p.global_position = spawn_pos

func start_flee(was_defeated: bool) -> void:
	is_fleeing = true
	current_state = GnomeState.PANIC_FLEE
	# Escolhe o lado mais próximo do mapa para sair
	var exit_x = 55.0 if global_position.x >= 0.0 else -55.0
	var exit_z = global_position.z + randf_range(-10.0, 10.0)
	flee_target_pos = Vector3(exit_x, 0.0, exit_z)
	
	# Restaura a música adequada
	if was_defeated or GameManager.current_period == "NIGHT":
		SoundManager.play_night_music(2.5, -5.0)
	elif GameManager.current_period == "DAY":
		SoundManager.play_day_music(2.5, -5.5)

func _despawn() -> void:
	if not is_fleeing:
		start_flee(false)
	queue_free()

func _look_towards(target_pos: Vector3, delta: float) -> void:
	var dir = (target_pos - global_position).normalized()
	dir.y = 0.0
	if dir.length_squared() > 0.01 and visual_root:
		var target_rot = atan2(dir.x, dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, 12.0 * delta)

func _animate_locomotion(delta: float) -> void:
	var speed = velocity.length()
	var t = Time.get_ticks_msec() * 0.001
	
	if sprite_25d:
		if speed > 0.5:
			sprite_25d.set_facing(velocity)
			sprite_25d.play("run", true, 14.0)
		else:
			sprite_25d.play("idle", true, 6.0)
			
	if speed > 0.5:
		# Correndo ligeiro: inclinado para frente, saco balança
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.32, delta * 12.0)
		visual_root.position.y = abs(sin(t * 22.0)) * 0.10
		
		if sack_node:
			sack_node.rotation.z = sin(t * 20.0) * 0.18
			sack_node.rotation.x = 0.25 + cos(t * 20.0) * 0.12
		if hat_node:
			hat_node.rotation.z = -sin(t * 20.0) * 0.12
	else:
		# Parado esperando: respira fundo e olha pros lados
		visual_root.rotation.x = lerp(visual_root.rotation.x, 0.0, delta * 8.0)
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 4.0)
		visual_root.scale.y = 1.0 + sin(t * 3.2) * 0.02
		
		if beard_node:
			beard_node.rotation_degrees.z = sin(t * 2.5) * 6.0
		if sack_node:
			sack_node.rotation.z = lerp(sack_node.rotation.z, 0.0, delta * 6.0)
