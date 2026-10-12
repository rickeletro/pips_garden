extends StaticBody3D
class_name GardenTower

signal tower_damaged(current_hp: float, max_hp: float)
signal tower_destroyed
signal level_upgraded(new_level: int)

enum PoisonType { SLOW, CORROSIVE, MIST }
enum Specialization { NONE, THORN_CANNON, SAP_CATAPULT }
enum TowerState { IDLE_SEARCHING, ATTACKING, COLLAPSED }

@export var tower_data: TowerData = null
@export var poison_type: PoisonType = PoisonType.SLOW
@export var level: int = 1
@export var specialization: Specialization = Specialization.NONE
@export var max_hp: float = 100.0

var current_state: TowerState = TowerState.IDLE_SEARCHING
var hp: float = 100.0

var is_broken: bool:
	get: return current_state == TowerState.COLLAPSED
	set(val):
		if val:
			change_state(TowerState.COLLAPSED)
		else:
			change_state(TowerState.IDLE_SEARCHING)

var fire_rate: float = 1.25 # 0.8 disparos/s (1.25s intervalo)
var fire_timer: float = 0.0
var target_search_timer: float = 0.0
var attack_range: float = 4.5
var base_damage: float = 15.0
var armor_pierce: float = 0.0

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

# Cached static poison materials and projectile meshes
static var poison_mats: Dictionary = {}
static var projectile_mesh_standard: SphereMesh = null
static var projectile_mesh_mist: SphereMesh = null
static var projectile_mesh_spike: CylinderMesh = null
static var projectile_mesh_sap: SphereMesh = null

func _ready() -> void:
	add_to_group("towers")
	if tower_data:
		level = tower_data.level
		base_damage = tower_data.damage_per_shot
		fire_rate = tower_data.attack_interval
		attack_range = tower_data.range_radius
		armor_pierce = tower_data.armor_pierce
		specialization = tower_data.specialization as Specialization
	hp = max_hp
	_init_static_resources()
	setup_damage_materials()
	update_level_visuals()
	update_poison_visual()
	update_damage_state()

func _init_static_resources() -> void:
	if poison_mats.is_empty():
		for p_type in [PoisonType.SLOW, PoisonType.CORROSIVE, PoisonType.MIST]:
			var col = Tokens.VENENO_AMBAR
			match p_type:
				PoisonType.SLOW: col = Tokens.VENENO_AMBAR
				PoisonType.CORROSIVE: col = Tokens.VENENO_VERDE
				PoisonType.MIST: col = Tokens.VENENO_VIOLETA
				
			var mat = StandardMaterial3D.new()
			mat.albedo_color = col
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 0.85
			mat.roughness = 0.25
			poison_mats[p_type] = mat
			
		projectile_mesh_standard = SphereMesh.new()
		projectile_mesh_standard.radius = 0.18
		projectile_mesh_standard.height = 0.36
		projectile_mesh_standard.radial_segments = 8
		projectile_mesh_standard.rings = 4
		
		projectile_mesh_mist = SphereMesh.new()
		projectile_mesh_mist.radius = 0.42
		projectile_mesh_mist.height = 0.84
		projectile_mesh_mist.radial_segments = 8
		projectile_mesh_mist.rings = 4
		
		projectile_mesh_spike = CylinderMesh.new()
		projectile_mesh_spike.top_radius = 0.02
		projectile_mesh_spike.bottom_radius = 0.08
		projectile_mesh_spike.height = 0.65
		projectile_mesh_spike.radial_segments = 6
		
		projectile_mesh_sap = SphereMesh.new()
		projectile_mesh_sap.radius = 0.32
		projectile_mesh_sap.height = 0.64
		projectile_mesh_sap.radial_segments = 8
		projectile_mesh_sap.rings = 5

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
	target_search_timer -= delta
	if target_search_timer <= 0.0 or current_target == null or not is_instance_valid(current_target):
		acquire_target()
		target_search_timer = 0.12
	
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
			attack_range = 4.5
			fire_rate = 1.25 # 0.8 tiros/s (DPS Base: 12.0)
			base_damage = 15.0
			armor_pierce = 0.0
		2:
			attack_range = 5.5
			fire_rate = 0.909 # 1.1 tiros/s (DPS Base: 39.6)
			base_damage = 18.0
			armor_pierce = 0.0
		3:
			if specialization == Specialization.SAP_CATAPULT:
				attack_range = 5.0
				fire_rate = 1.667 # 0.6 tiros/s (DPS Base: 21.0 Área)
				base_damage = 35.0
				armor_pierce = 0.0
			else:
				specialization = Specialization.THORN_CANNON
				attack_range = 7.0
				fire_rate = 2.0 # 0.5 tiros/s (DPS Base: 55.0 Perfuração)
				base_damage = 110.0
				armor_pierce = 0.5
			
	if range_shape and range_shape.shape is SphereShape3D:
		range_shape.shape.radius = attack_range

func get_poison_color() -> Color:
	match poison_type:
		PoisonType.SLOW: return Tokens.VENENO_AMBAR      # Âmbar (Mel lento)
		PoisonType.CORROSIVE: return Tokens.VENENO_VERDE # Verde (Ácido corrosivo)
		PoisonType.MIST: return Tokens.VENENO_VIOLETA    # Violeta (Névoa em área)
	return Tokens.VENENO_AMBAR

func update_poison_visual() -> void:
	var mat = poison_mats.get(poison_type, null)
	if poison_liquid and mat:
		poison_liquid.material_override = mat
		
	# Update nozzle tip
	if nozzle and nozzle.has_node("TipRing") and mat:
		var tip = nozzle.get_node("TipRing") as MeshInstance3D
		if tip:
			tip.material_override = mat

func cycle_poison_type() -> void:
	poison_type = ((poison_type + 1) % 3) as PoisonType
	update_poison_visual()
	var type_name = ""
	var col = get_poison_color()
	match poison_type:
		PoisonType.SLOW: type_name = "Veneno Âmbar (35% de lentidão por 3.5s)"
		PoisonType.CORROSIVE: type_name = "Veneno Verde (6 dano/s por 4s = 24 dano garantido)"
		PoisonType.MIST: type_name = "Névoa Violeta (Explosão de 2m com 40% dano base)"
	GameManager.notify("Torre alterada para: %s" % type_name, col)

func acquire_target() -> void:
	if current_target and is_instance_valid(current_target):
		if global_position.distance_to(current_target.global_position) <= attack_range:
			if current_target is BossMoth and current_target.global_position.y > 3.0:
				current_target = null
			else:
				return
		else:
			current_target = null
	
	current_target = null
	var tree = get_tree()
	if not tree:
		return
	var enemies = tree.get_nodes_in_group("enemies")
	var closest_dist = attack_range
	for en in enemies:
		if is_instance_valid(en):
			# Mariposa em voo alto não pode ser alvejada pelas torres
			if en is BossMoth and en.global_position.y > 3.0:
				continue
			var dist = global_position.distance_to(en.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = en

func fire_poison(target: Node3D) -> void:
	SoundManager.play_sparkle()
		
	# Acorn tank squashes and pulses on pump
	if acorn_tank:
		var pump_tween = create_tween()
		pump_tween.tween_property(acorn_tank, "scale", Vector3(1.25, 0.82, 1.25), 0.08)
		pump_tween.tween_property(acorn_tank, "scale", Vector3.ONE, 0.12)
	
	_spawn_single_projectile(target)
	
	# Torre Nv 2 dispara 2 projéteis consecutivos
	if level == 2:
		var tree = get_tree()
		if tree:
			var second_shot_timer = tree.create_timer(0.12)
			second_shot_timer.timeout.connect(func():
				if is_instance_valid(self) and not is_broken and is_instance_valid(target):
					_spawn_single_projectile(target)
			)

func _spawn_single_projectile(target: Node3D) -> void:
	var mesh: Mesh = projectile_mesh_standard
	var rot_x: float = 0.0
	
	if level == 3 and specialization == Specialization.THORN_CANNON:
		mesh = projectile_mesh_spike
		rot_x = 90.0
	elif level == 3 and specialization == Specialization.SAP_CATAPULT:
		mesh = projectile_mesh_sap
	elif poison_type == PoisonType.MIST:
		mesh = projectile_mesh_mist
		
	var mat = poison_mats.get(poison_type, null)
	var start_pos = nozzle.global_position
	var target_pos = target.global_position + Vector3(0, 0.35, 0)
	
	if NodePool:
		NodePool.spawn_projectile(
			start_pos,
			target_pos,
			0.16,
			mesh,
			mat,
			rot_x,
			func(): apply_poison_hit(target, target_pos)
		)
	else:
		var spray = Node3D.new()
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = mesh
		mesh_inst.rotation_degrees.x = rot_x
		mesh_inst.material_override = mat
		spray.add_child(mesh_inst)
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(spray)
			spray.global_position = start_pos
			var tween = create_tween()
			tween.tween_property(spray, "global_position", target_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func():
				apply_poison_hit(target, target_pos)
				spray.queue_free()
			)

func apply_poison_hit(target: Node3D, hit_pos: Vector3) -> void:
	var final_dmg = base_damage
	
	# 1. Aplicação do Dano Direto / Splash
	if level == 3 and specialization == Specialization.SAP_CATAPULT:
		# Catapulta de Seiva: Dano Splash 2.5m + Poça de Seiva
		var tree = get_tree()
		if tree:
			var enemies = tree.get_nodes_in_group("enemies")
			for en in enemies:
				if is_instance_valid(en) and hit_pos.distance_to(en.global_position) <= 2.5:
					if en.has_method("take_damage"):
						en.take_damage(final_dmg, Vector3.ZERO, false, armor_pierce)
					if en.has_method("apply_slow"):
						en.apply_slow(0.85, 3.0) # 15% slow da seiva
			_spawn_sap_puddle_fx(hit_pos)
	else:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(final_dmg, Vector3.ZERO, false, armor_pierce)
			
	# 2. Aplicação dos Multiplicadores de Veneno
	match poison_type:
		PoisonType.SLOW:
			# 🟢 Letárgico: Reduz velocidade em 35% por 3.5s (acumula com grama 40% -> 0.60 * 0.65 = 0.39)
			if is_instance_valid(target) and target.has_method("apply_slow"):
				target.apply_slow(0.65, 3.5)
		PoisonType.CORROSIVE:
			# 🧪 Ácido: 6 dano por segundo por 4s (24 dano total garantido, ignora armadura)
			if is_instance_valid(target) and target.has_method("apply_corrosive_dot"):
				target.apply_corrosive_dot(6.0, 4.0)
		PoisonType.MIST:
			# 🟣 Névoa de Esporos: Nuvem de 2.0m causando 40% do dano base do projétil aos adjacentes
			var tree = get_tree()
			if tree:
				var enemies = tree.get_nodes_in_group("enemies")
				for en in enemies:
					if is_instance_valid(en) and en != target and hit_pos.distance_to(en.global_position) <= 2.0:
						if en.has_method("take_damage"):
							en.take_damage(final_dmg * 0.40, Vector3.ZERO, false, armor_pierce)
						if en.has_method("apply_slow"):
							en.apply_slow(0.80, 2.0)

func _spawn_sap_puddle_fx(pos: Vector3) -> void:
	if NodePool:
		NodePool.spawn_puddle_fx(pos, Color(0.92, 0.65, 0.15, 0.65), 1.3, 2.5)
		return
		
	var parent_node = get_parent()
	if not parent_node:
		return
	var puddle = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.3
	cyl.height = 0.04
	puddle.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.92, 0.65, 0.15, 0.65)
	mat.roughness = 0.1
	puddle.material_override = mat
	parent_node.add_child(puddle)
	puddle.global_position = Vector3(pos.x, 0.05, pos.z)
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_interval(2.5)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(puddle.queue_free)

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

var collapse_count: int = 0

func change_state(new_state: TowerState) -> void:
	current_state = new_state
	match current_state:
		TowerState.COLLAPSED:
			if visuals_standing: visuals_standing.visible = false
			if visuals_collapsed: visuals_collapsed.visible = true
			if has_node("CollisionShape3D"):
				$CollisionShape3D.disabled = true
			if GameManager.grid_manager and GameManager.grid_manager.has_method("on_tower_broken"):
				GameManager.grid_manager.on_tower_broken(global_position)
			if GameEvents:
				GameEvents.tower_collapsed.emit(self)
		TowerState.IDLE_SEARCHING, TowerState.ATTACKING:
			if visuals_standing: visuals_standing.visible = true
			if visuals_collapsed: visuals_collapsed.visible = false
			if has_node("CollisionShape3D"):
				$CollisionShape3D.disabled = false
			if GameManager.grid_manager and GameManager.grid_manager.has_method("on_tower_restored"):
				GameManager.grid_manager.on_tower_restored(global_position)

func collapse_tower() -> void:
	collapse_count += 1
	change_state(TowerState.COLLAPSED)

func repair(free_repair: bool = false) -> bool:
	if not free_repair and not is_broken and hp >= max_hp:
		if level >= 2:
			GameManager.request_tower_specialization_dialog.emit(self)
			return true
		return try_upgrade()
		
	# Caso 1: Reparo Preventivo (Torre em pé com dano parcial)
	if not is_broken:
		if free_repair or GameManager.consume_resources(2, 0, 0):
			hp = max_hp
			update_damage_state()
			tower_damaged.emit(hp, max_hp)
			GameManager.notify("Torre reparada preventivamente! (2 gravetos)", Tokens.VERDE_FOLHA)
			return true
		else:
			GameManager.notify("Reparo preventivo requer 2 gravetos!", Tokens.PERIGO)
			return false
			
	# Caso 2: Reerguer Torre Caída (Destruída)
	# Custo: 4 Gravetos + 1 Engrenagem (+2 Gravetos por colapso sucessivo)
	var rebuild_twigs = 4 + max(0, collapse_count - 1) * 2
	var rebuild_gears = 1
	
	if free_repair or GameManager.consume_resources(rebuild_twigs, rebuild_gears, 0):
		hp = 100.0
		max_hp = 100.0
		level = 1
		specialization = Specialization.NONE
		is_broken = false
		
		if has_node("CollisionShape3D"):
			$CollisionShape3D.disabled = false
		if GameManager.grid_manager and GameManager.grid_manager.has_method("on_tower_repaired"):
			GameManager.grid_manager.on_tower_repaired(global_position)
		
		# Animate restoration of twigs from ground
		if visuals_collapsed: visuals_collapsed.visible = false
		if visuals_standing:
			visuals_standing.visible = true
			visuals_standing.scale = Vector3(0.3, 0.3, 0.3)
			var rebuild_tween = create_tween()
			rebuild_tween.tween_property(visuals_standing, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		update_level_visuals()
		update_poison_visual()
		update_damage_state()
		tower_damaged.emit(hp, max_hp)
		level_upgraded.emit(level)
		GameManager.notify("Torre reerguida das ruínas! (Nv 1 restaurado)", Tokens.VERDE_FOLHA)
		return true
	else:
		GameManager.notify("Reerguer torre caída requer %d gravetos e %d engrenagem!" % [rebuild_twigs, rebuild_gears], Tokens.PERIGO)
		return false

func try_upgrade(target_spec: Specialization = Specialization.NONE) -> bool:
	if level >= 3:
		# Se já for nível 3, permite alternar a especialização entre Canhão de Espinho e Catapulta de Seiva
		toggle_specialization()
		return false
	
	# Curva Exponencial Suave v1.0:
	# Nível 1 -> Nível 2: 6 Gravetos, 4 Engrenagens
	# Nível 2 -> Nível 3: 12 Gravetos, 8 Engrenagens
	var cost_twigs = 6 if level == 1 else 12
	var cost_gears = 4 if level == 1 else 8
	
	if GameManager.consume_resources(cost_twigs, cost_gears, 0):
		level += 1
		max_hp += 50.0
		hp = max_hp
		if level == 3:
			if target_spec != Specialization.NONE:
				specialization = target_spec
			else:
				specialization = Specialization.THORN_CANNON # Padrão 3A Canhão Espinho
				
		update_level_visuals()
		update_poison_visual()
		level_upgraded.emit(level)
		
		# Upgrade scale pulse
		if visuals_standing:
			var up_tween = create_tween()
			up_tween.tween_property(visuals_standing, "scale", Vector3(1.2, 1.2, 1.2), 0.12)
			up_tween.tween_property(visuals_standing, "scale", Vector3.ONE, 0.15)
			
		var spec_name = "Nível %d" % level
		if level == 3:
			spec_name = "Nv 3A: Canhão de Espinho (Alvo Único / Perfuração 50%)" if specialization == Specialization.THORN_CANNON else "Nv 3B: Catapulta de Seiva (Área 2.5m / Poça de Seiva)"
		GameManager.notify("Torre evoluída para: %s!" % spec_name, Tokens.DOURADO_LUZ)
		return true
	else:
		GameManager.notify("Evolução requer: %d gravetos e %d engrenagens." % [cost_twigs, cost_gears], Tokens.PERIGO)
		return false

func toggle_specialization() -> void:
	if level < 3:
		return
	if specialization == Specialization.THORN_CANNON:
		specialization = Specialization.SAP_CATAPULT
	else:
		specialization = Specialization.THORN_CANNON
	update_level_visuals()
	var spec_name = "Nv 3A: Canhão de Espinho" if specialization == Specialization.THORN_CANNON else "Nv 3B: Catapulta de Seiva"
	GameManager.notify("Especialização alterada para: %s" % spec_name, Tokens.DOURADO_LUZ)

