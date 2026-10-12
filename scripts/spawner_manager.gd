extends Node3D
class_name SpawnerManager

@export var aphid_scene: PackedScene
@export var caterpillar_scene: PackedScene
@export var wasp_scene: PackedScene
@export var beetle_scene: PackedScene
@export var firefly_scene: PackedScene
@export var boss_snail_scene: PackedScene
@export var boss_moth_scene: PackedScene
@export var boss_mantis_scene: PackedScene
@export var boss_spider_scene: PackedScene
@export var boss_wasp_queen_scene: PackedScene
@export var boss_scorpion_scene: PackedScene
@export var pickup_scene: PackedScene

var grid_manager: GridManager = null

# 7 Ondas do Dia 1 (Pós-onda 3: Boss Caramujo Ancião)
var day1_wave_configs = [
	{ "aphids": 6, "cats": 0, "wasps": 0, "beetles": 0, "fireflies": 0, "interval": 2.6 },
	{ "aphids": 8, "cats": 1, "wasps": 0, "beetles": 0, "fireflies": 0, "interval": 2.3 },
	{ "aphids": 9, "cats": 1, "wasps": 1, "beetles": 0, "fireflies": 0, "interval": 2.1 },
	{ "aphids": 12, "cats": 2, "wasps": 2, "beetles": 0, "fireflies": 0, "interval": 1.8 },
	{ "aphids": 14, "cats": 3, "wasps": 3, "beetles": 0, "fireflies": 0, "interval": 1.5 },
	{ "aphids": 16, "cats": 4, "wasps": 4, "beetles": 0, "fireflies": 0, "interval": 1.3 },
	{ "aphids": 18, "cats": 4, "wasps": 5, "beetles": 0, "fireflies": 0, "interval": 1.1 }
]

# 7 Ondas da Noite 1 (Pós-onda 3: Boss Mariposa Rainha)
var night1_wave_configs = [
	{ "aphids": 0, "cats": 0, "wasps": 0, "beetles": 2, "fireflies": 6, "interval": 2.2 },
	{ "aphids": 0, "cats": 0, "wasps": 0, "beetles": 4, "fireflies": 8, "interval": 2.0 },
	{ "aphids": 6, "cats": 0, "wasps": 0, "beetles": 5, "fireflies": 10, "interval": 1.8 },
	{ "aphids": 10, "cats": 0, "wasps": 0, "beetles": 6, "fireflies": 12, "interval": 1.5 },
	{ "aphids": 0, "cats": 4, "wasps": 0, "beetles": 8, "fireflies": 14, "interval": 1.3 },
	{ "aphids": 0, "cats": 6, "wasps": 0, "beetles": 10, "fireflies": 16, "interval": 1.1 },
	{ "aphids": 0, "cats": 8, "wasps": 0, "beetles": 12, "fireflies": 20, "interval": 0.8 }
]

# 7 Ondas do Dia 2 (Pós-onda 3: Boss Louva-a-Deus Imperial)
var day2_wave_configs = [
	{ "aphids": 16, "cats": 4, "wasps": 4, "beetles": 0, "fireflies": 0, "interval": 1.4 },
	{ "aphids": 20, "cats": 6, "wasps": 6, "beetles": 0, "fireflies": 0, "interval": 1.2 },
	{ "aphids": 24, "cats": 8, "wasps": 8, "beetles": 0, "fireflies": 0, "interval": 1.0 },
	{ "aphids": 30, "cats": 10, "wasps": 12, "beetles": 0, "fireflies": 0, "interval": 0.8 },
	{ "aphids": 36, "cats": 14, "wasps": 16, "beetles": 0, "fireflies": 0, "interval": 0.65 },
	{ "aphids": 42, "cats": 18, "wasps": 20, "beetles": 0, "fireflies": 0, "interval": 0.50 },
	{ "aphids": 50, "cats": 22, "wasps": 24, "beetles": 0, "fireflies": 0, "interval": 0.40 }
]

# 7 Ondas da Noite 2 (Pós-onda 3: Boss Aranha-Tecelã Sombria)
var night2_wave_configs = [
	{ "aphids": 0, "cats": 2, "wasps": 0, "beetles": 6, "fireflies": 10, "interval": 1.4 },
	{ "aphids": 0, "cats": 4, "wasps": 0, "beetles": 8, "fireflies": 14, "interval": 1.2 },
	{ "aphids": 8, "cats": 6, "wasps": 0, "beetles": 10, "fireflies": 16, "interval": 1.0 },
	{ "aphids": 12, "cats": 8, "wasps": 0, "beetles": 14, "fireflies": 20, "interval": 0.8 },
	{ "aphids": 16, "cats": 10, "wasps": 0, "beetles": 18, "fireflies": 24, "interval": 0.65 },
	{ "aphids": 20, "cats": 12, "wasps": 0, "beetles": 22, "fireflies": 28, "interval": 0.50 },
	{ "aphids": 26, "cats": 16, "wasps": 0, "beetles": 26, "fireflies": 32, "interval": 0.40 }
]

# 7 Ondas do Dia 3 (Pós-onda 3: Boss Vespa Imperatriz)
var day3_wave_configs = [
	{ "aphids": 18, "cats": 6, "wasps": 8, "beetles": 0, "fireflies": 0, "interval": 1.1 },
	{ "aphids": 24, "cats": 8, "wasps": 12, "beetles": 0, "fireflies": 0, "interval": 0.9 },
	{ "aphids": 30, "cats": 10, "wasps": 16, "beetles": 0, "fireflies": 0, "interval": 0.75 },
	{ "aphids": 36, "cats": 12, "wasps": 20, "beetles": 0, "fireflies": 0, "interval": 0.60 },
	{ "aphids": 42, "cats": 14, "wasps": 24, "beetles": 0, "fireflies": 0, "interval": 0.50 },
	{ "aphids": 48, "cats": 16, "wasps": 28, "beetles": 0, "fireflies": 0, "interval": 0.42 },
	{ "aphids": 55, "cats": 20, "wasps": 32, "beetles": 0, "fireflies": 0, "interval": 0.35 }
]

# 3 Ondas Densas da Noite 3 (Pré-Chefe Final Escorpião)
var night3_wave_configs = [
	{ "aphids": 16, "cats": 6, "wasps": 0, "beetles": 12, "fireflies": 16, "interval": 0.65 },
	{ "aphids": 22, "cats": 8, "wasps": 0, "beetles": 16, "fireflies": 22, "interval": 0.50 },
	{ "aphids": 30, "cats": 12, "wasps": 0, "beetles": 22, "fireflies": 30, "interval": 0.38 }
]

var spawning_active: bool = false
var spawn_queue: Array[String] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0
var gnome_spawned_this_night: bool = false

func _ready() -> void:
	add_to_group("spawner_manager")
	_load_fallback_scenes()
	init_references()
	GameManager.wave_state_changed.connect(_on_wave_state_changed)
	spawn_ground_harvest(10, 6, 0)

func _load_fallback_scenes() -> void:
	if not beetle_scene and ResourceLoader.exists("res://scenes/enemies/beetle.tscn"):
		beetle_scene = load("res://scenes/enemies/beetle.tscn")
	if not firefly_scene and ResourceLoader.exists("res://scenes/enemies/firefly.tscn"):
		firefly_scene = load("res://scenes/enemies/firefly.tscn")
	if not boss_snail_scene and ResourceLoader.exists("res://scenes/enemies/boss_snail.tscn"):
		boss_snail_scene = load("res://scenes/enemies/boss_snail.tscn")
	if not boss_moth_scene and ResourceLoader.exists("res://scenes/enemies/boss_moth.tscn"):
		boss_moth_scene = load("res://scenes/enemies/boss_moth.tscn")
	if not boss_mantis_scene and ResourceLoader.exists("res://scenes/enemies/boss_mantis.tscn"):
		boss_mantis_scene = load("res://scenes/enemies/boss_mantis.tscn")
	if not boss_spider_scene and ResourceLoader.exists("res://scenes/enemies/boss_spider.tscn"):
		boss_spider_scene = load("res://scenes/enemies/boss_spider.tscn")
	if not boss_wasp_queen_scene and ResourceLoader.exists("res://scenes/enemies/boss_wasp_queen.tscn"):
		boss_wasp_queen_scene = load("res://scenes/enemies/boss_wasp_queen.tscn")
	if not boss_scorpion_scene and ResourceLoader.exists("res://scenes/enemies/boss_scorpion.tscn"):
		boss_scorpion_scene = load("res://scenes/enemies/boss_scorpion.tscn")
	if not aphid_scene and ResourceLoader.exists("res://scenes/enemies/aphid.tscn"):
		aphid_scene = load("res://scenes/enemies/aphid.tscn")
	if not caterpillar_scene and ResourceLoader.exists("res://scenes/enemies/caterpillar.tscn"):
		caterpillar_scene = load("res://scenes/enemies/caterpillar.tscn")
	if not wasp_scene and ResourceLoader.exists("res://scenes/enemies/wasp.tscn"):
		wasp_scene = load("res://scenes/enemies/wasp.tscn")
	if not pickup_scene and ResourceLoader.exists("res://scenes/pickup.tscn"):
		pickup_scene = load("res://scenes/pickup.tscn")
		firefly_scene = load("res://scenes/enemies/firefly.tscn")
	if not boss_snail_scene and ResourceLoader.exists("res://scenes/enemies/boss_snail.tscn"):
		boss_snail_scene = load("res://scenes/enemies/boss_snail.tscn")
	if not boss_moth_scene and ResourceLoader.exists("res://scenes/enemies/boss_moth.tscn"):
		boss_moth_scene = load("res://scenes/enemies/boss_moth.tscn")
	if not aphid_scene and ResourceLoader.exists("res://scenes/enemies/aphid.tscn"):
		aphid_scene = load("res://scenes/enemies/aphid.tscn")
	if not caterpillar_scene and ResourceLoader.exists("res://scenes/enemies/caterpillar.tscn"):
		caterpillar_scene = load("res://scenes/enemies/caterpillar.tscn")
	if not wasp_scene and ResourceLoader.exists("res://scenes/enemies/wasp.tscn"):
		wasp_scene = load("res://scenes/enemies/wasp.tscn")
	if not pickup_scene and ResourceLoader.exists("res://scenes/pickup.tscn"):
		pickup_scene = load("res://scenes/pickup.tscn")

func is_spawning_active() -> bool:
	return spawning_active or not spawn_queue.is_empty()

func init_references() -> void:
	if GameManager.grid_manager:
		grid_manager = GameManager.grid_manager as GridManager
	elif is_inside_tree() and get_tree():
		grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _process(delta: float) -> void:
	# Verificação de spawn do Gnomo Ladrão à noite ao final da 1ª onda
	if GameManager.current_period == "NIGHT" and GameManager.current_wave == 1 and not gnome_spawned_this_night:
		if spawn_queue.size() <= 2:
			gnome_spawned_this_night = true
			spawn_gnome_npc()
	elif GameManager.current_period == "DAY":
		gnome_spawned_this_night = false
		
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
			GameManager.check_wave_cleared_status()

func spawn_gnome_npc() -> void:
	var tree = get_tree()
	if not tree:
		return
	var existing = tree.get_nodes_in_group("gnome")
	if not existing.is_empty():
		return
		
	var gnome_script = load("res://scripts/gnome_npc.gd")
	if gnome_script:
		var gnome = gnome_script.new()
		var parent_node = get_parent() if get_parent() else self
		parent_node.add_child(gnome)
		var side_x = -46.0 if randf() < 0.5 else 46.0
		gnome.global_position = Vector3(side_x, 0.0, randf_range(-20.0, 20.0))
		GameManager.notify("🦹‍♂️ Um Gnomo Ladrão invadiu o jardim para roubar os itens!", Color(0.4, 0.75, 1.0))

func _on_wave_state_changed(state: String, wave_num: int) -> void:
	if state == "WAVE_ACTIVE":
		if GameManager.current_period != "BOSS" and GameManager.current_period != "BOSS_MOTH":
			start_wave_spawning(wave_num)
	elif state == "PREPARATION":
		# Renovação dinâmica com teto de 24 itens no chão e curva suave
		var tree = get_tree()
		var existing_pickups = tree.get_nodes_in_group("pickups").size() if tree else 0
		if existing_pickups < 24:
			var twig_amt = clampi(9 - int(GameManager.current_wave * 0.7), 4, 9)
			var gear_amt = clampi(5 - int(GameManager.current_wave * 0.5), 2, 5)
			var available_slots = max(0, 24 - existing_pickups)
			var total_to_spawn = twig_amt + gear_amt
			if total_to_spawn > available_slots:
				var ratio = float(available_slots) / float(total_to_spawn)
				twig_amt = maxi(1, int(round(twig_amt * ratio)))
				gear_amt = maxi(1, available_slots - twig_amt)
			spawn_ground_harvest(twig_amt, gear_amt, 0)

func start_wave_spawning(wave_num: int) -> void:
	var configs = []
	if GameManager.current_period == "NIGHT":
		if GameManager.current_night == 3:
			configs = night3_wave_configs
		elif GameManager.current_night == 2:
			configs = night2_wave_configs
		else:
			configs = night1_wave_configs
	else:
		if GameManager.current_day == 3:
			configs = day3_wave_configs
		elif GameManager.current_day == 2:
			configs = day2_wave_configs
		else:
			configs = day1_wave_configs
			
	var idx = clampi(wave_num - 1, 0, configs.size() - 1)
	var cfg = configs[idx]
	
	spawn_queue.clear()
	spawn_interval = cfg["interval"]
	
	for i in range(cfg.get("aphids", 0)): spawn_queue.append("aphid")
	for i in range(cfg.get("cats", 0)): spawn_queue.append("cat")
	for i in range(cfg.get("wasps", 0)): spawn_queue.append("wasp")
	for i in range(cfg.get("beetles", 0)): spawn_queue.append("beetle")
	for i in range(cfg.get("fireflies", 0)): spawn_queue.append("firefly")
		
	spawn_queue.shuffle()
	spawning_active = true
	spawn_timer = 0.5
	
	if GameManager.current_period == "DAY" and cfg.get("wasps", 0) > 0:
		SoundManager.play_bee_buzz(-18.0)

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
	if type == "wasp" or type == "firefly":
		spawn_pos.y = 1.8
		if type == "wasp":
			SoundManager.play_bee_buzz(-16.0)
	else:
		spawn_pos.y = 0.08
	
	var en_node: Node3D = null
	match type:
		"aphid":
			if aphid_scene: en_node = aphid_scene.instantiate()
		"cat":
			if caterpillar_scene: en_node = caterpillar_scene.instantiate()
		"wasp":
			if wasp_scene: en_node = wasp_scene.instantiate()
		"beetle":
			if beetle_scene: en_node = beetle_scene.instantiate()
		"firefly":
			if firefly_scene: en_node = firefly_scene.instantiate()
			
	if en_node:
		en_node.position = spawn_pos
		add_child(en_node)
		en_node.global_position = spawn_pos
		if en_node.has_method("recalculate_path"):
			en_node.recalculate_path()

func spawn_boss_snail() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[0]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 0.1)
	
	var boss_node: Node3D = null
	if boss_snail_scene:
		boss_node = boss_snail_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_snail.tscn"):
		boss_node = load("res://scenes/enemies/boss_snail.tscn").instantiate()
		
	if boss_node:
		boss_node.position = spawn_pos
		add_child(boss_node)
		boss_node.global_position = spawn_pos
		if boss_node.has_method("recalculate_path"):
			boss_node.recalculate_path()

func spawn_boss_moth() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 2.4)
	
	var moth_node: Node3D = null
	if boss_moth_scene:
		moth_node = boss_moth_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_moth.tscn"):
		moth_node = load("res://scenes/enemies/boss_moth.tscn").instantiate()
		
	if moth_node:
		moth_node.position = spawn_pos
		add_child(moth_node)
		moth_node.global_position = spawn_pos

func spawn_boss_mantis() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 0.1)
	
	var mantis_node: Node3D = null
	if boss_mantis_scene:
		mantis_node = boss_mantis_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_mantis.tscn"):
		mantis_node = load("res://scenes/enemies/boss_mantis.tscn").instantiate()
		
	if mantis_node:
		mantis_node.position = spawn_pos
		add_child(mantis_node)
		mantis_node.global_position = spawn_pos
		if mantis_node.has_method("recalculate_path"):
			mantis_node.recalculate_path()

func spawn_boss_spider() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 0.1)
	
	var spider_node: Node3D = null
	if boss_spider_scene:
		spider_node = boss_spider_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_spider.tscn"):
		spider_node = load("res://scenes/enemies/boss_spider.tscn").instantiate()
		
	if spider_node:
		spider_node.position = spawn_pos
		add_child(spider_node)
		spider_node.global_position = spawn_pos
		if spider_node.has_method("recalculate_path"):
			spider_node.recalculate_path()

func spawn_boss_wasp_queen() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 2.2)
	
	var wasp_queen_node: Node3D = null
	if boss_wasp_queen_scene:
		wasp_queen_node = boss_wasp_queen_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_wasp_queen.tscn"):
		wasp_queen_node = load("res://scenes/enemies/boss_wasp_queen.tscn").instantiate()
		
	if wasp_queen_node:
		wasp_queen_node.position = spawn_pos
		add_child(wasp_queen_node)
		wasp_queen_node.global_position = spawn_pos

func spawn_boss_scorpion() -> void:
	if not grid_manager:
		init_references()
	if not grid_manager:
		return
		
	var spawners = grid_manager.spawner_cells
	if spawners.is_empty():
		return
		
	var sp_cell = spawners[randi() % spawners.size()]
	var spawn_pos = grid_manager.grid_to_world(sp_cell, 0.1)
	
	var scorpion_node: Node3D = null
	if boss_scorpion_scene:
		scorpion_node = boss_scorpion_scene.instantiate()
	elif ResourceLoader.exists("res://scenes/enemies/boss_scorpion.tscn"):
		scorpion_node = load("res://scenes/enemies/boss_scorpion.tscn").instantiate()
		
	if scorpion_node:
		scorpion_node.position = spawn_pos
		add_child(scorpion_node)
		scorpion_node.global_position = spawn_pos
		if scorpion_node.has_method("recalculate_path"):
			scorpion_node.recalculate_path()

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
