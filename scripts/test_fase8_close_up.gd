extends Node3D

func _ready() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var root = main_scene.instantiate()
	add_child(root)
	
	await get_tree().create_timer(0.3).timeout
	
	var heroine: Heroine = root.get_node("Heroine")
	var camera_rig = root.get_node_or_null("CameraRig")
	
	# Encontrar um Dandelion Clock
	var dandelions = get_tree().get_nodes_in_group("dandelion")
	var target_dand = null
	for d in dandelions:
		if d.has_method("on_attack_hit") and d.get("clock_head") != null:
			target_dand = d
			break
			
	if target_dand:
		# Posicionar Pip delicadamente ao lado do Dente-de-Leão
		heroine.global_position = target_dand.global_position + Vector3(0.7, 0, 0.3)
		heroine.visual_root.rotation.y = atan2(-0.7, -0.3)
		
		# Ajustar zoom da câmera para close-up macro delicado
		if camera_rig and camera_rig.has_method("set_zoom_level"):
			camera_rig.set_zoom_level(0.40)
			
	await get_tree().create_timer(0.5).timeout
	
	# Capturar screenshot
	var img = get_viewport().get_texture().get_image()
	DirAccess.make_dir_absolute("res://screenshots")
	img.save_png("res://screenshots/fase8_dandelion_translucent_seeds.png")
	print("✔ Screenshot capturada com sucesso em res://screenshots/fase8_dandelion_translucent_seeds.png")
	
	get_tree().quit(0)
