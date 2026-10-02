extends Control
class_name MinimapCanvas

@export var map_radius_meters: float = 48.0 # Raio do mapa de 100m (~48m em cada direção)

func _process(_delta: float) -> void:
	# Redesenhar a cada frame para rastreamento suave
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var draw_radius = minf(center.x, center.y) - 4.0
	
	# Fundo do Minimapa (Verde Musgo escuro)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.16, 0.22, 0.12, 0.88), true, -1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.MARROM_CASCA, false, 1.5)
	
	var grid = GameManager.grid_manager as GridManager
	if not grid:
		return
		
	# 1. Desenhar as trilhas sinuosas
	for cell in grid.path_cells.keys():
		var world_pos = grid.grid_to_world(cell, 0.0)
		var map_pos = world_to_minimap(world_pos, center, draw_radius)
		draw_circle(map_pos, 1.4, Color(0.48, 0.38, 0.28, 0.75))
		
	# 2. Desenhar as torres de gravetos
	for tw in grid.towers.values():
		if is_instance_valid(tw):
			var tw_map = world_to_minimap(tw.global_position, center, draw_radius)
			draw_circle(tw_map, 2.5, Tokens.LATAO_ENGRENAGEM)
			draw_arc(tw_map, 5.0, 0, TAU, 12, Color(Tokens.LATAO_ENGRENAGEM.r, Tokens.LATAO_ENGRENAGEM.g, Tokens.LATAO_ENGRENAGEM.b, 0.25), 1.0)
			
	# 3. Desenhar recursos no chão
	var tree = get_tree()
	if tree:
		var pickups = tree.get_nodes_in_group("pickups")
		for p in pickups:
			if is_instance_valid(p):
				var p_map = world_to_minimap(p.global_position, center, draw_radius)
				var alpha = 0.5 + sin(Time.get_ticks_msec() * 0.008) * 0.4
				draw_circle(p_map, 1.2, Color(Tokens.CREME_PERGAMINHO.r, Tokens.CREME_PERGAMINHO.g, Tokens.CREME_PERGAMINHO.b, alpha))
				
	# 4. Desenhar pragas (Inimigos)
	if tree:
		var enemies = tree.get_nodes_in_group("enemies")
		for en in enemies:
			if is_instance_valid(en):
				var en_map = world_to_minimap(en.global_position, center, draw_radius)
				draw_circle(en_map, 2.0, Tokens.PERIGO)
				
	# 5. Desenhar a Flor Central do Jardim (Objetivo)
	var flower_pos = center
	var t = Time.get_ticks_msec() * 0.003
	var flower_pulse = 3.5 + sin(t * 3.0) * 0.8
	draw_circle(flower_pos, flower_pulse, Color(0.88, 0.22, 0.38, 1.0))
	draw_arc(flower_pos, flower_pulse + 2.0, 0, TAU, 16, Color(1.0, 0.6, 0.7, 0.4), 1.0)
	
	# 6. Desenhar a heroína Pip
	if GameManager.heroine and is_instance_valid(GameManager.heroine):
		var pip = GameManager.heroine
		var pip_map = world_to_minimap(pip.global_position, center, draw_radius)
		draw_circle(pip_map, 3.2, Tokens.VERDE_FOLHA)
		draw_circle(pip_map, 1.5, Tokens.CREME_PERGAMINHO)
		
		# Indicador de direção
		var forward = -pip.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.01:
			var dir_2d = Vector2(forward.x, forward.z).normalized()
			draw_line(pip_map, pip_map + dir_2d * 5.0, Tokens.CREME_PERGAMINHO, 1.5)

func world_to_minimap(world_pos: Vector3, center: Vector2, max_radius: float) -> Vector2:
	var norm_x = clampf(world_pos.x / map_radius_meters, -1.0, 1.0)
	var norm_y = clampf(world_pos.z / map_radius_meters, -1.0, 1.0)
	return center + Vector2(norm_x * max_radius, norm_y * max_radius)
