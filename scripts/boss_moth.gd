extends EnemyBase
class_name BossMoth

# ==============================================================================
# CHEFE DA NOITE 1 / NOITE 2: MARIPOSA DA LUA CHEIA (QUEEN MOTH)
# ==============================================================================
# - Visual: Majestosa Mariposa Branca com asas translúcidas e antenas plumosas.
# - Combate Dinâmico:
#   * Voo Médio (2.8m): Totalmente alvejável por torres e ataques.
#   * Mergulho Rasante (1.1m): Desce para atacar defesas ou a Pip com pelos lunares.
#   * Janela de Vulnerabilidade: Permanece 1.8s ao alcance corpo-a-corpo da agulha de Pip.
#   * Relocação Dinâmica: Alterna ativamente entre diferentes torres e a Flor Central.
#   * Reação a Pip: Se Pip passar por baixo (<= 3.5m), ela mergulha imediatamente.
#   * Fase 2 (< 50% HP): Aura lunar radiante, rajadas de vento e esporos mágicos.
#   * Drop: 1 único Ovo de Joaninha no chão (y = 0.0).
# ==============================================================================

@onready var wing_left: Node3D = $Visuals/Wings/WingLeft
@onready var wing_right: Node3D = $Visuals/Wings/WingRight
@onready var antenna_left: Node3D = $Visuals/Head/AntennaLeft
@onready var antenna_right: Node3D = $Visuals/Head/AntennaRight

enum FlightPhase {
	CINEMATIC_INTRO,
	PATROL_HIGH,
	DIVE_TELEGRAPH,
	ATTACK_LOW,
	RECOVER_LINGER,
	ASCEND_RELOCATE
}

var current_phase: FlightPhase = FlightPhase.CINEMATIC_INTRO
var phase_timer: float = 0.0

const CRUISING_ALTITUDE: float = 1.95
const LOW_ALTITUDE: float = 0.90

var target_entity: Node3D = null
var recent_targets: Array[Node3D] = []
var attack_shot_done: bool = false
var is_enraged: bool = false
var patrol_duration: float = 0.0
var minion_summon_timer: float = 0.0

# Efeito visual de luz da lua acoplado à Mariposa
var moth_light: OmniLight3D = null

func _init() -> void:
	max_hp = 880.0 # Balanceado perfeitamente para o Chefe da Noite 1
	base_speed = 3.2
	attack_damage = 32.0
	attack_interval = 1.0
	xp_reward = 800
	is_flying = true

func _ready() -> void:
	super._ready()
	hp = max_hp
	current_speed = base_speed
	
	# Cria luz lunar suave conectada ao corpo da Mariposa
	moth_light = OmniLight3D.new()
	moth_light.light_color = Color(0.85, 0.92, 1.0)
	moth_light.light_energy = 2.2
	moth_light.omni_range = 7.0
	add_child(moth_light)
	
	global_position.y = CRUISING_ALTITUDE + 5.0
	GameManager.register_active_boss(self, "👑 MARIPOSA DA LUA CHEIA", max_hp)
	play_cinematic_entrance()

func play_cinematic_entrance() -> void:
	current_phase = FlightPhase.CINEMATIC_INTRO
	GameManager.is_in_cutscene = true
	GameManager.set_player_control_enabled(false)
	
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("focus_target"):
		cam.focus_target(self, 1.25, 3.5)
		
	var target_intro_pos = Vector3(global_position.x, CRUISING_ALTITUDE, global_position.z)
	
	SoundManager.play_fairy_dust(0.0)
	SoundManager.play_boss_music(1.2, -4.5)
	GameManager.notify("✨ Uma presença mágica e colossal surge sob a lua cheia...", Color(0.9, 0.95, 1.0))
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_intro_pos, 3.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		finish_cinematic_entrance()
	)
	
	# Failsafe de segurança
	var tree = get_tree()
	if tree:
		var safety = tree.create_timer(4.0)
		safety.timeout.connect(func():
			if current_phase == FlightPhase.CINEMATIC_INTRO:
				finish_cinematic_entrance()
		)

func finish_cinematic_entrance() -> void:
	if current_phase != FlightPhase.CINEMATIC_INTRO:
		return
		
	current_phase = FlightPhase.PATROL_HIGH
	phase_timer = 1.5
	GameManager.is_in_cutscene = false
	GameManager.set_player_control_enabled(true)
	
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("reset_focus"):
		cam.reset_focus(1.0, 4.5)
		
	GameManager.notify("👑 CHEFE: Mariposa da Lua Cheia desceu sobre o jardim!", Color(1.0, 0.45, 0.85))

func _physics_process(delta: float) -> void:
	if _death_handled:
		return
	animate_wings(delta)
	
	if current_phase == FlightPhase.CINEMATIC_INTRO:
		return
		
	# Processa status effects (lentidão, veneno DoT) sem depender da IA terrestre
	handle_status_effects(delta)
	
	# Verificação de Enrage (< 50% HP)
	if not is_enraged and hp < (max_hp * 0.5):
		trigger_enrage()
		
	# Invocação periódica de vaga-lumes lunares na Fase 2
	if is_enraged:
		minion_summon_timer += delta
		if minion_summon_timer >= 15.0:
			minion_summon_timer = 0.0
			var tree = get_tree()
			if tree and tree.get_nodes_in_group("enemies").size() < 6:
				spawn_lunar_minions(2)
				GameManager.notify("✨ A Mariposa Rainha invocou vaga-lumes lunares!", Color(0.85, 0.65, 1.0))
	
	match current_phase:
		FlightPhase.PATROL_HIGH:
			handle_patrol_high(delta)
		FlightPhase.DIVE_TELEGRAPH:
			handle_dive_telegraph(delta)
		FlightPhase.ATTACK_LOW:
			handle_attack_low(delta)
		FlightPhase.RECOVER_LINGER:
			handle_recover_linger(delta)
		FlightPhase.ASCEND_RELOCATE:
			handle_ascend_relocate(delta)
			
	if sprite_25d:
		if velocity.length_squared() > 0.01:
			sprite_25d.set_facing(velocity)
			sprite_25d.play("walk", true, 10.0)
		elif target_entity and is_instance_valid(target_entity):
			var to_target = target_entity.global_position - global_position
			sprite_25d.set_facing(to_target)

func animate_wings(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	var flap_multiplier = 1.4 if is_enraged else 1.0
	var flap_speed = 18.0 * flap_multiplier if (current_phase == FlightPhase.DIVE_TELEGRAPH or current_phase == FlightPhase.ATTACK_LOW) else 11.0 * flap_multiplier
	var flap = sin(t * flap_speed) * 38.0
	
	if wing_left:
		wing_left.rotation_degrees.z = flap
		wing_left.rotation_degrees.y = 15.0 + sin(t * 6.0) * 8.0
	if wing_right:
		wing_right.rotation_degrees.z = -flap
		wing_right.rotation_degrees.y = -15.0 - sin(t * 6.0) * 8.0
		
	if antenna_left:
		antenna_left.rotation_degrees.x = 22.0 + cos(t * 5.0) * 8.0
	if antenna_right:
		antenna_right.rotation_degrees.x = 22.0 + sin(t * 5.0) * 8.0
		
	if visual_root:
		visual_root.position.y = sin(t * 3.5) * 0.15

func trigger_enrage() -> void:
	is_enraged = true
	current_speed = base_speed * 1.3
	if moth_light:
		moth_light.light_color = Color(0.7, 0.85, 1.0)
		moth_light.light_energy = 3.8
		
	SoundManager.play_fairy_dust(2.0)
	GameManager.notify("🌕 FASE 2: A Mariposa canaliza a energia da Lua Cheia!", Color(0.8, 0.4, 1.0))
	execute_wind_storm()
	spawn_lunar_minions(2)

func spawn_lunar_minions(count: int = 2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var scn = load("res://scenes/enemies/firefly.tscn")
	if not scn:
		return
	for i in range(count):
		var minion = scn.instantiate()
		parent_node.add_child(minion)
		var angle = (float(i) / float(count)) * TAU
		minion.global_position = global_position + Vector3(cos(angle) * 3.2, -0.6, sin(angle) * 3.2)
		if minion.has_method("recalculate_path"):
			minion.recalculate_path()

func execute_wind_storm() -> void:
	spawn_wind_gust_fx()
	SoundManager.play_wind_dash(1.2, 0.4)
	var player = GameManager.heroine
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 6.0:
			var push_dir = (player.global_position - global_position).normalized()
			push_dir.y = 0.2
			player.velocity += push_dir * 8.5
			GameManager.notify("💨 Rajada de vento estelar da Mariposa!", Color(0.75, 0.9, 1.0))

func choose_target() -> Node3D:
	return select_best_target()

# --- SELEÇÃO DE ALVO COM RELOCAÇÃO DINÂMICA ---
func select_best_target() -> Node3D:
	var player = GameManager.heroine
	
	# 1. Se Pip estiver muito próxima (<= 3.5m), Mariposa foca nela
	if player and is_instance_valid(player):
		var dist_player = global_position.distance_to(player.global_position)
		if dist_player <= 3.5:
			return player
			
	# 2. Busca torres ativas não atacadas recentemente
	var tree = get_tree()
	if tree:
		var towers = tree.get_nodes_in_group("towers")
		var candidate_towers: Array[Node3D] = []
		for tw in towers:
			if is_instance_valid(tw) and tw.get("is_broken") != true:
				if not recent_targets.has(tw):
					candidate_towers.append(tw)
					
		# Se todas já foram atacadas no ciclo, limpa a memória
		if candidate_towers.is_empty():
			recent_targets.clear()
			for tw in towers:
				if is_instance_valid(tw) and tw.get("is_broken") != true:
					candidate_towers.append(tw)
					
		if not candidate_towers.is_empty():
			# Escolhe a mais próxima das elegíveis
			var closest: Node3D = null
			var closest_d = 9999.0
			for tw in candidate_towers:
				var d = global_position.distance_to(tw.global_position)
				if d < closest_d:
					closest_d = d
					closest = tw
			return closest
			
	# 3. Flor Central como objetivo
	if target_flower and is_instance_valid(target_flower):
		return target_flower
	elif GameManager.flower and is_instance_valid(GameManager.flower):
		return GameManager.flower
		
	return player

# --- ESTADOS DE VOO E COMBATE ---

func handle_patrol_high(delta: float) -> void:
	patrol_duration += delta
	# Mantém altitude de sobrevoo suave
	global_position.y = move_toward(global_position.y, CRUISING_ALTITUDE, delta * 3.5)
	
	# Reação instantânea: Se Pip passar por baixo, mergulha na Pip
	var player = GameManager.heroine
	if player and is_instance_valid(player):
		var flat_dist = Vector2(global_position.x - player.global_position.x, global_position.z - player.global_position.z).length()
		if flat_dist <= 4.2:
			target_entity = player
			patrol_duration = 0.0
			start_dive_telegraph()
			return
			
	# Atualiza alvo se necessário
	if not target_entity or not is_instance_valid(target_entity) or (target_entity.has_method("get") and target_entity.get("is_broken") == true):
		target_entity = select_best_target()
		
	if target_entity and is_instance_valid(target_entity):
		var target_pos = target_entity.global_position
		target_pos.y = CRUISING_ALTITUDE
		
		var to_target = (target_pos - global_position)
		var dist_flat = Vector2(to_target.x, to_target.z).length()
		
		# Navega em direção ao alvo
		velocity = to_target.normalized() * current_speed
		move_and_slide()
		look_at_horizontal(target_entity.global_position, delta)
		
		# Inicia telegrafia de mergulho ao se aproximar a <= 5.2m ou se patrulhar por mais de 2.5s
		if dist_flat <= 5.2 or patrol_duration >= 2.5:
			patrol_duration = 0.0
			start_dive_telegraph()
	else:
		if patrol_duration >= 2.0:
			patrol_duration = 0.0
			target_entity = select_best_target()
			start_dive_telegraph()
		else:
			velocity = velocity.lerp(Vector3.ZERO, delta * 2.0)
			move_and_slide()

func start_dive_telegraph() -> void:
	current_phase = FlightPhase.DIVE_TELEGRAPH
	phase_timer = 0.75 if is_enraged else 0.95
	SoundManager.play_fairy_dust(-2.0)

func handle_dive_telegraph(delta: float) -> void:
	phase_timer -= delta
	
	# Mergulho suave e rápido para a altitude baixa de ataque
	global_position.y = move_toward(global_position.y, LOW_ALTITUDE, delta * 5.5)
	
	if target_entity and is_instance_valid(target_entity):
		look_at_horizontal(target_entity.global_position, delta)
		var to_target = (target_entity.global_position - global_position)
		to_target.y = 0.0
		if to_target.length() > 2.8:
			velocity = to_target.normalized() * (current_speed * 1.1)
			move_and_slide()
	
	if phase_timer <= 0.0 or global_position.y <= LOW_ALTITUDE + 0.1:
		global_position.y = LOW_ALTITUDE
		current_phase = FlightPhase.ATTACK_LOW
		phase_timer = 0.2
		attack_shot_done = false

func handle_attack_low(delta: float) -> void:
	global_position.y = LOW_ALTITUDE
	phase_timer -= delta
	
	if target_entity and is_instance_valid(target_entity):
		look_at_horizontal(target_entity.global_position, delta)
		
	# Desacelera para disparar
	velocity = velocity.lerp(Vector3.ZERO, delta * 6.0)
	move_and_slide()
	
	if phase_timer <= 0.0 and not attack_shot_done:
		attack_shot_done = true
		if target_entity and is_instance_valid(target_entity):
			fire_lunar_barrage(target_entity)
			recent_targets.append(target_entity)
			
		# Inicia janela de vulnerabilidade (1.8 segundos em baixo para o jogador golpear!)
		current_phase = FlightPhase.RECOVER_LINGER
		phase_timer = 1.8

func handle_recover_linger(delta: float) -> void:
	global_position.y = LOW_ALTITUDE
	phase_timer -= delta
	
	# Flutuação leve enquanto fica vulnerável no solo
	velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)
	move_and_slide()
	
	if phase_timer <= 0.0:
		start_ascend_relocate()

func start_ascend_relocate() -> void:
	current_phase = FlightPhase.ASCEND_RELOCATE
	phase_timer = 1.1
	SoundManager.play_fairy_dust(-3.0)
	
	# Rajada de vento ao bater asas para subir
	spawn_wind_gust_fx()

func handle_ascend_relocate(delta: float) -> void:
	phase_timer -= delta
	global_position.y = move_toward(global_position.y, CRUISING_ALTITUDE, delta * 4.5)
	
	# Recuo tático em arco para reposicionar
	var backward = -global_transform.basis.z.normalized()
	backward.y = 0.0
	velocity = backward * (current_speed * 0.9)
	move_and_slide()
	
	if phase_timer <= 0.0 or global_position.y >= CRUISING_ALTITUDE - 0.1:
		global_position.y = CRUISING_ALTITUDE
		current_phase = FlightPhase.PATROL_HIGH
		# Escolhe o PRÓXIMO alvo diferente
		target_entity = select_best_target()

func look_at_horizontal(target_pos: Vector3, delta: float) -> void:
	var look_dir = (target_pos - global_position).normalized()
	look_dir.y = 0.0
	if look_dir.length_squared() > 0.01:
		var target_rot = atan2(look_dir.x, look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 7.0)

# --- ATAQUES & DISPAROS ---

func fire_lunar_barrage(target: Node3D) -> void:
	if not target or not is_instance_valid(target):
		return
		
	SoundManager.play_fairy_dust(-4.0)
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var target_base_pos = target.global_position + Vector3(0, 0.35, 0)
	var shoot_origin = global_position + Vector3(0, 0.1, 0.5)
	
	# Quantidade de projéteis (5 normais, 8 no leque de Enrage)
	var count = 8 if is_enraged else 5
	for i in range(count):
		var spread_angle = (i - (count - 1) * 0.5) * 0.22
		var base_dir = (target_base_pos - shoot_origin).normalized()
		var dir = base_dir.rotated(Vector3.UP, spread_angle)
		spawn_lunar_bristle(parent_node, shoot_origin, dir)
		
	if is_enraged:
		execute_wind_storm()

func spawn_lunar_bristle(parent_node: Node, origin: Vector3, dir: Vector3) -> void:
	var bristle = Area3D.new()
	bristle.collision_layer = 0
	bristle.collision_mask = 7 # Pip, Torres e Terreno
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.14
	cyl.height = 0.7
	col.shape = cyl
	bristle.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.08
	mesh.height = 0.7
	mesh_inst.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.albedo_color = Color(0.96, 0.98, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.9, 1.0, 1.0)
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	mesh_inst.rotation_degrees.x = 90.0
	bristle.add_child(mesh_inst)
	
	parent_node.add_child(bristle)
	bristle.global_position = origin
	
	var speed = 11.5
	var life_timer = 2.5
	var is_hit = false
	
	bristle.body_entered.connect(func(body: Node3D):
		if is_hit or body == self or body.is_in_group("enemies"):
			return
		is_hit = true
		if body.is_in_group("player"):
			GameManager.damage_pip(35.0)
			GameManager.notify("⚠️ Atingido pelos pelos mágicos da Mariposa!", Color(1.0, 0.5, 0.3))
		elif body.has_method("take_damage"):
			body.take_damage(38.0)
		bristle.queue_free()
	)
	
	var tween = create_tween()
	tween.tween_property(bristle, "global_position", origin + dir * (speed * life_timer), life_timer)
	tween.tween_callback(bristle.queue_free)

func spawn_wind_gust_fx() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var puff = Node3D.new()
	parent_node.add_child(puff)
	puff.global_position = global_position + Vector3(0, -0.4, 0)
	
	for i in range(6):
		var particle = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.08
		mesh.height = 0.16
		particle.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.95, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.9, 1.0)
		mat.emission_energy_multiplier = 1.5
		particle.material_override = mat
		puff.add_child(particle)
		
		var angle = (i / 6.0) * TAU
		var offset = Vector3(cos(angle) * 1.8, -0.2, sin(angle) * 1.8)
		var tw = particle.create_tween()
		tw.tween_property(particle, "position", offset, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(particle, "scale", Vector3.ZERO, 0.45)
		
	var timer = puff.get_tree().create_timer(0.5)
	timer.timeout.connect(puff.queue_free)

# --- RECEBIMENTO DE DANO & FEEDBACK ---
var _death_handled: bool = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, armor_pierce: float = 0.0) -> void:
	if current_phase == FlightPhase.CINEMATIC_INTRO or _death_handled:
		return
		
	# Som e faíscas de impacto
	SoundManager.play_sparkle(0.5, 0.2)
	super.take_damage(amount, Vector3.ZERO, is_dot, armor_pierce)
	GameManager.update_active_boss_hp(hp, max_hp, "👑 MARIPOSA DA LUA CHEIA")

func die() -> void:
	if _death_handled:
		return
	_death_handled = true
	is_dead = true
	velocity = Vector3.ZERO
	GameManager.unregister_active_boss(self)
	
	SoundManager.play_day_music(2.5, -6.0)
	GameManager.notify("🏆 MARIPOSA DA LUA CHEIA DERROTADA!", Color(0.9, 0.6, 1.0))
	
	var tree = get_tree()
	if tree:
		var existing_eggs = tree.get_nodes_in_group("ladybug_eggs")
		var existing_comps = tree.get_nodes_in_group("companions")
		if existing_eggs.is_empty() and existing_comps.is_empty():
			var parent_node = get_parent()
			if parent_node:
				var egg_script = load("res://scripts/ladybug_egg.gd")
				if egg_script:
					var egg = egg_script.new()
					parent_node.add_child(egg)
					# Drop no chão (y = 0.0)
					egg.global_position = Vector3(global_position.x, 0.0, global_position.z)
			
	if visual_root:
		var tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			super.die()
			GameManager.on_moth_boss_defeated()
		)
	else:
		super.die()
		GameManager.on_moth_boss_defeated()
