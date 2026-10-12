extends EnemyBase
class_name BossWaspQueen

# Chefe do Dia 3: Vespa Imperatriz (Hive Empress)
# Visual: Vespa gigante com asas translúcidas douradas, coroa real e ferrão quádruplo.
# Comportamento: Paira sobre o centro, dispara ferrões quádruplos e invoca mini-enxames de vespas operárias.
# Recompensa: Geleia Real (reparo instantâneo e gratuito de todas as torres + 40 HP na Flor).

@onready var wing_left: MeshInstance3D = $Visuals/WingLeft
@onready var wing_right: MeshInstance3D = $Visuals/WingRight
@onready var crown_mesh: MeshInstance3D = $Visuals/Crown
@onready var wasp_scene: PackedScene = preload("res://scenes/enemies/wasp.tscn")

var shoot_timer: float = 2.0
var summon_timer: float = 6.0
const HOVER_ALTITUDE: float = 2.8

func _init() -> void:
	max_hp = 2600.0 # Balanceado perfeitamente para o Chefe do Dia 3
	base_speed = 2.8
	attack_damage = 28.0
	attack_interval = 1.0
	xp_reward = 600
	is_flying = true

func _ready() -> void:
	super._ready()
	global_position.y = HOVER_ALTITUDE
	GameManager.register_active_boss(self, "👑 VESPA IMPERATRIZ", max_hp)
	SoundManager.play_boss_music(1.2, -4.5)
	GameManager.notify("👑 CHEFE: Vespa Imperatriz assumiu o controle dos céus!", Color(1.0, 0.85, 0.2))

func _physics_process(delta: float) -> void:
	super(delta)
	animate_queen(delta)
	
	global_position.y = move_toward(global_position.y, HOVER_ALTITUDE, delta * 2.0)
	
	shoot_timer -= delta
	summon_timer -= delta
	
	if shoot_timer <= 0.0:
		shoot_timer = 2.4
		fire_quad_stingers()
		
	if summon_timer <= 0.0:
		summon_timer = 8.5
		summon_worker_minions()
		
	# Movimento pairando sobre a Flor Central / Pip
	var target_pos = Vector3.ZERO
	if target_flower and is_instance_valid(target_flower):
		target_pos = target_flower.global_position + Vector3(sin(Time.get_ticks_msec() * 0.001) * 3.5, HOVER_ALTITUDE, cos(Time.get_ticks_msec() * 0.001) * 3.5)
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		target_pos = GameManager.heroine.global_position + Vector3(0, HOVER_ALTITUDE, 0)
		
	var dir = (target_pos - global_position).normalized()
	velocity = dir * current_speed
	move_and_slide()
	
	if visual_root and dir.length_squared() > 0.01:
		var target_rot = atan2(dir.x, dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 6.0)

func animate_queen(_delta: float) -> void:
	var buzz = sin(Time.get_ticks_msec() * 0.09) * 38.0
	if wing_left: wing_left.rotation_degrees.z = buzz
	if wing_right: wing_right.rotation_degrees.z = -buzz
	if visual_root:
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.004) * 0.2

func fire_quad_stingers() -> void:
	SoundManager.play_bee_buzz(-12.0)
	var parent_node = get_parent()
	if not parent_node:
		return
		
	var target_pos = GameManager.heroine.global_position if GameManager.heroine else (global_position + Vector3.FORWARD * 5.0)
	var base_dir = (target_pos - global_position).normalized()
	base_dir.y = 0.0
	
	for i in range(4):
		var angle = (i - 1.5) * 0.18
		var dir = base_dir.rotated(Vector3.UP, angle)
		
		var stinger = Area3D.new()
		stinger.collision_layer = 0
		stinger.collision_mask = 7
		
		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 0.12
		cyl.height = 0.6
		col.shape = cyl
		stinger.add_child(col)
		
		var mesh_inst = MeshInstance3D.new()
		var cyl_m = CylinderMesh.new()
		cyl_m.top_radius = 0.02
		cyl_m.bottom_radius = 0.08
		cyl_m.height = 0.6
		mesh_inst.mesh = cyl_m
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.82, 0.2, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.1)
		mat.emission_energy_multiplier = 1.2
		mesh_inst.material_override = mat
		mesh_inst.rotation_degrees.x = 90.0
		stinger.add_child(mesh_inst)
		
		parent_node.add_child(stinger)
		stinger.global_position = global_position + Vector3(0, -0.4, 0)
		
		var is_hit = false
		stinger.body_entered.connect(func(body: Node3D):
			if is_hit or body == self or body.is_in_group("enemies"):
				return
			is_hit = true
			if body.is_in_group("player"):
				GameManager.damage_pip(25.0)
				GameManager.notify("⚠️ Atingido pelo ferrão real da Imperatriz!", Tokens.PERIGO)
			elif body.has_method("take_damage"):
				body.take_damage(28.0)
			stinger.queue_free()
		)
		
		var tw = create_tween()
		tw.tween_property(stinger, "global_position", stinger.global_position + dir * 25.0, 2.0)
		tw.tween_callback(stinger.queue_free)

func summon_worker_minions() -> void:
	if not wasp_scene:
		return
	var parent_node = get_parent()
	if not parent_node:
		return
		
	GameManager.notify("🐝 A Vespa Imperatriz convocou operárias reais!", Tokens.DOURADO_LUZ)
	SoundManager.play_fairy_dust(-4.0)
	
	for i in range(2):
		var w = wasp_scene.instantiate()
		parent_node.add_child(w)
		var angle = (float(i) / 2.0) * TAU
		w.global_position = global_position + Vector3(cos(angle) * 2.0, 0, sin(angle) * 2.0)

func die() -> void:
	GameManager.notify("🏆 VESPA IMPERATRIZ DERROTADA! Ela dropou a Geleia Real!", Tokens.DOURADO_LUZ)
	
	var parent_node = get_parent()
	if parent_node:
		var pickup_scn = pickup_scene
		if not pickup_scn and ResourceLoader.exists("res://scenes/pickup.tscn"):
			pickup_scn = load("res://scenes/pickup.tscn")
		if pickup_scn:
			var pickup = pickup_scn.instantiate()
			pickup.item_type = "ROYAL_JELLY"
			parent_node.add_child(pickup)
			pickup.global_position = Vector3(global_position.x, 0.25, global_position.z)
			
	if visual_root:
		var tw = create_tween()
		tw.tween_property(visual_root, "scale", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			super.die()
			GameManager.on_boss_defeated("WASP_QUEEN")
		)
	else:
		super.die()
		GameManager.on_boss_defeated("WASP_QUEEN")
