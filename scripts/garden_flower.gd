extends StaticBody3D
class_name GardenFlower

@onready var visuals: Node3D = $Visuals
@onready var petals: Node3D = $Visuals/Petals
@onready var pollen_core: MeshInstance3D = $Visuals/PollenCore
@onready var stem: MeshInstance3D = $Visuals/Stem

var petal_materials: Array[StandardMaterial3D] = []
var core_material: StandardMaterial3D = null
var stem_material: StandardMaterial3D = null

const BASE_PETAL_COLOR: Color = Color(0.92, 0.25, 0.38, 1.0) # Rosa vibrante
const TARGET_PETAL_RED: Color = Color(0.82, 0.06, 0.10, 1.0) # Vermelho sangue / murcho
const BASE_CORE_COLOR: Color = Color(1.0, 0.82, 0.15, 1.0)   # Dourado pólen
const TARGET_CORE_RED: Color = Color(0.85, 0.25, 0.05, 1.0)  # Laranja avermelhado abrasador
const BASE_STEM_COLOR: Color = Color(0.20, 0.55, 0.22, 1.0)  # Verde caule
const TARGET_STEM_COLOR: Color = Color(0.42, 0.26, 0.16, 1.0) # Caule ressecado / escuro

func _ready() -> void:
	add_to_group("flower")
	GameManager.flower = self
	GameManager.flower_stats_changed.connect(_on_flower_stats_changed)
	setup_flower_materials()
	update_damage_color(GameManager.flower_hp, GameManager.flower_max_hp)

func setup_flower_materials() -> void:
	petal_materials.clear()
	if petals:
		for p in petals.get_children():
			var mesh_inst = p as MeshInstance3D
			if mesh_inst:
				var orig_mat = mesh_inst.get_active_material(0)
				if orig_mat is StandardMaterial3D:
					var dup = orig_mat.duplicate() as StandardMaterial3D
					mesh_inst.material_override = dup
					petal_materials.append(dup)
					
	if pollen_core:
		var orig_core = pollen_core.get_active_material(0)
		if orig_core is StandardMaterial3D:
			core_material = orig_core.duplicate() as StandardMaterial3D
			pollen_core.material_override = core_material
			
	if stem:
		var orig_stem = stem.get_active_material(0)
		if orig_stem is StandardMaterial3D:
			stem_material = orig_stem.duplicate() as StandardMaterial3D
			stem.material_override = stem_material

func _process(delta: float) -> void:
	# Suave balanço ao vento
	var time = Time.get_ticks_msec() * 0.001
	if visuals:
		visuals.rotation.z = sin(time * 1.5) * 0.04
		visuals.rotation.x = cos(time * 1.2) * 0.03
	if petals:
		petals.rotation.y += delta * 0.15

func _on_flower_stats_changed(current_hp: float, max_hp: float) -> void:
	update_damage_color(current_hp, max_hp)

func update_damage_color(current_hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var hp_pct = clampf(current_hp / max_hp, 0.0, 1.0)
	var danger_factor = 1.0 - hp_pct # 0.0 = 100% vida, 1.0 = destruída
	
	# 1. As pétalas vão ficando gradativamente mais vermelhas e escuras
	for mat in petal_materials:
		mat.albedo_color = BASE_PETAL_COLOR.lerp(TARGET_PETAL_RED, danger_factor * 0.88)
		if danger_factor > 0.35:
			mat.emission_enabled = true
			mat.emission = Color(0.95, 0.08, 0.08)
			mat.emission_energy_multiplier = (danger_factor - 0.35) * 2.5
		else:
			mat.emission_enabled = false
			
	# 2. O núcleo de pólen perde o brilho dourado e queima em tom avermelhado
	if core_material:
		core_material.albedo_color = BASE_CORE_COLOR.lerp(TARGET_CORE_RED, danger_factor * 0.85)
		core_material.emission = BASE_CORE_COLOR.lerp(Color(1.0, 0.15, 0.05), danger_factor)
		core_material.emission_energy_multiplier = 0.6 + danger_factor * 0.8
		
	# 3. O caule resseca
	if stem_material:
		stem_material.albedo_color = BASE_STEM_COLOR.lerp(TARGET_STEM_COLOR, danger_factor * 0.75)
		
	# 4. Inclinação e murchamento das pétalas conforme perde vida
	if petals:
		petals.position.y = 2.05 - danger_factor * 0.28
		petals.scale = Vector3.ONE.lerp(Vector3(1.12, 0.72, 1.12), danger_factor * 0.6)

func take_damage(amount: float) -> void:
	GameManager.damage_flower(amount)
	
	# Twitch / shudder no impacto de dano
	if visuals:
		var tree = get_tree()
		if tree:
			var tween = tree.create_tween()
			var shake_x = (randf() - 0.5) * 0.2
			var shake_z = (randf() - 0.5) * 0.2
			tween.tween_property(visuals, "scale", Vector3(1.22, 0.78, 1.22), 0.06)
			tween.parallel().tween_property(visuals, "position", Vector3(shake_x, 0, shake_z), 0.06)
			tween.tween_property(visuals, "scale", Vector3.ONE, 0.12)
			tween.parallel().tween_property(visuals, "position", Vector3.ZERO, 0.12)
