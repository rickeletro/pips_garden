extends StaticBody3D
class_name GardenFlower

const DirectionalSprite3D = preload("res://scripts/directional_sprite_3d.gd")

@onready var visuals: Node3D = $Visuals
@onready var petals: Node3D = $Visuals/Petals
@onready var pollen_core: MeshInstance3D = $Visuals/PollenCore
@onready var stem: MeshInstance3D = $Visuals/Stem

var sprite_25d: DirectionalSprite3D = null

# Estrutura 3D Volumétrica da Sakura com Alpha Map
var sakura_root: Node3D = null
var top_blossom_node: Node3D = null
var sakura_stem_mat: StandardMaterial3D = null
var sakura_crown_mat: StandardMaterial3D = null
var sakura_particles: CPUParticles3D = null

var petal_materials: Array[StandardMaterial3D] = []
var core_material: StandardMaterial3D = null
var stem_material: StandardMaterial3D = null

var base_petal_color: Color = Color(1.0, 1.0, 1.0, 1.0)
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
	_setup_sakura_volume_3d()
	_setup_thirst_badge()
	_setup_sprite_25d()
	update_damage_color(GameManager.flower_hp, GameManager.flower_max_hp)

func _setup_sakura_volume_3d() -> void:
	# Oculta primitivos geométricos antigos da cena original preservando hierarquia
	if visuals:
		for m in visuals.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).visible = false

	sakura_root = Node3D.new()
	sakura_root.name = "SakuraVolume3D"
	add_child(sakura_root)

	# 1. Material da Planta e Folhagem com Alpha Map (Alpha Scissor + Normal Map)
	sakura_stem_mat = StandardMaterial3D.new()
	sakura_stem_mat.albedo_texture = preload("res://textures/environment/sakura_flower_albedo.png")
	sakura_stem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	sakura_stem_mat.alpha_scissor_threshold = 0.42
	sakura_stem_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sakura_stem_mat.normal_enabled = true
	sakura_stem_mat.normal_texture = preload("res://textures/environment/sakura_flower_normal.png")
	sakura_stem_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sakura_stem_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	sakura_stem_mat.rim_enabled = true
	sakura_stem_mat.rim = 0.5
	sakura_stem_mat.rim_tint = 0.35
	sakura_stem_mat.roughness = 0.45

	# 2. Material da Coroa Superior de Pétalas Abertas (Top Blossom)
	sakura_crown_mat = StandardMaterial3D.new()
	sakura_crown_mat.albedo_texture = preload("res://textures/environment/sakura_blossom_top_albedo.png")
	sakura_crown_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	sakura_crown_mat.alpha_scissor_threshold = 0.42
	sakura_crown_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sakura_crown_mat.normal_enabled = true
	sakura_crown_mat.normal_texture = preload("res://textures/environment/sakura_blossom_top_normal.png")
	sakura_crown_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sakura_crown_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	sakura_crown_mat.rim_enabled = true
	sakura_crown_mat.rim = 0.6
	sakura_crown_mat.rim_tint = 0.4
	sakura_crown_mat.emission_enabled = true
	sakura_crown_mat.emission = Color(1.0, 0.88, 0.35)
	sakura_crown_mat.emission_energy_multiplier = 0.3
	sakura_crown_mat.roughness = 0.4

	# 3. Planos Cruzados Verticais em Estrela (3-Way Cross Cards para volume 3D em 360°)
	var cross_angles = [0.0, deg_to_rad(60.0), deg_to_rad(120.0)]
	var stem_quad = QuadMesh.new()
	stem_quad.size = Vector2(3.1, 4.0)

	for ang in cross_angles:
		var p_mesh = MeshInstance3D.new()
		p_mesh.mesh = stem_quad
		p_mesh.material_override = sakura_stem_mat
		p_mesh.position = Vector3(0, 2.0, 0)
		p_mesh.rotation.y = ang
		p_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		sakura_root.add_child(p_mesh)

	# 4. Coroa Superior com Flor de Sakura Desabrochada (Top Blossom Angled)
	top_blossom_node = Node3D.new()
	top_blossom_node.name = "TopBlossomCrown"
	top_blossom_node.position = Vector3(0, 2.45, 0)
	# Inclinada a -35° no eixo X alinhada ao pitch da câmera isométrica
	top_blossom_node.rotation_degrees.x = -35.0
	sakura_root.add_child(top_blossom_node)

	var crown_quad = QuadMesh.new()
	crown_quad.size = Vector2(2.4, 2.4)

	# Camada 1: Pétalas e cálice aberto
	var crown_mesh1 = MeshInstance3D.new()
	crown_mesh1.mesh = crown_quad
	crown_mesh1.material_override = sakura_crown_mat
	crown_mesh1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	top_blossom_node.add_child(crown_mesh1)

	# Camada 2: Pétalas sobrepostas rotacionadas para profundidade e volume
	var crown_mesh2 = MeshInstance3D.new()
	crown_mesh2.mesh = crown_quad
	crown_mesh2.material_override = sakura_crown_mat
	crown_mesh2.position = Vector3(0, 0.08, 0.05)
	crown_mesh2.rotation_degrees.y = 45.0
	crown_mesh2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	top_blossom_node.add_child(crown_mesh2)

	# 5. Sombra Suave de Contato no Solo
	var shadow_spr = Sprite3D.new()
	shadow_spr.axis = Vector3.AXIS_Y
	shadow_spr.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shadow_spr.position = Vector3(0, 0.02, 0)
	shadow_spr.scale = Vector3(3.2, 3.2, 3.2)
	shadow_spr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shadow_tex = load("res://textures/sprites/common/drop_shadow.png")
	if shadow_tex:
		shadow_spr.texture = shadow_tex
	sakura_root.add_child(shadow_spr)

	# 6. Partículas de Pétalas de Cerejeira Flutuantes (Cosy Ghibli Atmosphere)
	sakura_particles = CPUParticles3D.new()
	sakura_particles.name = "SakuraPetalParticles"
	sakura_particles.amount = 14
	sakura_particles.lifetime = 3.8
	sakura_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sakura_particles.emission_box_extents = Vector3(1.8, 0.8, 1.8)
	sakura_particles.position = Vector3(0, 2.3, 0)
	sakura_particles.gravity = Vector3(0.12, -0.22, 0.06)
	sakura_particles.initial_velocity_min = 0.1
	sakura_particles.initial_velocity_max = 0.3
	sakura_particles.angular_velocity_min = 0.6
	sakura_particles.angular_velocity_max = 2.2
	sakura_particles.scale_amount_min = 0.8
	sakura_particles.scale_amount_max = 1.3
	
	var part_mat = StandardMaterial3D.new()
	part_mat.albedo_texture = preload("res://textures/environment/sakura_petal_particle.png")
	part_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	part_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	part_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var part_quad = QuadMesh.new()
	part_quad.size = Vector2(0.24, 0.24)
	part_quad.material = part_mat
	sakura_particles.mesh = part_quad
	sakura_root.add_child(sakura_particles)

func _setup_sprite_25d() -> void:
	var flower_dir = "res://textures/sprites/environment/sacred_flower"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(flower_dir)):
		sprite_25d = DirectionalSprite3D.new()
		sprite_25d.name = "Sprite25D"
		# Resolução 256px: 256 * 0.016 = 4.096m de altura visual
		sprite_25d.sprite_pixel_size = 0.016
		sprite_25d.sprite_offset_y = 2.05
		sprite_25d.shadow_scale = Vector3(3.2, 3.2, 3.2)
		add_child(sprite_25d)
		sprite_25d.load_sprites_from_dir(flower_dir)
		sprite_25d.play("idle", true, 6.0)
		
		# A representação ativa é a malha volumétrica 3D com Alpha Map
		if sprite_25d.sprite:
			sprite_25d.sprite.visible = false
		if sprite_25d.shadow_sprite:
			sprite_25d.shadow_sprite.visible = false

func _setup_thirst_badge() -> void:
	thirst_badge = Node3D.new()
	thirst_badge.name = "ThirstAlertBadge"
	thirst_badge.position = Vector3(0, 3.8, 0)
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
	var time = Time.get_ticks_msec() * 0.001
	
	# Balanço suave de brisa e respiração viva da Sakura 3D
	if sakura_root:
		sakura_root.rotation.z = sin(time * 1.5) * 0.025
		sakura_root.rotation.x = cos(time * 1.1) * 0.02
		var breathe = 1.0 + sin(time * 1.8) * 0.018
		sakura_root.scale = Vector3(breathe, 2.0 - breathe, breathe)
		
	if top_blossom_node:
		top_blossom_node.rotation.y += delta * 0.08
		
	if thirst_badge and thirst_badge.visible:
		thirst_badge.position.y = 3.8 + sin(time * 3.0) * 0.12
		thirst_badge.rotation.y += delta * 1.2
		
	if visuals and visuals.visible:
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
	var dryness = (1.0 - current_hydration_pct) * 0.5
	
	# Atualiza materiais da Sakura com Alpha Map
	var target_tint = Color.WHITE
	if evolution_level > 0:
		target_tint = Color(1.15, 0.98, 1.12).lerp(Color(0.85, 0.30, 0.30), danger_factor * 0.8)
	else:
		target_tint = Color.WHITE.lerp(Color(0.78, 0.30, 0.30), danger_factor * 0.85)
		if current_hydration_pct < 0.45:
			target_tint = target_tint.lerp(Color(0.75, 0.62, 0.45), 0.35)
			
	if sakura_stem_mat:
		sakura_stem_mat.albedo_color = target_tint
	if sakura_crown_mat:
		sakura_crown_mat.albedo_color = target_tint
		if danger_factor > 0.35:
			sakura_crown_mat.emission = Color(0.95, 0.15, 0.15)
			sakura_crown_mat.emission_energy_multiplier = (danger_factor - 0.35) * 1.8
		elif evolution_level > 0:
			sakura_crown_mat.emission = Color(1.0, 0.6, 0.85)
			sakura_crown_mat.emission_energy_multiplier = 0.5
		else:
			sakura_crown_mat.emission = Color(1.0, 0.88, 0.35)
			sakura_crown_mat.emission_energy_multiplier = 0.3
			
	# Droop suave ao perder hidratação ou sofrer dano
	if top_blossom_node:
		var total_droop = clampf(danger_factor * 0.5 + dryness * 0.5, 0.0, 1.0)
		top_blossom_node.rotation_degrees.x = -35.0 - total_droop * 18.0

	# Atualiza também materiais procedurais de fallback
	for mat in petal_materials:
		mat.albedo_color = base_petal_color.lerp(Color(0.82, 0.06, 0.10, 1.0), danger_factor * 0.88)
		if danger_factor > 0.35:
			mat.emission = Color(0.95, 0.08, 0.08)
			mat.emission_energy_multiplier = (danger_factor - 0.35) * 2.5
		elif evolution_level > 0:
			mat.emission = Color(1.0, 0.5, 0.8)
			mat.emission_energy_multiplier = 0.35
		else:
			mat.emission_energy_multiplier = 0.0
			
	if core_material:
		core_material.albedo_color = Color(1.0, 0.82, 0.15, 1.0).lerp(Color(0.85, 0.25, 0.05, 1.0), danger_factor * 0.85)
		core_material.emission = Color(1.0, 0.82, 0.15, 1.0).lerp(Color(1.0, 0.15, 0.05), danger_factor)
		core_material.emission_energy_multiplier = 0.6 + danger_factor * 0.8
		
	var combined_stem_factor = clampf(danger_factor * 0.6 + dryness, 0.0, 1.0)
	if stem_material:
		stem_material.albedo_color = Color(0.20, 0.55, 0.22, 1.0).lerp(Color(0.42, 0.26, 0.16, 1.0), combined_stem_factor)

func apply_fairy_tear() -> void:
	evolution_level += 1
	
	# 1. Recupera 60% da vida máxima
	var heal_amt = GameManager.flower_max_hp * 0.60
	GameManager.heal_flower(heal_amt)
	
	# 2. Aumenta vida máxima em +10%
	GameManager.flower_max_hp *= 1.10
	GameManager.flower_stats_changed.emit(GameManager.flower_hp, GameManager.flower_max_hp)
	
	# 3. Cria e faz brotar nova folha viçosa
	spawn_evolved_leaf()
	
	# 4. Efeito visual e sonoro triunfante
	SoundManager.play_fairy_dust(-2.0)
		
	if sakura_root:
		var tween = create_tween()
		tween.tween_property(sakura_root, "scale", Vector3(1.35, 1.35, 1.35), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sakura_root, "scale", Vector3.ONE, 0.4)
		
	if sakura_stem_mat and sakura_crown_mat:
		var flash_tw = create_tween()
		flash_tw.tween_property(sakura_stem_mat, "albedo_color", Color(1.6, 2.2, 1.8), 0.2)
		flash_tw.parallel().tween_property(sakura_crown_mat, "albedo_color", Color(2.2, 1.6, 2.2), 0.2)
		flash_tw.tween_property(sakura_stem_mat, "albedo_color", Color(1.15, 0.98, 1.12), 0.3)
		flash_tw.parallel().tween_property(sakura_crown_mat, "albedo_color", Color(1.15, 0.98, 1.12), 0.3)
		
	if sakura_particles:
		sakura_particles.amount = 22
		
	update_damage_color(GameManager.flower_hp, GameManager.flower_max_hp)
	GameManager.notify("🌸 A Flor do Jardim Evoluiu! +60% de Vida, +10% Max HP e Nova Folha!", Color(0.4, 1.0, 0.7))

func spawn_evolved_leaf() -> void:
	if evolved_leaf:
		evolved_leaf.queue_free()
		
	evolved_leaf = Node3D.new()
	evolved_leaf.name = "EvolvedLeaf"
	
	var leaf_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.7, 0.08, 1.4)
	leaf_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.albedo_color = Color(0.24, 0.82, 0.40, 1.0) # Verde esmeralda vivo
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.95, 0.45)
	mat.emission_energy_multiplier = 0.35
	leaf_mesh.material_override = mat
	
	leaf_mesh.position = Vector3(0.55, 1.1, 0.25)
	leaf_mesh.rotation_degrees = Vector3(15.0, 45.0, -25.0)
	evolved_leaf.add_child(leaf_mesh)
	
	if sakura_root:
		sakura_root.add_child(evolved_leaf)
		evolved_leaf.scale = Vector3(0.01, 0.01, 0.01)
		var tween = create_tween()
		tween.tween_property(evolved_leaf, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func take_damage(amount: float) -> void:
	GameManager.damage_flower(amount)
	
	# Hit flash suave nos materiais de Sakura
	if sakura_stem_mat and sakura_crown_mat:
		var flash_color = Color(2.2, 0.5, 0.5, 1.0)
		var prev_stem = sakura_stem_mat.albedo_color
		var prev_crown = sakura_crown_mat.albedo_color
		sakura_stem_mat.albedo_color = flash_color
		sakura_crown_mat.albedo_color = flash_color
		
		var tree = get_tree()
		if tree:
			var tw = tree.create_tween()
			tw.tween_property(sakura_stem_mat, "albedo_color", prev_stem, 0.15)
			tw.parallel().tween_property(sakura_crown_mat, "albedo_color", prev_crown, 0.15)
			
	# Tremor orgânico da flor 3D
	if sakura_root:
		var tree = get_tree()
		if tree:
			var tween = tree.create_tween()
			var shake_x = (randf() - 0.5) * 0.18
			var shake_z = (randf() - 0.5) * 0.18
			tween.tween_property(sakura_root, "scale", Vector3(1.18, 0.82, 1.18), 0.06)
			tween.parallel().tween_property(sakura_root, "position", Vector3(shake_x, 0, shake_z), 0.06)
			tween.tween_property(sakura_root, "scale", Vector3.ONE, 0.12)
			tween.parallel().tween_property(sakura_root, "position", Vector3.ZERO, 0.12)
