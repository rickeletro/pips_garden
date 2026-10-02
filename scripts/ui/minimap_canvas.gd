extends Control
class_name MinimapCanvas

@export var map_radius_meters: float = 48.0 # Raio do mapa de 100m (~48m em cada direção)

func _process(_delta: float) -> void:
	# Redesenhar a cada frame para rastreamento suave e contínuo
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var draw_radius = minf(center.x, center.y) - 6.0
	if draw_radius <= 5.0:
		return
		
	# 1. Fundo do Radar (Verde musgo escuro com anéis de alcance)
	draw_circle(center, draw_radius, Color(0.12, 0.17, 0.09, 0.94))
	draw_arc(center, draw_radius, 0, TAU, 32, Tokens.MARROM_CASCA, 2.0)
	
	# Anéis concêntricos de radar (15m, 30m)
	var r1 = draw_radius * (15.0 / map_radius_meters)
	var r2 = draw_radius * (30.0 / map_radius_meters)
	draw_arc(center, r1, 0, TAU, 24, Color(Tokens.MARROM_CASCA.r, Tokens.MARROM_CASCA.g, Tokens.MARROM_CASCA.b, 0.25), 1.0)
	draw_arc(center, r2, 0, TAU, 24, Color(Tokens.MARROM_CASCA.r, Tokens.MARROM_CASCA.g, Tokens.MARROM_CASCA.b, 0.35), 1.0)
	
	# Linhas em cruz cardeais sutis
	draw_line(center - Vector2(draw_radius * 0.9, 0), center + Vector2(draw_radius * 0.9, 0), Color(0.3, 0.4, 0.25, 0.2), 1.0)
	draw_line(center - Vector2(0, draw_radius * 0.9), center + Vector2(0, draw_radius * 0.9), Color(0.3, 0.4, 0.25, 0.2), 1.0)
	
	# Marcadores Cardeais (N, S, L, O)
	var font = ThemeDB.fallback_font
	if font:
		var font_size = 9
		var col_card = Color(Tokens.CREME_PERGAMINHO.r, Tokens.CREME_PERGAMINHO.g, Tokens.CREME_PERGAMINHO.b, 0.75)
		draw_string(font, center + Vector2(-3, -draw_radius + 10), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col_card)
		draw_string(font, center + Vector2(-3, draw_radius - 3), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col_card)
		draw_string(font, center + Vector2(draw_radius - 10, 3), "L", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col_card)
		draw_string(font, center + Vector2(-draw_radius + 4, 3), "O", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col_card)

	var grid = GameManager.grid_manager as GridManager
	var tree = get_tree()
	
	# 2. Trilhas sinuosas de pedras
	if grid:
		for cell in grid.path_cells.keys():
			var world_pos = grid.grid_to_world(cell, 0.0)
			var map_pos = world_to_minimap(world_pos, center, draw_radius)
			draw_circle(map_pos, 2.2, Color(0.55, 0.44, 0.32, 0.85))
			draw_circle(map_pos, 1.0, Color(0.72, 0.62, 0.48, 0.9))

	# 3. Recursos coletáveis no chão e Dentes-de-Leão
	if tree:
		# Dentes-de-Leão (Pom-poms com sementes)
		var dandelions = tree.get_nodes_in_group("dandelion")
		for dand in dandelions:
			if is_instance_valid(dand):
				var dand_map = world_to_minimap(dand.global_position, center, draw_radius)
				var is_h = dand.get("is_harvested") == true
				if not is_h:
					draw_circle(dand_map, 2.4, Color(0.96, 0.96, 0.92, 0.8))
					draw_arc(dand_map, 3.8, 0, TAU, 8, Color(1.0, 1.0, 0.9, 0.35), 1.0)
					
		# Itens no chão (com sementes em dourado brilhante destacado)
		var pickups = tree.get_nodes_in_group("pickups")
		var pulse_glow = 0.5 + sin(Time.get_ticks_msec() * 0.007) * 0.4
		for p in pickups:
			if is_instance_valid(p):
				var p_map = world_to_minimap(p.global_position, center, draw_radius)
				var itype = p.get("item_type")
				if itype == "SEED":
					draw_circle(p_map, 2.5, Color(0.12, 0.08, 0.02, 1.0))
					draw_circle(p_map, 1.8, Color(1.0, 0.85, 0.22, pulse_glow))
				else:
					draw_circle(p_map, 1.5, Color(0.85, 0.85, 0.85, pulse_glow * 0.8))


	# 4. Torres de Defesa (Ícones nítidos com estado de vida / dano)
	if tree:
		var towers = tree.get_nodes_in_group("towers")
		for tw in towers:
			if is_instance_valid(tw):
				var tw_map = world_to_minimap(tw.global_position, center, draw_radius)
				var is_broken = tw.get("is_broken") == true
				var hp_pct = 1.0
				if tw.get("max_hp") and tw.get("max_hp") > 0:
					hp_pct = clampf(float(tw.get("hp")) / float(tw.get("max_hp")), 0.0, 1.0)
					
				# Círculo de alcance da torre
				draw_arc(tw_map, 11.0, 0, TAU, 16, Color(Tokens.LATAO_ENGRENAGEM.r, Tokens.LATAO_ENGRENAGEM.g, Tokens.LATAO_ENGRENAGEM.b, 0.18), 1.0)
				
				# Cor da torre: muda de Latão Dourado para Vermelho de Alerta quando danificada!
				var tower_color = Tokens.LATAO_ENGRENAGEM.lerp(Tokens.PERIGO, (1.0 - hp_pct) * 0.85)
				if is_broken:
					tower_color = Tokens.PERIGO
					
				# Borda preta de alto contraste + corpo da torre
				draw_circle(tw_map, 4.8, Color(0.1, 0.06, 0.02, 1.0))
				draw_circle(tw_map, 3.6, tower_color)
				
				# Anel indicador de saúde da torre
				var ring_col = Color(0.3, 0.85, 0.3) if hp_pct > 0.6 else (Color(1.0, 0.75, 0.2) if hp_pct > 0.3 else Tokens.PERIGO)
				draw_arc(tw_map, 5.2, -PI * 0.5, -PI * 0.5 + TAU * hp_pct, 12, ring_col, 1.4)
				
				# Se quebrada, desenha '!' de alerta
				if is_broken and font:
					var blink = sin(Time.get_ticks_msec() * 0.015) > 0.0
					if blink:
						draw_string(font, tw_map + Vector2(-2, 4), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1, 1, 1))

	# 5. Hordas / Inimigos se locomovendo (Marcadores vermelhos bem visíveis e animados)
	if tree:
		var enemies = tree.get_nodes_in_group("enemies")
		var time_ms = Time.get_ticks_msec()
		for en in enemies:
			if is_instance_valid(en):
				var en_map = world_to_minimap(en.global_position, center, draw_radius)
				var is_flying = en.get("is_flying") == true
				
				if is_flying:
					# Vespa / Voador: Losango amarelo-alaranjado com asas
					var pulse = sin(time_ms * 0.015) * 1.0
					draw_rect(Rect2(en_map - Vector2(3.5, 3.5), Vector2(7, 7)), Color(0.1, 0.0, 0.0, 1.0), true)
					draw_rect(Rect2(en_map - Vector2(2.5, 2.5), Vector2(5, 5)), Color(1.0, 0.5, 0.1, 1.0), true)
					draw_circle(en_map, 1.5, Color(1.0, 0.9, 0.3, 1.0))
					draw_arc(en_map, 5.0 + pulse, 0, TAU, 8, Color(1.0, 0.6, 0.1, 0.5), 1.0)
				else:
					# Pragas terrestres (pulgões, lagartas): Ponto vermelho vivo com borda escura e halo
					var pulse = 0.5 + sin(time_ms * 0.012) * 0.5
					draw_circle(en_map, 4.4, Color(0.12, 0.0, 0.0, 1.0)) # Borda escura para contraste
					draw_circle(en_map, 3.2, Tokens.PERIGO) # Vermelho vibrante
					draw_circle(en_map, 1.3, Color(1.0, 0.75, 0.6, 1.0)) # Núcleo brilhante
					draw_arc(en_map, 5.0 + pulse * 1.2, 0, TAU, 10, Color(Tokens.PERIGO.r, Tokens.PERIGO.g, Tokens.PERIGO.b, 0.35), 1.0)

	# 6. Flor Central do Jardim (Objetivo Principal)
	var flower_pos = center
	var flower_hp_pct = 1.0
	if GameManager.flower_max_hp > 0.0:
		flower_hp_pct = clampf(GameManager.flower_hp / GameManager.flower_max_hp, 0.0, 1.0)
		
	var t_flower = Time.get_ticks_msec() * 0.003
	var flower_pulse = 4.2 + sin(t_flower * 3.0) * 0.8
	
	# Cor da Flor Central varia com o dano: Rosa vibrante -> Vermelho machucado
	var flower_col = Color(0.92, 0.25, 0.38, 1.0).lerp(Tokens.PERIGO, (1.0 - flower_hp_pct) * 0.9)
	draw_circle(flower_pos, flower_pulse + 1.5, Color(0.12, 0.05, 0.08, 1.0))
	draw_circle(flower_pos, flower_pulse, flower_col)
	draw_circle(flower_pos, 2.0, Color(1.0, 0.85, 0.2, 1.0)) # Núcleo dourado
	
	# Anel de vida da Flor Central
	var flower_ring_col = Color(0.4, 0.9, 0.3) if flower_hp_pct > 0.6 else (Color(1.0, 0.8, 0.2) if flower_hp_pct > 0.3 else Tokens.PERIGO)
	draw_arc(flower_pos, flower_pulse + 3.2, -PI * 0.5, -PI * 0.5 + TAU * flower_hp_pct, 16, flower_ring_col, 1.8)

	# 7. Heroína Pip (O Player: marcador de alta visibilidade com pulso radar e ponteiro de direção)
	if GameManager.heroine and is_instance_valid(GameManager.heroine):
		var pip = GameManager.heroine
		var pip_map = world_to_minimap(pip.global_position, center, draw_radius)
		var t_pip = Time.get_ticks_msec() * 0.006
		var ping_radius = 5.0 + fmod(t_pip * 4.0, 9.0)
		var ping_alpha = clampf(1.0 - (ping_radius - 5.0) / 9.0, 0.0, 1.0)
		
		# Pulso de sonar/radar em volta de Pip
		draw_arc(pip_map, ping_radius, 0, TAU, 16, Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, ping_alpha * 0.8), 1.5)
		
		# Borda de contraste escura + Círculo Dourado Radiante + Centro Branco
		draw_circle(pip_map, 5.6, Color(0.08, 0.06, 0.02, 1.0))
		draw_circle(pip_map, 4.4, Tokens.DOURADO_LUZ)
		draw_circle(pip_map, 2.0, Color(1.0, 1.0, 1.0, 1.0))
		
		# Indicador direcional de visão/movimento de Pip (triângulo agudo)
		var forward = -pip.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.01:
			var dir_2d = Vector2(forward.x, forward.z).normalized()
			var tip = pip_map + dir_2d * 8.5
			var side1 = pip_map + Vector2(-dir_2d.y, dir_2d.x) * 3.5
			var side2 = pip_map - Vector2(-dir_2d.y, dir_2d.x) * 3.5
			draw_colored_polygon(PackedVector2Array([tip, side1, side2]), Tokens.DOURADO_LUZ)
			draw_polyline(PackedVector2Array([side1, tip, side2]), Color(0.1, 0.06, 0.02, 1.0), 1.2)

func world_to_minimap(world_pos: Vector3, center: Vector2, max_radius: float) -> Vector2:
	var norm_x = clampf(world_pos.x / map_radius_meters, -1.0, 1.0)
	var norm_y = clampf(world_pos.z / map_radius_meters, -1.0, 1.0)
	return center + Vector2(norm_x * max_radius, norm_y * max_radius)
