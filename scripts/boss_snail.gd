extends EnemyBase
class_name BossSnail

# Chefe do Amanhecer: Caramujo Ancião das Folhas
# Carapaça resistente com detalhes coloridos, olhos vesiculares nas pontas dos tentáculos,
# rastro brilhante de gosma que causa 5s de lentidão, ataque frontal no jogador e esmagamento de torres.

@onready var eyestalk_left: Node3D = $Visuals/Head/EyestalkLeft
@onready var eyestalk_right: Node3D = $Visuals/Head/EyestalkRight
@onready var foot_mesh: MeshInstance3D = $Visuals/BodyFoot
@onready var shell_root: Node3D = $Visuals/Shell

var slime_spawn_timer: float = 0.0
const SLIME_INTERVAL: float = 0.28
var last_slime_pos: Vector3 = Vector3.ZERO

var player_slam_cd: float = 0.0
var target_tower_in_front: Node3D = null
var is_slamming: bool = false

func _init() -> void:
	max_hp = 480.0 # Balanceado perfeitamente para o 1º Chefe (Dia 1)
	base_speed = 0.80
	attack_damage = 25.0
	attack_interval = 1.4
	xp_reward = 350
	is_flying = false

func _ready() -> void:
	super._ready()
	global_position.y = 0.0
	last_slime_pos = global_position
	# Não colide rigidamente com o player para evitar travamento em dash
	collision_mask = 1
	
	# Registra o chefe no GameManager para exibir a barra de vida régia no topo do HUD
	GameManager.register_active_boss(self, "🐌 CARAMUJO ANCIÃO DO ORVALHO", max_hp)
	
	# Inicia a trilha sonora de Batalha de Chefe
	SoundManager.play_boss_music(1.5, -4.5)
		
	GameManager.notify("⚠️ CHEFE: Caramujo Ancião do Orvalho apareceu!", Color(1.0, 0.4, 0.2))

func _physics_process(delta: float) -> void:
	if _death_handled:
		return
	super(delta)
	
	if player_slam_cd > 0.0:
		player_slam_cd -= delta
		
	# 1. Animação de locomoção fluida de molusco e tentáculos com olhos
	animate_snail(delta)
	
	# 2. Deixar rastro brilhante de gosma no chão
	handle_slime_trail(delta)
	
	# 3. Checagem de ataque frontal caso o jogador passe na frente
	check_player_in_front(delta)
	
	# 4. Checagem de torres no caminho à frente
	check_towers_in_path(delta)

func animate_snail(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	
	# Ondulação suave do corpo no solo
	if foot_mesh and velocity.length_squared() > 0.02:
		var wave = sin(t * 5.0)
		foot_mesh.scale.z = 1.0 + wave * 0.08
		foot_mesh.scale.x = 1.0 - wave * 0.05
		
	# Tentáculos superiores com olhos vesiculares se movem suavemente observando o jardim
	if eyestalk_left:
		eyestalk_left.rotation_degrees.x = 15.0 + sin(t * 3.5) * 12.0
		eyestalk_left.rotation_degrees.y = -8.0 + cos(t * 2.8) * 10.0
		eyestalk_left.rotation_degrees.z = sin(t * 2.2) * 8.0
		
	if eyestalk_right:
		eyestalk_right.rotation_degrees.x = 15.0 + cos(t * 3.2) * 12.0
		eyestalk_right.rotation_degrees.y = 8.0 - sin(t * 2.6) * 10.0
		eyestalk_right.rotation_degrees.z = -cos(t * 2.0) * 8.0
		
	# Concha balança com o peso da caminhada
	if shell_root:
		shell_root.rotation_degrees.z = sin(t * 2.5) * 3.0

func handle_slime_trail(delta: float) -> void:
	slime_spawn_timer -= delta
	if slime_spawn_timer <= 0.0 or global_position.distance_squared_to(last_slime_pos) > 0.65:
		slime_spawn_timer = SLIME_INTERVAL
		last_slime_pos = global_position
		spawn_slime_patch()

func spawn_slime_patch() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var patch = Area3D.new()
	patch.name = "SlimePuddle"
	patch.collision_layer = 0
	patch.collision_mask = 2 # Detecta Player (Camada 2)
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.15
	cyl.height = 0.4
	col.shape = cyl
	col.position.y = 0.15
	patch.add_child(col)
	
	# Visual brilhante perolado/esmeralda da gosma
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.05
	disc.bottom_radius = 1.15
	disc.height = 0.03
	mesh_inst.mesh = disc
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 0.95, 0.55, 0.62)
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.85, 0.45, 1.0)
	mat.emission_energy_multiplier = 0.75
	mesh_inst.material_override = mat
	mesh_inst.position.y = 0.02
	patch.add_child(mesh_inst)
	
	parent_node.add_child(patch)
	patch.global_position = global_position - Vector3(0, 0, 0)
	
	# Conecta colisão com o jogador para aplicar 2.5s de lentidão
	patch.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player") and body.has_method("apply_slime_slow"):
			body.apply_slime_slow(2.5)
	)
	
	# Checa se o player já está em cima no momento do spawn
	if GameManager.heroine and is_instance_valid(GameManager.heroine):
		if patch.global_position.distance_to(GameManager.heroine.global_position) < 1.1:
			GameManager.heroine.apply_slime_slow(2.5)
			
	# Desaparece suavemente após 12 segundos
	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		tween.tween_interval(10.0)
		tween.tween_property(mat, "albedo_color:a", 0.0, 2.0)
		tween.tween_callback(patch.queue_free)

var _death_handled: bool = false
var is_enraged: bool = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, armor_pierce: float = 0.0) -> void:
	if _death_handled:
		return
	super.take_damage(amount, knockback, is_dot, armor_pierce)
	GameManager.update_active_boss_hp(hp, max_hp, "🐌 CARAMUJO ANCIÃO DO ORVALHO")
	
	if not is_enraged and hp <= (max_hp * 0.5):
		trigger_enrage()

func trigger_enrage() -> void:
	is_enraged = true
	base_speed = 1.10
	current_speed = 1.10
	attack_interval = 1.0
	attack_damage = 32.0
	
	SoundManager.play_sparkle(1.2, 0.4)
	SoundManager.play_fairy_dust(0.0)
	GameManager.notify("⚠️ O Caramujo Ancião enfureceu-se! Sua concha reluz e seu rastro é mais perigoso!", Color(1.0, 0.5, 0.2))
	
	# Onda de choque de gosma ao redor
	var parent_node = get_parent()
	if parent_node:
		for i in range(8):
			var angle = (float(i) / 8.0) * TAU
			var offset = Vector3(cos(angle) * 2.8, 0.0, sin(angle) * 2.8)
			var patch_pos = global_position + offset
			spawn_extra_slime(parent_node, patch_pos)

func spawn_extra_slime(parent_node: Node, at_pos: Vector3) -> void:
	var patch = Area3D.new()
	patch.name = "SlimePuddleBurst"
	patch.collision_layer = 0
	patch.collision_mask = 2
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.0
	cyl.height = 0.3
	col.shape = cyl
	col.position.y = 0.15
	patch.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 0.9
	disc.bottom_radius = 1.0
	disc.height = 0.03
	mesh_inst.mesh = disc
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.4, 0.95, 0.6, 0.65)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.5, 1.0)
	mesh_inst.material_override = mat
	patch.add_child(mesh_inst)
	
	parent_node.add_child(patch)
	patch.global_position = at_pos
	
	patch.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player") and body.has_method("apply_slime_slow"):
			body.apply_slime_slow(2.5)
	)
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_interval(8.0)
		tw.tween_property(mat, "albedo_color:a", 0.0, 1.5)
		tw.tween_callback(patch.queue_free)

func check_player_in_front(delta: float) -> void:
	if player_slam_cd > 0.0 or is_slamming:
		return
		
	var player = GameManager.heroine
	if not player or not is_instance_valid(player):
		return
		
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	if dist <= 3.2:
		# Checa se está à frente (ângulo frontal)
		var forward = -global_transform.basis.z.normalized()
		var dot = forward.dot(to_player.normalized())
		if dot > 0.45: # Está na frente do caramujo!
			execute_frontal_slam(player)

func execute_frontal_slam(player: Node3D) -> void:
	is_slamming = true
	player_slam_cd = 2.4 if is_enraged else 3.0
	
	# Telégrafo de preparação (0.45s) com brilho nos olhos e aviso sonoro
	SoundManager.play_sparkle(-1.5, 0.2)
	
	var telegraph_marker = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 1.2
	ring.outer_radius = 1.8
	telegraph_marker.mesh = ring
	var t_mat = StandardMaterial3D.new()
	t_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	t_mat.albedo_color = Color(1.0, 0.3, 0.2, 0.5)
	telegraph_marker.material_override = t_mat
	add_child(telegraph_marker)
	telegraph_marker.position = Vector3(0.0, 0.05, -1.8)
	
	var tw_telegraph = create_tween()
	tw_telegraph.tween_property(t_mat, "albedo_color:a", 0.85, 0.4)
	tw_telegraph.tween_callback(telegraph_marker.queue_free)
	
	# Recuo e investida pesada para frente
	var tween = create_tween()
	tween.tween_property(visual_root, "position:z", 0.55, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "position:z", -0.95, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if player and is_instance_valid(player):
			var cur_dist = global_position.distance_to(player.global_position)
			if cur_dist <= 3.8:
				var dmg = 20.0 if is_enraged else 15.0
				GameManager.damage_pip(dmg)
				if player.has_method("apply_slime_slow"):
					player.apply_slime_slow(2.5)
				# Knockback
				var push_dir = (player.global_position - global_position).normalized()
				player.velocity = push_dir * 11.0 + Vector3.UP * 3.5
				GameManager.notify("💥 O Caramujo Ancião desferiu uma cabeçada!", Color(1.0, 0.4, 0.3))
	)
	tween.tween_property(visual_root, "position:z", 0.0, 0.40)
	tween.tween_callback(func():
		is_slamming = false
	)

func check_towers_in_path(delta: float) -> void:
	# Procura torres à sua frente para destruir
	var towers = get_tree().get_nodes_in_group("towers")
	var nearest_tower: Node3D = null
	var closest_d = 2.4
	
	for tow in towers:
		if is_instance_valid(tow) and not tow.is_broken:
			var d = global_position.distance_to(tow.global_position)
			if d < closest_d:
				closest_d = d
				nearest_tower = tow
				
	if nearest_tower:
		# Para e ataca a torre à frente
		velocity = Vector3.ZERO
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			smash_tower(nearest_tower)
	else:
		target_tower_in_front = null

func smash_tower(tower: Node3D) -> void:
	if not tower or not is_instance_valid(tower):
		return
	var tween = create_tween()
	tween.tween_property(visual_root, "position:y", 0.4, 0.15)
	tween.tween_property(visual_root, "position:y", 0.0, 0.10)
	tween.tween_callback(func():
		if tower and is_instance_valid(tower) and tower.has_method("take_damage"):
			tower.take_damage(attack_damage)
			GameManager.notify("⚠️ O Caramujo esmagou uma torre no caminho!", Color(1.0, 0.5, 0.2))
	)

func spawn_local_boss_loot() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var pickup_scn = pickup_scene
	if not pickup_scn and ResourceLoader.exists("res://scenes/pickup.tscn"):
		pickup_scn = load("res://scenes/pickup.tscn")
	if not pickup_scn:
		return
		
	# Drop exclusivo de 1 Lágrima de Fada (sem nenhum item a mais)
	var pickup = pickup_scn.instantiate()
	pickup.item_type = "FAIRY_TEAR"
	parent_node.add_child(pickup)
	pickup.global_position = Vector3(global_position.x, 0.25, global_position.z)

func die() -> void:
	if _death_handled:
		return
	_death_handled = true
	is_dead = true
	
	# Desativa colisão física imediatamente para que Pip não colida nem fique presa
	collision_layer = 0
	collision_mask = 0
	var col = find_child("CollisionShape3D", true, false)
	if col and col is CollisionShape3D:
		col.disabled = true
		
	velocity = Vector3.ZERO
	GameManager.unregister_active_boss(self)
	
	# Vitória sobre o Chefe!
	GameManager.notify("🏆 CARAMUJO ANCIÃO DERROTADO! Ele deixou cair uma Lágrima de Fada!", Color(0.3, 1.0, 0.5))
	
	# Drop concentrado apenas próximo ao corpo do chefe (Lágrima de Fada exclusiva)
	spawn_local_boss_loot()
	
	# Efeito de retração triunfante para dentro da concha
	if visual_root:
		var tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector3(0.05, 0.05, 0.05), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			GameManager.on_boss_defeated("SNAIL")
			if GameEvents:
				GameEvents.enemy_defeated.emit(self, xp_reward)
			GameManager.add_xp(xp_reward)
			GameManager.register_enemy_killed(self)
			queue_free()
		)
	else:
		GameManager.on_boss_defeated("SNAIL")
		if GameEvents:
			GameEvents.enemy_defeated.emit(self, xp_reward)
		GameManager.add_xp(xp_reward)
		GameManager.register_enemy_killed(self)
		queue_free()
