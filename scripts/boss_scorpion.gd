extends EnemyBase
class_name BossScorpion

# Chefe Final da Noite 3: Tirano Noturno - O Escorpião Luminescente
# Visual: Carapaça roxa-escura com marcas rúnicas azuis luminescentes pulsando, 8 pernas articuladas e ferrão colossal.
# Mecânica de Duelo de Precisão:
# - Persegue exclusivamente a Pip (5.2 m/s) com animação rastejante de 8 pernas.
# - 100% imune a ataques no corpo (carapaça blindada reflete a agulha).
# - Telegrafa golpe de ferrão por 1.0s (brilho azul vira branco).
# - Ao cravar o ferrão no solo, fica VULNERÁVEL por 3.0 segundos no ponto fraco da cauda!
# - Cinemática lenta e dramática de sacrifício da Joaninha e cinemática final estelar de vitória.

@onready var claw_left: Node3D = $Visuals/ClawL
@onready var claw_right: Node3D = $Visuals/ClawR
@onready var tail_root: Node3D = $Visuals/Tail
@onready var tail_stinger: Node3D = $Visuals/Tail/StingerJoint/Stinger
@onready var stinger_joint: Node3D = $Visuals/Tail/StingerJoint
@onready var weakpoint_marker: MeshInstance3D = $Visuals/Tail/StingerJoint/WeakpointMarker
@onready var runes_light: OmniLight3D = $Visuals/RunesLight

@onready var leg_l1: Node3D = $Visuals/Legs/LegL1
@onready var leg_l2: Node3D = $Visuals/Legs/LegL2
@onready var leg_l3: Node3D = $Visuals/Legs/LegL3
@onready var leg_l4: Node3D = $Visuals/Legs/LegL4
@onready var leg_r1: Node3D = $Visuals/Legs/LegR1
@onready var leg_r2: Node3D = $Visuals/Legs/LegR2
@onready var leg_r3: Node3D = $Visuals/Legs/LegR3
@onready var leg_r4: Node3D = $Visuals/Legs/LegR4

enum ScorpionState {
	INTRO_CUTSCENE,
	CHASE,
	TELEGRAPH,
	STRIKE_STUCK,
	RECOVER,
	VICTORY_CUTSCENE
}

var current_state: ScorpionState = ScorpionState.INTRO_CUTSCENE
var state_timer: float = 0.0
var is_stinger_vulnerable: bool = false
var sacrifice_ladybug: Node3D = null

func _init() -> void:
	max_hp = 3400.0 # Balanceado perfeitamente para o Chefe Final da Campanha (Noite 3)
	base_speed = 5.2
	attack_damage = 50.0
	attack_interval = 1.0
	xp_reward = 1000
	is_flying = false

func _ready() -> void:
	super._ready()
	global_position.y = 0.0
	GameManager.register_active_boss(self, "🦂 TIRANO NOTURNO (ESCORPIÃO)", max_hp)
	if weakpoint_marker:
		weakpoint_marker.visible = false
	start_intro_cinematic()

func start_intro_cinematic() -> void:
	current_state = ScorpionState.INTRO_CUTSCENE
	GameManager.is_in_cutscene = true
	GameManager.set_player_control_enabled(false)
	
	# Transição de Câmera lenta e cinematográfica para o Escorpião
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("focus_target"):
		cam.focus_target(self, 0.95, 2.5)
		
	SoundManager.play_boss_music(1.0, -3.0)
	GameManager.notify("🌑 Um estrondo abala a terra... O Tirano Noturno emergiu!", Color(0.7, 0.4, 1.0))
	
	var tree = get_tree()
	if not tree:
		return
		
	# Encontra ou instancia a Joaninha companheira para a cena
	var companions = tree.get_nodes_in_group("companions")
	if not companions.is_empty():
		sacrifice_ladybug = companions[0]
	else:
		var comp_scn = load("res://scripts/ladybug_companion.gd")
		if comp_scn:
			sacrifice_ladybug = comp_scn.new()
			get_parent().add_child(sacrifice_ladybug)
			sacrifice_ladybug.global_position = global_position + Vector3(0, 0.2, 5.5)
			
	# Pausa de suspense antes da Joaninha avançar
	var t1 = tree.create_timer(1.8)
	t1.timeout.connect(func():
		if not is_instance_valid(sacrifice_ladybug):
			finish_intro_cinematic()
			return
			
		GameManager.notify("🐞 A Joaninha Companheira voa bravamente para deter o monstro!", Tokens.DOURADO_LUZ)
		
		# Voo em curva ascendente e lenta da Joaninha
		var tw_lady = tree.create_tween()
		tw_lady.tween_property(sacrifice_ladybug, "global_position", global_position + Vector3(0, 1.2, 2.2), 1.8).set_trans(Tween.TRANS_SINE)
		
		# Escorpião ergue a cauda ameaçadoramente
		if tail_root:
			var tw_tail_prep = tree.create_tween()
			tw_tail_prep.tween_property(tail_root, "rotation_degrees:x", 35.0, 1.4)
			
		tw_lady.tween_callback(func():
			# Golpe brutal e lento do ferrão atravessando a Joaninha
			if tail_root:
				var tw_strike = tree.create_tween()
				tw_strike.tween_property(tail_root, "rotation_degrees:x", -75.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw_strike.tween_property(tail_root, "rotation_degrees:x", 0.0, 0.4)
			
			SoundManager.play_sparkle(-6.0, 0.5)
			
			# Joaninha solta ganido de dor e tomba no chão
			var tw_fall = tree.create_tween()
			tw_fall.tween_property(sacrifice_ladybug, "position:y", 0.05, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw_fall.parallel().tween_property(sacrifice_ladybug, "rotation_degrees:z", 90.0, 0.6)
			
			# Câmera transita suave e lentamente até a Pip
			var t_cam_pip = tree.create_timer(1.6)
			t_cam_pip.timeout.connect(func():
				var pip = GameManager.heroine
				if pip and is_instance_valid(pip):
					if cam and cam.has_method("focus_target"):
						cam.focus_target(pip, 0.75, 2.0)
					
					# Balão dramático de vingança com lágrimas
					if pip.has_method("show_revenge_dialog"):
						pip.show_revenge_dialog("Você vai pagar por isso... EU VOU ME VINGAR!", 3.0)
					else:
						GameManager.notify("Pip: 'Você vai pagar por isso... EU VOU ME VINGAR!'", Tokens.PERIGO)
						
				var t_start = tree.create_timer(2.8)
				t_start.timeout.connect(func():
					if cam and cam.has_method("reset_focus"):
						cam.reset_focus(1.0, 4.0)
					finish_intro_cinematic()
				)
			)
		)
	)

func finish_intro_cinematic() -> void:
	current_state = ScorpionState.CHASE
	GameManager.is_in_cutscene = false
	GameManager.set_player_control_enabled(true)
	GameManager.notify("👑 CHEFE FINAL: Tirano Noturno - O Escorpião Luminescente!", Color(0.8, 0.3, 1.0))

func _physics_process(delta: float) -> void:
	super(delta)
	animate_scorpion(delta)
	
	match current_state:
		ScorpionState.CHASE:
			handle_chase(delta)
		ScorpionState.TELEGRAPH:
			handle_telegraph(delta)
		ScorpionState.STRIKE_STUCK:
			handle_strike_stuck(delta)
		ScorpionState.RECOVER:
			handle_recover(delta)

func animate_scorpion(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	if claw_left: claw_left.rotation_degrees.y = 15.0 + sin(t * 5.0) * 12.0
	if claw_right: claw_right.rotation_degrees.y = -15.0 - cos(t * 5.0) * 12.0
	if runes_light:
		runes_light.light_energy = 1.5 + sin(t * 6.0) * 0.5
		
	# Animação rastejante realista das 8 pernas
	var is_moving = velocity.length_squared() > 0.1
	var crawl = sin(t * 14.0) * 20.0 if is_moving else 0.0
	
	if leg_l1: leg_l1.rotation_degrees.z = crawl
	if leg_l2: leg_l2.rotation_degrees.z = -crawl
	if leg_l3: leg_l3.rotation_degrees.z = crawl
	if leg_l4: leg_l4.rotation_degrees.z = -crawl
	
	if leg_r1: leg_r1.rotation_degrees.z = -crawl
	if leg_r2: leg_r2.rotation_degrees.z = crawl
	if leg_r3: leg_r3.rotation_degrees.z = -crawl
	if leg_r4: leg_r4.rotation_degrees.z = crawl

func handle_chase(delta: float) -> void:
	var pip = GameManager.heroine
	if not pip or not is_instance_valid(pip):
		return
		
	var to_pip = (pip.global_position - global_position)
	to_pip.y = 0.0
	var dist = to_pip.length()
	
	if dist > 2.6:
		var dir = to_pip.normalized()
		velocity = dir * current_speed
		move_and_slide()
		
		if visual_root:
			var target_rot = atan2(dir.x, dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 7.0)
	else:
		# Próximo o bastante para preparar o golpe de ferrão
		start_telegraph()

func start_telegraph() -> void:
	current_state = ScorpionState.TELEGRAPH
	state_timer = 1.0 # 1.0s de telegrafia clara
	velocity = Vector3.ZERO
	
	# O brilho das runas da cauda muda para branco intenso
	if runes_light:
		runes_light.light_color = Color(1.0, 1.0, 1.0)
		runes_light.light_energy = 3.5
		
	SoundManager.play_sparkle(-2.0, 0.4)
	GameManager.notify("⚠️ FERRÃO ERGUIDO! USE O DASH LATERAL PARA DESVIAR!", Tokens.RUIVO_COBRE)
	
	# Animação de erguer o ferrão alto
	if tail_root:
		var tw = create_tween()
		tw.tween_property(tail_root, "rotation_degrees:x", 45.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func handle_telegraph(delta: float) -> void:
	state_timer -= delta
	velocity = Vector3.ZERO
	if state_timer <= 0.0:
		slam_stinger_into_ground()

func slam_stinger_into_ground() -> void:
	current_state = ScorpionState.STRIKE_STUCK
	state_timer = 3.0 # Janela de 3.0s de vulnerabilidade total
	is_stinger_vulnerable = true
	
	# Cravada violenta no chão
	if tail_root:
		var tw = create_tween()
		tw.tween_property(tail_root, "rotation_degrees:x", -75.0, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		
	SoundManager.play_sparkle(2.0)
	
	if weakpoint_marker:
		weakpoint_marker.visible = true
		
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip):
		var slam_pos = global_position + visual_root.global_transform.basis.z * 1.6
		if slam_pos.distance_to(pip.global_position) < 1.6 and not pip.get("is_invulnerable"):
			GameManager.damage_pip(attack_damage)
			GameManager.notify("⚠️ Atingido em cheio pelo impacto do ferrão!", Tokens.PERIGO)
			
	GameManager.notify("🎯 FERRÃO PRESO NO SOLO! GOLPEIE O FERRÃO AGORA (150% DANO)!", Tokens.DOURADO_LUZ)

func handle_strike_stuck(delta: float) -> void:
	state_timer -= delta
	velocity = Vector3.ZERO
	
	# Pulso visual no marcador do ponto fraco
	if weakpoint_marker:
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.25
		weakpoint_marker.scale = Vector3(pulse, pulse, pulse)
		
	if state_timer <= 0.0:
		start_recovery()

func start_recovery() -> void:
	current_state = ScorpionState.RECOVER
	state_timer = 0.8
	is_stinger_vulnerable = false
	if weakpoint_marker:
		weakpoint_marker.visible = false
	if runes_light:
		runes_light.light_color = Color(0.2, 0.8, 1.0)
		runes_light.light_energy = 1.8
		
	SoundManager.play_fairy_dust(-2.0)
	
	# Puxa o ferrão para fora com um solavanco
	if tail_root:
		var tw = create_tween()
		tw.tween_property(tail_root, "rotation_degrees:x", 0.0, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	# Onda de choque empurra Pip para trás caso esteja colada
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip):
		var dist = global_position.distance_to(pip.global_position)
		if dist < 3.0:
			var push_dir = (pip.global_position - global_position).normalized()
			pip.velocity = push_dir * 6.0

func handle_recover(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = ScorpionState.CHASE

func take_stinger_damage(amount: float) -> void:
	current_state = ScorpionState.STRIKE_STUCK
	is_stinger_vulnerable = true
	take_damage(amount)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, armor_pierce: float = 0.0) -> void:
	if current_state == ScorpionState.INTRO_CUTSCENE or current_state == ScorpionState.VICTORY_CUTSCENE:
		return
		
	if is_stinger_vulnerable:
		# Ponto fraco exposto: recebe 150% do dano com faíscas luminosas!
		SoundManager.play_sparkle(1.5)
		super.take_damage(amount * 1.5, Vector3.ZERO, is_dot, 1.0)
	else:
		# 100% imune a ataques normais no corpo blindado
		SoundManager.play_sparkle(-7.0, 0.2)
		GameManager.notify("🛡️ A carapaça rúnica refletiu o ataque! Acerte o ferrão preso!", Tokens.CREME_PERGAMINHO)

func die() -> void:
	current_state = ScorpionState.VICTORY_CUTSCENE
	GameManager.is_in_cutscene = true
	GameManager.set_player_control_enabled(false)
	
	GameManager.notify("🏆 O TIRANO NOTURNO FOI DERROTADO!", Color(0.8, 0.4, 1.0))
	SoundManager.play_fairy_dust(0.0)
	
	# Estilhaçamento lento do Escorpião em cinzas azuis
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "scale", Vector3(1.4, 0.08, 1.4), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(runes_light, "light_energy", 0.0, 1.8) if runes_light else null
		tw.tween_callback(func():
			if visual_root: visual_root.visible = false
			play_final_victory_cutscene()
		)
	else:
		play_final_victory_cutscene()

func play_final_victory_cutscene() -> void:
	var tree = get_tree()
	if not tree:
		GameManager.on_boss_defeated("SCORPION")
		return
		
	var cam = get_viewport().get_camera_3d()
	var pip = GameManager.heroine
	
	# Garante que a Joaninha esteja presente no solo para a cena final
	if not sacrifice_ladybug or not is_instance_valid(sacrifice_ladybug):
		var comp_scn = load("res://scripts/ladybug_companion.gd")
		if comp_scn:
			sacrifice_ladybug = comp_scn.new()
			get_parent().add_child(sacrifice_ladybug)
			sacrifice_ladybug.global_position = global_position + Vector3(1.5, 0.05, 1.5)
			sacrifice_ladybug.rotation_degrees.z = 90.0
			
	var lady_pos = sacrifice_ladybug.global_position if is_instance_valid(sacrifice_ladybug) else global_position
	
	# 1. Câmera acompanha Pip caminhando lentamente até a Joaninha
	if pip and is_instance_valid(pip):
		if cam and cam.has_method("focus_target"):
			cam.focus_target(pip, 0.8, 2.0)
			
		var tw_walk = tree.create_tween()
		tw_walk.tween_property(pip, "global_position", lady_pos + Vector3(0.65, 0, 0.65), 2.8).set_trans(Tween.TRANS_SINE)
		tw_walk.tween_callback(func():
			# 2. Pip se ajoelha ao lado da amiga
			if pip.has_node("Visuals"):
				var tw_kneel = tree.create_tween()
				tw_kneel.tween_property(pip.get_node("Visuals"), "position:y", -0.18, 0.6)
				
			# 3. Luz dourada suave e espiral de partículas subindo ao céu estrelado
			if is_instance_valid(sacrifice_ladybug):
				var tw_glow = tree.create_tween()
				tw_glow.tween_property(sacrifice_ladybug, "scale", Vector3(0.01, 0.01, 0.01), 3.2).set_trans(Tween.TRANS_SINE)
				tw_glow.parallel().tween_property(sacrifice_ladybug, "position:y", 8.0, 3.2).set_trans(Tween.TRANS_CUBIC)
				
				# Espiral de estrelinhas celestiais
				for i in range(12):
					var star = MeshInstance3D.new()
					var sph = SphereMesh.new()
					sph.radius = 0.06
					sph.height = 0.12
					star.mesh = sph
					var smat = StandardMaterial3D.new()
					smat.albedo_color = Color(1.0, 0.92, 0.4, 0.95)
					smat.emission_enabled = true
					smat.emission = Color(1.0, 0.88, 0.35)
					smat.emission_energy_multiplier = 2.5
					star.material_override = smat
					
					var parent_node = sacrifice_ladybug.get_parent()
					if parent_node:
						parent_node.add_child(star)
						var ang = (i / 12.0) * TAU
						var start_pos = lady_pos + Vector3(cos(ang) * 0.4, 0.2, sin(ang) * 0.4)
						star.global_position = start_pos
						var tw_s = tree.create_tween()
						var end_pos = start_pos + Vector3(cos(ang + 2.5) * 1.5, 9.0 + (i * 0.3), sin(ang + 2.5) * 1.5)
						tw_s.tween_property(star, "global_position", end_pos, 3.2 + randf() * 0.5).set_trans(Tween.TRANS_SINE)
						tw_s.parallel().tween_property(star, "scale", Vector3.ZERO, 3.2)
						tw_s.tween_callback(star.queue_free)
				
			SoundManager.play_fairy_dust(2.0)
			GameManager.notify("✨ O espírito da Joaninha sobe em constelação para proteger o Jardim para sempre...", Tokens.DOURADO_LUZ)
			
			# 4. Melodia de harpa/piano conclui e exibe tela de vitória
			var t_end = tree.create_timer(4.0)
			t_end.timeout.connect(func():
				GameManager.on_boss_defeated("SCORPION")
			)
		)
	else:
		var t_fallback = tree.create_timer(2.0)
		t_fallback.timeout.connect(func():
			GameManager.on_boss_defeated("SCORPION")
		)
