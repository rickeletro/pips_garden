extends Node3D

func _ready() -> void:
	print("--- RENDERIZANDO SHOWCASE DA FASE 3: TORRES DE GRAVETOS E ENGRENAGENS ---")
	
	# Configurar estados para exibição
	var t_broken = $Towers/TowerBroken as GardenTower
	t_broken.take_damage(100.0)
	
	var ghost_invalid = $Towers/GhostInvalid as TowerGhost
	ghost_invalid.set_valid(false)
	
	# Aguardar renderização inicial
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img = get_viewport().get_texture().get_image()
	DirAccess.make_dir_absolute("res://screenshots")
	var err = img.save_png("res://screenshots/fase3_torres.png")
	if err == OK:
		print("✔ Screenshot salva com sucesso em: screenshots/fase3_torres.png")
	else:
		printerr("Erro ao salvar screenshot: ", err)
		
	# Validações dos requisitos da Fase 3
	var t1 = $Towers/TowerLvl1 as GardenTower
	var t2 = $Towers/TowerLvl2 as GardenTower
	var t3 = $Towers/TowerLvl3 as GardenTower
	var ghost_valid = $Towers/GhostValid as TowerGhost
	
	assert(t1 != null and t1.level == 1, "Torre 1 deve ser nível 1")
	assert(t1.poison_type == GardenTower.PoisonType.SLOW, "Torre 1 deve usar veneno âmbar")
	assert(t2 != null and t2.level == 2, "Torre 2 deve ser nível 2")
	assert(t2.poison_type == GardenTower.PoisonType.CORROSIVE, "Torre 2 deve usar veneno verde")
	assert(t3 != null and t3.level == 3, "Torre 3 deve ser nível 3")
	assert(t3.poison_type == GardenTower.PoisonType.MIST, "Torre 3 deve usar veneno violeta")
	
	assert(t_broken.is_broken == true, "Torre quebrada deve estar no estado colapsado")
	assert(t_broken.visuals_standing.visible == false, "Torre quebrada não deve exibir tenda em pé")
	assert(t_broken.visuals_collapsed.visible == true, "Torre quebrada deve exibir escombros no chão")
	
	assert(ghost_valid != null, "TowerGhost válido deve existir")
	assert(ghost_invalid != null, "TowerGhost inválido deve existir")
	print("✔ Todos os requisitos da Fase 3 (Níveis 1, 2 e 3, 3 tipos de veneno, estado colapsado e ghost) validados com sucesso!")
	
	get_tree().quit(0)
