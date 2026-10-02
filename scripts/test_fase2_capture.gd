extends Node

func _ready() -> void:
	print("Carregando main.tscn no scene tree com Autoloads para capturar Fase 2...")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	add_child(main_node)
	
	# Wait for rendering to settle
	for i in range(30):
		await get_tree().process_frame
		
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png("res://screenshots/fase2_hud.png")
		if err == OK:
			print("✔ Screenshot da Fase 2 capturado com sucesso em screenshots/fase2_hud.png")
		else:
			printerr("Erro ao salvar screenshot: ", err)
			
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)
