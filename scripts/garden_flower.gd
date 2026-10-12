extends StaticBody3D
class_name GardenFlower

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")

@onready var visuals: Node3D = $Visuals
@onready var petals: Node3D = $Visuals/Petals
@onready var pollen_core: MeshInstance3D = $Visuals/PollenCore
@onready var stem: MeshInstance3D = $Visuals/Stem

var sprite_25d: DirectionalSprite3D = null

var petal_materials: Array[StandardMaterial3D] = []
var core_material: StandardMaterial3D = null
var stem_material: StandardMaterial3D = null

var base_petal_color: Color = Color(0.92, 0.25, 0.38, 1.0) # Rosa vibrante inicial
const TARGET_PETAL_RED: Color = Color(0.82, 0.06, 0.10, 1.0) # Vermelho sangue / murcho
var base_core_color: Color = Color(1.0, 0.82, 0.15, 1.0)   # Dourado pólen
const TARGET_CORE_RED: Color = Color(0.85, 0.25, 0.05, 1.0)  # Laranja avermelhado
const BASE_STEM_COLOR: Color = Color(0.20, 0.55, 0.22, 1.0)  # Verde caule
const TARGET_STEM_COLOR: Color = Color(0.42, 0.26, 0.16, 1.0) # Caule ressecado

var evolved_leaf: Node3D = null
var evolution_level: int = 0

var current_hydration_pct: float = 1.0
var thirst_badge: Node3D = null

func _ready() -> void:
	add_to_group("flower")
	GameManager.flower = self
	GameManager.flower_stats_changed.connect(_on_flower_stats_changed)
	GameManager.flower_hydration_changed.connect(_on_flower_hydration_changed)
	setup_flower_materials()
	_setup_thirst_badge()
	_setup_sprite_25d()
	update_damage_color(GameManager.flower_hp, GameManager.flower_max_hp)

func _setup_sprite_25d() -> void:
	var flower_dir = "res://textures/sprites/environment/sacred_flower"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(flower_dir)):
		sprite_25d = DirectionalSprite3D.new()
		sprite_25d.name = "Sprite25D"
		# Escala 2x aumentada: 128 * 0.032 = ~4.1m de altura visual
		sprite_25d.sprite_pixel_size = 0.032
		sprite_25d.sprite_offset_y = 2.05
		sprite_25d.shadow_scale = Vector3(3.2, 3.2, 3.2)
		add_child(sprite_25d)
		sprite_25d.load_sprites_from_dir(flower_dir)
		sprite_25d.play("idle", true, 6.0)
		
		# Oculta malhas 3D procedurais preservando a hierarquia de nós
		if visuals:
			for m in visuals.find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).visible = false

func _setup_thirst_badge() -> void:
	thirst_badge = Node3D.new()
	thirst_badge.name = "ThirstAlertBadge"
	thirst_badge.position = Vector3(0, 3.4, 0)
	thirst_badge.visible = false
	add_child(thirst_badge)
	
	var drop_icon = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.22
	sph.height = 0.42
	drop_icon.mesh = sph
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.75, 1.0, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.85, 1.0)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_icon.material_override = mat
	thirst_badge.add_child(drop_icon)

func _on_flower_hydration_changed(hydration: float, max_hydration: float) -> void:
	current_hydration_pct = clampf(hydration / max_hydration, 0.0, 1.0)
	if thirst_badge:
		thirst_badge.visible = (current_hydration_pct < 0.45)
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
					dup.emission_enabled = true
					dup.emission_energy_multiplier = 0.0
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
	if visuals and visuals.visible:
		visuals.rotation.z = sin(time * 1.5) * 0.04
		visuals.rotation.x = cos(time * 1.2) * 0.03
	if petals:
		petals.rotation.y += delta * 0.15
	if thirst_badge and thirst_badge.visible:
		thirst_badge.position.y = 3.8 + sin(time * 3.0) * 0.12
		thirst_badge.rotation.y += delta * 1.2
	if sprite_25d:
		# Respiração sutil pastoral estilo Ghibli
		var breathe = 1.0 + sin(time * 1.8) * 0.02
		sprite_25d.scale = Vector3(breathe, 2.0 - breathe, breathe)

func _on_flower_stats_changed(current_hp: float, max_hp: float) -> void:
	update_damage_color(current_hp, max_hp)

func update_damage_color(current_hp: float, max_hp: float) -> void:
	if max_hp <= 0.0:
		return
	var hp_pct = clampf(current_hp / max_hp, 0.0, 1.0)
	var danger_factor = 1.0 - hp_pct # 0.0 = 100% vida, 1.0 = destruída
	
	# Efeito dinâmico no sprite 2.5D
	if sprite_25d and sprite_25d.sprite:
		var tint: Color
		if evolution_level > 0:
			tint = Color(1.12, 0.96, 1.08).lerp(Color(0.85, 0.30, 0.30), danger_factor * 0.8)
		else:
			tint = Color(1.0, 1.0, 1.0).lerp(Color(0.72, 0.32, 0.32), danger_factor * 0.85)
			if current_hydration_pct < 0.45:
				tint = tint.lerp(Color(0.70, 0.60, 0.45), 0.35)
		sprite_25d.sprite.modulate = tint
	
	# 1. As pétalas vão ficando gradativamente mais vermelhas e escuras
	for mat in petal_materials:
		mat.albedo_color = base_petal_color.lerp(TARGET_PETAL_RED, danger_factor * 0.88)
		if danger_factor > 0.35:
			mat.emission = Color(0.95, 0.08, 0.08)
			mat.emission_energy_multiplier = (danger_factor - 0.35) * 2.5
		elif evolution_level > 0:
			mat.emission = Color(1.0, 0.5, 0.8)
			mat.emission_energy_multiplier = 0.35
		else:
			mat.emission_energy_multiplier = 0.0
			
	# 2. O núcleo de pólen
	if core_material:
		core_material.albedo_color = base_core_color.lerp(TARGET_CORE_RED, danger_factor * 0.85)
		core_material.emission = base_core_color.lerp(Color(1.0, 0.15, 0.05), danger_factor)
		core_material.emission_energy_multiplier = 0.6 + danger_factor * 0.8
		
	# 3. O caule (leva em conta HP e desidratação)
	var dryness = (1.0 - current_hydration_pct) * 0.5
	var combined_stem_factor = clampf(danger_factor * 0.6 + dryness, 0.0, 1.0)
	if stem_material:
		stem_material.albedo_color = BASE_STEM_COLOR.lerp(TARGET_STEM_COLOR, combined_stem_factor)
		
	# 4. Inclinação e murchamento das pétalas
	if petals:
		var total_droop = clampf(danger_factor * 0.6 + dryness * 0.4, 0.0, 1.0)
		petals.position.y = 2.05 - total_droop * 0.28
		petals.scale = Vector3.ONE.lerp(Vector3(1.12, 0.72, 1.12), total_droop)

func apply_fairy_tear() -> void:
	evolution_level += 1
	
	# 1. Recupera 60% da vida máxima
	var heal_amt = GameManager.flower_max_hp * 0.60
	GameManager.heal_flower(heal_amt)
	
	# 2. Aumenta vida máxima em +10%
	GameManager.flower_max_hp *= 1.10
	GameManager.flower_stats_changed.emit(GameManager.flower_hp, GameManager.flower_max_hp)
	
	# 3. Ganha nova cor perolada/magenta luminosa
	base_petal_color = Color(1.0, 0.38, 0.68, 1.0) # Nova cor encantada
	base_core_color = Color(1.0, 0.92, 0.35, 1.0)
	
	# 4. Cria e faz brotar uma nova folha viçosa no caule
	spawn_evolved_leaf()
	
	# 5. Efeito visual e sonoro triunfante
	SoundManager.play_fairy_dust(-2.0)
		
	if visuals:
		var tween = create_tween()
		tween.tween_property(visuals, "scale", Vector3(1.3, 1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(visuals, "scale", Vector3.ONE, 0.35)
		
	if sprite_25d:
		var spr_tween = create_tween()
		spr_tween.tween_property(sprite_25d, "scale", Vector3(1.35, 1.35, 1.35), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		spr_tween.tween_property(sprite_25d, "scale", Vector3.ONE, 0.4)
		sprite_25d.flash_hit(Color(1.6, 2.2, 1.6, 1.0), 0.45)
		
	update_damage_color(GameManager.flower_hp, GameManager.flower_max_hp)
	GameManager.notify("🌸 A Flor do Jardim Evoluiu! +60% de Vida, +10% Max HP e Nova Folha!", Color(0.4, 1.0, 0.7))

func spawn_evolved_leaf() -> void:
	if evolved_leaf:
		evolved_leaf.queue_free()
		
	evolved_leaf = Node3D.new()
	evolved_leaf.name = "EvolvedLeaf"
	
	var leaf_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.65, 0.08, 1.35)
	leaf_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.albedo_color = Color(0.22, 0.75, 0.35, 1.0) # Verde esmeralda vivo
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.4)
	mat.emission_energy_multiplier = 0.3
	leaf_mesh.material_override = mat
	
	leaf_mesh.position = Vector3(0.45, 0.85, 0.2)
	leaf_mesh.rotation_degrees = Vector3(15.0, 45.0, -25.0)
	evolved_leaf.add_child(leaf_mesh)
	
	if visuals:
		visuals.add_child(evolved_leaf)
		evolved_leaf.scale = Vector3(0.01, 0.01, 0.01)
		var tween = create_tween()
		tween.tween_property(evolved_leaf, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func take_damage(amount: float) -> void:
	GameManager.damage_flower(amount)
	
	if sprite_25d:
		sprite_25d.flash_hit(Color(2.2, 0.4, 0.4, 1.0), 0.16)
		var spr_tree = get_tree()
		if spr_tree:
			var tween = spr_tree.create_tween()
			var shake_x = (randf() - 0.5) * 0.15
			tween.tween_property(sprite_25d, "position", Vector3(shake_x, 0, 0), 0.05)
			tween.tween_property(sprite_25d, "position", Vector3.ZERO, 0.1)
	
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
