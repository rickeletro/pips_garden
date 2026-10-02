extends Node3D
class_name FlyingSeedPappus

@onready var visuals: Node3D = $Visuals

var velocity: Vector3 = Vector3.ZERO
var ground_y: float = 0.25
var sway_seed: float = 0.0
var has_landed: bool = false
var pickup_scene: PackedScene = preload("res://scenes/pickup.tscn")

func _ready() -> void:
	sway_seed = randf() * 100.0
	# Leve escala aleatória para cada semente parecer única
	var s = randf_range(0.85, 1.15)
	if visuals:
		visuals.scale = Vector3(s, s, s)

func launch(origin_pos: Vector3, burst_dir: Vector3) -> void:
	global_position = origin_pos
	# Impulso inicial: sai voando para cima e para fora como soprado pelo vento
	var up_boost = randf_range(3.8, 5.5)
	var horiz_speed = randf_range(2.0, 4.2)
	velocity = burst_dir.normalized() * horiz_speed + Vector3(0, up_boost, 0)
	# Adiciona leve turbulência aleatória
	velocity.x += (randf() - 0.5) * 1.5
	velocity.z += (randf() - 0.5) * 1.5

func _physics_process(delta: float) -> void:
	if has_landed:
		return
		
	# Gravidade suave (efeito paraquedas flutuante)
	velocity.y -= 2.8 * delta
	# Velocidade terminal de queda muito suave (-0.95 m/s)
	velocity.y = maxf(velocity.y, -0.95)
	
	# Resistência do ar reduz o deslocamento horizontal
	velocity.x = lerp(velocity.x, 0.0, 1.6 * delta)
	velocity.z = lerp(velocity.z, 0.0, 1.6 * delta)
	
	# Oscilação orgânica do paraquedas no vento
	var t = Time.get_ticks_msec() * 0.005 + sway_seed
	if visuals:
		visuals.rotation.z = sin(t * 2.8) * 0.28
		visuals.rotation.x = cos(t * 2.2) * 0.22
		visuals.rotation.y += delta * 1.5
		
	global_position += velocity * delta
	
	# Pouso no chão
	if global_position.y <= ground_y:
		land_on_ground()

func land_on_ground() -> void:
	if has_landed:
		return
	has_landed = true
	
	# Cria o item colecionável de semente no solo
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		if pickup:
			pickup.set("item_type", "SEED")
			var parent_node = get_parent()
			if parent_node:
				parent_node.add_child(pickup)
				pickup.global_position = Vector3(global_position.x, ground_y, global_position.z)
				
				# Animação suave de aterrissagem do pickup
				if pickup.visuals:
					pickup.visuals.scale = Vector3(0.2, 0.2, 0.2)
					var land_tween = pickup.create_tween()
					land_tween.tween_property(pickup.visuals, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Efeito de poeira dourada ao aterrissar
	spawn_landing_dust()
	queue_free()

func spawn_landing_dust() -> void:
	var tree = get_tree()
	if not tree:
		return
	var dust = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.2
	dust.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.4, 0.8)
	dust.material_override = mat
	
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(dust)
		dust.global_position = Vector3(global_position.x, ground_y + 0.05, global_position.z)
		var dt = dust.create_tween()
		dt.tween_property(dust, "scale", Vector3(1.8, 0.2, 1.8), 0.2)
		dt.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.2)
		dt.tween_callback(dust.queue_free)
