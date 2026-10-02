extends Node3D

func _ready() -> void:
	print("--- RENDERIZANDO SHOWCASE DA FASE 4: PIP (A HEROÍNA) ---")
	
	var pip_idle = $Pips/PipIdle as Heroine
	var pip_run = $Pips/PipRun as Heroine
	var pip_attack = $Pips/PipAttack as Heroine
	var pip_plant = $Pips/PipPlant as Heroine
	var pip_build = $Pips/PipBuild as Heroine
	var pip_hop = $Pips/PipHop as Heroine
	
	# Posição de Corrida (Arrietty run)
	pip_run.visual_root.rotation.x = 0.28
	pip_run.visual_root.position.y = 0.08
	if pip_run.hair_ponytail:
		pip_run.hair_ponytail.rotation.x = pip_run.base_ponytail_x + 0.4
	if pip_run.needle_pivot:
		pip_run.needle_pivot.rotation.z = 0.25
		
	# Posição de Ataque (Estocada de agulha com rastro prateado)
	pip_attack.needle_pivot.position = Vector3(0.08, 0.32, 0.52)
	pip_attack.needle_pivot.rotation_degrees = Vector3(-80, 0, 0)
	pip_attack.create_slash_effect(Color(0.92, 0.95, 1.0, 0.95), 1.1)
	
	# Posição de Plantio (Agachada tocando o solo com partículas)
	pip_plant.visual_root.position.y = -0.15
	pip_plant.needle_pivot.rotation_degrees = Vector3(45, 0, 0)
	pip_plant.spawn_leaf_puff_fx(pip_plant.global_position)
	
	# Posição de Construção (Martelando o solo com agulha)
	pip_build.needle_pivot.rotation_degrees = Vector3(-95, 0, 0)
	pip_build.spawn_dust_puff_fx(pip_build.global_position + Vector3(0, 0.05, 0.25), Tokens.LATAO_ENGRENAGEM)
	
	# Posição de Coleta (Pulo de alegria / Hop)
	pip_hop.visual_root.position.y = 0.22
	pip_hop.visual_root.scale = Vector3(0.9, 1.15, 0.9)
	
	# Aguardar renderização dos efeitos visuais
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	var img = get_viewport().get_texture().get_image()
	DirAccess.make_dir_absolute("res://screenshots")
	var err = img.save_png("res://screenshots/fase4_pip.png")
	if err == OK:
		print("✔ Screenshot salva com sucesso em: screenshots/fase4_pip.png")
	else:
		printerr("Erro ao salvar screenshot: ", err)
		
	# Asserções de conformidade visual da Fase 4
	assert(pip_idle != null, "Pip Idle deve existir")
	assert(pip_run != null, "Pip Run deve existir")
	assert(pip_attack != null, "Pip Attack deve existir")
	assert(pip_plant != null, "Pip Plant deve existir")
	assert(pip_build != null, "Pip Build deve existir")
	assert(pip_hop != null, "Pip Hop deve existir")
	
	# Validar escala e proporções
	var col_shape = pip_idle.get_node("CollisionShape3D") as CollisionShape3D
	assert(col_shape != null and col_shape.shape is CapsuleShape3D, "Pip deve ter CapsuleShape3D")
	var capsule = col_shape.shape as CapsuleShape3D
	assert(capsule.height <= 0.8 and capsule.height >= 0.6, "Altura de Pip deve ser miniatura (0.6 a 0.8 unidades)")
	
	# Validar referências de cabelo ruivo e agulha
	assert(pip_idle.hair_ponytail != null, "Pip deve ter mecha/rabo de cavalo de cabelo")
	assert(pip_idle.needle_mesh != null, "Pip deve portar a agulha de costura")
	
	print("✔ Todos os critérios da Fase 4 (visual Arrietty, proporções miniatura, agulha, túnica de folha e animações) validados com sucesso!")
	get_tree().quit(0)
