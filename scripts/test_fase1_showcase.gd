extends Control

func _ready() -> void:
	print("--- SHOWCASE FASE 1: FUNDAÇÃO (DESIGN TOKENS, THEME & SVG ICONS) ---")
	
	# Wait for render frames to ensure full rasterization
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png("res://screenshots/fase1_fundacao.png")
		if err == OK:
			print("✔ Screenshot capturado com sucesso em screenshots/fase1_fundacao.png")
		else:
			printerr("Erro ao salvar screenshot: ", err)
	
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)
