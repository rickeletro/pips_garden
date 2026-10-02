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

var astar: AStar2D = AStar2D.new()

var flower_cell: Vector2i = Vector2i(0, 0)
var spawner_cells: Array[Vector2i] = [
	Vector2i(0, -22), # Portão Norte
	Vector2i(-22, 0), # Portão Oeste
	Vector2i(22, 0),  # Portão Leste
	Vector2i(0, 22)   # Portão Sul
]

const WEIGHT_DIRT: float = 3.5
const WEIGHT_PATH: float = 1.6  # Caminho demarcado de terra batida (atrai pragas naturalmente)
const WEIGHT_GRASS: float = 1.0 # Grama viçosa plantada por Pip (preferência máxima)

# Packed scenes
@export var tower_scene: PackedScene

# MultiMeshInstance3D para a Grama com Shader Aquarela Zelda TotK
var grass_multimesh: MultiMeshInstance3D = null
var grass_blade_mesh: BoxMesh = null
var current_grass_count: int = 0
const MAX_GRASS_BLADES: int = 28000

func _ready() -> void:
	GameManager.grid_manager = self
	generate_winding_paths()
	init_grid()
	init_watercolor_grass_multimesh()
	spawn_path_decorations()
	spawn_ambient_garden_flowers()

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

# Inicializa o MultiMeshInstance3D com o Shader Aquarela Zelda TotK
func init_watercolor_grass_multimesh() -> void:
	grass_multimesh = MultiMeshInstance3D.new()
	grass_multimesh.name = "ZeldaWatercolorGrassMultiMesh"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = MAX_GRASS_BLADES
	
	grass_blade_mesh = BoxMesh.new()
	grass_blade_mesh.size = Vector3(0.18, 0.95, 0.04)
	
	var mat = load("res://shaders/zelda_watercolor_grass.tres")
	if mat:
		grass_blade_mesh.material = mat
		
	mm.mesh = grass_blade_mesh
	grass_multimesh.multimesh = mm
	add_child(grass_multimesh)
	
	# Povoar grama ambiente espalhada pelo campo do jardim
	spawn_ambient_meadow_grass(11000)

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
		var tilt_x = (randf() - 0.5) * 0.25
		t = t.rotated(Vector3.UP, rot_y)
		t = t.rotated(Vector3.RIGHT, tilt_x)
		
		var scale_var = 0.75 + randf() * 0.55
		t = t.scaled(Vector3(scale_var, scale_var, scale_var))
		t.origin = Vector3(rx, (grass_blade_mesh.size.y * scale_var) * 0.5, rz)
		
		mm.set_instance_transform(current_grass_count, t)
		var col_var = Color(0.85 + randf() * 0.15, 0.9 + randf() * 0.1, 0.85 + randf() * 0.15, 1.0)
		mm.set_instance_color(current_grass_count, col_var)
		
		current_grass_count += 1

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
	var id = get_point_id(cell)
	astar.set_point_weight_scale(id, WEIGHT_GRASS)
	
	# Adicionar tufos densos ao MultiMesh no local plantado
	add_dense_grass_to_multimesh(cell, 24)
	
	GameManager.notify("Grama viçosa plantada! Pragas terrestres preferem e são desaceleradas aqui.", Tokens.VERDE_FOLHA)
	grass_planted.emit(cell)
	path_updated.emit()
	return true

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
		t = t.rotated(Vector3.RIGHT, (randf() - 0.5) * 0.3)
		var s = 0.85 + randf() * 0.45
		t = t.scaled(Vector3(s, s, s))
		t.origin = center + Vector3(offset_x, (grass_blade_mesh.size.y * s) * 0.5, offset_z)
		
		mm.set_instance_transform(current_grass_count, t)
		mm.set_instance_color(current_grass_count, Color(1.0, 1.0, 0.9, 1.0))
		current_grass_count += 1

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

# Decorações visuais da trilha de terra batida e pedras
func spawn_path_decorations() -> void:
	var path_node = Node3D.new()
	path_node.name = "PathDecorations"
	add_child(path_node)
	
	var pebble_mat = StandardMaterial3D.new()
	pebble_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	pebble_mat.albedo_color = Color(0.52, 0.42, 0.32) # Terra batida
	pebble_mat.roughness = 0.92
	
	for cell in path_cells.keys():
		var pos = grid_to_world(cell, 0.015)
		# Disco orgânico arredondado de terra/pedra
		var slab = MeshInstance3D.new()
		var disc = CylinderMesh.new()
		disc.top_radius = CELL_SIZE * 0.44
		disc.bottom_radius = CELL_SIZE * 0.48
		disc.height = 0.025
		disc.radial_segments = 8
		slab.mesh = disc
		slab.material_override = pebble_mat
		slab.position = pos + Vector3((randf() - 0.5) * 0.25, 0.0, (randf() - 0.5) * 0.25)
		slab.rotation.y = randf() * TAU
		path_node.add_child(slab)
		
		# Pedras de rio na beira da trilha
		if randf() > 0.4:
			var pebble = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.14 + randf() * 0.12
			sphere.height = sphere.radius * 1.3
			pebble.mesh = sphere
			var p_mat = StandardMaterial3D.new()
			p_mat.albedo_color = Color(0.62, 0.58, 0.52)
			pebble.material_override = p_mat
			var edge_offset = Vector3((randf() - 0.5) * 1.5, 0.05, (randf() - 0.5) * 1.5)
			pebble.position = pos + edge_offset
			path_node.add_child(pebble)

# Enche o jardim com flores coloridas, margaridas, dentes-de-leão e elementos gigantes
func spawn_ambient_garden_flowers() -> void:
	var flowers_root = Node3D.new()
	flowers_root.name = "AmbientGardenFlora"
	add_child(flowers_root)
	
	var daisy_scn = load("res://scenes/environment/giant_daisy.tscn")
	var dandelion_scn = load("res://scenes/environment/giant_dandelion.tscn")
	var bell_scn = load("res://scenes/environment/giant_bellflower.tscn")
	var rock_scn = load("res://scenes/environment/giant_rock.tscn")
	var root_scn = load("res://scenes/environment/giant_tree_root.tscn")
	var dew_scn = load("res://scenes/environment/giant_dewdrop.tscn")
	
	# 1. Margaridas gigantes pelo campo
	if daisy_scn:
		for i in range(36):
			var daisy = daisy_scn.instantiate()
			var cell = get_random_free_cell()
			daisy.position = grid_to_world(cell, 0.0)
			daisy.rotation.y = randf() * TAU
			var s = 0.85 + randf() * 0.4
			daisy.scale = Vector3(s, s, s)
			flowers_root.add_child(daisy)
			
	# 2. Dentes-de-Leão dourados
	if dandelion_scn:
		for i in range(42):
			var dand = dandelion_scn.instantiate()
			var cell = get_random_free_cell()
			dand.position = grid_to_world(cell, 0.0)
			dand.rotation.y = randf() * TAU
			flowers_root.add_child(dand)
			
	# 3. Campânulas violetas
	if bell_scn:
		for i in range(30):
			var bell = bell_scn.instantiate()
			var cell = get_random_free_cell()
			bell.position = grid_to_world(cell, 0.0)
			bell.rotation.y = randf() * TAU
			flowers_root.add_child(bell)
			
	# 4. Rochedos gigantes bloqueando trechos e esculpindo o relevo
	if rock_scn:
		var rock_positions = [
			Vector2i(-10, -12),
			Vector2i(12, -10),
			Vector2i(-12, 11),
			Vector2i(11, 13)
		]
		for r_pos in rock_positions:
			var rock = rock_scn.instantiate()
			rock.position = grid_to_world(r_pos, 0.0)
			rock.rotation.y = randf() * TAU
			flowers_root.add_child(rock)
			
	# 5. Raiz de árvore gigante atravessando o quadrante nordeste
	if root_scn:
		var tree_root = root_scn.instantiate()
		tree_root.position = Vector3(18.0, 0.0, -16.0)
		tree_root.rotation_degrees = Vector3(0, 35, 0)
		flowers_root.add_child(tree_root)
		
	# 6. Gotas de orvalho translúcidas sobre as folhas
	if dew_scn:
		for i in range(30):
			var dew = dew_scn.instantiate()
			var cell = get_random_free_cell()
			dew.position = grid_to_world(cell, 0.0)
			flowers_root.add_child(dew)

func get_random_free_cell() -> Vector2i:
	for _attempt in range(50):
		var rx = randi_range(-HALF_EXTENT + 2, HALF_EXTENT - 2)
		var ry = randi_range(-HALF_EXTENT + 2, HALF_EXTENT - 2)
		var c = Vector2i(rx, ry)
		if not path_cells.has(c) and c.length() > 3:
			return c
	return Vector2i(randi_range(4, 15), randi_range(4, 15))
