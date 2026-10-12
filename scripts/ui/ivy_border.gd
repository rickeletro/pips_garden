extends Control
class_name IvyBorderCanvas

# IvyBorderCanvas - Moldura botânica viva de hera / trepadeira
# Desenha ramos curvos, folhas de hera de vários tamanhos e gavinhas que emolduram a tela inteira.

@export var border_thickness: float = 42.0
@export var animate_wind: bool = true

var leaves_data: Array[Dictionary] = []
var vines_paths: Array[PackedVector2Array] = []
var flowers_data: Array[Dictionary] = []
var last_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate_ivy_elements()

func _process(_delta: float) -> void:
	if size != last_size:
		_generate_ivy_elements()
	if animate_wind:
		queue_redraw()

func _generate_ivy_elements() -> void:
	last_size = size
	leaves_data.clear()
	vines_paths.clear()
	flowers_data.clear()
	
	if size.x < 100 or size.y < 100:
		return
		
	var w = size.x
	var h = size.y
	var margin = 26.0
	
	# 1. Traçados principais das trepadeiras (ramos curvos ao longo das bordas)
	# Borda Superior
	vines_paths.append(_generate_wavy_vine(Vector2(margin, margin), Vector2(w - margin, margin), Vector2(0, 1), 22))
	vines_paths.append(_generate_wavy_vine(Vector2(margin + 40, margin + 8), Vector2(w - margin - 40, margin + 6), Vector2(0, 1), 16))
	
	# Borda Inferior
	vines_paths.append(_generate_wavy_vine(Vector2(margin, h - margin), Vector2(w - margin, h - margin), Vector2(0, -1), 22))
	vines_paths.append(_generate_wavy_vine(Vector2(margin + 40, h - margin - 8), Vector2(w - margin - 40, h - margin - 6), Vector2(0, -1), 16))
	
	# Borda Esquerda
	vines_paths.append(_generate_wavy_vine(Vector2(margin, margin), Vector2(margin, h - margin), Vector2(1, 0), 18))
	vines_paths.append(_generate_wavy_vine(Vector2(margin + 8, margin + 40), Vector2(margin + 6, h - margin - 40), Vector2(1, 0), 14))
	
	# Borda Direita
	vines_paths.append(_generate_wavy_vine(Vector2(w - margin, margin), Vector2(w - margin, h - margin), Vector2(-1, 0), 18))
	vines_paths.append(_generate_wavy_vine(Vector2(w - margin - 8, margin + 40), Vector2(w - margin - 6, h - margin - 40), Vector2(-1, 0), 14))
	
	# 2. Cantos com ramos adicionais em arco espiralado para dentro
	var corner_len = 110.0
	# Canto Superior Esquerdo
	vines_paths.append(_generate_corner_vine(Vector2(margin, margin), Vector2(margin + corner_len, margin + 28), Vector2(margin + 28, margin + corner_len)))
	# Canto Superior Direito
	vines_paths.append(_generate_corner_vine(Vector2(w - margin, margin), Vector2(w - margin - corner_len, margin + 28), Vector2(w - margin - 28, margin + corner_len)))
	# Canto Inferior Esquerdo
	vines_paths.append(_generate_corner_vine(Vector2(margin, h - margin), Vector2(margin + corner_len, h - margin - 28), Vector2(margin + 28, h - margin - corner_len)))
	# Canto Inferior Direito
	vines_paths.append(_generate_corner_vine(Vector2(w - margin, h - margin), Vector2(w - margin - corner_len, h - margin - 28), Vector2(w - margin - 28, h - margin - corner_len)))
	
	# 3. Povoar folhas de hera ao longo dos ramos
	_populate_leaves(w, h, margin)

func _generate_wavy_vine(start_pt: Vector2, end_pt: Vector2, inward_normal: Vector2, segments: int) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var dir = end_pt - start_pt
	var len_val = dir.length()
	if len_val < 1.0:
		return pts
		
	var step = len_val / float(segments)
	var forward = dir.normalized()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var base_p = start_pt + forward * (t * len_val)
		# Ondulação senoidal orgânica
		var wave_amp = sin(t * TAU * 3.5 + start_pt.x * 0.05) * 7.5 + (sin(t * TAU * 7.0) * 3.5)
		var final_p = base_p + inward_normal * wave_amp
		pts.append(final_p)
		
	return pts

func _generate_corner_vine(corner_pt: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var steps = 18
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		# Quadratic bezier curling inwards
		var pt = (1.0 - t) * (1.0 - t) * corner_pt + 2.0 * (1.0 - t) * t * ((p1 + p2) * 0.5 + (corner_pt - (p1 + p2) * 0.5) * -0.2) + t * t * ((p1 + p2) * 0.5)
		pts.append(pt)
	return pts

func _populate_leaves(w: float, h: float, margin: float) -> void:
	# Cores botânicas harmoniosas (verde musgo, verde oliva, verde folha vibrante, creme)
	var leaf_colors = [
		Color(0.22, 0.46, 0.20, 0.95), # Verde bosque profundo
		Color(0.28, 0.58, 0.25, 0.95), # Verde hera vibrante
		Color(0.36, 0.68, 0.30, 0.92), # Broto jovem claro
		Color(0.18, 0.38, 0.16, 0.98), # Verde escuro de sombra
		Color(0.42, 0.62, 0.24, 0.90)  # Verde oliva aconchegante
	]
	
	for path in vines_paths:
		for i in range(1, path.size() - 1, 2):
			var pos = path[i]
			var next_pos = path[i + 1]
			var tangent = (next_pos - pos).normalized()
			var normal = Vector2(-tangent.y, tangent.x)
			
			# Folha primária
			var side = 1.0 if (i % 4 == 0) else -1.0
			var angle = atan2(tangent.y, tangent.x) + (side * randf_range(0.4, 1.2))
			var size_scale = randf_range(11.0, 18.0)
			var col = leaf_colors[randi() % leaf_colors.size()]
			
			leaves_data.append({
				"pos": pos + normal * randf_range(-4.0, 6.0),
				"angle": angle,
				"scale": size_scale,
				"color": col,
				"sway_speed": randf_range(1.5, 3.2),
				"sway_offset": randf() * 10.0
			})
			
			# Pequenas flores brancas/amarelas pontuais (jasmim / flor do bosque)
			if randf() < 0.18:
				flowers_data.append({
					"pos": pos + normal * (side * 12.0),
					"scale": randf_range(4.0, 6.5),
					"sway_offset": randf() * 10.0
				})
				
	# Densidade extra reforçada nos 4 cantos da tela (para criar moldura rica)
	var corners = [
		Vector2(margin + 12, margin + 12),
		Vector2(w - margin - 12, margin + 12),
		Vector2(margin + 12, h - margin - 12),
		Vector2(w - margin - 12, h - margin - 12)
	]
	
	for c_pos in corners:
		for k in range(8):
			var ang = randf() * TAU
			var dist = randf_range(10.0, 48.0)
			leaves_data.append({
				"pos": c_pos + Vector2(cos(ang), sin(ang)) * dist,
				"angle": ang + PI * 0.5,
				"scale": randf_range(13.0, 22.0),
				"color": leaf_colors[randi() % leaf_colors.size()],
				"sway_speed": randf_range(1.2, 2.5),
				"sway_offset": randf() * 10.0
			})

func _draw() -> void:
	var t = Time.get_ticks_msec() * 0.001
	
	# 1. Desenha os caules/ramos principais da trepadeira (Marrom casca / verde galho)
	var vine_mat_col = Color(0.18, 0.28, 0.12, 0.95)
	var vine_accent_col = Color(0.28, 0.42, 0.20, 0.85)
	
	for path in vines_paths:
		if path.size() > 1:
			draw_polyline(path, vine_mat_col, 3.8, true)
			draw_polyline(path, vine_accent_col, 1.8, true)
			
	# 2. Desenha cada folha de hera com silhueta e nervura central
	for leaf in leaves_data:
		var pos = leaf["pos"]
		var base_angle = leaf["angle"]
		var s = leaf["scale"]
		var col = leaf["color"]
		var sway = sin(t * leaf["sway_speed"] + leaf["sway_offset"]) * 0.12
		var angle = base_angle + sway
		
		_draw_ivy_leaf(pos, angle, s, col)
		
	# 3. Desenha flores delicadas nos ramos
	for fl in flowers_data:
		var pos = fl["pos"]
		var s = fl["scale"]
		var sway = sin(t * 2.0 + fl["sway_offset"]) * 0.08
		_draw_flower(pos, s, sway)

func _draw_ivy_leaf(center_pos: Vector2, angle: float, leaf_size: float, col: Color) -> void:
	# Geometria clássica de folha de hera (3 pontas botânicas: ponta central alongada e duas asas laterais)
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var base_poly = [
		Vector2(0, 0),                           # Haste / base
		Vector2(-0.45 * leaf_size, -0.35 * leaf_size), # Asa esquerda
		Vector2(-0.35 * leaf_size, -0.65 * leaf_size), # Ponta lateral esquerda
		Vector2(-0.15 * leaf_size, -0.75 * leaf_size), # Reentrância esquerda
		Vector2(0, -1.05 * leaf_size),                 # Ponta central principal
		Vector2(0.15 * leaf_size, -0.75 * leaf_size),  # Reentrância direita
		Vector2(0.35 * leaf_size, -0.65 * leaf_size),  # Ponta lateral direita
		Vector2(0.45 * leaf_size, -0.35 * leaf_size),  # Asa direita
	]
	
	var transformed_pts = PackedVector2Array()
	for pt in base_poly:
		var rx = pt.x * cos_a - pt.y * sin_a
		var ry = pt.x * sin_a + pt.y * cos_a
		transformed_pts.append(center_pos + Vector2(rx, ry))
		
	# Preenchimento da folha
	draw_colored_polygon(transformed_pts, col)
	
	# Borda suave de contraste
	var border_col = Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.9)
	draw_polyline(transformed_pts, border_col, 1.2, true)
	
	# Nervura central delicada
	var tip_rx = (0 * cos_a) - (-0.95 * leaf_size * sin_a)
	var tip_ry = (0 * sin_a) + (-0.95 * leaf_size * cos_a)
	var vein_col = Color(1.0, 1.0, 0.8, 0.45)
	draw_line(center_pos, center_pos + Vector2(tip_rx, tip_ry), vein_col, 1.0, true)

func _draw_flower(center_pos: Vector2, flower_size: float, rot_offset: float) -> void:
	# Florzinha branca de 5 pétalas no estilo jasmim do bosque
	var petals_count = 5
	var petal_col = Color(0.98, 0.98, 0.94, 0.95)
	
	for i in range(petals_count):
		var a = (float(i) / float(petals_count)) * TAU + rot_offset
		var dir = Vector2(cos(a), sin(a))
		var petal_pos = center_pos + dir * (flower_size * 0.65)
		draw_circle(petal_pos, flower_size * 0.45, petal_col)
		
	# Miolo dourado brilhante
	draw_circle(center_pos, flower_size * 0.32, Color(1.0, 0.85, 0.22, 1.0))
