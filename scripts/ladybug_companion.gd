extends CharacterBody3D
class_name LadybugCompanion

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")
var sprite_25d: DirectionalSprite3D = null

# Joaninha Companheira (NPC Aliado) - Eclodida do Ovo de Joaninha
# Ajuda Pip a patrulhar o jardim, caçando ativamente e eliminando pulgões (Aphids).
# Quando não há pulgões, segue alegremente a Pip como fiel companheira.

@export var move_speed: float = 5.2
@export var attack_damage: float = 30.0
@export var attack_rate: float = 0.45 # Ataque rápido a cada 0.45s

var attack_timer: float = 0.0
var current_target: Node3D = null
var visual_root: Node3D = null
var antenna_left: Node3D = null
var antenna_right: Node3D = null
var is_hopping: bool = false

func _ready() -> void:
	add_to_group("allies")
	add_to_group("companions")
	collision_layer = 0 # Não interfere fisicamente nas colisões do player
	collision_mask = 1  # Colide apenas com o chão
	_build_visuals()

func _build_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "Visuals"
	add_child(visual_root)
	
	# 1. Carapaça Domo Vermelha com Brilho Suave
	var body = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.38
	sphere.radial_segments = 14
	sphere.rings = 8
	body.mesh = sphere
	body.position = Vector3(0, 0.20, 0)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	body_mat.albedo_color = Color(0.92, 0.18, 0.12, 1.0) # Vermelho carmim vivo
	body_mat.roughness = 0.2
	body_mat.metallic = 0.1
	body.material_override = body_mat
	visual_root.add_child(body)
	
	# Linha central divisória das asas (élitros)
	var wing_line = MeshInstance3D.new()
	var box_line = BoxMesh.new()
	box_line.size = Vector3(0.02, 0.04, 0.54)
	wing_line.mesh = box_line
	wing_line.position = Vector3(0, 0.38, 0)
	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.08, 0.08, 0.1, 1.0)
	black_mat.roughness = 0.3
	wing_line.material_override = black_mat
	visual_root.add_child(wing_line)
	
	# Pintinhas pretas clássicas da joaninha
	var spot_offsets = [
		Vector3(0.14, 0.28, 0.12),
		Vector3(-0.14, 0.28, 0.12),
		Vector3(0.18, 0.26, -0.06),
		Vector3(-0.18, 0.26, -0.06),
		Vector3(0.12, 0.28, -0.20),
		Vector3(-0.12, 0.28, -0.20)
	]
	for offset in spot_offsets:
		var spot = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.05
		sm.height = 0.04
		sm.radial_segments = 8
		sm.rings = 4
		spot.mesh = sm
		spot.material_override = black_mat
		spot.position = offset
		visual_root.add_child(spot)
		
	# 2. Cabeça preta arredondada
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.22
	head.mesh = head_mesh
	head.material_override = black_mat
	head.position = Vector3(0, 0.18, 0.28)
	visual_root.add_child(head)
	
	# Olhos fofos em desenho animado
	for eye_x in [-0.08, 0.08]:
		var eye = MeshInstance3D.new()
		var em = SphereMesh.new()
		em.radius = 0.04
		em.height = 0.04
		eye.mesh = em
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.98, 0.98, 0.98, 1.0)
		eye.material_override = eye_mat
		eye.position = Vector3(eye_x, 0.23, 0.38)
		visual_root.add_child(eye)
		
		# Pupila preta brilhante
		var pupil = MeshInstance3D.new()
		var pm = SphereMesh.new()
		pm.radius = 0.02
		pm.height = 0.02
		pupil.mesh = pm
		pupil.material_override = black_mat
		pupil.position = Vector3(eye_x, 0.235, 0.415)
		visual_root.add_child(pupil)
		
	# 3. Anteninhas simpáticas
	antenna_left = MeshInstance3D.new()
	var ant_mesh = CylinderMesh.new()
	ant_mesh.top_radius = 0.012
	ant_mesh.bottom_radius = 0.012
	ant_mesh.height = 0.14
	antenna_left.mesh = ant_mesh
	antenna_left.material_override = black_mat
	antenna_left.position = Vector3(-0.06, 0.30, 0.34)
	antenna_left.rotation_degrees = Vector3(35, -20, -15)
	visual_root.add_child(antenna_left)
	
	antenna_right = MeshInstance3D.new()
	antenna_right.mesh = ant_mesh
	antenna_right.material_override = black_mat
	antenna_right.position = Vector3(0.06, 0.30, 0.34)
	antenna_right.rotation_degrees = Vector3(35, 20, 15)
	visual_root.add_child(antenna_right)
	
	# Visual 2.5D Pixel Art Ragnarok
	var ladybug_folder = "res://textures/sprites/npcs/ladybug"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ladybug_folder)):
		sprite_25d = DirectionalSprite3D.new()
		sprite_25d.name = "Sprite25D"
		sprite_25d.sprite_offset_y = 0.40
		sprite_25d.sprite_pixel_size = 0.014
		sprite_25d.shadow_scale = Vector3(1.10, 1.10, 1.10)
		add_child(sprite_25d)
		sprite_25d.load_sprites_from_dir(ladybug_folder)
		sprite_25d.play("idle", true, 6.0)
		for m in visual_root.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).visible = false

func _physics_process(delta: float) -> void:
	attack_timer -= delta
	animate_idle(delta)
	
	current_target = find_priority_target()
	
	if current_target and is_instance_valid(current_target):
		move_and_attack_target(current_target, delta)
	else:
		follow_heroine(delta)

func animate_idle(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	
	if sprite_25d:
		if velocity.length_squared() > 0.1:
			sprite_25d.set_facing(velocity)
			sprite_25d.play("walk", true, 12.0)
		else:
			sprite_25d.play("idle", true, 6.0)
			
	if antenna_left:
		antenna_left.rotation_degrees.x = 35.0 + sin(t * 8.0) * 8.0
	if antenna_right:
		antenna_right.rotation_degrees.x = 35.0 + cos(t * 8.0) * 8.0
		
	# Pequeno balanço orgânico ao correr
	if velocity.length_squared() > 0.1 and visual_root and not is_hopping:
		visual_root.rotation.z = sin(t * 16.0) * 0.08
		visual_root.position.y = abs(sin(t * 16.0)) * 0.05
	elif visual_root and not is_hopping:
		visual_root.rotation.z = 0.0
		visual_root.position.y = sin(t * 3.0) * 0.02

func find_priority_target() -> Node3D:
	var tree = get_tree()
	if not tree:
		return null
		
	var enemies = tree.get_nodes_in_group("enemies")
	var best_aphid: Node3D = null
	var best_aphid_dist: float = 9999.0
	
	var fallback_enemy: Node3D = null
	var fallback_dist: float = 9999.0
	
	for en in enemies:
		if not is_instance_valid(en) or en.get("hp") != null and en.hp <= 0.0:
			continue
			
		var dist = global_position.distance_to(en.global_position)
		
		# 1. Prioridade máxima: Pulgões (Aphids)
		if en is Aphid or en.name.to_lower().contains("aphid") or en.name.to_lower().contains("pulgao"):
			if dist < best_aphid_dist:
				best_aphid_dist = dist
				best_aphid = en
		else:
			# 2. Outras pragas terrestres se estiverem razoavelmente próximas
			if dist < fallback_dist:
				fallback_dist = dist
				fallback_enemy = en
				
	if best_aphid:
		return best_aphid
	return fallback_enemy

func move_and_attack_target(target: Node3D, delta: float) -> void:
	var to_target = (target.global_position - global_position)
	to_target.y = 0.0
	var dist = to_target.length()
	
	if dist > 0.1:
		var dir = to_target.normalized()
		velocity = dir * move_speed
		move_and_slide()
		
		var target_rot = atan2(dir.x, dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 12.0)
		
	if dist <= 1.3:
		if attack_timer <= 0.0:
			attack_timer = attack_rate
			perform_chomp_attack(target)

func perform_chomp_attack(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
		
	# Animação de bote / mordida rápida
	if visual_root:
		var tween = create_tween()
		var dir = (target.global_position - global_position).normalized()
		tween.tween_property(visual_root, "position", dir * 0.25, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_root, "position", Vector3.ZERO, 0.08)
		
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, (target.global_position - global_position).normalized() * 1.5)
		
	# Se o pulgão morreu com este golpe, celebra com um pulinho alegre
	if target.get("hp") != null and target.hp <= 0.0:
		play_celebration_hop()

func play_celebration_hop() -> void:
	if is_hopping or not visual_root:
		return
	is_hopping = true
	var tw = create_tween()
	tw.tween_property(visual_root, "position:y", 0.32, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual_root, "position:y", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): is_hopping = false)

func follow_heroine(delta: float) -> void:
	var pip = GameManager.heroine
	if not pip or not is_instance_valid(pip):
		velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)
		move_and_slide()
		return
		
	var to_pip = (pip.global_position - global_position)
	to_pip.y = 0.0
	var dist = to_pip.length()
	
	if dist > 2.6:
		var dir = to_pip.normalized()
		velocity = dir * (move_speed * 0.85)
		move_and_slide()
		
		var target_rot = atan2(dir.x, dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 10.0)
	else:
		velocity = velocity.lerp(Vector3.ZERO, delta * 6.0)
		move_and_slide()
