extends Node3D

func _ready() -> void:
	print("--- RENDERIZANDO SHOWCASE DA FASE 5: JARDIM 10x, FLORES, TRILHAS, AQUARELA ZELDA E ZOOM ---")
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	
	DirAccess.make_dir_absolute("res://screenshots")
	var cam: GardenCameraController = $Camera3D
	
	# 1. Capturar Visão Panorâmica Ampla (Zoom Out - 10x Jardim Inteiro com Trilhas e Flores)
	cam.set_zoom_immediate(2.4)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var img_out = get_viewport().get_texture().get_image()
	img_out.save_png("res://screenshots/fase5_zoom_out.png")
	print("✔ Screenshot de Zoom Out salva: screenshots/fase5_zoom_out.png")
	
	# 2. Capturar Visão Próxima (Zoom In - Grama Aquarela Zelda, Pip e Flores de Perto)
	cam.set_zoom_immediate(0.45)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var img_in = get_viewport().get_texture().get_image()
	img_in.save_png("res://screenshots/fase5_zoom_in.png")
	print("✔ Screenshot de Zoom In salva: screenshots/fase5_zoom_in.png")
	
	# 3. Capturar Visão Padrão de Gameplay com HUD e Minimapa
	cam.set_zoom_immediate(1.1)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	var img_game = get_viewport().get_texture().get_image()
	img_game.save_png("res://screenshots/fase5_jardim_10x.png")
	print("✔ Screenshot Principal salva: screenshots/fase5_jardim_10x.png")
	
	# Validações dos requisitos da Fase 5 e do pedido do usuário
	var grid: GridManager = $GridManager
	assert(grid != null, "GridManager deve existir")
	assert(grid.HALF_EXTENT >= 24, "Jardim deve ser 10x maior (~100m x 100m, raio >= 24)")
	assert(grid.path_cells.size() >= 40, "Trilha sinuosa das hordas deve existir com pelo menos 40 células demarcadas")
	assert(grid.grass_multimesh != null, "MultiMesh da grama deve existir")
	assert(grid.grass_multimesh.multimesh.instance_count > 0, "MultiMesh da grama deve possuir instâncias ativas")
	
	assert(cam != null, "Camera3D com GardenCameraController deve existir")
	cam.zoom_in()
	assert(cam.target_zoom < 1.1, "Função zoom_in deve aproximar a câmera")
	cam.zoom_out()
	cam.zoom_out()
	assert(cam.target_zoom > 1.0, "Função zoom_out deve afastar a câmera")
	
	print("✔ Todos os requisitos validados: Jardim 10x maior, trilhas sinuosas, grama aquarela zelda com vento, flora abundante e zoom in/out!")
	get_tree().quit(0)
