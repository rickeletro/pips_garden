extends Node3D
class_name DewDrop

# Gota de Orvalho Compacta (Jardim Miúdo)
# Coletada por aproximação ou golpe da Pip:
# Cura +25 HP para a Pip e adiciona +1 carga ao Frasco de Orvalho (máx 3).
# Sem poça/círculo azul no chão.

var visuals: Node3D = null
var drop_mesh: MeshInstance3D = null

var is_popped: bool = false
static var shared_drop_mesh: SphereMesh = null
static var shared_drop_mat: StandardMaterial3D = null

func _ready() -> void:
	add_to_group("dew_drop")
	add_to_group("dewdrops")
	_init_visuals()
	_setup_trigger_area()
	_play_spawn_pop()

func _setup_trigger_area() -> void:
	var trigger = Area3D.new()
	trigger.name = "CollectArea"
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.0
	col.shape = sphere
	trigger.add_child(col)
	add_child(trigger)
	trigger.body_entered.connect(func(body):
		if not is_popped and (body.is_in_group("player") or body is CharacterBody3D):
			if GameManager.dew_flask_charges < GameManager.MAX_DEW_CHARGES:
				on_attack_hit(body.global_position)
	)
	trigger.area_entered.connect(func(area):
		if not is_popped and area.name.contains("Attack"):
			if GameManager.dew_flask_charges < GameManager.MAX_DEW_CHARGES:
				on_attack_hit(area.global_position)
	)

func _init_visuals() -> void:
	if shared_drop_mesh == null:
		shared_drop_mesh = SphereMesh.new()
		shared_drop_mesh.radius = 0.20
		shared_drop_mesh.height = 0.38
		shared_drop_mesh.radial_segments = 12
		shared_drop_mesh.rings = 8
		
		shared_drop_mat = StandardMaterial3D.new()
		shared_drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shared_drop_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shared_drop_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		shared_drop_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		shared_drop_mat.albedo_color = Color(0.68, 0.90, 1.0, 0.85)
		shared_drop_mat.roughness = 0.05
		shared_drop_mat.emission_enabled = true
		shared_drop_mat.emission = Color(0.55, 0.85, 1.0, 1.0)
		shared_drop_mat.emission_energy_multiplier = 0.65
		shared_drop_mat.rim_enabled = true
		shared_drop_mat.rim = 0.90
		
	if not visuals:
		visuals = Node3D.new()
		visuals.name = "Visuals"
		add_child(visuals)
		
	if not drop_mesh:
		drop_mesh = MeshInstance3D.new()
		drop_mesh.name = "DropMesh"
		drop_mesh.mesh = shared_drop_mesh
		drop_mesh.material_override = shared_drop_mat
		drop_mesh.position = Vector3(0, 0.22, 0)
		visuals.add_child(drop_mesh)

func _process(_delta: float) -> void:
	if is_popped:
		return
	var t = Time.get_ticks_msec() * 0.002 + global_position.x
	if visuals:
		visuals.scale.y = 1.0 + sin(t * 3.0) * 0.06
		visuals.scale.x = 1.0 - sin(t * 3.0) * 0.03
		visuals.scale.z = visuals.scale.x

func _play_spawn_pop() -> void:
	if visuals:
		visuals.scale = Vector3.ZERO
		var tw = create_tween()
		tw.tween_property(visuals, "scale", Vector3(1.15, 1.15, 1.15), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(visuals, "scale", Vector3.ONE, 0.12)

func on_attack_hit(_attacker_pos: Vector3 = Vector3.ZERO) -> void:
	if is_popped:
		return
	if GameManager.dew_flask_charges >= GameManager.MAX_DEW_CHARGES:
		GameManager.notify("💧 Frasco de Orvalho cheio (%d/%d)!" % [GameManager.dew_flask_charges, GameManager.MAX_DEW_CHARGES], Tokens.DOURADO_LUZ)
		return
		
	is_popped = true
	GameManager.heal_pip(25.0)
	GameManager.add_dew_flask_charge(1)
	SoundManager.play_fairy_dust(-2.0)
	GameManager.notify("💧 Gota de Orvalho coletada! +25 HP e +1 Frasco", Tokens.DOURADO_LUZ)
	
	# Desaparece suavemente no ar sem criar nenhuma poça ou círculo no chão
	if visuals:
		var tw = create_tween()
		tw.tween_property(visuals, "scale", Vector3(1.3, 1.3, 1.3), 0.06)
		tw.tween_property(visuals, "scale", Vector3.ZERO, 0.12)
		tw.tween_callback(queue_free)
	else:
		queue_free()
