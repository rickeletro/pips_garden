extends SceneTree

func _init() -> void:
	var models = [
		"res://models/Trees.glb",
		"res://models/Pine Trees.glb",
		"res://models/Birch Trees.glb"
	]
	for m_path in models:
		print("=== " + m_path + " ===")
		var scn = load(m_path)
		if not scn:
			print("Could not load ", m_path)
			continue
		var inst = scn.instantiate()
		for child in inst.find_children("*", "MeshInstance3D"):
			var mi: MeshInstance3D = child
			print("Child:", mi.name, " transform:", mi.transform, " aabb:", mi.mesh.get_aabb() if mi.mesh else AABB())
		inst.queue_free()

	quit()

