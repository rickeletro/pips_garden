extends EnemyBase
class_name BossSpider

# Chefe da Noite 2: Aranha-Tecelã Sombria (Shadow Weaver)
# Visual: Aracnídeo aveludado escuro com detalhes brancos bioluminescentes.
# Comportamento: Posiciona casulos de teia no chão que prendem Pip e atira teias que reduzem o alcance das torres.
# Recompensa: Néctar Revigorante (+80 HP na Flor Central).

@onready var legs_root: Node3D = $Visuals/Legs
@onready var fangs_node: Node3D = $Visuals/Head/Fangs

var web_trap_cd: float = 3.5
var web_shot_cd: float = 5.0

func _init() -> void:
	max_hp = 1950.0 # Balanceado perfeitamente para o Chefe da Noite 2
	base_speed = 2.6
	attack_damage = 30.0
	attack_interval = 1.1
	xp_reward = 550
	is_flying = false

func _ready() -> void:
	super._ready()
	global_position.y = 0.0
	GameManager.register_active_boss(self, "🕷️ ARANHA-TECELÃ SOMBRIA", max_hp)
	SoundManager.play_boss_music(1.2, -4.5)
	GameManager.notify("👑 CHEFE: Aranha-Tecelã Sombria emergiu das sombras!", Color(0.85, 0.5, 1.0))

func _physics_process(delta: float) -> void:
	super(delta)
	animate_spider(delta)
	
	web_trap_cd -= delta
	web_shot_cd -= delta
	
	if web_trap_cd <= 0.0:
		web_trap_cd = 4.5
		spawn_web_trap()
		
	if web_shot_cd <= 0.0:
		web_shot_cd = 6.0
		shoot_web_at_nearest_tower()
		
	# Movimento em direção à Pip ou Flor
	var target = choose_target()
	if target and is_instance_valid(target):
		var target_pos = target.global_position
		target_pos.y = 0.0
		var to_target = (target_pos - global_position)
		to_target.y = 0.0
		var dist = to_target.length()
		
		if dist > 1.8:
			var dir = to_target.normalized()
			velocity = dir * current_speed
			move_and_slide()
			
			if visual_root:
				var target_rot = atan2(dir.x, dir.z)
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 8.0)
		else:
			# Mordida venenosa
			velocity = Vector3.ZERO
			if attack_timer <= 0.0:
				attack_timer = attack_interval
				perform_venom_bite(target)

func animate_spider(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	if legs_root and velocity.length_squared() > 0.1:
		var leg_wave = sin(t * 14.0) * 12.0
		legs_root.rotation_degrees.y = leg_wave
	if fangs_node:
		fangs_node.rotation_degrees.x = sin(t * 6.0) * 10.0

func choose_target() -> Node3D:
	var pip = GameManager.heroine
	if pip and is_instance_valid(pip):
		var d = global_position.distance_to(pip.global_position)
		if d < 6.5:
			return pip
	if target_flower and is_instance_valid(target_flower):
		return target_flower
	return null

func spawn_web_trap() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var trap = Area3D.new()
	trap.name = "WebCocoonTrap"
	trap.collision_layer = 0
	trap.collision_mask = 2 # Detecta Player
	
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.35
	cyl.height = 0.2
	col.shape = cyl
	trap.add_child(col)
	
	# Visual de teia no chão
	var mesh_inst = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 1.3
	cm.bottom_radius = 1.3
	cm.height = 0.03
	mesh_inst.mesh = cm
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.95, 1.0, 0.72)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.5
	mesh_inst.material_override = mat
	trap.add_child(mesh_inst)
	
	parent_node.add_child(trap)
	trap.global_position = Vector3(global_position.x, 0.04, global_position.z)
	
	var is_triggered = false
	trap.body_entered.connect(func(body: Node3D):
		if is_triggered or not body.is_in_group("player"):
			return
		is_triggered = true
		GameManager.notify("🕸️ Preso em um casulo de teia! Ataque com a agulha para se soltar!", Tokens.RUIVO_COBRE)
		if body.has_method("take_damage"):
			body.take_damage(8.0)
		if body.get("velocity") != null:
			body.velocity = Vector3.ZERO
	)
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_interval(14.0)
		tw.tween_property(mat, "albedo_color:a", 0.0, 1.0)
		tw.tween_callback(trap.queue_free)

func shoot_web_at_nearest_tower() -> void:
	var tree = get_tree()
	if not tree:
		return
	var towers = tree.get_nodes_in_group("towers")
	var nearest_t: Node3D = null
	var min_d = 9999.0
	for tw in towers:
		if is_instance_valid(tw) and tw.get("is_broken") != true:
			var d = global_position.distance_to(tw.global_position)
			if d < min_d and d < 12.0:
				min_d = d
				nearest_t = tw
				
	if nearest_t:
		SoundManager.play_fairy_dust(-6.0)
		GameManager.notify("🕸️ A Aranha disparou teias, reduzindo o alcance de uma torre!", Tokens.CREME_PERGAMINHO)
		if nearest_t.get("attack_range") != null:
			var orig_r = nearest_t.attack_range
			nearest_t.attack_range *= 0.60
			var t_timer = tree.create_timer(5.0)
			t_timer.timeout.connect(func():
				if is_instance_valid(nearest_t):
					nearest_t.attack_range = orig_r
			)

func perform_venom_bite(target: Node3D) -> void:
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "position:z", 0.35, 0.1)
		tw.tween_property(visual_root, "position:z", 0.0, 0.12)
		
	if target == GameManager.heroine:
		GameManager.damage_pip(attack_damage)
		GameManager.notify("⚠️ Picada venenosa da Aranha!", Tokens.PERIGO)
	elif target.has_method("take_damage"):
		target.take_damage(attack_damage)

func die() -> void:
	GameManager.notify("🏆 ARANHA-TECELÃ SOMBRIA DERROTADA! Ela dropou o Néctar Revigorante!", Tokens.DOURADO_LUZ)
	
	var parent_node = get_parent()
	if parent_node:
		var pickup_scn = pickup_scene
		if not pickup_scn and ResourceLoader.exists("res://scenes/pickup.tscn"):
			pickup_scn = load("res://scenes/pickup.tscn")
		if pickup_scn:
			var pickup = pickup_scn.instantiate()
			pickup.item_type = "REVITALIZING_NECTAR"
			parent_node.add_child(pickup)
			pickup.global_position = Vector3(global_position.x, 0.25, global_position.z)
			
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "scale", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			super.die()
			GameManager.on_boss_defeated("SPIDER")
		)
	else:
		super.die()
		GameManager.on_boss_defeated("SPIDER")
