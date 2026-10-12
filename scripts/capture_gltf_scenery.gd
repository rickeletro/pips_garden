extends Node3D

func _ready() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var root = main_scene.instantiate()
	add_child(root)
	
	GameManager.start_game_from_intro()
	var hud = root.get_node("GameHUD")
	if hud and hud.intro_panel:
		hud.intro_panel.visible = false
	
	var heroine: Heroine = root.get_node("Heroine")
	var camera: Camera3D = root.get_node("Camera3D")
	var grid: GridManager = root.get_node("GridManager")
	
	# Plant grass around Pip
	if grid:
		grid.plant_grass(Vector2i(0, 1))
		grid.plant_grass(Vector2i(1, 1))
		grid.plant_grass(Vector2i(1, 2))
		grid.plant_grass(Vector2i(2, 2))
		grid.plant_grass(Vector2i(0, 2))
	
	heroine.global_position = Vector3(1.5, 0.0, 2.0)
	
	# Camera close-up macro on scenery
	camera.global_position = Vector3(1.5, 3.5, 6.0)
	camera.look_at(Vector3(1.5, 0.4, 2.0))
	
	await get_tree().create_timer(0.4).timeout
	
	var img = get_viewport().get_texture().get_image()
	DirAccess.make_dir_absolute("res://screenshots")
	img.save_png("res://screenshots/gltf_scenery_upgrade.png")
	
	var global_art_path = "/Users/ricardosouza/.gemini/antigravity-ide/brain/c901c242-6a3e-4f2e-986d-52b8b9aca98b/gltf_scenery_upgrade.png"
	img.save_png(global_art_path)
	print("✔ Screenshot salva no artifact directory!")
	
	get_tree().quit(0)
