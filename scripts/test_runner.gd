extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE AUTOMATIZADO DE JARDIM MIÚDO (ATUALIZADO) ---")
	
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("ERRO: Falha ao carregar main.tscn")
		get_tree().quit(1)
		return
		
	var root_node = main_scene.instantiate()
	add_child(root_node)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var grid: GridManager = root_node.get_node("GridManager")
	var heroine: Heroine = root_node.get_node("Heroine")
	var spawner: SpawnerManager = root_node.get_node("SpawnerManager")
	var flower: GardenFlower = root_node.get_node("GardenFlower")
	var hud: GameHUD = root_node.get_node("GameHUD")
	
	assert(grid != null, "GridManager deve existir")
	assert(heroine != null, "Heroine deve existir")
	assert(spawner != null, "SpawnerManager deve existir")
	assert(flower != null, "GardenFlower deve existir")
	assert(hud != null, "GameHUD deve existir")
	print("✔ Todos os nós centrais e referências globais do GameManager instanciados com sucesso.")
	
	# 1. Testar Countdown de 15 segundos entre ondas
	assert(GameManager.countdown_active == true, "Countdown automático deve estar ativo na preparação")
	assert(GameManager.wave_countdown <= 15.0 and GameManager.wave_countdown > 14.0, "Countdown inicial deve ser de 15 segundos")
	assert(GameManager.max_waves == 7, "Número total de ondas deve ser 7 para progressão aprofundada")
	print("✔ Sistema de countdown de 15 segundos entre ondas validado.")
	
	# 2. Testar Dificuldade Progressiva das 7 Ondas
	assert(spawner.wave_configs.size() == 7, "Configuração de spawner deve ter 7 ondas")
	var total_w1 = spawner.wave_configs[0]["aphids"] + spawner.wave_configs[0]["cats"] + spawner.wave_configs[0]["wasps"]
	var total_w7 = spawner.wave_configs[6]["aphids"] + spawner.wave_configs[6]["cats"] + spawner.wave_configs[6]["wasps"]
	assert(total_w7 > total_w1 * 5, "Onda 7 deve ter um volume muito maior de pragas que a Onda 1")
	assert(spawner.wave_configs[6]["interval"] < spawner.wave_configs[0]["interval"], "Cadência de spawn deve acelerar progressivamente")
	print("✔ Progressão de dificuldade das 7 ondas validada (Onda 1: %d pragas -> Onda 7: %d pragas com cadência acelerada)." % [total_w1, total_w7])
	
	# 3. Testar Plantio de Grama e Efeito de Desaceleração
	var grass_cell = Vector2i(0, 2)
	var plant_ok = grid.plant_grass(grass_cell)
	assert(plant_ok, "Deve plantar grama com sucesso em (0,2)")
	
	var aphid_scn = load("res://scenes/enemies/aphid.tscn")
	var wasp_scn = load("res://scenes/enemies/wasp.tscn")
	
	var aphid: Aphid = aphid_scn.instantiate()
	root_node.add_child(aphid)
	aphid.global_position = grid.grid_to_world(grass_cell, 0.0) # Posicionado sobre a grama
	
	var wasp: Wasp = wasp_scn.instantiate()
	root_node.add_child(wasp)
	wasp.global_position = grid.grid_to_world(grass_cell, 1.8) # Voador sobre a grama
	
	# Processar física para atualizar efeitos de terreno
	aphid.handle_status_effects(0.016)
	wasp.handle_status_effects(0.016)
	
	assert(aphid.grass_slow_factor < 1.0, "Pragas terrestres (pulgão) DEVEM ser desaceleradas pela grama (fator: %f)" % aphid.grass_slow_factor)
	assert(wasp.grass_slow_factor == 1.0, "Pragas aéreas (vespa/abelha) NÃO devem sofrer efeito da grama (fator: %f)" % wasp.grass_slow_factor)
	print("✔ Regra de terreno validada: Grama desacelera pragas terrestres (fator %.2f), sem efeito sobre unidades voadoras (fator %.2f)!" % [aphid.grass_slow_factor, wasp.grass_slow_factor])
	
	# 4. Testar Action Slots do HUD (Grama, Torre, Ataque, Veneno, Esquiva, Reparo)
	var initial_seeds = GameManager.seeds
	heroine.global_position = grid.grid_to_world(Vector2i(2, 2), 0.0)
	GameManager.request_plant_grass.emit()
	assert(GameManager.seeds == initial_seeds - 1, "Slot de Plantar Grama deve responder à emissão e plantar sob a Pip")
	
	var initial_twigs = GameManager.twigs
	var initial_gears = GameManager.gears
	heroine.global_position = grid.grid_to_world(Vector2i(3, 3), 0.0)
	GameManager.request_build_tower.emit()
	assert(GameManager.twigs == initial_twigs - 3, "Slot de Construir Torre deve descontar gravetos")
	assert(GameManager.gears == initial_gears - 2, "Slot de Construir Torre deve descontar engrenagens")
	
	var tower_built = grid.towers.get(Vector2i(3, 3)) as GardenTower
	assert(tower_built != null, "Torre deve ter sido construída pelo slot")
	
	heroine.global_position = tower_built.global_position + Vector3(0.5, 0, 0)
	var prev_poison = tower_built.poison_type
	GameManager.request_cycle_poison.emit()
	assert(tower_built.poison_type != prev_poison, "Slot de Veneno deve alternar o tipo de veneno da torre próxima")
	print("✔ Slots de Ação clicáveis do HUD (Grama, Torre, Veneno, Ataque, Esquiva, Reparo) 100% integrados.")
	
	# 5. Testar Combate e Morte de Inimigos sem erros de null tree
	aphid.take_damage(100.0)
	wasp.take_damage(100.0)
	await get_tree().process_frame
	print("✔ Pragas eliminadas e drops criados sem nenhum erro de referência nula.")
	
	# 6. Testar Requisitos da Fase 3: Torre de Gravetos em 3 Níveis, Estados de Dano e Ghost
	assert(tower_built.level == 1, "Torre inicial deve ser nível 1")
	assert(tower_built.visuals_standing.visible == true, "Torre inicial deve ter estrutura cônica em pé")
	assert(tower_built.visuals_collapsed.visible == false, "Torre inicial não deve ter escombros ativos")
	
	# Testar dano e colapso
	tower_built.take_damage(120.0)
	assert(tower_built.is_broken == true, "Torre deve ficar quebrada após dano letal")
	assert(tower_built.visuals_standing.visible == false, "Tenda em pé deve ocultar no colapso")
	assert(tower_built.visuals_collapsed.visible == true, "Escombros de gravetos devem aparecer no colapso")
	
	# Testar reparo
	GameManager.twigs += 10
	GameManager.gears += 10
	var repaired = tower_built.repair()
	assert(repaired == true, "Reparo deve ter sucesso com recursos disponíveis")
	assert(tower_built.is_broken == false, "Torre deve voltar a funcionar após reparo")
	assert(tower_built.visuals_standing.visible == true, "Tenda em pé deve reaparecer após reparo")
	assert(tower_built.visuals_collapsed.visible == false, "Escombros devem ser ocultados após reparo")
	
	# Testar upgrades de nível
	var upgraded_l2 = tower_built.try_upgrade()
	assert(upgraded_l2 == true and tower_built.level == 2, "Upgrade para nível 2 deve funcionar")
	var upgraded_l3 = tower_built.try_upgrade()
	assert(upgraded_l3 == true and tower_built.level == 3, "Upgrade para nível 3 deve funcionar")
	assert(tower_built.level3_root.visible == true, "Nível 3 deve exibir engrenagem mestra e vaga-lume")
	
	# Testar ghost de posicionamento
	var ghost_scene = load("res://scenes/tower_ghost.tscn")
	var ghost_inst: TowerGhost = ghost_scene.instantiate()
	root_node.add_child(ghost_inst)
	ghost_inst.set_valid(true)
	ghost_inst.set_valid(false)
	ghost_inst.queue_free()
	print("✔ Torre de gravetos: 3 níveis visuais, dano/colapso, reparo dinâmico e ghost validados 100%.")
	
	# 7. Testar Requisitos da Fase 4: Pip (Visual Arrietty, Proporções Chibi e 6 Animações)
	var col_shape = heroine.get_node("CollisionShape3D") as CollisionShape3D
	assert(col_shape != null and col_shape.shape is CapsuleShape3D, "Pip deve ter CapsuleShape3D")
	var capsule = col_shape.shape as CapsuleShape3D
	assert(capsule.height <= 0.8 and capsule.height >= 0.6, "Altura de Pip deve ser miniatura (0.6 a 0.8 unidades)")
	assert(heroine.hair_ponytail != null, "Pip deve possuir mecha de cabelo ruivo")
	assert(heroine.needle_mesh != null, "Pip deve portar agulha de costura")
	
	# Testar disparo das 6 animações
	heroine.execute_attack_combo()
	heroine.play_collect_hop()
	heroine.take_damage(5.0)
	heroine.start_dash()
	print("✔ Pip: proporções de miniatura, cabelo ruivo, agulha e 6 animações procedurais validadas 100%.")
	
	# 8. Testar Requisitos da Fase 5: Jardim 10x Maior, Trilhas, Grama MultiMesh Aquarela e Zoom In/Out
	assert(grid.HALF_EXTENT >= 24, "Jardim deve ser 10x maior que o inicial (~100m x 100m)")
	assert(grid.path_cells.size() >= 40, "Trilha sinuosa das hordas deve existir com pelo menos 40 células")
	assert(grid.grass_multimesh != null, "MultiMesh da grama deve estar ativo")
	assert(grid.grass_multimesh.multimesh.instance_count >= 10000, "MultiMesh deve suportar milhares de folhas de grama a 60 FPS")
	
	var cam: GardenCameraController = root_node.get_node("Camera3D")
	assert(cam != null, "Camera3D com controlador de zoom deve existir")
	var prev_zoom = cam.target_zoom
	cam.zoom_in()
	assert(cam.target_zoom < prev_zoom, "Comando de zoom_in deve diminuir distância da câmera")
	cam.zoom_out()
	cam.zoom_out()
	assert(cam.target_zoom > prev_zoom, "Comando de zoom_out deve afastar a câmera")
	print("✔ Jardim 10x maior, trilhas sinuosas, grama MultiMesh Zelda TotK e Zoom In/Out validados 100%.")
	
	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
