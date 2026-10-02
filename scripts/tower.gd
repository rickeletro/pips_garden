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

var fire_rate: float = 0.8
var fire_timer: float = 0.0
var attack_range: float = 6.0

@onready var gear_mesh: MeshInstance3D = $Visuals/Gear
@onready var nozzle: Node3D = $Visuals/Nozzle
@onready var range_area: Area3D = $RangeArea
@onready var range_shape: CollisionShape3D = $RangeArea/CollisionShape3D
@onready var poison_vial: MeshInstance3D = $Visuals/PoisonVial
@onready var smoke_fx: MeshInstance3D = $Visuals/BrokenSmoke

var current_target: Node3D = null

func _ready() -> void:
	add_to_group("towers")
	hp = max_hp
	update_stats_by_level()
	update_poison_visual()
	if smoke_fx:
		smoke_fx.visible = false

func _process(delta: float) -> void:
	if is_broken:
		if gear_mesh:
			gear_mesh.rotation.y += delta * 0.2 # Slow stutter
		return
	
	# Rotate gear when working
	if gear_mesh:
		gear_mesh.rotation.y += delta * (4.0 if current_target else 1.0)
	
	fire_timer -= delta
	acquire_target()
	
	if current_target and is_instance_valid(current_target):
		# Aim nozzle towards target
		var dir = (current_target.global_position - nozzle.global_position).normalized()
		var target_y_rot = atan2(dir.x, dir.z)
		nozzle.rotation.y = lerp_angle(nozzle.rotation.y, target_y_rot, 12.0 * delta)
		
		if fire_timer <= 0.0:
			fire_poison(current_target)
			fire_timer = fire_rate

func update_stats_by_level() -> void:
	match level:
		1:
			attack_range = 6.0
			fire_rate = 0.85
		2:
			attack_range = 7.5
			fire_rate = 0.55
		3:
			attack_range = 9.0
			fire_rate = 0.35
			
	if range_shape and range_shape.shape is SphereShape3D:
		range_shape.shape.radius = attack_range

func update_poison_visual() -> void:
	if not poison_vial:
		return
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	match poison_type:
		PoisonType.SLOW:
			mat.albedo_color = Color(0.2, 0.7, 1.0) # Ice blue
		PoisonType.CORROSIVE:
			mat.albedo_color = Color(0.85, 0.2, 0.95) # Acid purple
		PoisonType.MIST:
			mat.albedo_color = Color(0.25, 0.95, 0.4) # Emerald mist
	poison_vial.material_override = mat

func cycle_poison_type() -> void:
	poison_type = ((poison_type + 1) % 3) as PoisonType
	update_poison_visual()
	var type_name = ""
	match poison_type:
		PoisonType.SLOW: type_name = "Veneno Lento (Cola e reduz velocidade)"
		PoisonType.CORROSIVE: type_name = "Veneno Corrosivo (Ácido ao longo do tempo)"
		PoisonType.MIST: type_name = "Névoa em Área (Explosão em nuvem)"
	GameManager.notify("Torre alterada para: %s" % type_name, Color(0.4, 0.9, 1.0))

func acquire_target() -> void:
	if current_target and is_instance_valid(current_target):
		if global_position.distance_to(current_target.global_position) <= attack_range:
			return # Keep current target
	
	current_target = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = attack_range
	for en in enemies:
		if is_instance_valid(en):
			var dist = global_position.distance_to(en.global_position)
			if dist < closest_dist:
				closest_dist = dist
				current_target = en

func fire_poison(target: Node3D) -> void:
	# Spawn visual poison spray projectile
	var spray = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25 if poison_type != PoisonType.MIST else 0.45
	sphere.height = sphere.radius * 2.0
	mesh_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	match poison_type:
		PoisonType.SLOW:
			mat.albedo_color = Color(0.2, 0.7, 1.0, 0.75)
		PoisonType.CORROSIVE:
			mat.albedo_color = Color(0.9, 0.15, 0.9, 0.75)
		PoisonType.MIST:
			mat.albedo_color = Color(0.3, 0.95, 0.45, 0.6)
			
	mesh_inst.material_override = mat
	spray.add_child(mesh_inst)
	get_parent().add_child(spray)
	spray.global_position = nozzle.global_position
	
	# Tween towards target
	var target_pos = target.global_position + Vector3(0, 0.3, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(spray, "global_position", target_pos, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		apply_poison_hit(target, target_pos)
		spray.queue_free()
	)

func apply_poison_hit(target: Node3D, hit_pos: Vector3) -> void:
	var dmg_mult = 1.0 + (level - 1) * 0.4
	
	match poison_type:
		PoisonType.SLOW:
			if is_instance_valid(target) and target.has_method("apply_slow"):
				target.apply_slow(0.45, 3.5)
				target.take_damage(8.0 * dmg_mult)
		PoisonType.CORROSIVE:
			if is_instance_valid(target) and target.has_method("apply_corrosive_dot"):
				target.apply_corrosive_dot(12.0 * dmg_mult, 4.0)
				target.take_damage(14.0 * dmg_mult)
		PoisonType.MIST:
			# Area of effect
			var enemies = get_tree().get_nodes_in_group("enemies")
			var blast_radius = 3.5
			for en in enemies:
				if is_instance_valid(en) and hit_pos.distance_to(en.global_position) <= blast_radius:
					en.take_damage(22.0 * dmg_mult)
					if en.has_method("apply_slow"):
						en.apply_slow(0.7, 2.0)

func take_damage(amount: float) -> void:
	if is_broken:
		return
	hp -= amount
	tower_damaged.emit(hp, max_hp)
	
	if hp <= 0.0:
		hp = 0.0
		is_broken = true
		if smoke_fx:
			smoke_fx.visible = true
		GameManager.notify("Uma torre quebrou! Repare-a com gravetos (E).", Color(1.0, 0.3, 0.3))

func repair() -> bool:
	if not is_broken and hp >= max_hp:
		# Check if can upgrade
		return try_upgrade()
		
	# Cost: 2 twigs
	if GameManager.consume_resources(2, 0, 0):
		hp = max_hp
		is_broken = false
		if smoke_fx:
			smoke_fx.visible = false
		GameManager.notify("Torre reparada e pronta para ação!", Color(0.3, 1.0, 0.4))
		tower_damaged.emit(hp, max_hp)
		return true
	else:
		GameManager.notify("Você precisa de 2 gravetos para consertar a torre!", Color(1.0, 0.4, 0.4))
		return false

func try_upgrade() -> bool:
	if level >= 3:
		GameManager.notify("Torre já está no nível máximo!", Color(0.9, 0.9, 0.9))
		return false
	
	var cost_twigs = 4 if level == 1 else 6
	var cost_gears = 2 if level == 1 else 4
	
	if GameManager.consume_resources(cost_twigs, cost_gears, 0):
		level += 1
		max_hp += 40.0
		hp = max_hp
		update_stats_by_level()
		level_upgraded.emit(level)
		GameManager.notify("Torre evoluída para Nível %d! Alcance e cadência aumentados!" % level, Color(1.0, 0.85, 0.2))
		
		# Visual upgrade: add extra gear or scale up
		if level >= 2 and gear_mesh:
			gear_mesh.scale = Vector3(1.3, 1.3, 1.3)
		return true
	else:
		GameManager.notify("Evolução requer: %d gravetos e %d engrenagens." % [cost_twigs, cost_gears], Color(1.0, 0.6, 0.3))
		return false
