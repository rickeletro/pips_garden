extends Node3D
class_name DandelionClock

@onready var visuals: Node3D = $Visuals
@onready var stem: MeshInstance3D = $Visuals/Stem
@onready var clock_head: Node3D = $Visuals/ClockHead
@onready var fluff_globe: Node3D = $Visuals/ClockHead/FluffGlobe
@onready var receptacle: MeshInstance3D = $Visuals/ClockHead/Receptacle

var is_harvested: bool = false
var sway_offset: float = 0.0

# Mecânica de Sede & Hidratação
var hydration: float = 100.0
const MAX_HYDRATION: float = 100.0
var is_withered: bool = false

var pappus_scene: PackedScene = preload("res://scenes/environment/flying_seed_pappus.tscn")

# Materiais compartilhados para as sementes presas no caule
static var mat_seed: StandardMaterial3D = null
static var mat_stalk: StandardMaterial3D = null
static var mat_tuft: StandardMaterial3D = null
static var mat_haze: StandardMaterial3D = null

# Geometrias de Mesh estáticas compartilhadas para alta performance
static var shared_seed_mesh: CylinderMesh = null
static var shared_stalk_mesh: CylinderMesh = null
static var shared_tuft_mesh: CylinderMesh = null
static var shared_haze_mesh: SphereMesh = null

# Cores da Haste / Caule para Indicação de Sede
const COLOR_STEM_HEALTHY: Color = Color(0.24, 0.65, 0.22, 1.0) # Verde saudável
const COLOR_STEM_DRY: Color = Color(0.85, 0.62, 0.15, 1.0)     # Amarelo/âmbar seco
const COLOR_STEM_CRITICAL: Color = Color(0.95, 0.15, 0.12, 1.0)# Vermelho crítico

var stem_mat: StandardMaterial3D = null
var death_timer_label: Label3D = null

func _ready() -> void:
	add_to_group("dandelion")
	sway_offset = randf() * 100.0
	setup_shared_materials()
	setup_shared_meshes()
	build_visible_seeds_on_stem()
	_setup_stem_and_timer_ui()
	GameManager.wave_state_changed.connect(_on_wave_state_changed)

func _setup_stem_and_timer_ui() -> void:
	if stem:
		stem_mat = StandardMaterial3D.new()
		stem_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		stem_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		stem_mat.albedo_color = COLOR_STEM_HEALTHY
		stem_mat.roughness = 0.5
		stem_mat.emission_enabled = true
		stem_mat.emission = COLOR_STEM_CRITICAL
		stem_mat.emission_energy_multiplier = 0.0
		stem.material_override = stem_mat
		
	death_timer_label = Label3D.new()
	death_timer_label.name = "DeathCountdownLabel"
	death_timer_label.position = Vector3(0, 2.5, 0)
	death_timer_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	death_timer_label.no_depth_test = true
	death_timer_label.font_size = 28
	death_timer_label.outline_size = 8
	death_timer_label.outline_modulate = Color(0.1, 0.05, 0.05, 0.9)
	death_timer_label.modulate = Color(1.0, 0.25, 0.2)
	death_timer_label.visible = false
	add_child(death_timer_label)

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	# Regenera quando amanhece um novo dia (Dia 2, etc.)
	if GameManager.current_period == "DAY" and wave_number == 0:
		regrow_for_new_day()

func regrow_for_new_day() -> void:
	is_harvested = false
	is_withered = false
	hydration = MAX_HYDRATION
	if fluff_globe:
		fluff_globe.visible = true
		fluff_globe.scale = Vector3.ZERO
		var pop_tween = create_tween()
		pop_tween.tween_property(fluff_globe, "scale", Vector3(1.22, 1.22, 1.22), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(fluff_globe, "scale", Vector3.ONE, 0.2)

func water_dandelion() -> bool:
	if GameManager.consume_dew_flask_charge():
		hydration = MAX_HYDRATION
		is_withered = false
		if fluff_globe:
			fluff_globe.visible = true
			fluff_globe.scale = Vector3.ONE
		SoundManager.play_fairy_dust(0.0)
		GameManager.notify("🌾 Dente-de-Leão totalmente hidratado!", Tokens.VERDE_FOLHA)
		return true
	return false

func wither_and_die() -> void:
	is_withered = true
	if fluff_globe and fluff_globe.visible:
		var tw = create_tween()
		tw.tween_property(fluff_globe, "scale", Vector3.ZERO, 0.35)
		tw.tween_callback(func(): fluff_globe.visible = false)
	GameManager.notify("🍂 Um Dente-de-Leão secou por falta de orvalho!", Tokens.PERIGO)

func setup_shared_meshes() -> void:
	if shared_seed_mesh == null:
		shared_seed_mesh = CylinderMesh.new()
		shared_seed_mesh.top_radius = 0.012
		shared_seed_mesh.bottom_radius = 0.038
		shared_seed_mesh.height = 0.16
		shared_seed_mesh.radial_segments = 6
		
		shared_stalk_mesh = CylinderMesh.new()
		shared_stalk_mesh.top_radius = 0.007
		shared_stalk_mesh.bottom_radius = 0.007
		shared_stalk_mesh.height = 0.44
		shared_stalk_mesh.radial_segments = 5
		
		shared_tuft_mesh = CylinderMesh.new()
		shared_tuft_mesh.top_radius = 0.09
		shared_tuft_mesh.bottom_radius = 0.015
		shared_tuft_mesh.height = 0.22
		shared_tuft_mesh.radial_segments = 6
		
		shared_haze_mesh = SphereMesh.new()
		shared_haze_mesh.radius = 0.72
		shared_haze_mesh.height = 1.35
		shared_haze_mesh.radial_segments = 16
		shared_haze_mesh.rings = 10

func setup_shared_materials() -> void:
	if mat_seed == null:
		# Material da semente visível presa ao caule (tom dourado-âmbar brilhante)
		mat_seed = StandardMaterial3D.new()
		mat_seed.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat_seed.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat_seed.albedo_color = Color(0.94, 0.72, 0.20, 1.0)
		mat_seed.roughness = 0.4
		mat_seed.emission_enabled = true
		mat_seed.emission = Color(1.0, 0.82, 0.25, 1.0)
		mat_seed.emission_energy_multiplier = 0.55
		
		# Material do filamento/haste delicada
		mat_stalk = StandardMaterial3D.new()
		mat_stalk.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat_stalk.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat_stalk.albedo_color = Color(0.88, 0.85, 0.72, 0.85)
		mat_stalk.roughness = 0.7
		
		# Material das plumas individuais com transparência suave
		mat_tuft = StandardMaterial3D.new()
		mat_tuft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_tuft.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_tuft.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat_tuft.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat_tuft.albedo_color = Color(0.98, 0.98, 0.95, 0.52)
		mat_tuft.roughness = 0.9
		mat_tuft.emission_enabled = true
		mat_tuft.emission = Color(1.0, 1.0, 0.95, 1.0)
		mat_tuft.emission_energy_multiplier = 0.28
		
		# Material da cúpula externa de pluma translúcida (efeito ar e névoa leve)
		mat_haze = StandardMaterial3D.new()
		mat_haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_haze.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_haze.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat_haze.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat_haze.albedo_color = Color(0.98, 0.98, 0.95, 0.28)
		mat_haze.roughness = 0.95
		mat_haze.emission_enabled = true
		mat_haze.emission = Color(1.0, 0.98, 0.92, 1.0)
		mat_haze.emission_energy_multiplier = 0.18

# Constrói o arranjo floral onde é possível ver claramente as sementes douradas
# presas no receptáculo central do caule, irradiando seus filamentos e paraquedas translúcidos
func build_visible_seeds_on_stem() -> void:
	if not fluff_globe:
		return
		
	# Limpa filhos pré-existentes se houver
	for child in fluff_globe.get_children():
		child.queue_free()
		
	# 1. Cúpula externa translúcida e leve (como uma névoa de penugem)
	var outer_haze = MeshInstance3D.new()
	outer_haze.mesh = shared_haze_mesh
	outer_haze.material_override = mat_haze
	fluff_globe.add_child(outer_haze)
	
	# Meshes reutilizáveis compartilhados
	var seed_mesh = shared_seed_mesh
	var stalk_mesh = shared_stalk_mesh
	var tuft_mesh = shared_tuft_mesh
	
	# 2. Distribuição Fibonacci em esfera: 8 sementes visíveis presas ao caule
	var count = 8
	for i in range(count):
		# Ângulo esférico dourado
		var y = 1.0 - (float(i) / float(count - 1)) * 1.6 # Favorece hemisfério superior e equatorial
		var radius_at_y = sqrt(maxf(0.0, 1.0 - y * y))
		var theta = i * 2.3999632 # Proporção áurea
		var dir = Vector3(cos(theta) * radius_at_y, y, sin(theta) * radius_at_y).normalized()
		
		# Não projeta para baixo direto no caule
		if dir.y < -0.35:
			dir.y = abs(dir.y) * 0.4
			dir = dir.normalized()
			
		var spoke = Node3D.new()
		fluff_globe.add_child(spoke)
		
		# Alinha o eixo Z ou Y com a direção radial
		var up_vec = Vector3.UP if abs(dir.y) < 0.9 else Vector3.FORWARD
		spoke.look_at(dir, up_vec)
		
		# A) Semente dourada-âmbar visível fixada no receptáculo central do caule
		var seed_inst = MeshInstance3D.new()
		seed_inst.mesh = seed_mesh
		seed_inst.material_override = mat_seed
		seed_inst.position = Vector3(0, 0, -0.14)
		seed_inst.rotation_degrees.x = 90
		spoke.add_child(seed_inst)
		
		# B) Haste/filamento delicado que conecta a semente ao paraquedas
		var stalk_inst = MeshInstance3D.new()
		stalk_inst.mesh = stalk_mesh
		stalk_inst.material_override = mat_stalk
		stalk_inst.position = Vector3(0, 0, -0.40)
		stalk_inst.rotation_degrees.x = 90
		spoke.add_child(stalk_inst)
		
		# C) Paraquedas / tufo de pluma translúcida na extremidade externa
		var tuft_inst = MeshInstance3D.new()
		tuft_inst.mesh = tuft_mesh
		tuft_inst.material_override = mat_tuft
		tuft_inst.position = Vector3(0, 0, -0.66)
		tuft_inst.rotation_degrees.x = 90
		spoke.add_child(tuft_inst)

func _process(delta: float) -> void:
	if not is_withered and not GameManager.is_in_intro and not is_harvested:
		hydration = maxf(0.0, hydration - delta * 1.0) # ~100s de hidratação
		if hydration <= 0.0:
			wither_and_die()
			
	# Atualiza a cor dinâmica do caule e o cronômetro de morte
	var pct = clampf(hydration / MAX_HYDRATION, 0.0, 1.0)
	if stem_mat:
		if pct > 0.40:
			var t_val = (pct - 0.40) / 0.60
			stem_mat.albedo_color = COLOR_STEM_DRY.lerp(COLOR_STEM_HEALTHY, t_val)
			if stem_mat.emission_energy_multiplier != 0.0:
				stem_mat.emission_energy_multiplier = 0.0
		else:
			var t_val = pct / 0.40
			stem_mat.albedo_color = COLOR_STEM_CRITICAL.lerp(COLOR_STEM_DRY, t_val)
			if hydration <= 20.0 and not is_withered:
				var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.012) * 0.5
				stem_mat.emission_energy_multiplier = 0.6 + pulse * 1.4
			elif stem_mat.emission_energy_multiplier != 0.0:
				stem_mat.emission_energy_multiplier = 0.0
				
	# Cronômetro 3D visível quando a planta fica vermelha (< 20s de vida restante)
	if death_timer_label:
		if hydration <= 20.0 and not is_withered and not is_harvested and not GameManager.is_in_intro:
			death_timer_label.visible = true
			death_timer_label.text = "⏳ %ds" % int(ceil(hydration))
			death_timer_label.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.12)
		else:
			death_timer_label.visible = false
			
	# Suave oscilação pastoral ao vento
	var t = Time.get_ticks_msec() * 0.001 + sway_offset
	if visuals:
		visuals.rotation.x = sin(t * 1.5) * 0.035
		visuals.rotation.z = cos(t * 1.2) * 0.035

func on_attack_hit(attacker_pos: Vector3) -> void:
	if is_withered:
		if visuals:
			var tw = create_tween()
			tw.tween_property(visuals, "position:x", 0.08, 0.05)
			tw.tween_property(visuals, "position:x", -0.08, 0.05)
			tw.tween_property(visuals, "position:x", 0.0, 0.08)
		GameManager.notify("Este dente-de-leão secou por falta de orvalho! Regue-o com o frasco.", Tokens.PERIGO)
		return
		
	if is_harvested:
		# Tremor vegetal indicando que só floresce no próximo dia
		if visuals:
			var tw = create_tween()
			tw.tween_property(visuals, "position:x", 0.08, 0.05)
			tw.tween_property(visuals, "position:x", -0.08, 0.05)
			tw.tween_property(visuals, "position:x", 0.0, 0.08)
		GameManager.notify("Este dente-de-leão só florescerá novamente no próximo dia!", Tokens.CREME_PERGAMINHO)
		return
		
	is_harvested = true
	
	# Recuo orgânico do caule para longe do golpe
	var bend_dir = (global_position - attacker_pos).normalized()
	bend_dir.y = 0.0
	if bend_dir.length_squared() < 0.01:
		bend_dir = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
		
	if visuals:
		var stem_tween = create_tween()
		stem_tween.tween_property(visuals, "rotation:z", bend_dir.x * 0.45, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stem_tween.tween_property(visuals, "rotation:z", -bend_dir.x * 0.25, 0.12)
		stem_tween.tween_property(visuals, "rotation:z", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	# Estouro suave da pluma translúcida
	if fluff_globe:
		var burst_tween = create_tween()
		burst_tween.tween_property(fluff_globe, "scale", Vector3(1.35, 1.35, 1.35), 0.08)
		burst_tween.tween_property(fluff_globe, "scale", Vector3.ZERO, 0.14)
		burst_tween.tween_callback(func(): fluff_globe.visible = false)
		
	# Lança as sementes voadoras com paraquedas (pappus) translúcido pelo ar
	spawn_flying_pappus(bend_dir)
	GameManager.notify("Dente-de-leão soprado! Recolha as sementes que estão voando!", Tokens.DOURADO_LUZ)

func spawn_flying_pappus(impact_dir: Vector3) -> void:
	if not pappus_scene:
		return
		
	var parent_node = get_parent()
	if not parent_node:
		parent_node = self
		
	var spawn_origin = clock_head.global_position if clock_head else (global_position + Vector3(0, 2.4, 0))
	var seed_count = 2
	
	for i in range(seed_count):
		var pappus = pappus_scene.instantiate()
		if pappus:
			parent_node.add_child(pappus)
			
			var base_angle = (float(i) / seed_count) * TAU
			var angle = base_angle + randf_range(-0.35, 0.35)
			var spread_dir = Vector3(cos(angle), 0.0, sin(angle))
			var final_dir = (spread_dir * 0.75 + impact_dir * 0.55).normalized()
			
			if pappus.has_method("launch"):
				pappus.launch(spawn_origin, final_dir)
