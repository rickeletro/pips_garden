extends Node

signal resources_changed(twigs: int, gears: int, seeds: int, capacity: int)
signal pip_stats_changed(hp: float, max_hp: float, xp: int, level: int)
signal flower_stats_changed(hp: float, max_hp: float)
signal wave_state_changed(state: String, wave_number: int)
signal wave_countdown_updated(time_left: float)
signal notification_requested(text: String, color: Color)
signal enemy_died(enemy: Node3D)

# Action signals for Hotbar Slots
signal request_plant_grass
signal request_build_tower
signal request_attack
signal request_dash
signal request_cycle_poison
signal request_repair

enum WaveState { PREPARATION, WAVE_ACTIVE, VICTORY, DEFEAT }

# Global Node References (immune to get_tree null bug)
var grid_manager: Node3D = null
var flower: Node3D = null
var heroine: CharacterBody3D = null

# Inventory (Bolsa de Couro)
var twigs: int = 10
var gears: int = 4
var seeds: int = 8
var bag_capacity: int = 30

# Pip Stats
var pip_hp: float = 100.0
var pip_max_hp: float = 100.0
var pip_xp: int = 0
var pip_level: int = 1
var pip_damage_bonus: float = 0.0

# Flor do Jardim Stats
var flower_hp: float = 120.0
var flower_max_hp: float = 120.0

# Waves & Countdown
var current_wave: int = 0
var max_waves: int = 7
var wave_state: WaveState = WaveState.PREPARATION
var enemies_alive: int = 0

const COUNTDOWN_DURATION: float = 15.0
var wave_countdown: float = COUNTDOWN_DURATION
var countdown_active: bool = true

# Active selected tower poison mode (for UI slot)
var active_poison_mode: int = 0 # 0: Slow, 1: Corrosive, 2: Mist

func _ready() -> void:
	emit_all_stats()

func _process(delta: float) -> void:
	if wave_state == WaveState.PREPARATION and countdown_active:
		wave_countdown -= delta
		wave_countdown_updated.emit(max(0.0, wave_countdown))
		if wave_countdown <= 0.0:
			start_next_wave()

func emit_all_stats() -> void:
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	flower_stats_changed.emit(flower_hp, flower_max_hp)
	wave_state_changed.emit(get_wave_state_string(), current_wave)
	wave_countdown_updated.emit(wave_countdown)

func get_total_inventory_items() -> int:
	return twigs + gears + seeds

func can_add_item() -> bool:
	return get_total_inventory_items() < bag_capacity

func add_twig(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		notify("Bolsa de couro cheia!", Color(1.0, 0.4, 0.4))
		return false
	twigs += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func add_gear(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		notify("Bolsa de couro cheia!", Color(1.0, 0.4, 0.4))
		return false
	gears += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func add_seed(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		notify("Bolsa de couro cheia!", Color(1.0, 0.4, 0.4))
		return false
	seeds += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func consume_resources(req_twigs: int, req_gears: int, req_seeds: int) -> bool:
	if twigs >= req_twigs and gears >= req_gears and seeds >= req_seeds:
		twigs -= req_twigs
		gears -= req_gears
		seeds -= req_seeds
		resources_changed.emit(twigs, gears, seeds, bag_capacity)
		return true
	notify("Recursos insuficientes na bolsa!", Color(1.0, 0.4, 0.4))
	return false

func add_xp(amount: int) -> void:
	pip_xp += amount
	var needed = pip_level * 50
	if pip_xp >= needed:
		pip_xp -= needed
		pip_level += 1
		pip_damage_bonus += 5.0
		pip_max_hp += 15.0
		pip_hp = pip_max_hp
		bag_capacity += 5
		notify("Pip subiu para o Nível %d! Dano e bolsa aumentados!" % pip_level, Color(1.0, 0.85, 0.2))
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	resources_changed.emit(twigs, gears, seeds, bag_capacity)

func damage_pip(amount: float) -> void:
	if wave_state == WaveState.DEFEAT:
		return
	pip_hp = max(0.0, pip_hp - amount)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	if pip_hp <= 0.0:
		notify("Pip foi atordoada! Resgatando para a flor...", Color(1.0, 0.3, 0.3))
		pip_hp = pip_max_hp * 0.6
		pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)

func heal_pip(amount: float) -> void:
	pip_hp = min(pip_max_hp, pip_hp + amount)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)

func damage_flower(amount: float) -> void:
	if wave_state == WaveState.DEFEAT:
		return
	flower_hp = max(0.0, flower_hp - amount)
	flower_stats_changed.emit(flower_hp, flower_max_hp)
	if flower_hp <= 0.0:
		wave_state = WaveState.DEFEAT
		countdown_active = false
		wave_state_changed.emit("DEFEAT", current_wave)
		notify("A Flor do Jardim foi destruída pelas pragas!", Color(1.0, 0.2, 0.2))

func heal_flower(amount: float) -> void:
	flower_hp = min(flower_max_hp, flower_hp + amount)
	flower_stats_changed.emit(flower_hp, flower_max_hp)

func start_next_wave() -> bool:
	if wave_state != WaveState.PREPARATION:
		return false
	current_wave += 1
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_countdown = COUNTDOWN_DURATION
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("Onda %d iniciada! Defenda a flor!" % current_wave, Color(1.0, 0.6, 0.2))
	return true

func register_enemy_spawned() -> void:
	enemies_alive += 1

func register_enemy_killed(enemy: Node3D) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	enemy_died.emit(enemy)
	if wave_state == WaveState.WAVE_ACTIVE and enemies_alive == 0:
		var tree = get_tree()
		if tree:
			var spawner = tree.get_first_node_in_group("spawner_manager")
			if spawner and spawner.has_method("is_spawning_active") and spawner.is_spawning_active():
				return
		on_wave_cleared()

func on_wave_cleared() -> void:
	if current_wave >= max_waves:
		wave_state = WaveState.VICTORY
		countdown_active = false
		wave_state_changed.emit("VICTORY", current_wave)
		notify("Vitória! O Jardim da Torre foi salvo!", Color(0.3, 1.0, 0.4))
	else:
		wave_state = WaveState.PREPARATION
		wave_countdown = COUNTDOWN_DURATION
		countdown_active = true
		wave_state_changed.emit("PREPARATION", current_wave)
		notify("Onda %d vencida! Próxima onda em 15 segundos..." % current_wave, Color(0.4, 0.9, 0.5))

func notify(text: String, color: Color = Color.WHITE) -> void:
	notification_requested.emit(text, color)

func get_wave_state_string() -> String:
	match wave_state:
		WaveState.PREPARATION: return "PREPARATION"
		WaveState.WAVE_ACTIVE: return "WAVE_ACTIVE"
		WaveState.VICTORY: return "VICTORY"
		WaveState.DEFEAT: return "DEFEAT"
	return "PREPARATION"

func reset_game() -> void:
	twigs = 10
	gears = 4
	seeds = 8
	bag_capacity = 30
	pip_hp = 100.0
	pip_max_hp = 100.0
	pip_xp = 0
	pip_level = 1
	pip_damage_bonus = 0.0
	flower_hp = 120.0
	flower_max_hp = 120.0
	current_wave = 0
	enemies_alive = 0
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_DURATION
	countdown_active = true
	emit_all_stats()
	var tree = get_tree()
	if tree:
		tree.reload_current_scene()
