extends Camera3D
class_name GardenCameraController

## ==============================================================================
## 🎥 RAGNAROK 2.5D ISOMETRIC CAMERA CONTROLLER (ESTILO NEXT-GEN / MOBILE)
## ==============================================================================
## - Projeção em perspectiva com FOV reduzido (30° - 35°) para achatamento 2.5D de diorama.
## - Ângulo isométrico clássico (Yaw: 45°, Pitch: 35° a 40°, Roll: 0°).
## - Algoritmo Target Offset Follow com Vector3 SmoothDamp (amortecimento inercial elástico).
## - Zoom dinâmico via scroll do mouse / gestos de pinça / atalhos de teclado.
## - Antecipação de movimento (Look-Ahead suave na direção da caminhada).
## - Sistema de oclusão inteligente (See-Through Fade) para copas, torres e cogumelos.
## ==============================================================================

# ------------------------------------------------------------------------------
# 1. PARÂMETROS DO ALVO E SEGUIMENTO (SMOOTHDAMP)
# ------------------------------------------------------------------------------
@export_group("Target Follow")
@export var target_path: NodePath
@export var target_offset_y: float = 0.65 ## Ponto focal vertical relativo ao alvo (peito/cintura da Pip)
@export var smooth_time: float = 0.18 ## Inércia elástica clássica de MMOs (0.15s - 0.22s)
@export var max_follow_speed: float = 40.0 ## Velocidade máxima de acompanhamento durante dashes

# ------------------------------------------------------------------------------
# 2. ÂNGULOS E PROJEÇÃO ISOMÉTRICA (ESTILO RAGNAROK)
# ------------------------------------------------------------------------------
@export_group("Isometric Projection")
@export_range(20.0, 50.0, 0.5) var camera_fov: float = 32.0 ## FOV reduzido (30° - 35°) simula diorama 2.5D
@export_range(20.0, 60.0, 0.5) var pitch_angle: float = 38.0 ## Inclinação para baixo (35° a 40°)
@export_range(-180.0, 180.0, 0.5) var yaw_angle: float = 45.0 ## Rotação lateral isométrica (45° clássico)
@export var roll_angle: float = 0.0 ## Roll fixado em 0° para estabilidade de horizonte

# ------------------------------------------------------------------------------
# 3. DISTÂNCIA & ZOOM DINÂMICO
# ------------------------------------------------------------------------------
@export var default_distance: float = 16.0 ## Distância padrão (~14 a 18 unidades, enquadra 8-10m de trilha)
@export var min_distance: float = 10.0 ## Zoom máximo aproximado
@export var max_distance: float = 36.0 ## Zoom máximo afastado (permite visão panorâmica)
@export var intro_distance: float = 32.0 ## Distância inicial panorâmica da introdução
@export var zoom_step: float = 1.5 ## Passo de alteração do zoom por clique de scroll
@export var zoom_smooth_speed: float = 9.0 ## Velocidade de interpolação do zoom
@export var enable_zoom_input: bool = true ## Permite zoom dinâmico pelo jogador

# ------------------------------------------------------------------------------
# 4. LOOK-AHEAD (ANTECIPAÇÃO DE MOVIMENTO)
# ------------------------------------------------------------------------------
@export_group("Look-Ahead")
@export var look_ahead_enabled: bool = true
@export var look_ahead_distance: float = 1.1 ## Metros de antecipação à frente da Pip
@export var look_ahead_smooth_time: float = 0.22 ## Suavização da transição de direção

# ------------------------------------------------------------------------------
# 5. OCLUSÃO / TRANSPARÊNCIA (SEE-THROUGH FADE)
# ------------------------------------------------------------------------------
@export_group("Occlusion Fade")
@export var occlusion_fade_enabled: bool = true
@export_range(0.0, 1.0, 0.05) var occluded_transparency: float = 0.70 ## 70% transparente (30% visível)
@export var occlusion_fade_speed: float = 8.5
@export_flags_3d_physics var occlusion_mask: int = 1

# ------------------------------------------------------------------------------
# VARIÁVEIS DE ESTADO INTERNO
# ------------------------------------------------------------------------------
var target_node: Node3D = null
var default_target_node: Node3D = null
var is_cinematic_focus: bool = false

var current_distance: float = 16.0
var target_distance: float = 16.0
var target_zoom_mult: float = 1.0

var current_velocity: Vector3 = Vector3.ZERO
var look_ahead_velocity: Vector3 = Vector3.ZERO
var current_look_ahead: Vector3 = Vector3.ZERO

# Dicionário de malhas com transparência ativa (GeometryInstance3D -> bool)
var active_occluders: Dictionary = {}

# Retrocompatibilidade com sistemas existentes
var follow_speed: float = 6.0:
	get: return 1.0 / maxf(0.01, smooth_time)
	set(v): smooth_time = clampf(1.0 / maxf(0.1, v), 0.05, 0.5)

var current_zoom: float:
	get: return current_distance / default_distance
	set(v): set_zoom_immediate(v)

var target_zoom: float:
	get: return target_distance / default_distance
	set(v): target_zoom_mult = v; target_distance = clampf(default_distance * v, min_distance, max_distance)

var base_offset: Vector3:
	get: return _calculate_offset_vector(default_distance)
	set(_v): pass

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================

func _ready() -> void:
	add_to_group("camera")
	GameManager.camera = self
	_resolve_target()
	
	# Configura modo de projeção e FOV estilo Ragnarok Mobile
	projection = PROJECTION_PERSPECTIVE
	fov = camera_fov
	
	# Calibra distâncias iniciais
	if GameManager.is_in_intro:
		target_zoom_mult = intro_distance / default_distance
		target_distance = intro_distance
		current_distance = intro_distance
	else:
		target_zoom_mult = 1.0
		target_distance = default_distance
		current_distance = default_distance
		
	# Aplica orientação angular de rotação isométrica inicial
	_apply_camera_rotation()
	
	# Posicionamento instantâneo no primeiro frame para evitar sobressaltos
	if target_node and is_instance_valid(target_node):
		var init_focus = target_node.global_position + Vector3(0.0, target_offset_y, 0.0)
		global_position = init_focus + _calculate_offset_vector(current_distance)

var is_zooming_intro: bool = false

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
		
	_resolve_target()
	if not target_node or not is_instance_valid(target_node):
		return
		
	# 1. Atualiza Zoom Dinâmico Suave (não conflita com a transição cinematográfica de entrada)
	if is_zooming_intro:
		target_distance = current_distance
	else:
		current_distance = lerp(current_distance, target_distance, clampf(delta * zoom_smooth_speed, 0.0, 1.0))
	
	# 2. Calcula Ponto Focal com Look-Ahead Suave
	var base_focus = target_node.global_position + Vector3(0.0, target_offset_y, 0.0)
	var target_look_ahead = Vector3.ZERO
	
	if look_ahead_enabled and not is_cinematic_focus:
		var move_dir = _get_target_movement_direction()
		if move_dir.length_squared() > 0.01:
			target_look_ahead = move_dir * look_ahead_distance
			
	var damp_la = smooth_damp_v3(current_look_ahead, target_look_ahead, look_ahead_velocity, look_ahead_smooth_time, delta, 15.0)
	current_look_ahead = damp_la[0]
	look_ahead_velocity = damp_la[1]
	
	var desired_focus_point = base_focus + current_look_ahead
	
	# 3. Calcula Posição Desejada da Câmera (Target Offset Follow com Rotação Isométrica)
	var offset_vector = _calculate_offset_vector(current_distance)
	var desired_camera_pos = desired_focus_point + offset_vector
	
	# 4. Interpolação Suave via SmoothDamp Vector3 (Inércia elástica de Ragnarok)
	var damp_pos = smooth_damp_v3(global_position, desired_camera_pos, current_velocity, smooth_time, delta, max_follow_speed)
	global_position = damp_pos[0]
	current_velocity = damp_pos[1]
	
	# 5. Mantém os ângulos de rotação isométricos fixados
	_apply_camera_rotation()
	
	# 6. Oclusão e Transparência Inteligente (See-Through Fade)
	_update_occlusion_fade(delta, base_focus)

# ==============================================================================
# ALGORITMO MATEMÁTICO DE TARGET OFFSET FOLLOW & SMOOTHDAMP
# ==============================================================================

## Retorna a base de rotação isométrica a partir dos ângulos de Euler (YXZ)
func _get_isometric_basis() -> Basis:
	return Basis.from_euler(Vector3(
		deg_to_rad(-pitch_angle),
		deg_to_rad(yaw_angle),
		deg_to_rad(roll_angle)
	))

## Aplica a rotação fixa à câmera garantindo o enquadramento isométrico
func _apply_camera_rotation() -> void:
	basis = _get_isometric_basis()

## Calcula o vetor de deslocamento (Offset Vector) a partir da rotação e distância
func _calculate_offset_vector(distance: float) -> Vector3:
	return _get_isometric_basis() * Vector3(0.0, 0.0, distance)

## Implementação padrão do algoritmo Vector3 SmoothDamp (Game Math / Unity standard)
static func smooth_damp_v3(current: Vector3, target: Vector3, current_vel: Vector3, smooth_t: float, delta: float, max_speed: float = INF) -> Array:
	smooth_t = maxf(0.0001, smooth_t)
	var omega: float = 2.0 / smooth_t
	var x: float = omega * delta
	var exp_factor: float = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change: Vector3 = current - target
	var original_to: Vector3 = target

	var max_change: float = max_speed * smooth_t
	var change_len: float = change.length()
	if change_len > max_change and change_len > 0.0:
		change = (change / change_len) * max_change

	var target_adjusted: Vector3 = current - change
	var temp: Vector3 = (current_vel + omega * change) * delta
	var new_vel: Vector3 = (current_vel - omega * temp) * exp_factor
	var new_pos: Vector3 = target_adjusted + (change + temp) * exp_factor

	# Previne overshoot elástico além do alvo
	if (original_to - current).dot(new_pos - original_to) > 0.0:
		new_pos = original_to
		new_vel = (new_pos - original_to) / delta

	return [new_pos, new_vel]

## Detecta a direção de movimento horizontal do alvo para o Look-Ahead
func _get_target_movement_direction() -> Vector3:
	if target_node is CharacterBody3D:
		var v = (target_node as CharacterBody3D).velocity
		var h_vel = Vector3(v.x, 0.0, v.z)
		if h_vel.length() > 0.3:
			return h_vel.normalized()
	elif target_node.has_method("get_forward_vector"):
		return target_node.get_forward_vector()
	return Vector3.ZERO

# ==============================================================================
# SISTEMA DE OCLUSÃO / TRANSPARÊNCIA (SEE-THROUGH FADE)
# ==============================================================================

func _update_occlusion_fade(delta: float, focus_point: Vector3) -> void:
	if not occlusion_fade_enabled:
		_restore_all_occluders(delta)
		return
		
	var space = get_world_3d().direct_space_state
	if not space:
		return
		
	var query = PhysicsRayQueryParameters3D.create(global_position, focus_point)
	query.collision_mask = occlusion_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var excludes: Array[RID] = []
	if target_node is CollisionObject3D:
		excludes.append((target_node as CollisionObject3D).get_rid())
	query.exclude = excludes
	
	var current_hits: Dictionary = {}
	var ray_from = global_position
	
	# Raycast sequencial permitindo atravessar até 3 obstáculos na linha de visão
	for _i in range(3):
		query.from = ray_from
		var hit = space.intersect_ray(query)
		if hit.is_empty():
			break
			
		var collider = hit.get("collider")
		if collider:
			# Ignora terreno, chão e o próprio alvo
			if collider == target_node or collider.name == "Ground" or collider is Terrain3D or collider.is_in_group("terrain") or collider.is_in_group("flower"):
				break
				
			_collect_occluder_geometries(collider, current_hits)
			
			var hit_pos: Vector3 = hit.get("position")
			var step_dir = (focus_point - hit_pos).normalized()
			ray_from = hit_pos + (step_dir * 0.35)
			if ray_from.distance_squared_to(focus_point) < 0.5:
				break
		else:
			break
			
	# 1. Aplica esmaecimento suave nos obstáculos interceptados
	for geo in current_hits.keys():
		if is_instance_valid(geo):
			active_occluders[geo] = true
			geo.transparency = lerp(geo.transparency, occluded_transparency, clampf(delta * occlusion_fade_speed, 0.0, 1.0))
			
	# 2. Restaura opacidade original quando a visão é desobstruída
	var to_remove: Array[GeometryInstance3D] = []
	for geo in active_occluders.keys():
		if not is_instance_valid(geo):
			to_remove.append(geo)
			continue
		if not current_hits.has(geo):
			geo.transparency = move_toward(geo.transparency, 0.0, delta * (occlusion_fade_speed * 0.6))
			if geo.transparency <= 0.02:
				geo.transparency = 0.0
				to_remove.append(geo)
				
	for geo in to_remove:
		active_occluders.erase(geo)

func _collect_occluder_geometries(node: Node, out_dict: Dictionary) -> void:
	if not node:
		return
	if node is GeometryInstance3D:
		out_dict[node] = true
	for child in node.find_children("*", "GeometryInstance3D", true, false):
		out_dict[child] = true

func _restore_all_occluders(delta: float) -> void:
	var to_remove: Array[GeometryInstance3D] = []
	for geo in active_occluders.keys():
		if is_instance_valid(geo):
			geo.transparency = move_toward(geo.transparency, 0.0, delta * occlusion_fade_speed)
			if geo.transparency <= 0.02:
				geo.transparency = 0.0
				to_remove.append(geo)
		else:
			to_remove.append(geo)
	for geo in to_remove:
		active_occluders.erase(geo)

# ==============================================================================
# INPUTS DE ZOOM (MOUSE WHEEL, PINCH TOUCH & TECLADO)
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not enable_zoom_input:
		return
	if GameManager.is_in_intro or GameManager.is_in_cutscene:
		return
		
	# 1. Mouse Wheel Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_out()
			
	# 2. Pinça Touch / Trackpad (InputEventMagnifyGesture)
	elif event is InputEventMagnifyGesture:
		var delta_dist = (event.factor - 1.0) * zoom_step * 3.5
		target_distance = clampf(target_distance - delta_dist, min_distance, max_distance)
		target_zoom_mult = target_distance / default_distance
		
	# 3. Teclado (+ / - / PageUp / PageDown)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD or event.keycode == KEY_PAGEUP:
			zoom_in()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_PAGEDOWN:
			zoom_out()

func zoom_in(amount: float = -1.0) -> void:
	var step = zoom_step if amount < 0 else amount
	target_distance = clampf(target_distance - step, min_distance, max_distance)
	target_zoom_mult = target_distance / default_distance

func zoom_out(amount: float = -1.0) -> void:
	var step = zoom_step if amount < 0 else amount
	target_distance = clampf(target_distance + step, min_distance, max_distance)
	target_zoom_mult = target_distance / default_distance

# ==============================================================================
# MÉTODOS PÚBLICOS E RETROCOMPATIBILIDADE DE GAMEPLAY & CUTSCENES
# ==============================================================================

func set_zoom_immediate(zoom_ratio: float) -> void:
	target_zoom_mult = zoom_ratio
	target_distance = clampf(default_distance * zoom_ratio, min_distance, max_distance)
	current_distance = target_distance
	if target_node and is_instance_valid(target_node):
		var base_focus = target_node.global_position + Vector3(0.0, target_offset_y, 0.0)
		global_position = base_focus + _calculate_offset_vector(current_distance)

func focus_target(node: Node3D, zoom_ratio: float = 1.0, speed: float = 4.0) -> void:
	if not node or not is_instance_valid(node):
		return
	is_cinematic_focus = true
	target_node = node
	target_zoom_mult = zoom_ratio
	target_distance = clampf(default_distance * zoom_ratio, min_distance, max_distance)
	smooth_time = clampf(1.0 / maxf(0.5, speed), 0.08, 0.35)

func reset_focus(zoom_ratio: float = 1.0, speed: float = 4.5) -> void:
	is_cinematic_focus = false
	_resolve_default_target()
	target_node = default_target_node
	target_zoom_mult = zoom_ratio
	target_distance = clampf(default_distance * zoom_ratio, min_distance, max_distance)
	smooth_time = clampf(1.0 / maxf(0.5, speed), 0.08, 0.35)

func zoom_to_gameplay(duration: float = 3.6, on_complete: Callable = Callable()) -> void:
	is_cinematic_focus = false
	_resolve_default_target()
	target_node = default_target_node
	target_zoom_mult = 1.0
	
	if duration > 0.0:
		is_zooming_intro = true
		current_distance = intro_distance # Inicia bem alto (~32m a 34m)
		target_distance = default_distance
		smooth_time = 0.35
		
		var tree = get_tree()
		if tree:
			var tw = tree.create_tween()
			tw.tween_property(self, "current_distance", default_distance, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func():
				is_zooming_intro = false
				current_distance = default_distance
				target_distance = default_distance
				smooth_time = 0.18
				if on_complete.is_valid():
					on_complete.call()
			)
		else:
			is_zooming_intro = false
			current_distance = default_distance
			target_distance = default_distance
			smooth_time = 0.18
			if on_complete.is_valid():
				on_complete.call()
	else:
		is_zooming_intro = false
		current_distance = default_distance
		target_distance = default_distance
		smooth_time = 0.18
		if on_complete.is_valid():
			on_complete.call()

func start_credits_slow_zoom_out(duration: float = 20.0) -> void:
	is_cinematic_focus = true
	if GameManager.flower and is_instance_valid(GameManager.flower):
		target_node = GameManager.flower
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		target_node = GameManager.heroine
		
	target_distance = max_distance
	smooth_time = 0.45
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_property(self, "target_distance", max_distance, duration).set_trans(Tween.TRANS_SINE)

func _resolve_target() -> void:
	if not target_node or not is_instance_valid(target_node):
		_resolve_default_target()
		target_node = default_target_node

func _resolve_default_target() -> void:
	if has_node(target_path):
		default_target_node = get_node(target_path)
	elif GameManager.heroine and is_instance_valid(GameManager.heroine):
		default_target_node = GameManager.heroine
	elif is_inside_tree() and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			default_target_node = players[0]
