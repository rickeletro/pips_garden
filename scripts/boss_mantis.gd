extends EnemyBase
class_name BossMantis

# Chefe do Dia 2: Louva-a-Deus Imperial (The Blade Mantis)
# Visual: Inseto esbelto verde-esmeralda com pernas articuladas, cabeça triangular, olhos compostos e braços em foice serrilhada.
# Comportamento: Anda devagar em qualquer direção, prepara um bote telegrafado e desfere um Dash super veloz em linha reta.
# Recompensa: Âmbar Magnético (Ímã de itens permanente de 6.0 metros).

@onready var arm_left: Node3D = $Visuals/Thorax/ArmLeft
@onready var arm_right: Node3D = $Visuals/Thorax/ArmRight
@onready var head_node: Node3D = $Visuals/Head
@onready var scythe_blade_l: MeshInstance3D = $Visuals/Thorax/ArmLeft/BladeL
@onready var scythe_blade_r: MeshInstance3D = $Visuals/Thorax/ArmRight/BladeR

@onready var leg_mid_l: Node3D = $Visuals/Legs/LegMidL
@onready var leg_mid_r: Node3D = $Visuals/Legs/LegMidR
@onready var leg_hind_l: Node3D = $Visuals/Legs/LegHindL
@onready var leg_hind_r: Node3D = $Visuals/Legs/LegHindR

enum MantisState {
	WALKING_CHASE,
	LUNGE_TELEGRAPH,
	DASH_LUNGING,
	SLASHING_TOWER,
	RECOVERING
}

var mantis_state: MantisState = MantisState.WALKING_CHASE
var state_timer: float = 0.0
var lunge_target_pos: Vector3 = Vector3.ZERO
var lunge_dir: Vector3 = Vector3.FORWARD
var lunge_speed: float = 18.0
var disarm_cd: float = 0.0
var lunge_cd: float = 3.5

func _init() -> void:
	max_hp = 1400.0 # Balanceado perfeitamente para o Chefe do Dia 2
	base_speed = 2.2 # Anda devagar de forma calculada e imponente
	attack_damage = 40.0
	attack_interval = 1.0
	xp_reward = 500
	is_flying = false

func _ready() -> void:
	super._ready()
	global_position.y = 0.0
	GameManager.register_active_boss(self, "🪲 LOUVA-A-DEUS IMPERIAL", max_hp)
	SoundManager.play_boss_music(1.2, -4.5)
	GameManager.notify("🪲 CHEFE: Louva-a-Deus Imperial emboscou o jardim!", Color(0.3, 1.0, 0.5))

func _physics_process(delta: float) -> void:
	super(delta)
	animate_mantis(delta)
	
	if disarm_cd > 0.0: disarm_cd -= delta
	if lunge_cd > 0.0: lunge_cd -= delta
	
	match mantis_state:
		MantisState.WALKING_CHASE:
			handle_walking_chase(delta)
		MantisState.LUNGE_TELEGRAPH:
			handle_lunge_telegraph(delta)
		MantisState.DASH_LUNGING:
			handle_dash_lunging(delta)
		MantisState.SLASHING_TOWER:
			handle_slashing(delta)
		MantisState.RECOVERING:
			handle_recovering(delta)

func animate_mantis(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	
	# Foices em postura de guarda / agitação
	if arm_left:
		arm_left.rotation_degrees.x = -25.0 + sin(t * 8.0) * 12.0
		arm_left.rotation_degrees.z = 10.0 + cos(t * 6.0) * 6.0
	if arm_right:
		arm_right.rotation_degrees.x = -25.0 - sin(t * 8.0) * 12.0
		arm_right.rotation_degrees.z = -10.0 - cos(t * 6.0) * 6.0
		
	# Cabeça triangular rastreando alvos
	if head_node:
		head_node.rotation_degrees.y = sin(t * 3.5) * 15.0
		
	# Animação de caminhada com as 4 pernas
	var is_moving = velocity.length_squared() > 0.1
	var walk_speed = 10.0 if mantis_state == MantisState.WALKING_CHASE else 25.0
	var leg_swing = sin(t * walk_speed) * 22.0 if is_moving else 0.0
	
	if leg_mid_l: leg_mid_l.rotation_degrees.z = leg_swing
	if leg_mid_r: leg_mid_r.rotation_degrees.z = -leg_swing
	if leg_hind_l: leg_hind_l.rotation_degrees.z = -leg_swing
	if leg_hind_r: leg_hind_r.rotation_degrees.z = leg_swing

func handle_walking_chase(delta: float) -> void:
	# Checa se Pip está próxima para desferir o bote rápido
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip) and lunge_cd <= 0.0:
		var dist_pip = global_position.distance_to(pip.global_position)
		if dist_pip < 8.0:
			start_lunge_telegraph(pip.global_position)
			return
			
	# Caminha devagar em qualquer direção rumo às defesas ou Flor
	var target_node = find_target_defense()
	if target_node and is_instance_valid(target_node):
		var target_pos = target_node.global_position
		target_pos.y = 0.0
		var to_target = (target_pos - global_position)
		to_target.y = 0.0
		var dist = to_target.length()
		
		if dist > 1.6:
			var dir = to_target.normalized()
			velocity = dir * current_speed
			move_and_slide()
			
			if visual_root:
				var target_rot = atan2(dir.x, dir.z)
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 8.0)
		else:
			# Alcance de corte
			start_slash_tower(target_node)
	else:
		velocity = velocity.lerp(Vector3.ZERO, delta * 4.0)
		move_and_slide()

func find_target_defense() -> Node3D:
	var towers = get_tree().get_nodes_in_group("towers")
	var nearest_t: Node3D = null
	var min_d = 9999.0
	for tw in towers:
		if is_instance_valid(tw) and tw.get("is_broken") != true:
			var d = global_position.distance_to(tw.global_position)
			if d < min_d:
				min_d = d
				nearest_t = tw
	if nearest_t:
		return nearest_t
	if target_flower and is_instance_valid(target_flower):
		return target_flower
	return null

func start_lunge_telegraph(target_pos: Vector3) -> void:
	mantis_state = MantisState.LUNGE_TELEGRAPH
	state_timer = 1.1 # 1.1s de preparação visível
	lunge_target_pos = target_pos
	lunge_dir = (target_pos - global_position).normalized()
	lunge_dir.y = 0.0
	velocity = Vector3.ZERO
	SoundManager.play_sparkle(-3.0, 0.4)
	GameManager.notify("⚠️ O Louva-a-Deus se agachou para o bote! Prepare o Dash!", Tokens.RUIVO_COBRE)
	
	if visual_root:
		var target_rot = atan2(lunge_dir.x, lunge_dir.z)
		visual_root.rotation.y = target_rot
		var tw = create_tween()
		tw.tween_property(visual_root, "position:y", -0.22, 0.35) # Agacha para impulso
		tw.tween_property(visual_root, "position:y", -0.18, 0.75)

func handle_lunge_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity = Vector3.ZERO
	
	# Vibração rápida das foices durante a preparação
	if scythe_blade_l and scythe_blade_r:
		var shake = sin(Time.get_ticks_msec() * 0.05) * 0.08
		scythe_blade_l.position.x = 0.18 + shake
		scythe_blade_r.position.x = -0.18 - shake
		
	if state_timer <= 0.0:
		start_dash_lunge()

func start_dash_lunge() -> void:
	mantis_state = MantisState.DASH_LUNGING
	state_timer = 0.40 # 0.40s de dash ultra-rápido
	velocity = lunge_dir * lunge_speed
	SoundManager.play_sparkle(1.5, 0.2)
	
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "position:y", 0.1, 0.1)

func handle_dash_lunging(delta: float) -> void:
	state_timer -= delta
	velocity = lunge_dir * lunge_speed
	move_and_slide()
	
	# Checa colisão com Pip durante o dash
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip):
		var dist = global_position.distance_to(pip.global_position)
		if dist < 1.6 and not pip.get("is_invulnerable"):
			GameManager.damage_pip(attack_damage)
			GameManager.notify("⚠️ Atingido em cheio pelo corte do Louva-a-Deus!", Tokens.PERIGO)
			start_recovery()
			return
			
	if state_timer <= 0.0:
		start_recovery()

func start_slash_tower(tower_node: Node3D) -> void:
	mantis_state = MantisState.SLASHING_TOWER
	state_timer = 0.6
	velocity = Vector3.ZERO
	
	if visual_root:
		var dir = (tower_node.global_position - global_position).normalized()
		visual_root.rotation.y = atan2(dir.x, dir.z)
		
	if arm_left and arm_right:
		var tw = create_tween()
		tw.tween_property(arm_left, "rotation_degrees:x", 45.0, 0.2)
		tw.parallel().tween_property(arm_right, "rotation_degrees:x", 45.0, 0.2)
		tw.tween_callback(func():
			if is_instance_valid(tower_node) and tower_node.has_method("take_damage"):
				tower_node.take_damage(attack_damage * 1.5)
				SoundManager.play_sparkle(-5.0, 0.4)
		)

func handle_slashing(delta: float) -> void:
	state_timer -= delta
	velocity = Vector3.ZERO
	if state_timer <= 0.0:
		start_recovery()

func start_recovery() -> void:
	mantis_state = MantisState.RECOVERING
	state_timer = 0.8
	lunge_cd = 4.0
	velocity = Vector3.ZERO
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "position:y", 0.0, 0.3)

func handle_recovering(delta: float) -> void:
	state_timer -= delta
	velocity = Vector3.ZERO
	if state_timer <= 0.0:
		mantis_state = MantisState.WALKING_CHASE

func die() -> void:
	GameManager.notify("🏆 LOUVA-A-DEUS IMPERIAL DERROTADO!", Tokens.DOURADO_LUZ)
	
	# Drop exclusivo do Âmbar Magnético
	var parent_node = get_parent()
	if parent_node:
		var pickup_scene = load("res://scenes/pickup.tscn")
		if pickup_scene:
			var amber = pickup_scene.instantiate()
			amber.item_type = "MAGNET_AMBER"
			parent_node.add_child(amber)
			amber.global_position = Vector3(global_position.x, 0.25, global_position.z)
			
	if visual_root:
		var tween = create_tween()
		tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			super.die()
			GameManager.on_boss_defeated("MANTIS")
		)
	else:
		super.die()
		GameManager.on_boss_defeated("MANTIS")
