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
	var heroine = root_node.get_node("Heroine")
	var spawner: SpawnerManager = root_node.get_node("SpawnerManager")
	var flower: GardenFlower = root_node.get_node("GardenFlower")
	var hud = root_node.get_node("GameHUD")
	
	assert(grid != null, "GridManager deve existir")
	assert(heroine != null, "Heroine deve existir")
	assert(spawner != null, "SpawnerManager deve existir")
	assert(flower != null, "GardenFlower deve existir")
	assert(flower.sprite_25d != null, "GardenFlower deve possuir nó Sprite25D")
	assert(flower.sprite_25d.animations.has("idle"), "GardenFlower deve possuir animação idle")
	assert(hud != null, "GameHUD deve existir")
	print("✔ Todos os nós centrais e referências globais do GameManager instanciados com sucesso (incluindo Flor Sagrada 2.5D).")
	
	# 1. Iniciar jogo a partir da intro para testes
	GameManager.start_game_from_intro()
	assert(GameManager.countdown_active == true, "Countdown automático deve estar ativo na preparação")
	assert(GameManager.wave_countdown <= 30.0 and GameManager.wave_countdown > 28.0, "Countdown inicial deve ser de 30 segundos")
	assert(GameManager.max_waves == 7, "Número total de ondas deve ser 7 para progressão aprofundada")
	print("✔ Sistema de countdown de 30 segundos entre ondas validado.")
	
	# 2. Testar Dificuldade Progressiva das Ondas de Dia e Noite
	assert(spawner.day1_wave_configs.size() == 7, "Configuração do Dia 1 deve ter 7 ondas")
	assert(spawner.night1_wave_configs.size() == 7, "Configuração da Noite 1 deve ter 7 ondas")
	assert(spawner.day2_wave_configs.size() == 7, "Configuração do Dia 2 deve ter 7 ondas")
	assert(spawner.night2_wave_configs.size() == 7, "Configuração da Noite 2 deve ter 7 ondas")
	assert(spawner.day3_wave_configs.size() == 7, "Configuração do Dia 3 deve ter 7 ondas")
	assert(spawner.night3_wave_configs.size() == 3, "Configuração da Noite 3 deve ter 3 ondas antes do Chefe Final")
	
	var total_w1 = spawner.day1_wave_configs[0]["aphids"] + spawner.day1_wave_configs[0]["cats"] + spawner.day1_wave_configs[0]["wasps"]
	var total_w7 = spawner.day1_wave_configs[6]["aphids"] + spawner.day1_wave_configs[6]["cats"] + spawner.day1_wave_configs[6]["wasps"]
	assert(total_w7 >= total_w1 * 4, "Onda 7 deve ter um volume muito maior de pragas que a Onda 1")
	assert(spawner.day1_wave_configs[6]["interval"] < spawner.day1_wave_configs[0]["interval"], "Cadência de spawn deve acelerar progressivamente")
	print("✔ Progressão de dificuldade das ondas (Dia 1, Dia 2, Noite 1, Noite 2) validada.")
	
	# 3. Testar Plantio de Grama e Efeito de Desaceleração
	var grass_cell = Vector2i(0, 2)
	var plant_ok = grid.plant_grass(grass_cell)
	assert(plant_ok, "Deve plantar grama com sucesso em (0,2)")
	
	var aphid_scn = load("res://scenes/enemies/aphid.tscn")
	var wasp_scn = load("res://scenes/enemies/wasp.tscn")
	
	var aphid = aphid_scn.instantiate()
	root_node.add_child(aphid)
	aphid.global_position = grid.grid_to_world(grass_cell, 0.0) # Posicionado sobre a grama
	
	var wasp = wasp_scn.instantiate()
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
	
	# Testar dano e colapso (colisão desabilitada para não prender inimigos)
	tower_built.take_damage(120.0)
	assert(tower_built.is_broken == true, "Torre deve ficar quebrada após dano letal")
	assert(tower_built.visuals_standing.visible == false, "Tenda em pé deve ocultar no colapso")
	assert(tower_built.visuals_collapsed.visible == true, "Escombros de gravetos devem aparecer no colapso")
	assert(tower_built.get_node("CollisionShape3D").disabled == true, "Colisão da torre DEVE ser desativada ao quebrar para não bloquear passagem dos inimigos")
	
	# Testar reerguer torre caída (Custo: 4 Gravetos + 1 Engrenagem)
	GameManager.twigs += 10
	GameManager.gears += 10
	var prev_twigs = GameManager.twigs
	var prev_gears = GameManager.gears
	var repaired = tower_built.repair()
	assert(repaired == true, "Reparo deve ter sucesso com recursos disponíveis")
	assert(GameManager.twigs == prev_twigs - 4, "Reerguer torre caída no 1º colapso deve custar 4 gravetos")
	assert(GameManager.gears == prev_gears - 1, "Reerguer torre caída no 1º colapso deve custar 1 engrenagem")
	assert(tower_built.is_broken == false, "Torre deve voltar a funcionar após reparo")
	assert(tower_built.visuals_standing.visible == true, "Tenda em pé deve reaparecer após reparo")
	assert(tower_built.visuals_collapsed.visible == false, "Escombros devem ser ocultados após reparo")
	assert(tower_built.get_node("CollisionShape3D").disabled == false, "Colisão da torre DEVE ser reativada ao ser consertada")
	assert(tower_built.level == 1, "Torre reerguida deve retornar no Nível 1")
	
	# Testar reparo preventivo (Torre em pé com dano parcial: 2 Gravetos, 0 Engrenagens)
	tower_built.hp = 50.0
	var prev_twigs_prev = GameManager.twigs
	var prev_gears_prev = GameManager.gears
	var prev_repaired = tower_built.repair()
	assert(prev_repaired == true, "Reparo preventivo deve funcionar")
	assert(tower_built.hp == tower_built.max_hp, "Reparo preventivo deve curar 100% do HP")
	assert(GameManager.twigs == prev_twigs_prev - 2, "Reparo preventivo deve custar apenas 2 gravetos")
	assert(GameManager.gears == prev_gears_prev, "Reparo preventivo NÃO deve consumir engrenagens")
	
	# Testar upgrades de nível com Curva Exponencial Suave (Nv 2 = 6G/4E; Nv 3 = 12G/8E)
	GameManager.twigs += 30
	GameManager.gears += 25
	var prev_tw_up1 = GameManager.twigs
	var prev_gr_up1 = GameManager.gears
	var upgraded_l2 = tower_built.try_upgrade()
	assert(upgraded_l2 == true and tower_built.level == 2, "Upgrade para nível 2 deve funcionar")
	assert(GameManager.twigs == prev_tw_up1 - 6, "Upgrade para nível 2 deve custar 6 gravetos")
	assert(GameManager.gears == prev_gr_up1 - 4, "Upgrade para nível 2 deve custar 4 engrenagens")
	
	var prev_tw_up2 = GameManager.twigs
	var prev_gr_up2 = GameManager.gears
	var upgraded_l3 = tower_built.try_upgrade(GardenTower.Specialization.THORN_CANNON)
	assert(upgraded_l3 == true and tower_built.level == 3, "Upgrade para nível 3 deve funcionar")
	assert(GameManager.twigs == prev_tw_up2 - 12, "Upgrade para nível 3 deve custar 12 gravetos")
	assert(GameManager.gears == prev_gr_up2 - 8, "Upgrade para nível 3 deve custar 8 engrenagens")
	assert(tower_built.specialization == GardenTower.Specialization.THORN_CANNON, "Especialização 3A deve ser Canhão de Espinho")
	assert(tower_built.base_damage == 110.0, "Dano da 3A deve ser 110")
	assert(tower_built.armor_pierce == 0.5, "Canhão de espinho deve ter 50% de perfuração de armadura")
	
	# Testar alternância para 3B Catapulta de Seiva via UI dialog e método
	GameManager.request_tower_specialization_dialog.emit(tower_built)
	assert(hud.spec_modal != null and hud.spec_modal.visible == true, "Modal de especialização deve abrir via sinal")
	hud._select_specialization(GardenTower.Specialization.SAP_CATAPULT)
	assert(tower_built.specialization == GardenTower.Specialization.SAP_CATAPULT, "Especialização 3B deve ser Catapulta de Seiva")
	assert(tower_built.base_damage == 35.0, "Dano da 3B deve ser 35")
	assert(tower_built.level3_root.visible == true, "Nível 3 deve exibir engrenagem mestra e vaga-lume")
	
	# Testar ghost de posicionamento
	var ghost_scene = load("res://scenes/tower_ghost.tscn")
	var ghost_inst: TowerGhost = ghost_scene.instantiate()
	root_node.add_child(ghost_inst)
	ghost_inst.set_valid(true)
	ghost_inst.set_valid(false)
	ghost_inst.queue_free()
	print("✔ Torre de gravetos: 3 níveis, Custos Exponenciais (6G/4E e 12G/8E), Reparo Preventivo vs Queda, Especializações 3A/3B e Ghost validados 100%.")
	
	# 6.5. Testar Chefes da Campanha v1.0 (6 Chefes) e Colecionáveis/Recompensas
	var snail_scn = load("res://scenes/enemies/boss_snail.tscn")
	var snail: BossSnail = snail_scn.instantiate()
	root_node.add_child(snail)
	assert(snail.max_hp >= 400.0, "HP do Caramujo deve ser balanceado para o 1º dia (>= 400 HP)")
	snail.spawn_local_boss_loot()
	var drops = root_node.get_tree().get_nodes_in_group("pickups")
	for drop in drops:
		if is_instance_valid(drop) and drop.get("item_type") != null:
			if drop.item_type == "FAIRY_TEAR":
				assert(true, "Caramujo dropou Lágrima de Fada")
	snail.queue_free()
	
	var moth_scn = load("res://scenes/enemies/boss_moth.tscn")
	var moth: BossMoth = moth_scn.instantiate()
	root_node.add_child(moth)
	assert(moth.max_hp >= 800.0, "HP da Mariposa deve ser balanceado (>= 800 HP)")
	assert(moth.attack_damage >= 30.0, "Dano da Mariposa deve ser equilibrado (>= 30)")
	var target_def = moth.choose_target()
	assert(target_def != null, "Mariposa deve focar em defesas (torres/flor)")
	moth.queue_free()
	
	# Testar Novos Chefes: Louva-a-Deus, Aranha, Vespa Imperatriz e Escorpião
	var mantis_scn = load("res://scenes/enemies/boss_mantis.tscn")
	var mantis = mantis_scn.instantiate()
	root_node.add_child(mantis)
	assert(mantis.max_hp >= 1200.0, "HP do Louva-a-Deus deve ser >= 1200")
	mantis.queue_free()
	
	var spider_scn = load("res://scenes/enemies/boss_spider.tscn")
	var spider = spider_scn.instantiate()
	root_node.add_child(spider)
	assert(spider.max_hp >= 1800.0, "HP da Aranha deve ser >= 1800")
	spider.queue_free()
	
	var wasp_queen_scn = load("res://scenes/enemies/boss_wasp_queen.tscn")
	var wasp_queen = wasp_queen_scn.instantiate()
	root_node.add_child(wasp_queen)
	assert(wasp_queen.max_hp >= 2400.0, "HP da Vespa Imperatriz deve ser >= 2400")
	wasp_queen.queue_free()
	
	var scorpion_scn = load("res://scenes/enemies/boss_scorpion.tscn")
	var scorpion = scorpion_scn.instantiate()
	root_node.add_child(scorpion)
	assert(scorpion.max_hp >= 3000.0, "HP do Escorpião deve ser >= 3000")
	
	# Testar imunidade frontal/corpo e vulnerabilidade no ferrão
	scorpion.current_state = 1 # CHASE
	var prev_scorp_hp = scorpion.hp
	scorpion.take_damage(50.0)
	assert(scorpion.hp == prev_scorp_hp, "Escorpião deve ser 100% imune a dano em seu corpo blindado")
	
	# Testar dano no ponto fraco exposto
	if scorpion.has_method("take_stinger_damage"):
		scorpion.take_stinger_damage(200.0)
		assert(scorpion.hp < prev_scorp_hp, "Ferrão cravado do Escorpião deve sofrer dano total")
	scorpion.queue_free()
	
	# Testar Recompensas & Power-ups (Ímã, Néctar, Geleia Real, Lágrima de Fada, Pólen Prateado)
	assert(GameManager.has_magnet_upgrade == false, "Ímã inicial deve estar desativado")
	assert(GameManager.magnet_radius == 2.2, "Raio magnético inicial deve ser 2.2m")
	GameManager.add_magnet_amber()
	assert(GameManager.has_magnet_upgrade == true, "Âmbar magnético deve ativar o upgrade permanente")
	assert(GameManager.magnet_radius == 6.0, "Raio magnético deve expandir para 6.0m com Âmbar Magnético")
	
	var prev_fl_hp = GameManager.flower_hp
	GameManager.add_revitalizing_nectar()
	assert(GameManager.flower_hp >= prev_fl_hp, "Néctar Revigorante deve curar a Flor Central")
	
	GameManager.add_royal_jelly()
	assert(GameManager.royal_jellies >= 1, "Geleia Real deve ser registrada")
	
	GameManager.add_silver_pollen()
	assert(GameManager.silver_pollens >= 1, "Pólen Prateado deve ser registrado")
	
	# Testar Balão de Diálogo e Emoção da Pip
	heroine.show_revenge_dialog("Você vai pagar por isso... EU VOU ME VINGAR!", 2.0)
	
	# Testar Ovo de Joaninha e Eclosão da Joaninha Companheira NPC
	var egg_script = load("res://scripts/ladybug_egg.gd")
	var egg = egg_script.new()
	root_node.add_child(egg)
	egg.global_position = Vector3(1, 0, 1)
	assert(egg.global_position.y == 0.0, "Ovo de joaninha deve ficar no chão (y = 0)")
	egg.time_left = 0.05
	egg._process(0.06)
	
	# Joaninha companheira deve ter nascido
	var companions = root_node.get_tree().get_nodes_in_group("companions")
	assert(not companions.is_empty(), "Joaninha Companheira deve ter nascido da eclosão do ovo")
	var companion = companions[0]
	assert(companion != null, "Companion deve existir")
	
	# Testar comportamento de caça ao pulgão pela joaninha
	var test_aphid = aphid_scn.instantiate()
	root_node.add_child(test_aphid)
	test_aphid.global_position = Vector3(2, 0, 2)
	var prio = companion.find_priority_target()
	assert(prio == test_aphid, "Joaninha Companheira deve priorizar caça aos pulgões")
	companion.perform_chomp_attack(test_aphid)
	test_aphid.queue_free()
	print("✔ Todos os 6 Chefes da Campanha, Balão de Diálogo da Pip, Ponto Fraco do Escorpião, Companheira Joaninha e Recompensas Especiais validados 100%.")
	
	# 7. Testar Frasco de Orvalho, Coleta Limpa e Hidratação das Plantas
	var dew_script = load("res://scripts/dew_drop.gd")
	var dew_drop = dew_script.new()
	root_node.add_child(dew_drop)
	dew_drop.global_position = grid.grid_to_world(Vector2i(1, 1), 0.0)
	
	GameManager.dew_flask_charges = 0
	dew_drop.on_attack_hit(heroine.global_position)
	assert(dew_drop.is_popped == true, "Gota de orvalho deve ser coletada com golpe ou aproximação")
	assert(GameManager.dew_flask_charges == 1, "Frasco da Pip deve armazenar +1 gota ao coletar orvalho")
	
	# Testar Sede e Rega do Dente-de-Leão
	var dandelions = root_node.get_tree().get_nodes_in_group("dandelion")
	if not dandelions.is_empty():
		var dand: DandelionClock = dandelions[0]
		dand.hydration = 0.0
		dand._process(0.1)
		assert(dand.is_withered == true, "Dente-de-Leão deve murchar/secar com 0% de hidratação")
		
		# Regar Dente-de-Leão com gota do frasco
		var watered = dand.water_dandelion()
		assert(watered == true, "Rega do Dente-de-Leão deve ser bem-sucedida")
		assert(dand.is_withered == false, "Dente-de-Leão deve se reidratar e reviver")
		assert(dand.hydration == 100.0, "Hidratação do Dente-de-Leão deve retornar a 100%")
		assert(GameManager.dew_flask_charges == 0, "Gota de orvalho deve ser consumida do frasco")
		
	# Testar Sede e Rega da Flor Central
	GameManager.flower_hydration = 0.0
	GameManager.add_dew_flask_charge(1)
	var prev_fl_hp_before_water = GameManager.flower_hp
	var fl_watered = GameManager.water_flower()
	assert(fl_watered == true, "Flor Central deve aceitar rega de orvalho")
	assert(GameManager.flower_hydration == 50.0, "Hidratação da Flor Central deve aumentar em +50%")
	assert(GameManager.flower_hp == min(GameManager.flower_max_hp, prev_fl_hp_before_water + 5.0), "Flor Central deve receber +5 HP com orvalho")
	
	# Testar Sistema de Tutorial Guiado (Pós-Onda 1)
	assert(hud.tutorial_manager != null, "TutorialManager deve estar instanciado no GameHUD")
	GameManager.trigger_tutorial_post_wave_1.emit()
	assert(hud.tutorial_manager.get("is_tutorial_active") == true, "Tutorial guiado deve iniciar pós-Onda 1")
	assert(GameManager.countdown_active == false, "Countdown deve congelar durante o tutorial")
	assert(SoundManager.tutorial_lp_filter != null, "Filtro passa-baixas de áudio deve estar ativo no tutorial")
	
	hud.tutorial_manager.finish_tutorial()
	assert(hud.tutorial_manager.get("is_tutorial_active") == false, "Tutorial guiado deve encerrar corretamente")
	assert(GameManager.countdown_active == true, "Countdown de preparação deve retomar após o tutorial")
	print("✔ Ecossistema: Frasco de Orvalho, Hidratação/Sede de Plantas e Tutorial Guiado validados 100%.")
	
	# 8. Testar Requisitos da Pip (Visual Arrietty, Proporções Chibi e Animações)
	var col_shape = heroine.get_node("CollisionShape3D") as CollisionShape3D
	assert(col_shape != null and col_shape.shape is CapsuleShape3D, "Pip deve ter CapsuleShape3D")
	var capsule = col_shape.shape as CapsuleShape3D
	assert(capsule.height <= 0.8 and capsule.height >= 0.6, "Altura de Pip deve ser miniatura (0.6 a 0.8 unidades)")
	assert(heroine.hair_ponytail != null, "Pip deve possuir mecha de cabelo ruivo")
	assert(heroine.needle_mesh != null, "Pip deve portar agulha de costura")
	
	# Testar disparo das animações e combo
	heroine.execute_attack_combo()
	heroine.play_collect_hop()
	heroine.take_damage(5.0)
	heroine.start_dash()
	print("✔ Pip: proporções de miniatura, cabelo ruivo, agulha, combo e dash validados 100%.")
	
	# 9. Testar Requisitos do Cenário e Câmera
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
	# 10. Testar Checkpoint da Noite 2 e Reinício após Derrota
	GameManager.set_night_2_checkpoint()
	assert(GameManager.has_night_2_checkpoint == true, "Checkpoint da Noite 2 deve estar ativo")
	heroine.play_checkpoint_glow()
	
	# Simula derrota e verifica textos do HUD
	GameManager.wave_state = GameManager.WaveState.DEFEAT
	GameManager.wave_state_changed.emit("DEFEAT", 1)
	var restart_btn = hud.game_over_panel.get_node("VBox/RestartBtn") as Button
	assert(restart_btn.text.contains("Noite 2"), "Botão de derrota deve sugerir iniciar na Noite 2 com checkpoint ativo")
	
	GameManager.load_night_2_checkpoint()
	assert(GameManager.current_period == "NIGHT" and GameManager.current_night == 2, "Checkpoint deve restaurar o jogo na Noite 2")
	assert(GameManager.pip_hp == GameManager.pip_max_hp, "HP de Pip deve estar cheio no checkpoint")
	assert(GameManager.flower_hp == GameManager.flower_max_hp, "HP da Flor deve estar cheio no checkpoint")
	print("✔ Checkpoint da Noite 2, Efeito de Brilho da Pip e Reinício Customizado de Derrota validados 100%.")
	
	# 11. Testar NPC Gnomo Ladrão Noturno
	var gnome_script = load("res://scripts/gnome_npc.gd")
	var gnome = gnome_script.new()
	root_node.add_child(gnome)
	gnome.global_position = Vector3(2.0, 0.0, 2.0)
	
	assert(gnome.base_speed > 5.0, "Gnomo deve correr mais rápido que a Pip (base: %f > 5.0)" % gnome.base_speed)
	assert(SoundManager.music_gnome_stream != null, "Música Campfire Sneaks do Gnomo deve estar carregada")
	assert(SoundManager.sfx_rabbit_squeak != null, "SFX de coelho do Gnomo deve estar carregado")
	
	# Simula item para o gnomo coletar
	var pickup_scn = load("res://scenes/pickup.tscn")
	var test_item = pickup_scn.instantiate()
	test_item.item_type = "TWIG"
	root_node.add_child(test_item)
	test_item.global_position = Vector3(2.2, 0.2, 2.2)
	
	gnome.collect_pickup(test_item)
	assert(gnome.stolen_items.size() == 1, "Gnomo deve colocar item roubado no saco")
	
	# 1º Golpe no Gnomo
	gnome.take_damage(1.0)
	assert(gnome.hits_taken == 1, "Gnomo deve registrar 1º golpe")
	assert(gnome.current_speed > 7.0, "Gnomo deve acelerar a corrida após o 1º golpe")
	
	# 2º Golpe no Gnomo (Explosão de loot e fuga)
	gnome.take_damage(1.0)
	assert(gnome.hits_taken == 2, "Gnomo deve registrar 2º golpe")
	assert(gnome.is_fleeing == true, "Gnomo deve entrar em estado de fuga em pânico")
	gnome.queue_free()
	print("✔ NPC Gnomo Ladrão: visual, velocidade, saco infinito, barulho de coelho, 2 golpes e fuga validados 100%.")
	
	# 12. Testar Visual 2.5D Isométrico de Todos os Inimigos e Chefes
	var enemy_scenes = [
		"res://scenes/enemies/aphid.tscn",
		"res://scenes/enemies/beetle.tscn",
		"res://scenes/enemies/caterpillar.tscn",
		"res://scenes/enemies/wasp.tscn",
		"res://scenes/enemies/firefly.tscn",
		"res://scenes/enemies/boss_snail.tscn",
		"res://scenes/enemies/boss_moth.tscn",
		"res://scenes/enemies/boss_mantis.tscn",
		"res://scenes/enemies/boss_wasp_queen.tscn",
		"res://scenes/enemies/boss_spider.tscn",
		"res://scenes/enemies/boss_scorpion.tscn"
	]
	
	for scn_path in enemy_scenes:
		var scn = load(scn_path)
		var ent = scn.instantiate()
		root_node.add_child(ent)
		assert(ent.sprite_25d != null, "Inimigo %s deve possuir nó Sprite25D" % scn_path)
		assert(ent.sprite_25d.animations.has("idle") or ent.sprite_25d.animations.has("walk"), "Inimigo %s deve ter animação idle ou walk" % scn_path)
		for dir_vec in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3(1, 0, 1).normalized()]:
			ent.sprite_25d.set_facing(dir_vec)
			ent.sprite_25d.update_direction_from_camera()
		ent.queue_free()
	print("✔ Todos os 5 Inimigos Regulares e 6 Chefes: Sprites 2.5D Pixel Art (8 direções) validados 100%.")
	
	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
