extends Node
class_name DayNightCycle

# DayNightCycle para Jardim Miúdo
# Controla a rotação solar/lunar, sombras dinâmicas e transição de cores Dia -> Pôr do Sol -> Noite de Lua Cheia

@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment

var sky_mat: ProceduralSkyMaterial = null
var current_progress: float = 0.0 # 0.0 (Manhã) -> 0.75 (Pôr do Sol) -> 1.0 (Noite de Lua Cheia)
var target_progress: float = 0.0
var is_night: bool = false

# Cores de Iluminação Direcional (Sol & Lua Cheia)
const SUN_DAY = Color(1.0, 0.96, 0.88)
const SUN_AFTERNOON = Color(1.0, 0.84, 0.58)
const SUN_SUNSET = Color(1.0, 0.52, 0.32)
const MOON_FULL_NIGHT = Color(0.68, 0.80, 0.98) # Prata azulado luminoso de lua cheia

# Cores do Céu (Top)
const SKY_DAY = Color(0.47, 0.72, 0.90)
const SKY_AFTERNOON = Color(0.42, 0.58, 0.85)
const SKY_SUNSET = Color(0.38, 0.28, 0.58)
const SKY_NIGHT = Color(0.08, 0.14, 0.32) # Azul marinho estrelado luminoso

# Cores do Horizonte
const HORIZON_DAY = Color(1.0, 0.93, 0.82)
const HORIZON_AFTERNOON = Color(1.0, 0.82, 0.65)
const HORIZON_SUNSET = Color(0.95, 0.55, 0.30)
const HORIZON_NIGHT = Color(0.20, 0.28, 0.46) # Horizonte azulado suave iluminado pela lua

# Luz Ambiente
const AMBIENT_DAY = Color(0.95, 0.90, 0.80)
const AMBIENT_SUNSET = Color(0.80, 0.60, 0.50)
const AMBIENT_NIGHT = Color(0.30, 0.38, 0.54) # Ambiente visível e agradável de lua cheia

func _ready() -> void:
	if world_environment and world_environment.environment and world_environment.environment.sky:
		var s = world_environment.environment.sky.sky_material
		if s and s is ProceduralSkyMaterial:
			sky_mat = s
			
	GameManager.wave_state_changed.connect(_on_wave_state_changed)
	update_lighting(0.0)

var lighting_timer: float = 0.0

func _process(delta: float) -> void:
	if abs(current_progress - target_progress) > 0.002:
		current_progress = lerp(current_progress, target_progress, delta * 1.5)
		lighting_timer -= delta
		if lighting_timer <= 0.0:
			lighting_timer = 0.05
			update_lighting(current_progress)
	elif current_progress != target_progress:
		current_progress = target_progress
		update_lighting(current_progress)

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	if GameManager.current_period == "NIGHT":
		is_night = true
		if wave_number <= 4:
			target_progress = 1.0 # Noite de Lua Cheia
		elif wave_number == 5:
			target_progress = 0.88 # Madrugada / horizonte clareando
		elif wave_number == 6:
			target_progress = 0.75 # Alvorada
		else:
			target_progress = 0.65 # Fim da noite / primeiros raios
	elif GameManager.current_period == "BOSS_PREP" or GameManager.current_period == "BOSS":
		is_night = false
		target_progress = 0.08 # Amanhecer dourado glorioso
	else:
		is_night = false
		# Ondas do Dia
		var max_w = float(GameManager.max_waves)
		var factor = clampf(float(wave_number) / max_w, 0.0, 1.0)
		target_progress = factor * 0.75

func set_night_transition_immediate(duration: float = 4.0) -> void:
	is_night = true
	var tween = create_tween()
	tween.tween_property(self, "target_progress", 1.0, duration)

func update_lighting(prog: float) -> void:
	# prog: 0.0 (Dia) -> 0.4 (Tarde) -> 0.75 (Pôr do Sol) -> 1.0 (Noite de Lua Cheia)
	
	# 1. Rotação da Luz e Sombras (Sol de dia / Lua cheia à noite)
	if sun_light:
		# Ângulo de elevação (Pitch): 55 graus no dia -> 20 graus no pôr do sol -> 45 graus (luz alta da lua cheia)
		var pitch_deg = 55.0
		var yaw_deg = 35.0
		
		if prog < 0.8:
			var t = prog / 0.8
			pitch_deg = lerp(55.0, 18.0, t)
			yaw_deg = lerp(35.0, 95.0, t)
		else:
			# À noite a lua cheia sobe no céu para iluminar bem todo o jardim com sombras nítidas
			var t = (prog - 0.8) / 0.2
			pitch_deg = lerp(18.0, 48.0, t)
			yaw_deg = lerp(95.0, 140.0, t)
			
		sun_light.rotation_degrees = Vector3(-pitch_deg, yaw_deg, 0)
		
		# Cor e Energia da Luz Direcional
		if prog < 0.4:
			var t = prog / 0.4
			sun_light.light_color = SUN_DAY.lerp(SUN_AFTERNOON, t)
			sun_light.light_energy = lerp(1.3, 1.15, t)
		elif prog < 0.8:
			var t = (prog - 0.4) / 0.4
			sun_light.light_color = SUN_AFTERNOON.lerp(SUN_SUNSET, t)
			sun_light.light_energy = lerp(1.15, 0.82, t)
		else:
			var t = (prog - 0.8) / 0.2
			sun_light.light_color = SUN_SUNSET.lerp(MOON_FULL_NIGHT, t)
			# Energia clara de Lua Cheia: 0.72 (visibilidade excelente e poética)
			sun_light.light_energy = lerp(0.82, 0.72, t)
			
	# 2. Céu Procedural e Luz Ambiente
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		
		var cur_sky_top: Color
		var cur_horizon: Color
		var cur_ambient: Color
		var cur_fog: Color
		
		if prog < 0.4:
			var t = prog / 0.4
			cur_sky_top = SKY_DAY.lerp(SKY_AFTERNOON, t)
			cur_horizon = HORIZON_DAY.lerp(HORIZON_AFTERNOON, t)
			cur_ambient = AMBIENT_DAY
			cur_fog = Color(0.98, 0.94, 0.86).lerp(Color(0.96, 0.88, 0.75), t)
		elif prog < 0.8:
			var t = (prog - 0.4) / 0.4
			cur_sky_top = SKY_AFTERNOON.lerp(SKY_SUNSET, t)
			cur_horizon = HORIZON_AFTERNOON.lerp(HORIZON_SUNSET, t)
			cur_ambient = AMBIENT_DAY.lerp(AMBIENT_SUNSET, t)
			cur_fog = Color(0.96, 0.88, 0.75).lerp(Color(0.88, 0.58, 0.42), t)
		else:
			var t = (prog - 0.8) / 0.2
			cur_sky_top = SKY_SUNSET.lerp(SKY_NIGHT, t)
			cur_horizon = HORIZON_SUNSET.lerp(HORIZON_NIGHT, t)
			cur_ambient = AMBIENT_SUNSET.lerp(AMBIENT_NIGHT, t)
			cur_fog = Color(0.88, 0.58, 0.42).lerp(Color(0.14, 0.20, 0.36), t)
			
		env.ambient_light_color = cur_ambient
		env.ambient_light_sky_contribution = lerp(0.75, 0.60, prog)
		env.fog_light_color = cur_fog
		env.fog_density = lerp(0.0022, 0.0028, prog)
		
		if sky_mat:
			sky_mat.sky_top_color = cur_sky_top
			sky_mat.sky_horizon_color = cur_horizon
			sky_mat.ground_horizon_color = cur_horizon
			sky_mat.ground_bottom_color = Color(0.29, 0.22, 0.15).lerp(Color(0.08, 0.10, 0.16), prog)
