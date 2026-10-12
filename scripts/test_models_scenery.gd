extends Node3D

func _ready() -> void:
	var g_scn = load("res://models/Grass.glb")
	var f_scn = load("res://models/Flowers.glb")
	var r_scn = load("res://models/Rocks.glb")
	var b_scn = load("res://models/Bushes.glb")
	var fb_scn = load("res://models/Flower Bushes.glb")
	
	# Create floor
	var floor_mesh = PlaneMesh.new()
	floor_mesh.size = Vector2(20, 20)
	var floor_node = MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	var f_mat = StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.22, 0.35, 0.18)
	floor_node.material_override = f_mat
	add_child(floor_node)
	
	# Heroine reference size (~0.7m tall)
	var pip_box = BoxMesh.new()
	pip_box.size = Vector3(0.3, 0.7, 0.3)
	var pip_inst = MeshInstance3D.new()
	pip_inst.mesh = pip_box
	pip_inst.position = Vector3(0, 0.35, 0)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.9, 0.3, 0.1) # red
	pip_inst.material_override = p_mat
	add_child(pip_inst)
	
	# Grass extracted mesh with rotation
	if g_scn:
		var g_inst = g_scn.instantiate()
		var g_mesh: Mesh = null
		for c in g_inst.find_children("*", "MeshInstance3D"):
			if c.name == "Grass_Large_Extruded":
				g_mesh = c.mesh
				break
		g_inst.queue_free()
		
		if g_mesh:
			var mm_inst = MultiMeshInstance3D.new()
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.instance_count = 50
			mm.mesh = g_mesh
			mm_inst.multimesh = mm
			add_child(mm_inst)
			
			for i in range(50):
				var t = Transform3D()
				# Rotate -90 deg on X to stand upright + random Y yaw
				t = t.rotated(Vector3.UP, randf() * TAU)
				t = t.rotated_local(Vector3.RIGHT, deg_to_rad(-90))
				# Scale so grass is ~0.85m to 1.15m (Pip is 0.7m)
				var s = randf_range(160.0, 220.0)
				t = t.scaled_local(Vector3(s, s, s))
				var pos = Vector3(randf_range(-2, 2), 0.0, randf_range(-2, 2))
				t.origin = pos
				mm.set_instance_transform(i, t)
				
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.8, 3.5)
	cam.look_at(Vector3(0, 0.5, 0))
	add_child(cam)
	
	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO)
	add_child(light)
	
	await get_tree().create_timer(0.4).timeout
	var img = get_viewport().get_texture().get_image()
	img.save_png("/Users/ricardosouza/.gemini/antigravity-ide/brain/c901c242-6a3e-4f2e-986d-52b8b9aca98b/test_grass_upright.png")
	print("✔ Test render saved!")
	get_tree().quit(0)
