extends StaticBody3D
class_name GardenTower

signal tower_damaged(current_hp: float, max_hp: float)
signal tower_destroyed
signal level_upgraded(new_level: int)

enum PoisonType { SLOW, CORROSIVE, MIST }

@export var poison_type: PoisonType = PoisonType.SLOW
@export var level: int = 1
@export var max_hp: float = 100.0

var hp: float = 100.0
var is_broken: bool = false

var fire_rate: float = 0.85
var fire_timer: float = 0.0
var attack_range: float = 6.0

# Node References
@onready var visuals_standing: Node3D = $Visuals/StandingTent
@onready var visuals_collapsed: Node3D = $Visuals/CollapsedTent

@onready var level1_root: Node3D = $Visuals/StandingTent/Level1Parts
@onready var level2_root: Node3D = $Visuals/StandingTent/Level2Parts
@onready var level3_root: Node3D = $Visuals/StandingTent/Level3Parts

@onready var acorn_tank: MeshInstance3D = $Visuals/StandingTent/Level1Parts/AcornTank
@onready var poison_liquid: MeshInstance3D = $Visuals/StandingTent/Level1Parts/AcornTank/PoisonLiquid
@onready var nozzle: Node3D = $Visuals/StandingTent/Level1Parts/Nozzle

@onready var gear_level1: MeshInstance3D = $Visuals/StandingTent/Level1Parts/ToyGear
@onready var gear_level2_a: MeshInstance3D = $Visuals/StandingTent/Level2Parts/GearPairA
@onready var gear_level2_b: MeshInstance3D = $Visuals/StandingTent/Level2Parts/GearPairB
@onready var master_gear_level3: MeshInstance3D = $Visuals/StandingTent/Level3Parts/MasterGear
@onready var firefly_light: OmniLight3D = $Visuals/StandingTent/Level3Parts/FireflyLantern/OmniLight3D
@onready var leaf_banners: Node3D = $Visuals/StandingTent/Level3Parts/LeafBanners

@onready var range_area: Area3D = $RangeArea
@onready var range_shape: CollisionShape3D = $RangeArea/CollisionShape3D
@onready var broken_smoke: MeshInstance3D = $Visuals/StandingTent/BrokenSmoke

var current_target: Node3D = null
var gear_rot_speed: float = 0.0

var damage_materials: Array[StandardMaterial3D] = []
var base_albedo_colors: Array[Color] = []

func _ready() -> void:
	add_to_group("towers")
	hp = max_hp
	setup_damage_materials()
	update_level_visuals()
	update_poison_visual()
	update_damage_state()

func setup_damage_materials() -> void:
	damage_materials.clear()
	base_albedo_colors.clear()
	if not visuals_standing:
		return
	for node in visuals_standing.find_children("*", "MeshInstance3D"):
		var m = node as MeshInstance3D
		if m and m != poison_liquid and m != broken_smoke:
			var mat = m.get_active_material(0)
			if mat and mat is StandardMaterial3D:
				var dup = mat.duplicate() as StandardMaterial3D
				m.material_override = dup
				damage_materials.append(dup)
				base_albedo_colors.append(dup.albedo_color)

func _process(delta: float) -> void:
	if is_broken:
		return
	
	# Rotate gears when working or tracking target
	var target_rot_speed = 0.0
	if current_target and is_instance_valid(current_target):
		target_rot_speed = 7.0
	else:
		target_rot_speed = 1.0
		
	# Damage stutter if HP < 50%
	if hp < max_hp * 0.5:
		if randf() < 0.2:
			target_rot_speed = -2.0 # Stutter / jam
			
	gear_rot_speed = lerp(gear_rot_speed, target_rot_speed, delta * 5.0)
	rotate_gears(gear_rot_speed * delta)
	
	# Animate Level 3 firefly & banners
	if level >= 3:
		animate_level3_decorations(delta)
	
	fire_timer -= delta
	acquire_target()
	
	if current_target and is_instance_valid(current_target):
		aim_nozzle(delta)
		
		if fire_timer <= 0.0:
			fire_poison(current_target)
			fire_timer = fire_rate

func rotate_gears(delta_rot: float) -> void:
	if gear_level1 and gear_level1.visible:
		gear_level1.rotation.y += delta_rot
	if level2_root and level2_root.visible:
		if gear_level2_a: gear_level2_a.rotation.y += delta_rot
		if gear_level2_b: gear_level2_b.rotation.y -= delta_rot # Meshed opposite spin
	if level3_root and level3_root.visible:
		if master_gear_level3: master_gear_level3.rotation.z += delta_rot * 0.8

func animate_level3_decorations(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.003
	if firefly_light:
		firefly_light.light_energy = 0.8 + sin(t * 4.0) * 0.4
	if leaf_banners:
		leaf_banners.rotation.z = sin(t * 2.0) * 0.12
		leaf_banners.rotation.x = cos(t * 1.5) * 0.08

func aim_nozzle(delta: float) -> void:
	if not nozzle or not is_instance_valid(current_target):
		return
	var dir = (current_target.global_position - nozzle.global_position).normalized()
	var target_y_rot = atan2(dir.x, dir.z)
	nozzle.rotation.y = lerp_angle(nozzle.rotation.y, target_y_rot, 12.0 * delta)

func update_level_visuals() -> void:
	if level1_root: level1_root.visible = true
	if level2_root: level2_root.visible = (level >= 2)
	if level3_root: level3_root.visible = (level >= 3)
	
	match level:
		1:
			attack_range = 6.0
			fire_rate = 0.85
		2:
			attack_range = 7.5
			fire_rate = 0.55
		3:
			attack_range = 9.2
			fire_rate = 0.38
			
	if range_shape and range_shape.shape is SphereShape3D:
		range_shape.shape.radius = attack_range

func get_poison_color() -> Color:
	match poison_type:
		PoisonType.SLOW: return Tokens.VENENO_AMBAR      # Âmbar (Mel lento)
		PoisonType.CORROSIVE: return Tokens.VENENO_VERDE # Verde (Ácido corrosivo)
		PoisonType.MIST: return Tokens.VENENO_VIOLETA    # Violeta (Névoa em área)
	return Tokens.VENENO_AMBAR

func update_poison_visual() -> void:
	var col = get_poison_color()
	
	if poison_liquid:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.85
		mat.roughness = 0.25
		poison_liquid.material_override = mat
		
	# Update nozzle tip
	if nozzle and nozzle.has_node("TipRing"):
		var tip = nozzle.get_node("TipRing") as MeshInstance3D
		if tip:
			var tip_mat = StandardMaterial3D.new()
			tip_mat.albedo_color = col
			tip_mat.emission_enabled = true
			tip_mat.emission = col
			tip_mat.emission_energy_multiplier = 0.5
			tip.material_override = tip_mat

func cycle_poison_type() -> void:
	poison_type = ((poison_type + 1) % 3) as PoisonType
	update_poison_visual()
	var type_name = ""
	var col = get_poison_color()
	match poison_type:
		PoisonType.SLOW: type_name = "Veneno Âmbar (Cola e desacelera pragas)"
		PoisonType.CORROSIVE: type_name = "Veneno Verde (Ácido corrosivo potente)"
		PoisonType.MIST: type_name = "Névoa Violeta (Explosão tóxica em área)"
	GameManager.notify("Torre alterada para: %s" % type_name, col)

func acquire_target() -> void:
	if current_target and is_instance_valid(current_target):
		if global_position.distance_to(current_target.global_position) <= attack_range:
			return
	
	current_target = null
	var tree = get_tree()
	if not tree:
		return
	var enemies = tree.get_nodes_in_group("enemies")
	var closest_dist = attack_range
	for en in enemies:
		if is_instance_valid(en):
			var dist = global_position.distance_to(en.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = en

func fire_poison(target: Node3D) -> void:
	# Acorn tank squashes and pulses on pump
	if acorn_tank:
		var pump_tween = create_tween()
		pump_tween.tween_property(acorn_tank, "scale", Vector3(1.25, 0.82, 1.25), 0.08)
		pump_tween.tween_property(acorn_tank, "scale", Vector3.ONE, 0.12)
	
	# Spawn visual droplet/projectile
	var spray = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.22 if poison_type != PoisonType.MIST else 0.42
	sphere.height = sphere.radius * 2.0
	mesh_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	var col = get_poison_color()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.9
	mesh_inst.material_override = mat
	
	spray.add_child(mesh_inst)
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(spray)
		spray.global_position = nozzle.global_position
		
		var target_pos = target.global_position + Vector3(0, 0.35, 0)
		var tween = create_tween()
		tween.tween_property(spray, "global_position", target_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			apply_poison_hit(target, target_pos)
			spray.queue_free()
		)

func apply_poison_hit(target: Node3D, hit_pos: Vector3) -> void:
	var dmg_mult = 1.0 + (level - 1) * 0.45
	
	match poison_type:
		PoisonType.SLOW:
			if is_instance_valid(target) and target.has_method("apply_slow"):
				target.apply_slow(0.45, 3.5)
				target.take_damage(9.0 * dmg_mult)
		PoisonType.CORROSIVE:
			if is_instance_valid(target) and target.has_method("apply_corrosive_dot"):
				target.apply_corrosive_dot(14.0 * dmg_mult, 4.0)
				target.take_damage(16.0 * dmg_mult)
		PoisonType.MIST:
			var tree = get_tree()
			if tree:
				var enemies = tree.get_nodes_in_group("enemies")
				var blast_radius = 3.6
				for en in enemies:
					if is_instance_valid(en) and hit_pos.distance_to(en.global_position) <= blast_radius:
						en.take_damage(24.0 * dmg_mult)
						if en.has_method("apply_slow"):
							en.apply_slow(0.7, 2.0)

func take_damage(amount: float) -> void:
	if is_broken:
		return
	hp -= amount
	tower_damaged.emit(hp, max_hp)
	
	# Shudder/twitch no impacto de dano
	if visuals_standing:
		var tree = get_tree()
		if tree:
			var twitch_tween = tree.create_tween()
			var rand_offset = Vector3((randf() - 0.5) * 0.15, 0, (randf() - 0.5) * 0.15)
			twitch_tween.tween_property(visuals_standing, "position", rand_offset, 0.05)
			twitch_tween.tween_property(visuals_standing, "position", Vector3.ZERO, 0.08)
			
	update_damage_state()
	
	if hp <= 0.0:
		hp = 0.0
		is_broken = true
		collapse_tower()
		GameManager.notify("Uma torre de gravetos quebrou! Aproxime-se e repare (E).", Tokens.PERIGO)

func update_damage_state() -> void:
	var hp_pct = clampf(hp / max_hp, 0.0, 1.0)
	var danger_factor = 1.0 - hp_pct # 0.0 em 100% de vida, 1.0 quando destruída
	
	if broken_smoke:
		broken_smoke.visible = (hp_pct < 0.5)
		
	# Mudança progressiva de cor: a torre vai ficando cada vez mais vermelha conforme toma dano
	var target_red = Color(0.92, 0.15, 0.12, 1.0)
	for i in range(damage_materials.size()):
		if i < base_albedo_colors.size():
			var mat = damage_materials[i]
			var orig_col = base_albedo_colors[i]
			
			# Mistura a cor original da madeira/latão com vermelho de perigo
			mat.albedo_color = orig_col.lerp(target_red, danger_factor * 0.82)
			
			# Quando a torre está em estado crítico (< 40% de vida), ativa pulso de emissão vermelha
			if danger_factor > 0.4:
				mat.emission_enabled = true
				mat.emission = Color(0.95, 0.12, 0.08)
				mat.emission_energy_multiplier = (danger_factor - 0.4) * 2.2
			else:
				mat.emission_enabled = false

func collapse_tower() -> void:
	if visuals_standing: visuals_standing.visible = false
	if visuals_collapsed: visuals_collapsed.visible = true

func repair() -> bool:
	if not is_broken and hp >= max_hp:
		return try_upgrade()
		
	# Cost: 2 twigs
	if GameManager.consume_resources(2, 0, 0):
		hp = max_hp
		is_broken = false
		
		# Animate restoration of twigs from ground
		if visuals_collapsed: visuals_collapsed.visible = false
		if visuals_standing:
			visuals_standing.visible = true
			visuals_standing.scale = Vector3(0.3, 0.3, 0.3)
			var rebuild_tween = create_tween()
			rebuild_tween.tween_property(visuals_standing, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		update_damage_state()
		tower_damaged.emit(hp, max_hp)
		GameManager.notify("Torre restaurada com gravetos!", Tokens.VERDE_FOLHA)
		return true
	else:
		GameManager.notify("Você precisa de 2 gravetos para consertar a torre!", Tokens.PERIGO)
		return false

func try_upgrade() -> bool:
	if level >= 3:
		GameManager.notify("Torre já está no nível 3 (máximo)!", Tokens.CREME_PERGAMINHO)
		return false
	
	var cost_twigs = 4 if level == 1 else 6
	var cost_gears = 2 if level == 1 else 4
	
	if GameManager.consume_resources(cost_twigs, cost_gears, 0):
		level += 1
		max_hp += 45.0
		hp = max_hp
		update_level_visuals()
		update_poison_visual()
		level_upgraded.emit(level)
		
		# Upgrade scale pulse
		if visuals_standing:
			var up_tween = create_tween()
			up_tween.tween_property(visuals_standing, "scale", Vector3(1.2, 1.2, 1.2), 0.12)
			up_tween.tween_property(visuals_standing, "scale", Vector3.ONE, 0.15)
			
		GameManager.notify("Torre evoluída para Nível %d!" % level, Tokens.DOURADO_LUZ)
		return true
	else:
		GameManager.notify("Evolução requer: %d gravetos e %d engrenagens." % [cost_twigs, cost_gears], Tokens.PERIGO)
		return false
