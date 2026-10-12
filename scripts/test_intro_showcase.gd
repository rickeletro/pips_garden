extends Node3D

func _ready() -> void:
	print("--- CAPTURANDO SCREENSHOT DA NOVA INTRO COM MOLDURA DE HERA ---")
	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	add_child(root_node)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	
	var img = get_viewport().get_texture().get_image()
	DirAccess.make_dir_absolute("screenshots")
	img.save_png("screenshots/intro_ivy_frame.png")
	print("✔ Screenshot salva com sucesso em: screenshots/intro_ivy_frame.png")
	get_tree().quit(0)
