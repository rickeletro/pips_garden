extends Node3D

@onready var grid_manager: GridManager = $GridManager
@onready var spawner_manager: SpawnerManager = $SpawnerManager

func _ready() -> void:
	spawn_decorative_garden_border()
	
	# Initial tutorial prompt
	await get_tree().create_timer(0.5).timeout
	GameManager.notify("Bem-vindo ao Jardim Miúdo! Plante grama (Q) e construa torres (B) antes da onda!", Color(1.0, 0.95, 0.5))

func spawn_decorative_garden_border() -> void:
	# Giant blades of grass and pebbles around the border to frame the garden
	var border_root = Node3D.new()
	border_root.name = "GiantGardenBorders"
	add_child(border_root)
	
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.2, 0.6, 0.18)
	blade_mat.roughness = 0.6
	blade_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	blade_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.48, 0.42)
	stone_mat.roughness = 0.9
	stone_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	
	var dew_mat = StandardMaterial3D.new()
	dew_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dew_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.7)
	dew_mat.roughness = 0.05
	dew_mat.metallic = 0.2
	
	var radius = 15.5
	var count = 36
	for i in range(count):
		var angle = (float(i) / count) * TAU
		var pos = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		
		# Towering blade of grass (miniature perspective: blades are huge!)
		var blade = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.5, 4.0 + randf() * 2.5, 0.15)
		blade.mesh = box
		blade.material_override = blade_mat
		blade.position = pos + Vector3(0, box.size.y * 0.45, 0)
		blade.rotation_degrees = Vector3(
			(randf() - 0.5) * 15.0,
			randf() * 360.0,
			(randf() - 0.5) * 15.0
		)
		border_root.add_child(blade)
		
		# Giant pebble
		if i % 3 == 0:
			var pebble = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.8 + randf() * 0.6
			sphere.height = sphere.radius * 1.5
			pebble.mesh = sphere
			pebble.material_override = stone_mat
			pebble.position = pos * 0.92 + Vector3(0, 0.2, 0)
			pebble.scale = Vector3(1.2, 0.7, 1.0)
			border_root.add_child(pebble)
			
		# Dew drop resting on leaf
		if i % 5 == 0:
			var dew = MeshInstance3D.new()
			var dsphere = SphereMesh.new()
			dsphere.radius = 0.35
			dsphere.height = 0.7
			dew.mesh = dsphere
			dew.material_override = dew_mat
			dew.position = pos + Vector3(0, 2.5, 0)
			border_root.add_child(dew)
