extends Node3D

# Showcase Cinematográfico em Close-Up:
# Apresentação Detalhada das Cenas da Noite 3 (Sacrifício, Vingança, Morte e Ascensão Celestial)

func _ready() -> void:
	print("--- EXECUTANDO CINEMÁTICA EM CLOSE-UP EM CLAREIRA ABERTA ---")
	
	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	add_child(root_node)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var hud = root_node.get_node_or_null("GameHUD")
	if hud:
		hud.intro_panel.visible = false
		hud.margin_container.visible = false # Oculta HUD para visualização cinematográfica pura
		
	GameManager.start_game_from_intro()
	GameManager.current_period = "NIGHT"
	GameManager.current_night = 3
	
	var cycle = root_node.get_node_or_null("DayNightCycle")
	if cycle:
		cycle.target_progress = 1.0
		cycle.current_progress = 1.0
		if cycle.has_method("update_lighting"):
			cycle.update_lighting(1.0)
			
	var cam: GardenCameraController = root_node.get_node_or_null("Camera3D")
	
	# Posições na clareira limpa do jardim
	var clearing_center = Vector3(6.0, 0.0, 6.0)
	
	var pip = GameManager.heroine
	if pip:
		pip.global_position = clearing_center + Vector3(-2.2, 0, 0.5)
		
	# Instancia a Joaninha companheira
	var comp_scn = load("res://scripts/ladybug_companion.gd")
	var ladybug: Node3D = comp_scn.new()
	root_node.add_child(ladybug)
	ladybug.global_position = clearing_center + Vector3(0.0, 0.05, 1.2)
	
	# Instancia o Escorpião Boss Final
	var scorp_scn = load("res://scenes/enemies/boss_scorpion.tscn")
	var scorpion = scorp_scn.instantiate()
	root_node.add_child(scorpion)
	scorpion.global_position = clearing_center + Vector3(2.5, 0, -1.0)
	scorpion.sacrifice_ladybug = ladybug
	
	# Câmera em close-up dramático
	if cam:
		cam.target_node = scorpion
		cam.base_offset = Vector3(0.0, 4.5, 5.0) # Ângulo próximo e imersivo
		cam.current_zoom = 0.8
		cam.target_zoom = 0.8
		
	DirAccess.make_dir_absolute("screenshots")
	
	# 1. Ataque do ferrão e sacrifício da Joaninha
	await get_tree().create_timer(3.2).timeout
	var img1 = get_viewport().get_texture().get_image()
	img1.save_png("screenshots/cinematic_1_ladybug_sacrifice.png")
	print("✔ Screenshot 1 capturada")
	
	# 2. Câmera foca em Pip com diálogo de vingança e lágrimas
	if cam and pip:
		cam.target_node = pip
		cam.base_offset = Vector3(0.0, 3.8, 4.2)
		cam.target_zoom = 0.85
	await get_tree().create_timer(2.4).timeout
	var img2 = get_viewport().get_texture().get_image()
	img2.save_png("screenshots/cinematic_2_pip_revenge.png")
	print("✔ Screenshot 2 capturada")
	
	# 3. Derrota e estilhaçamento do Escorpião em cinzas azuis
	if cam:
		cam.target_node = scorpion
	scorpion.die()
	await get_tree().create_timer(1.2).timeout
	var img3 = get_viewport().get_texture().get_image()
	img3.save_png("screenshots/cinematic_3_scorpion_defeat.png")
	print("✔ Screenshot 3 capturada")
	
	# 4. Pip ajoelha e espiral de estrelas celestiais sobe ao céu
	if cam and pip:
		cam.target_node = pip
	await get_tree().create_timer(3.5).timeout
	var img4 = get_viewport().get_texture().get_image()
	img4.save_png("screenshots/cinematic_4_celestial_ascent.png")
	print("✔ Screenshot 4 capturada")
	
	# 5. Início do Encerramento Cinematográfico: Zoom Out Lento + Moldura Botânica + Créditos Rolando
	if hud:
		hud.start_cinematic_credits_sequence()
	await get_tree().create_timer(3.5).timeout
	var img5 = get_viewport().get_texture().get_image()
	img5.save_png("screenshots/cinematic_5_botanical_credits_crawl.png")
	print("✔ Screenshot 5 capturada (Créditos Rolando com Moldura Botânica e Zoom Out)")
	
	# 6. Créditos com o Nome do Criador Ricardo Ferreira de Souza
	await get_tree().create_timer(4.5).timeout
	var img6 = get_viewport().get_texture().get_image()
	img6.save_png("screenshots/cinematic_6_creator_credits.png")
	print("✔ Screenshot 6 capturada (Nome do Criador Ricardo Ferreira de Souza)")
	
	print("--- SHOWCASE CLOSE-UP FINALIZADO ---")
	get_tree().quit(0)
