extends Node3D
class_name SpawnerManager

@export var aphid_scene: PackedScene
@export var caterpillar_scene: PackedScene
@export var wasp_scene: PackedScene
@export var pickup_scene: PackedScene

var grid_manager: GridManager = null

# 7 Ondas com dificuldade progressiva e combinações ricas de pragas
var wave_configs = [
	# Onda 1: Primeiros pulgões terrestres (aprendizado de plantio de grama)
	{ "aphids": 10, "cats": 0, "wasps": 0, "interval": 1.1 },
	# Onda 2: Introdução das lagartas resistentes no solo
	{ "aphids": 16, "cats": 3, "wasps": 0, "interval": 0.95 },
	# Onda 3: Primeira aparição das vespas aéreas (ignoram a grama!)
	{ "aphids": 14, "cats": 6, "wasps": 4, "interval": 0.82 },
	# Onda 4: Enxame misto acelerado
	{ "aphids": 20, "cats": 9, "wasps": 7, "interval": 0.70 },
	# Onda 5: Horda pesada com alta resistência e múltiplos flancos
	{ "aphids": 26, "cats": 13, "wasps": 11, "interval": 0.58 },
	# Onda 6: Enxame crítico no solo e céu
	{ "aphids": 34, "cats": 18, "wasps": 15, "interval": 0.48 },
	# Onda 7: Clímax épico da Área 1 (A invasão da Torre do Jardim)
	{ "aphids": 45, "cats": 24, "wasps": 22, "interval": 0.38 }
]

var spawning_active: bool = false
var spawn_queue: Array[String] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

func _ready() -> void:
	init_references()
	GameManager.wave_state_changed.connect(_on_wave_state_changed)
	spawn_ground_harvest(12, 6, 8)

func init_references() -> void:
	if GameManager.grid_manager:
		grid_manager = GameManager.grid_manager as GridManager
	elif is_inside_tree() and get_tree():
		grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _process(delta: float) -> void:
	if not spawning_active:
		return
		
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		if not spawn_queue.is_empty():
			var enemy_type = spawn_queue.pop_front()
			spawn_single_enemy(enemy_type)
			spawn_timer = spawn_interval
		else:
			spawning_active = false

func _on_wave_state_changed(state: String, wave_num: int) -> void:
	if state == "WAVE_ACTIVE":
		start_wave_spawning(wave_num)
	elif state == "PREPARATION":
		# Renovação de recursos no jardim para a próxima defesa
		spawn_ground_harvest(10, 5, 8)

func start_wave_spawning(wave_num: int) -> void:
	var idx = clampi(wave_num - 1, 0, wave_configs.size() - 1)
	var cfg = wave_configs[idx]
	
	spawn_queue.clear()
	spawn_interval = cfg["interval"]
	
	for i in range(cfg["aphids"]):
		spawn_queue.append("aphid")
	for i in range(cfg["cats"]):
		spawn_queue.append("cat")
	for i in range(cfg["wasps"]):
		spawn_queue.append("wasp")
		
	spawn_queue.shuffle()
	spawning_active = true
	spawn_timer = 0.5

func spawn_single_enemy(type: String) -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 0.0)
	
	var en_node: Node3D = null
	match type:
		"aphid":
			if aphid_scene: en_node = aphid_scene.instantiate()
		"cat":
			if caterpillar_scene: en_node = caterpillar_scene.instantiate()
		"wasp":
			if wasp_scene: en_node = wasp_scene.instantiate()
			
	if en_node:
		add_child(en_node)
		en_node.global_position = spawn_pos

func spawn_ground_harvest(twig_count: int, gear_count: int, seed_count: int) -> void:
	if not grid_manager:
		init_references()
	if not grid_manager or not pickup_scene:
		return
		
	var total_items = []
	for i in range(twig_count): total_items.append("TWIG")
	for i in range(gear_count): total_items.append("GEAR")
	for i in range(seed_count): total_items.append("SEED")
	
	var extent = 18
	if grid_manager:
		extent = mini(18, grid_manager.HALF_EXTENT - 3)
		
	for item_type in total_items:
		var rx = randi_range(-extent, extent)
		var rz = randi_range(-extent, extent)
		if rx == 0 and rz == 0:
			rx = 2
			
		var spawn_pos = grid_manager.grid_to_world(Vector2i(rx, rz), 0.25)
		spawn_pos.x += (randf() - 0.5) * 1.2
		spawn_pos.z += (randf() - 0.5) * 1.2
		
		var pickup = pickup_scene.instantiate()
		pickup.item_type = item_type
		add_child(pickup)
		pickup.global_position = spawn_pos
