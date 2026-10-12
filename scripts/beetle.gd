extends EnemyBase
class_name Beetle

# Besouro do Jardim Noturno (Carapaça Pesada e Resistente)
@onready var horn: MeshInstance3D = $Visuals/Horn
@onready var shell: MeshInstance3D = $Visuals/Shell

func _init() -> void:
	max_hp = 240.0
	base_speed = 1.15
	attack_damage = 18.0
	attack_interval = 1.2
	xp_reward = 45
	is_flying = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, armor_pierce: float = 0.0) -> void:
	# Carapaça rígida: 30% de redução de dano direto (mitigado por perfuração de armadura)
	var effective = amount
	if not is_dot:
		var armor_reduction = 0.30 * clampf(1.0 - armor_pierce, 0.0, 1.0)
		effective = amount * (1.0 - armor_reduction)
		knockback *= 0.25
		# Clink metálico suave na carapaça
		SoundManager.play_sparkle(-7.0, 0.25)
	super(effective, knockback, is_dot, armor_pierce)

func spawn_drop() -> void:
	var roll = randf()
	var drop_type = ""
	# Besouro blindado noturno: 60% chance de drop (alto valor de engrenagens)
	if roll < 0.30:
		drop_type = "GEAR"
	elif roll < 0.55:
		drop_type = "TWIG"
	elif roll < 0.65:
		drop_type = "SEED"
	else:
		return
		
	var drop_scn = load("res://scenes/pickup.tscn")
	if drop_scn:
		var p = drop_scn.instantiate()
		p.item_type = drop_type
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(p)
			p.global_position = global_position + Vector3(0, 0.2, 0)

func _physics_process(delta: float) -> void:
	super(delta)
	
	# Passada firme e pesada do besouro (wobble lateral rítmico)
	if velocity.length_squared() > 0.05 and visual_root:
		var step_wobble = sin(Time.get_ticks_msec() * 0.012) * 5.0
		visual_root.rotation_degrees.z = step_wobble
		visual_root.position.y = abs(sin(Time.get_ticks_msec() * 0.012)) * 0.05
