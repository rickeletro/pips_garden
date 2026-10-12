extends Node3D
class_name GridManager

signal path_updated
signal grass_planted(pos: Vector2i)
signal tower_built(pos: Vector2i, tower_node: Node3D)

const CELL_SIZE: float = 2.0
const HALF_EXTENT: int = 24 # 49x49 grid (~98m x 98m, >10x a área anterior!)

enum TileType { DIRT, PATH, GRASS, TOWER, FLOWER, SPAWNER }

var grid_data: Dictionary = {} # Vector2i -> TileType
var path_cells: Dictionary = {} # Vector2i -> bool
var towers: Dictionary = {} # Vector2i -> Node3D
var grass_visuals: Dictionary = {} # Vector2i -> Node3D
var grass_health: Dictionary = {} # Vector2i -> float
const MAX_GRASS_HP: float = 35.0

var astar: AStar2D = AStar2D.new()

var flower_cell: Vector2i = Vector2i(0, 0)
var spawner_cells: Array[Vector2i] = [
	Vector2i(0, -16), # Entrada Norte
	Vector2i(-16, 0), # Entrada Oeste
	Vector2i(16, 0),  # Entrada Leste
	Vector2i(0, 16)   # Entrada Sul
]

const WEIGHT_DIRT: float = 3.5
const WEIGHT_PATH: float = 1.6  # Caminho demarcado de terra batida (atrai pragas naturalmente)
const WEIGHT_GRASS: float = 1.0 # Grama viçosa plantada por Pip (preferência máxima)

# Packed scenes
@export var tower_scene: PackedScene

# Modelos GLTF e Caches de Malhas do Cenário (Grass.glb, Flowers.glb, Rocks.glb, Bushes.glb, Flower Bushes.glb, Trees.glb)
var grass_meshes: Array[Mesh] = []
var grass_material: Material = null
var flower_meshes: Array[Mesh] = []
var bush_meshes: Array[Mesh] = []
var rock_meshes: Array[Mesh] = []
var tree_meshes: Array[Mesh] = []

# MultiMeshInstance3D para a Grama GLTF com Vento Zelda
var grass_multimesh: MultiMeshInstance3D = null
var current_grass_count: int = 0
const MAX_GRASS_BLADES: int = 10000

func _ready() -> void:
	GameManager.grid_manager = self
	load_gltf_scenery_models()
	generate_winding_paths()
	init_grid()
	init_watercolor_grass_multimesh()
	spawn_distant_horizon_forest()
	spawn_path_decorations()
	spawn_ambient_garden_flowers()
	spawn_interactive_dew_drops(8)
	GameManager.wave_state_changed.connect(_on_wave_state_changed)

func load_gltf_scenery_models() -> void:
	# 1. Grama (Grass.glb)
	var grass_scn = load("res://models/Grass.glb")
	if grass_scn:
		var g_inst = grass_scn.instantiate()
		for child in g_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				grass_meshes.append(child.mesh)
		g_inst.queue_free()
		
	# 2. Flores (Flowers.glb)
	var flower_scn = load("res://models/Flowers.glb")
	if flower_scn:
		var f_inst = flower_scn.instantiate()
		for child in f_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				flower_meshes.append(child.mesh)
		f_inst.queue_free()

	# 3. Arbustos com Flores e Folhagens (Flower Bushes.glb & Bushes.glb)
	var flower_bush_scn = load("res://models/Flower Bushes.glb")
	if flower_bush_scn:
		var fb_inst = flower_bush_scn.instantiate()
		for child in fb_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				bush_meshes.append(child.mesh)
		fb_inst.queue_free()

	var bush_scn = load("res://models/Bushes.glb")
	if bush_scn:
		var b_inst = bush_scn.instantiate()
		for child in b_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				bush_meshes.append(child.mesh)
		b_inst.queue_free()

	# 4. Pedras e Rochedos (Rocks.glb)
	var rock_scn = load("res://models/Rocks.glb")
	if rock_scn:
		var r_inst = rock_scn.instantiate()
		for child in r_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				rock_meshes.append(child.mesh)
		r_inst.queue_free()

	# 5. Árvores da Floresta do Horizonte (Trees.glb)
	var tree_scn = load("res://models/Trees.glb")
	if tree_scn:
		var t_inst = tree_scn.instantiate()
		for child in t_inst.find_children("*", "MeshInstance3D"):
			if child is MeshInstance3D and child.mesh:
				tree_meshes.append(child.mesh)
		t_inst.queue_free()

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	# Ao amanhecer do Dia 1 e Dia 2, formam-se 8 Gotas de Orvalho
	if GameManager.current_period == "DAY" and wave_number == 0 and state == "PREPARATION":
		spawn_interactive_dew_drops(8)

func get_point_id(cell: Vector2i) -> int:
	return (cell.x + 100) * 10000 + (cell.y + 100)

func is_valid_cell(cell: Vector2i) -> bool:
	return abs(cell.x) <= HALF_EXTENT and abs(cell.y) <= HALF_EXTENT

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(round(world_pos.x / CELL_SIZE), round(world_pos.z / CELL_SIZE))

func grid_to_world(grid_pos: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(grid_pos.x * CELL_SIZE, height, grid_pos.y * CELL_SIZE)

func get_tile_type(cell: Vector2i) -> TileType:
	if grid_data.has(cell):
		return grid_data[cell]
	return TileType.DIRT

# Gera os caminhos sinuosos e demarcados pelos 4 portões até a Flor Central
func generate_winding_paths() -> void:
	path_cells.clear()
	
	# Caminho Norte: (0, -22) -> (0, 0) com curvas sinuosas
	trace_bezier_path(Vector2(0, -22), Vector2(6, -14), Vector2(-4, -6), Vector2(0, 0))
	# Caminho Sul: (0, 22) -> (0, 0)
	trace_bezier_path(Vector2(0, 22), Vector2(-6, 14), Vector2(5, 7), Vector2(0, 0))
	# Caminho Oeste: (-22, 0) -> (0, 0)
	trace_bezier_path(Vector2(-22, 0), Vector2(-14, 5), Vector2(-6, -4), Vector2(0, 0))
	# Caminho Leste: (22, 0) -> (0, 0)
	trace_bezier_path(Vector2(22, 0), Vector2(14, -5), Vector2(6, 4), Vector2(0, 0))

func trace_bezier_path(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	var steps = 40
	var prev_cell = Vector2i(round(p0.x), round(p0.y))
	path_cells[prev_cell] = true
	
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		# Cubic Bezier
		var pt = (1.0 - t) * (1.0 - t) * (1.0 - t) * p0 + \
				 3.0 * (1.0 - t) * (1.0 - t) * t * p1 + \
				 3.0 * (1.0 - t) * t * t * p2 + \
				 t * t * t * p3
		var cell = Vector2i(round(pt.x), round(pt.y))
		
		# Conectar células adjacentes para garantir continuidade contínua no grid
		if cell != prev_cell:
			connect_grid_line(prev_cell, cell)
			prev_cell = cell

func connect_grid_line(c0: Vector2i, c1: Vector2i) -> void:
	var cur = c0
	while cur != c1:
		path_cells[cur] = true
		if cur.x < c1.x: cur.x += 1
		elif cur.x > c1.x: cur.x -= 1
		elif cur.y < c1.y: cur.y += 1
		elif cur.y > c1.y: cur.y -= 1
	path_cells[c1] = true

func init_grid() -> void:
	astar.clear()
	grid_data.clear()
	
	# Criar células do grid e AStar nodes
	for x in range(-HALF_EXTENT, HALF_EXTENT + 1):
		for y in range(-HALF_EXTENT, HALF_EXTENT + 1):
			var cell = Vector2i(x, y)
			var id = get_point_id(cell)
			
			var weight = WEIGHT_DIRT
			var type = TileType.DIRT
			
			if path_cells.has(cell):
				weight = WEIGHT_PATH
				type = TileType.PATH
				
			astar.add_point(id, Vector2(cell.x, cell.y), weight)
			grid_data[cell] = type
	
	# Conectar células vizinhas no AStar
	for x in range(-HALF_EXTENT, HALF_EXTENT + 1):
		for y in range(-HALF_EXTENT, HALF_EXTENT + 1):
			var cell = Vector2i(x, y)
			var id = get_point_id(cell)
			
			var neighbors = [
				Vector2i(x + 1, y),
				Vector2i(x - 1, y),
				Vector2i(x, y + 1),
				Vector2i(x, y - 1)
			]
			for n_cell in neighbors:
				if is_valid_cell(n_cell):
					var n_id = get_point_id(n_cell)
					if not astar.are_points_connected(id, n_id):
						astar.connect_points(id, n_id)
						
	# Registrar pontos especiais
	grid_data[flower_cell] = TileType.FLOWER
	for spawner in spawner_cells:
		grid_data[spawner] = TileType.SPAWNER

# Inicializa o MultiMeshInstance3D com os tufos de grama aquarela e Shader de Vento Zelda TotK
func init_watercolor_grass_multimesh() -> void:
	grass_multimesh = MultiMeshInstance3D.new()
	grass_multimesh.name = "GrassMultiMesh"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = MAX_GRASS_BLADES
	
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.18, 0.95, 0.04)
	mm.mesh = blade_mesh
		
	var wind_mat = load("res://shaders/zelda_watercolor_grass.tres")
	if wind_mat:
		grass_multimesh.material_override = wind_mat
		
	grass_multimesh.multimesh = mm
	grass_multimesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(grass_multimesh)
	
	# Povoar grama ambiente espalhada pelo campo do jardim (~2200 tufos altos)
	spawn_ambient_meadow_grass(2200)

func spawn_ambient_meadow_grass(count: int) -> void:
	var mm = grass_multimesh.multimesh
	for i in range(count):
		if current_grass_count >= MAX_GRASS_BLADES:
			break
			
		var rx = (randf() - 0.5) * (HALF_EXTENT * 2.0 * CELL_SIZE * 0.95)
		var rz = (randf() - 0.5) * (HALF_EXTENT * 2.0 * CELL_SIZE * 0.95)
		
		# Não colocar grama densa no centro exato da trilha principal
		var cell = world_to_grid(Vector3(rx, 0, rz))
		if path_cells.has(cell) and randf() > 0.15:
			continue
			
		var t = Transform3D()
		var rot_y = randf() * TAU
		t = t.rotated(Vector3.UP, rot_y)
		
		# Escala para a grama ficar ereta e mais alta que a Pip (~0.85m a 1.25m)
		var s_height = randf_range(1.0, 1.45)
		var s_width = randf_range(0.9, 1.3)
		t = t.scaled(Vector3(s_width, s_height, s_width))
		t.origin = Vector3(rx, s_height * 0.45, rz)
		
		mm.set_instance_transform(current_grass_count, t)
		var col_var = Color(0.9 + randf() * 0.1, 0.95 + randf() * 0.05, 0.9 + randf() * 0.1, 1.0)
		mm.set_instance_color(current_grass_count, col_var)
		
		current_grass_count += 1
		
	mm.visible_instance_count = current_grass_count

# Cria floresta colossal ao horizonte em 1 único Draw Call via MultiMesh (Zero Lag!)
func spawn_distant_horizon_forest() -> void:
	if tree_meshes.is_empty():
		return
		
	var tree_mm_node = MultiMeshInstance3D.new()
	tree_mm_node.name = "DistantForestMultiMesh"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tree_meshes[0]
	mm.instance_count = 80
	tree_mm_node.multimesh = mm
	tree_mm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tree_mm_node)
	
	for i in range(80):
		var angle = (float(i) / 80.0) * TAU
		var dist = randf_range(54.0, 88.0)
		var pos = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		var t = Transform3D()
		t = t.rotated(Vector3.UP, randf() * TAU)
		t = t.rotated_local(Vector3.RIGHT, deg_to_rad(-90))
		var s_tree = randf_range(280.0, 420.0)
		t = t.scaled_local(Vector3(s_tree, s_tree, s_tree))
		t.origin = pos
		mm.set_instance_transform(i, t)

func plant_grass(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		GameManager.notify("Fora dos limites do jardim!", Tokens.PERIGO)
		return false
	
	if grid_data.has(cell) and grid_data[cell] == TileType.GRASS:
		GameManager.notify("Aqui já tem grama viçosa!", Tokens.CREME_PERGAMINHO)
		return false
		
	if grid_data.has(cell) and (grid_data[cell] == TileType.TOWER or grid_data[cell] == TileType.FLOWER):
		GameManager.notify("Não pode plantar grama nesta estrutura!", Tokens.PERIGO)
		return false
	
	if not GameManager.consume_resources(0, 0, 1):
		return false
	
	grid_data[cell] = TileType.GRASS
	grass_health[cell] = MAX_GRASS_HP
	var id = get_point_id(cell)
	astar.set_point_weight_scale(id, WEIGHT_GRASS)
	
	# Adicionar tufos densos ao MultiMesh no local plantado
	add_dense_grass_to_multimesh(cell, 24)
	
	GameManager.notify("Grama viçosa plantada! Pragas terrestres preferem e são desaceleradas aqui.", Tokens.VERDE_FOLHA)
	grass_planted.emit(cell)
	path_updated.emit()
	return true

func damage_grass(cell: Vector2i, amount: float) -> bool:
	if not grid_data.has(cell) or grid_data[cell] != TileType.GRASS:
		return false
		
	var hp = grass_health.get(cell, MAX_GRASS_HP) - amount
	grass_health[cell] = hp
	
	if hp <= 0.0:
		destroy_grass(cell)
		return true # Grama destruída
	return false

func destroy_grass(cell: Vector2i) -> void:
	if not grid_data.has(cell) or grid_data[cell] != TileType.GRASS:
		return
	grass_health.erase(cell)
	
	var id = get_point_id(cell)
	if path_cells.has(cell):
		grid_data[cell] = TileType.PATH
		astar.set_point_weight_scale(id, WEIGHT_PATH)
	else:
		grid_data[cell] = TileType.DIRT
		astar.set_point_weight_scale(id, WEIGHT_DIRT)
		
	GameManager.notify("⚠️ Uma lagarta devorou a grama do jardim!", Tokens.DOURADO_LUZ)
	path_updated.emit()

func add_dense_grass_to_multimesh(cell: Vector2i, count: int) -> void:
	if not grass_multimesh or not grass_multimesh.multimesh:
		return
	var mm = grass_multimesh.multimesh
	var center = grid_to_world(cell, 0.0)
	
	for i in range(count):
		if current_grass_count >= MAX_GRASS_BLADES:
			break
			
		var offset_x = (randf() - 0.5) * (CELL_SIZE * 0.85)
		var offset_z = (randf() - 0.5) * (CELL_SIZE * 0.85)
		var t = Transform3D()
		t = t.rotated(Vector3.UP, randf() * TAU)
		var s_height = randf_range(1.1, 1.5)
		var s_width = randf_range(1.0, 1.4)
		t = t.scaled(Vector3(s_width, s_height, s_width))
		t.origin = center + Vector3(offset_x, s_height * 0.45, offset_z)
		
		mm.set_instance_transform(current_grass_count, t)
		mm.set_instance_color(current_grass_count, Color(1.0, 1.0, 0.92, 1.0))
		current_grass_count += 1
		
	mm.visible_instance_count = current_grass_count

func can_place_tower(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		GameManager.notify("Posição fora do jardim!", Tokens.PERIGO)
		return false
	
	if cell == flower_cell:
		GameManager.notify("Não pode construir sobre a Flor do Jardim!", Tokens.PERIGO)
		return false
		
	for sp in spawner_cells:
		if cell == sp:
			GameManager.notify("Não pode bloquear o ponto de entrada das pragas!", Tokens.PERIGO)
			return false
	
	if grid_data.has(cell) and grid_data[cell] == TileType.TOWER:
		GameManager.notify("Já existe uma torre aqui!", Tokens.PERIGO)
		return false
	
	# Testar se bloqueia todos os caminhos dos spawners até a flor
	var test_id = get_point_id(cell)
	astar.set_point_disabled(test_id, true)
	
	var flower_id = get_point_id(flower_cell)
	var all_reachable = true
	for sp in spawner_cells:
		var sp_id = get_point_id(sp)
		var test_path = astar.get_point_path(sp_id, flower_id)
		if test_path.is_empty():
			all_reachable = false
			break
	
	astar.set_point_disabled(test_id, false)
	
	if not all_reachable:
		GameManager.notify("Regra violada: Não é permitido fechar todo o caminho até a flor!", Tokens.PERIGO)
		return false
		
	return true

func build_tower_at(cell: Vector2i, tower_pck: PackedScene = null) -> Node3D:
	if not can_place_tower(cell):
		return null
	
	if not GameManager.consume_resources(3, 2, 0):
		return null
	
	grid_data[cell] = TileType.TOWER
	var id = get_point_id(cell)
	astar.set_point_disabled(id, true)
	
	var pck = tower_pck if tower_pck else tower_scene
	var tw: Node3D = null
	if pck:
		tw = pck.instantiate()
		tw.position = grid_to_world(cell, 0.0)
		add_child(tw)
		towers[cell] = tw
		if tw.has_signal("tower_destroyed"):
			tw.tower_destroyed.connect(func(): on_tower_destroyed(cell))
	
	GameManager.notify("Torre de Gravetos construída!", Tokens.DOURADO_LUZ)
	tower_built.emit(cell, tw)
	path_updated.emit()
	return tw

func on_tower_destroyed(cell: Vector2i) -> void:
	if towers.has(cell):
		towers.erase(cell)
	grid_data[cell] = TileType.PATH if path_cells.has(cell) else TileType.DIRT
	var id = get_point_id(cell)
	astar.set_point_disabled(id, false)
	path_updated.emit()

func on_tower_broken(world_pos: Vector3) -> void:
	var cell = world_to_grid(world_pos)
	var id = get_point_id(cell)
	astar.set_point_disabled(id, false) # Libera caminho imediatamente
	path_updated.emit()

func on_tower_repaired(world_pos: Vector3) -> void:
	var cell = world_to_grid(world_pos)
	var id = get_point_id(cell)
	astar.set_point_disabled(id, true) # Volta a bloquear o ponto no pathfinding
	path_updated.emit()

func get_path_to_flower(from_world_pos: Vector3) -> PackedVector3Array:
	var from_cell = world_to_grid(from_world_pos)
	if not is_valid_cell(from_cell):
		from_cell.x = clampi(from_cell.x, -HALF_EXTENT, HALF_EXTENT)
		from_cell.y = clampi(from_cell.y, -HALF_EXTENT, HALF_EXTENT)
	
	var from_id = get_point_id(from_cell)
	var to_id = get_point_id(flower_cell)
	
	var point_2d_path = astar.get_point_path(from_id, to_id)
	var result = PackedVector3Array()
	
	for pt in point_2d_path:
		var cell = Vector2i(round(pt.x), round(pt.y))
		result.append(grid_to_world(cell, 0.0))
	
	var flower_world = grid_to_world(flower_cell, 0.0)
	if result.is_empty() or result[-1].distance_to(flower_world) > 0.1:
		result.append(flower_world)
		
	return result

# Trilha de terra batida contínua criada por passagem (Foot Trail suave e natural)
func spawn_path_decorations() -> void:
	var path_keys = path_cells.keys()
	var path_count = path_keys.size()
	if path_count == 0:
		return
		
	# MultiMesh para a trilha contínua de terra batida pisada (Foot Trail)
	var trail_mm_node = MultiMeshInstance3D.new()
	trail_mm_node.name = "FootTrailMultiMesh"
	
	var trail_mm = MultiMesh.new()
	trail_mm.transform_format = MultiMesh.TRANSFORM_3D
	trail_mm.use_colors = true
	trail_mm.instance_count = path_count
	
	var disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = CELL_SIZE * 0.58
	disc_mesh.bottom_radius = CELL_SIZE * 0.62
	disc_mesh.height = 0.012
	disc_mesh.radial_segments = 14
	
	var dirt_mat = StandardMaterial3D.new()
	dirt_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	dirt_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	dirt_mat.albedo_color = Color(0.54, 0.44, 0.32) # Terra batida pisada natural
	dirt_mat.roughness = 0.95
	trail_mm_node.material_override = dirt_mat
	
	trail_mm.mesh = disc_mesh
	trail_mm_node.multimesh = trail_mm
	trail_mm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail_mm_node)
	
	for i in range(path_count):
		var cell = path_keys[i]
		var pos = grid_to_world(cell, 0.006)
		
		var t_trail = Transform3D()
		t_trail = t_trail.rotated(Vector3.UP, randf() * TAU)
		var s_var = randf_range(0.96, 1.08)
		t_trail = t_trail.scaled(Vector3(s_var, 1.0, s_var))
		t_trail.origin = pos + Vector3(randf_range(-0.08, 0.08), 0.0, randf_range(-0.08, 0.08))
		trail_mm.set_instance_transform(i, t_trail)
		
		var col_tint = Color(1.0 + randf_range(-0.04, 0.04), 1.0 + randf_range(-0.04, 0.04), 1.0 + randf_range(-0.04, 0.04), 1.0)
		trail_mm.set_instance_color(i, col_tint)

# Enche as bordas do jardim com as flores .tscn e rochedos 3D, mantendo o centro com a Flor Central e Dentes-de-Leão
func spawn_ambient_garden_flowers() -> void:
	var flora_root = Node3D.new()
	flora_root.name = "AmbientGardenFlora"
	add_child(flora_root)
	
	var daisy_scn = load("res://scenes/environment/giant_daisy.tscn")
	var dandelion_scn = load("res://scenes/environment/giant_dandelion.tscn")
	var bell_scn = load("res://scenes/environment/giant_bellflower.tscn")
	var dandelion_clock_scn = load("res://scenes/environment/dandelion_clock.tscn")
	var rock_scn = load("res://scenes/environment/giant_rock.tscn")
	var root_scn = load("res://scenes/environment/giant_tree_root.tscn")
	var dew_scn = load("res://scenes/environment/giant_dewdrop.tscn")
	
	# 1. Dentes-de-Leão Pom-Pom Interativos (Flor central e raio médio)
	if dandelion_clock_scn:
		var starter_positions = [
			Vector2i(4, 5),
			Vector2i(-5, 4),
			Vector2i(5, -5),
			Vector2i(-4, -6),
			Vector2i(7, 3),
			Vector2i(-6, -4)
		]
		for s_pos in starter_positions:
			var d_clock = dandelion_clock_scn.instantiate()
			d_clock.position = grid_to_world(s_pos, 0.0)
			d_clock.rotation.y = randf() * TAU
			flora_root.add_child(d_clock)
			
		for i in range(6):
			var d_clock = dandelion_clock_scn.instantiate()
			var cell = get_random_mid_cell()
			d_clock.position = grid_to_world(cell, 0.0)
			d_clock.rotation.y = randf() * TAU
			flora_root.add_child(d_clock)
			
	# 2. Margaridas Gigantes .tscn (Apenas nas bordas externas radius >= 22m)
	if daisy_scn:
		for i in range(12):
			var daisy = daisy_scn.instantiate()
			var cell = get_random_border_cell()
			daisy.position = grid_to_world(cell, 0.0)
			daisy.rotation.y = randf() * TAU
			var s = randf_range(1.2, 1.8)
			daisy.scale = Vector3(s, s, s)
			flora_root.add_child(daisy)
			
	# 3. Dentes-de-Leão Floridos Dourados .tscn (Apenas nas bordas externas radius >= 22m)
	if dandelion_scn:
		for i in range(10):
			var dand = dandelion_scn.instantiate()
			var cell = get_random_border_cell()
			dand.position = grid_to_world(cell, 0.0)
			dand.rotation.y = randf() * TAU
			var s = randf_range(1.1, 1.6)
			dand.scale = Vector3(s, s, s)
			flora_root.add_child(dand)
			
	# 4. Campânulas Violetas .tscn (Apenas nas bordas externas radius >= 22m)
	if bell_scn:
		for i in range(10):
			var bell = bell_scn.instantiate()
			var cell = get_random_border_cell()
			bell.position = grid_to_world(cell, 0.0)
			bell.rotation.y = randf() * TAU
			var s = randf_range(1.2, 1.7)
			bell.scale = Vector3(s, s, s)
			flora_root.add_child(bell)
			
	# 5. Rochedos 3D Gigantes .tscn (com modelo real de pedra Rocks.glb, sem cubo!)
	if rock_scn:
		var rock_positions = [
			Vector2i(-15, -17),
			Vector2i(17, -15),
			Vector2i(-17, 16),
			Vector2i(16, 18),
			Vector2i(-18, -6),
			Vector2i(18, 7),
			Vector2i(-7, -20),
			Vector2i(8, 20)
		]
		for r_pos in rock_positions:
			var rock = rock_scn.instantiate()
			rock.position = grid_to_world(r_pos, 0.0)
			rock.rotation.y = randf() * TAU
			flora_root.add_child(rock)
			
	# 6. Raízes de árvore gigantes .tscn atravessando quadrantes periféricos
	if root_scn:
		var tree_root1 = root_scn.instantiate()
		tree_root1.position = Vector3(24.0, 0.0, -22.0)
		tree_root1.rotation_degrees = Vector3(0, 35, 0)
		tree_root1.scale = Vector3(1.3, 1.3, 1.3)
		flora_root.add_child(tree_root1)
		
		var tree_root2 = root_scn.instantiate()
		tree_root2.position = Vector3(-22.0, 0.0, 24.0)
		tree_root2.rotation_degrees = Vector3(0, -45, 0)
		tree_root2.scale = Vector3(1.3, 1.3, 1.3)
		flora_root.add_child(tree_root2)
		
	# 7. Gotas de orvalho gigantes .tscn sobre as folhas
	if dew_scn:
		for i in range(8):
			var dew = dew_scn.instantiate()
			var cell = get_random_mid_cell()
			dew.position = grid_to_world(cell, 0.0)
			flora_root.add_child(dew)

# Célula na borda externa do jardim (distância >= 22m da Flor Central)
func get_random_border_cell() -> Vector2i:
	for _attempt in range(50):
		var rx = randi_range(-HALF_EXTENT + 2, HALF_EXTENT - 2)
		var ry = randi_range(-HALF_EXTENT + 2, HALF_EXTENT - 2)
		var c = Vector2i(rx, ry)
		if not path_cells.has(c) and c.length() >= 11:
			return c
	var sign_x = 1 if randf() > 0.5 else -1
	var sign_y = 1 if randf() > 0.5 else -1
	return Vector2i(sign_x * randi_range(12, HALF_EXTENT - 2), sign_y * randi_range(12, HALF_EXTENT - 2))

# Célula intermediária (distância moderada entre 6m e 18m)
func get_random_mid_cell() -> Vector2i:
	for _attempt in range(50):
		var rx = randi_range(-10, 10)
		var ry = randi_range(-10, 10)
		var c = Vector2i(rx, ry)
		if not path_cells.has(c) and c.length() >= 4 and c.length() <= 10:
			return c
	return Vector2i(randi_range(4, 8), randi_range(4, 8))

const DewDropScript = preload("res://scripts/dew_drop.gd")

func spawn_interactive_dew_drops(count: int = 8) -> void:
	for i in range(count):
		var drop = DewDropScript.new()
		var cell = get_random_mid_cell()
		drop.position = grid_to_world(cell, 0.0)
		add_child(drop)

