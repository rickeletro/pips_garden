extends EnemyBase
class_name Aphid

func _init() -> void:
	max_hp = 45.0
	base_speed = 3.2
	attack_damage = 6.0
	attack_interval = 0.9
	xp_reward = 12
	is_flying = false

func _physics_process(delta: float) -> void:
	super(delta)
	# Wiggle legs / body slightly while running
	if velocity.length_squared() > 0.1 and visual_root:
		visual_root.position.y = 0.15 + abs(sin(Time.get_ticks_msec() * 0.025)) * 0.08
