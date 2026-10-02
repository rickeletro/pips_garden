extends EnemyBase
class_name Caterpillar

func _init() -> void:
	max_hp = 125.0
	base_speed = 1.6
	attack_damage = 12.0
	attack_interval = 1.4
	xp_reward = 30
	is_flying = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false) -> void:
	# Thick cuticle: 25% damage reduction against physical impacts, but vulnerable to dots
	var effective_damage = amount
	if not is_dot:
		effective_damage = amount * 0.75
		# Reduced knockback due to weight
		knockback *= 0.35
		
	super.take_damage(effective_damage, knockback, is_dot)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Undulating caterpillar wave animation
	if velocity.length_squared() > 0.1 and visual_root:
		var wave = sin(Time.get_ticks_msec() * 0.01)
		visual_root.scale.z = 1.0 + wave * 0.18
		visual_root.scale.y = 1.0 - wave * 0.12
