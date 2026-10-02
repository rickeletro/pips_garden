extends Node3D
class_name GridManager

signal path_updated
signal grass_planted(pos: Vector2i)
signal tower_built(pos: Vector2i, tower_node: Node3D)

const CELL_SIZE: float = 2.0
const HALF_EXTENT: int = 7 # Grid from -7 to +7 (15x15)

enum TileType { DIRT, GRASS, TOWER, FLOWER, SPAWNER }

var grid_data: Dictionary = {} # Vector2i -> TileType
var grass_visuals: Dictionary = {} # Vector2i -> Node3D
var towers: Dictionary = {} # Vector2i -> Node3D

var astar: AStar2D = AStar2D.new()

var flower_cell: Vector2i = Vector2i(0, 0)
var spawner_cells: Array[Vector2i] = [
	Vector2i(0, -6),
	Vector2i(-6, 0),
	Vector2i(6, 0),
	Vector2i(0, 6)
]

const WEIGHT_DIRT: float = 3.5
const WEIGHT_GRASS: float = 1.0

# Packed scene for grass decoration
@export var grass_tuft_scene: PackedScene
@export var tower_scene: PackedScene

func _ready() -> void:
	GameManager.grid_manager = self
	init_grid()

func init_grid() -> void:
	astar.clear()
	grid_data.clear()
	
	# Populate grid cells and AStar nodes
	for x in range(-HALF_EXTENT, HALF_EXTENT + 1):
		for y in range(-HALF_EXTENT, HALF_EXTENT + 1):
			var cell = Vector2i(x, y)
			var id = get_point_id(cell)
			astar.add_point(id, Vector2(cell.x, cell.y), WEIGHT_DIRT)
			grid_data[cell] = TileType.DIRT
	
	# Connect neighboring cells
	for x in range(-HALF_EXTENT, HALF_EXTENT + 1):
		for y in range(-HALF_EXTENT, HALF_EXTENT + 1):
			var cell = Vector2i(x, y)
			var id = get_point_id(cell)
			
			# 4 Cardinal directions
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
	
	# Register special cells
	grid_data[flower_cell] = TileType.FLOWER
	for spawner in spawner_cells:
		grid_data[spawner] = TileType.SPAWNER

func get_point_id(cell: Vector2i) -> int:
	# Unique integer mapping for cell (-7..7, -7..7)
	return (cell.x + 50) * 1000 + (cell.y + 50)

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

func plant_grass(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		GameManager.notify("Fora dos limites do jardim!", Color(1.0, 0.4, 0.4))
		return false
	
	if grid_data.has(cell) and grid_data[cell] == TileType.GRASS:
		GameManager.notify("Aqui já tem grama viçosa!", Color(0.8, 0.8, 0.8))
		return false
		
	if grid_data.has(cell) and (grid_data[cell] == TileType.TOWER or grid_data[cell] == TileType.FLOWER):
		GameManager.notify("Não pode plantar grama nesta estrutura!", Color(1.0, 0.4, 0.4))
		return false
	
	if not GameManager.consume_resources(0, 0, 1):
		return false
	
	grid_data[cell] = TileType.GRASS
	var id = get_point_id(cell)
	astar.set_point_weight_scale(id, WEIGHT_GRASS)
	
	# Spawn visual grass tufts
	spawn_grass_visual(cell)
	
	GameManager.notify("Grama plantada! As pragas preferem este caminho.", Color(0.4, 1.0, 0.5))
	grass_planted.emit(cell)
	path_updated.emit()
	return true

func can_place_tower(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		GameManager.notify("Posição fora do jardim!", Color(1.0, 0.4, 0.4))
		return false
	
	if cell == flower_cell:
		GameManager.notify("Não pode construir sobre a Flor do Jardim!", Color(1.0, 0.4, 0.4))
		return false
		
	for sp in spawner_cells:
		if cell == sp:
			GameManager.notify("Não pode bloquear o ponto de entrada das pragas!", Color(1.0, 0.4, 0.4))
			return false
	
	if grid_data.has(cell) and grid_data[cell] == TileType.TOWER:
		GameManager.notify("Já existe uma torre aqui!", Color(1.0, 0.4, 0.4))
		return false
	
	# Critical rule: Test if blocking this cell cuts off ALL paths from any spawner to the flower
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
	
	# Revert test
	astar.set_point_disabled(test_id, false)
	
	if not all_reachable:
		GameManager.notify("Regra violada: Não é permitido fechar todo o caminho até a flor!", Color(1.0, 0.3, 0.3))
		return false
		
	return true

func build_tower_at(cell: Vector2i, tower_pck: PackedScene = null) -> Node3D:
	if not can_place_tower(cell):
		return null
	
	# Cost: 3 twigs, 2 gears
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
	
	GameManager.notify("Torre de Gravetos construída!", Color(0.9, 0.8, 0.3))
	tower_built.emit(cell, tw)
	path_updated.emit()
	return tw

func on_tower_destroyed(cell: Vector2i) -> void:
	if towers.has(cell):
		towers.erase(cell)
	grid_data[cell] = TileType.DIRT
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
	
	# Ensure the exact flower location is the final destination
	var flower_world = grid_to_world(flower_cell, 0.0)
	if result.is_empty() or result[-1].distance_to(flower_world) > 0.1:
		result.append(flower_world)
		
	return result

func spawn_grass_visual(cell: Vector2i) -> void:
	var center = grid_to_world(cell, 0.0)
	var root_node = Node3D.new()
	root_node.name = "Grass_%d_%d" % [cell.x, cell.y]
	
	# Create multiple stylized grass blades on this tile
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.28, 0.72, 0.22)
	grass_mat.roughness = 0.7
	grass_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	grass_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	
	for i in range(8):
		var blade = MeshInstance3D.new()
		var prism = BoxMesh.new()
		prism.size = Vector3(0.12, 0.55 + randf() * 0.35, 0.08)
		blade.mesh = prism
		blade.material_override = grass_mat
		
		var offset_x = (randf() - 0.5) * (CELL_SIZE * 0.75)
		var offset_z = (randf() - 0.5) * (CELL_SIZE * 0.75)
		blade.position = Vector3(offset_x, prism.size.y * 0.5, offset_z)
		blade.rotation_degrees = Vector3(
			(randf() - 0.5) * 20.0,
			randf() * 360.0,
			(randf() - 0.5) * 20.0
		)
		root_node.add_child(blade)
	
	# Add a small cute clover or dandelion bud randomly
	if randf() > 0.4:
		var bud = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.14
		sphere.height = 0.28
		bud.mesh = sphere
		var bud_mat = StandardMaterial3D.new()
		bud_mat.albedo_color = Color(1.0, 0.88, 0.3) if randf() > 0.5 else Color(0.95, 0.5, 0.7)
		bud.material_override = bud_mat
		bud.position = Vector3((randf() - 0.5) * 0.8, 0.45, (randf() - 0.5) * 0.8)
		root_node.add_child(bud)
		
	root_node.position = center
	add_child(root_node)
	grass_visuals[cell] = root_node
