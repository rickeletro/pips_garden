extends EnemyBase
class_name Caterpillar

# Lagarta Voraz do Jardim
# Come a grama plantada no caminho até destruí-la para abrir passagem!

var is_eating_grass: bool = false
var eating_cell: Vector2i = Vector2i.ZERO

func _init() -> void:
	max_hp = 180.0
	base_speed = 1.55
	attack_damage = 15.0
	attack_interval = 1.4
	xp_reward = 35
	is_flying = false

func spawn_drop() -> void:
	var roll = randf()
	var drop_type = ""
	# Mini-tanque com 55% de chance de drop de materiais de construção
	if roll < 0.28:
		drop_type = "TWIG"
	elif roll < 0.42:
		drop_type = "GEAR"
	elif roll < 0.55:
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

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, is_dot: bool = false, armor_pierce: float = 0.0) -> void:
	# Cutícula espessa: 25% de redução contra dano físico direto (mitigado por perfuração)
	var effective_damage = amount
	if not is_dot:
		var armor_reduction = 0.25 * clampf(1.0 - armor_pierce, 0.0, 1.0)
		effective_damage = amount * (1.0 - armor_reduction)
		knockback *= 0.35
		
	super(effective_damage, knockback, is_dot, armor_pierce)

func _physics_process(delta: float) -> void:
	super(delta)
	
	# Animação ondulatória de locomoção ou mastigação
	if is_eating_grass and visual_root:
		var munch = sin(Time.get_ticks_msec() * 0.03) * 0.25
		visual_root.rotation.x = munch
		visual_root.scale.z = 1.0 + abs(munch) * 0.2
	elif velocity.length_squared() > 0.05 and visual_root:
		var wave = sin(Time.get_ticks_msec() * 0.01)
		visual_root.scale.z = 1.0 + wave * 0.18
		visual_root.scale.y = 1.0 - wave * 0.12
		visual_root.rotation.x = 0.0

func check_attack_target(delta: float) -> void:
	# 1. Checa alvos padrão (Pip, Torres, Flor)
	super(delta)
	
	if is_currently_attacking:
		is_eating_grass = false
		return
		
	# 2. Mecânica especial da Lagarta: Devorar a grama do caminho
	is_eating_grass = false
	if grid_manager:
		var my_cell = grid_manager.world_to_grid(global_position)
		if grid_manager.get_tile_type(my_cell) == GridManager.TileType.GRASS:
			is_eating_grass = true
			is_currently_attacking = true
			eating_cell = my_cell
			
			# Mastiga a grama (18 de dano por segundo)
			var destroyed = grid_manager.damage_grass(my_cell, 18.0 * delta)
			if destroyed:
				is_eating_grass = false
				is_currently_attacking = false
				recalculate_path()
