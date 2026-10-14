extends Node3D
class_name GardenAmbientParticles

# Sistema de Partículas Ambientais Estilo Ghibli
# 1. Esporos de Pólen Dourados (Dia/Tarde - partículas de poeira e pólen iluminadas pelo sol)
# 2. Plumas de Dente-de-Leão (Vento no campo)
# 3. Vagalumes Místicos (Noite e Crepúsculo - luz pulsante verde-esmeralda e azul-celeste)

var pollen_particles: CPUParticles3D = null
var dandelion_fluff: CPUParticles3D = null
var firefly_particles: CPUParticles3D = null

static var glow_texture: ImageTexture = null

func _ready() -> void:
	name = "GardenAmbientParticles"
	ensure_glow_texture()
	setup_pollen_motes()
	setup_dandelion_fluff()
	setup_night_fireflies()
	
	if GameManager:
		GameManager.wave_state_changed.connect(_on_wave_state_changed)
	update_particle_states()

static func ensure_glow_texture() -> ImageTexture:
	if glow_texture != null:
		return glow_texture
	
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	var max_r = size * 0.48
	
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha = clampf(1.0 - (dist / max_r), 0.0, 1.0)
			alpha = smoothstep(0.0, 1.0, alpha)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
			
	glow_texture = ImageTexture.create_from_image(img)
	return glow_texture

func setup_pollen_motes() -> void:
	pollen_particles = CPUParticles3D.new()
	pollen_particles.name = "PollenMotes"
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ensure_glow_texture()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var qm = QuadMesh.new()
	qm.size = Vector2(0.22, 0.22)
	qm.material = mat
	pollen_particles.mesh = qm
	
	pollen_particles.amount = 140
	pollen_particles.lifetime = 9.0
	pollen_particles.preprocess = 4.0
	pollen_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pollen_particles.emission_box_extents = Vector3(38.0, 4.0, 38.0)
	pollen_particles.position = Vector3(0.0, 3.5, 0.0)
	
	pollen_particles.gravity = Vector3(0.08, -0.02, 0.04)
	pollen_particles.initial_velocity_min = 0.15
	pollen_particles.initial_velocity_max = 0.45
	pollen_particles.angular_velocity_min = -15.0
	pollen_particles.angular_velocity_max = 15.0
	
	var col_grad = Gradient.new()
	col_grad.set_color(0, Color(1.0, 0.94, 0.70, 0.0))
	col_grad.add_point(0.2, Color(1.0, 0.94, 0.70, 0.75))
	col_grad.add_point(0.8, Color(1.0, 0.88, 0.60, 0.65))
	col_grad.set_color(1, Color(1.0, 0.85, 0.50, 0.0))
	pollen_particles.color_ramp = col_grad
	
	add_child(pollen_particles)

func setup_dandelion_fluff() -> void:
	dandelion_fluff = CPUParticles3D.new()
	dandelion_fluff.name = "DandelionFluff"
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ensure_glow_texture()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var qm = QuadMesh.new()
	qm.size = Vector2(0.35, 0.35)
	qm.material = mat
	dandelion_fluff.mesh = qm
	
	dandelion_fluff.amount = 38
	dandelion_fluff.lifetime = 12.0
	dandelion_fluff.preprocess = 6.0
	dandelion_fluff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dandelion_fluff.emission_box_extents = Vector3(45.0, 5.0, 45.0)
	dandelion_fluff.position = Vector3(0.0, 4.0, 0.0)
	
	# Vento pastoral empurrando suavemente em diagonal
	dandelion_fluff.gravity = Vector3(0.35, -0.04, 0.18)
	dandelion_fluff.initial_velocity_min = 0.4
	dandelion_fluff.initial_velocity_max = 0.9
	dandelion_fluff.tangential_accel_min = -0.2
	dandelion_fluff.tangential_accel_max = 0.2
	
	var col_grad = Gradient.new()
	col_grad.set_color(0, Color(0.98, 0.98, 0.94, 0.0))
	col_grad.add_point(0.2, Color(0.98, 0.98, 0.94, 0.85))
	col_grad.add_point(0.8, Color(0.95, 0.95, 0.90, 0.75))
	col_grad.set_color(1, Color(0.92, 0.92, 0.88, 0.0))
	dandelion_fluff.color_ramp = col_grad
	
	add_child(dandelion_fluff)

func setup_night_fireflies() -> void:
	firefly_particles = CPUParticles3D.new()
	firefly_particles.name = "NightFireflies"
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ensure_glow_texture()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	
	var qm = QuadMesh.new()
	qm.size = Vector2(0.32, 0.32)
	qm.material = mat
	firefly_particles.mesh = qm
	
	firefly_particles.amount = 85
	firefly_particles.lifetime = 8.0
	firefly_particles.preprocess = 4.0
	firefly_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	firefly_particles.emission_box_extents = Vector3(36.0, 2.2, 36.0)
	firefly_particles.position = Vector3(0.0, 1.8, 0.0) # Vôo rasante perto das flores e heras
	
	firefly_particles.gravity = Vector3(0.0, 0.02, 0.0)
	firefly_particles.initial_velocity_min = 0.2
	firefly_particles.initial_velocity_max = 0.6
	firefly_particles.orbit_velocity_min = -0.15
	firefly_particles.orbit_velocity_max = 0.15
	
	var col_grad = Gradient.new()
	col_grad.set_color(0, Color(0.55, 0.98, 0.45, 0.0))
	col_grad.add_point(0.25, Color(0.60, 1.0, 0.50, 0.95))
	col_grad.add_point(0.50, Color(0.45, 0.88, 1.0, 0.90)) # Variação para azul celestial suave
	col_grad.add_point(0.75, Color(0.65, 1.0, 0.55, 0.85))
	col_grad.set_color(1, Color(0.50, 0.95, 0.40, 0.0))
	firefly_particles.color_ramp = col_grad
	
	add_child(firefly_particles)

func _on_wave_state_changed(_state: String, _wave_number: int) -> void:
	update_particle_states()

func update_particle_states() -> void:
	var period = GameManager.current_period if GameManager else "DAY"
	var is_night = (period == "NIGHT")
	
	if pollen_particles:
		pollen_particles.emitting = not is_night
	if dandelion_fluff:
		dandelion_fluff.emitting = true # Sementes flutuam dia e noite
	if firefly_particles:
		firefly_particles.emitting = is_night
