extends Node

# GameManager (Singleton) - Jardim Miúdo
# Gerencia Recursos, Status de Pip e da Flor, Ondas, Ciclo Dia/Noite, Boss e Notificações

signal resources_changed(twigs: int, gears: int, seeds: int, capacity: int)
signal pip_stats_changed(hp: float, max_hp: float, xp: int, level: int)
signal flower_stats_changed(hp: float, max_hp: float)
signal dew_flask_changed(charges: int, max_charges: int)
signal flower_hydration_changed(hydration: float, max_hydration: float)
signal trigger_tutorial_post_wave_1
signal wave_state_changed(state: String, wave_number: int)
signal wave_countdown_updated(time_left: float)
signal notification_requested(text: String, color: Color)
signal enemy_died(enemy: Node3D)

# Sinais de Barra de Vida do Chefe
signal boss_appeared(boss_node: Node3D, boss_name: String, max_hp: float)
signal boss_health_updated(current_hp: float, max_hp: float, boss_name: String)
signal boss_vanished

# Sinais de Hotbar Slots
signal request_plant_grass
signal request_build_tower
signal request_attack
signal request_dash
signal request_cycle_poison
signal request_repair
signal request_water
signal request_water_target
signal request_tower_specialization_dialog(tower: Node3D)

enum WaveState { PREPARATION, WAVE_ACTIVE, VICTORY, DEFEAT }

# Referências Globais
var grid_manager: Node3D = null
var flower: Node3D = null
var heroine: CharacterBody3D = null
var hud: Node = null
var camera: GardenCameraController = null

# Inventário & Colecionáveis
var twigs: int = 10
var gears: int = 4
var seeds: int = 6
var fairy_tears: int = 0
var silver_pollens: int = 0
var magnet_ambers: int = 0
var revitalizing_nectars: int = 0
var royal_jellies: int = 0
var bag_capacity: int = 40
var last_bag_full_notify_time: float = 0.0

# Frasco de Orvalho da Pip (Capacidade: 3 Gotas)
var dew_flask_charges: int = 0
const MAX_DEW_CHARGES: int = 3

# Power-ups Permanentes
var has_magnet_upgrade: bool = false
var magnet_radius: float = 2.2 # 2.2m padrão, 6.0m com Âmbar Magnético

# Pip Stats
var pip_hp: float = 100.0
var pip_max_hp: float = 100.0
var pip_xp: int = 0
var pip_level: int = 1
var pip_damage_bonus: float = 0.0

# Flor Stats & Hidratação
var flower_hp: float = 200.0
var flower_max_hp: float = 200.0
var flower_hydration: float = 100.0
const MAX_FLOWER_HYDRATION: float = 100.0
var flower_dehydration_timer: float = 0.0

signal game_started

# Ciclo Dia / Noite & Ondas & Bosses
var is_in_intro: bool = true
var is_in_cutscene: bool = false

var current_period: String = "DAY" # "DAY", "NIGHT", "BOSS_SNAIL", "BOSS_MOTH", "BOSS_MANTIS", "BOSS_SPIDER", "BOSS_WASP_QUEEN", "BOSS_SCORPION"
var current_day: int = 1
var current_night: int = 1
var current_wave: int = 0
var max_waves: int = 7
var wave_state: WaveState = WaveState.PREPARATION
var enemies_alive: int = 0

const COUNTDOWN_DURATION: float = 30.0 # 30 segundos para explorar e preparar defesas entre ondas
const COUNTDOWN_PERIOD_PREP: float = 60.0 # 1 minuto para preparar defesas na transição de período
const COUNTDOWN_NIGHT_PREP: float = 60.0 # Compatibilidade
const COUNTDOWN_BOSS_PREP: float = 60.0  # Compatibilidade
var wave_countdown: float = COUNTDOWN_DURATION
var countdown_active: bool = false # Fica pausado na tela de introdução

# Modo de Veneno selecionado (0: Lento, 1: Ácido, 2: Névoa)
var active_poison_mode: int = 0

func _ready() -> void:
	emit_all_stats()

func set_player_control_enabled(enabled: bool) -> void:
	if heroine and is_instance_valid(heroine) and heroine.has_method("set_control_enabled"):
		heroine.set_control_enabled(enabled)

func start_game_from_intro(with_zoom_sequence: bool = false) -> void:
	is_in_intro = false
	SoundManager.play_day_music(2.2, -6.0)
	
	var cam: GardenCameraController = camera
	if not cam:
		var tree = get_tree()
		if tree:
			var vp_cam = tree.root.get_viewport().get_camera_3d()
			if vp_cam is GardenCameraController:
				cam = vp_cam
			else:
				cam = tree.get_first_node_in_group("camera") as GardenCameraController
				
	if with_zoom_sequence and cam and cam.has_method("zoom_to_gameplay"):
		set_player_control_enabled(false)
		countdown_active = false
		cam.zoom_to_gameplay(2.4, func():
			countdown_active = true
			set_player_control_enabled(true)
			game_started.emit()
			if hud and "tutorial_manager" in hud and hud.tutorial_manager:
				hud.tutorial_manager.start_tutorial()
			else:
				notify("🌸 Bem-vindo ao Jardim da Pip! Plante grama e prepare suas defesas!", Color(1.0, 0.92, 0.6))
		)
	else:
		countdown_active = true
		set_player_control_enabled(true)
		if cam and cam.has_method("zoom_to_gameplay"):
			cam.zoom_to_gameplay(0.1)
		game_started.emit()
		notify("🌸 Bem-vindo ao Jardim da Pip! Plante grama e prepare suas defesas!", Color(1.0, 0.92, 0.6))

func _process(delta: float) -> void:
	if is_in_intro:
		return
		
	if wave_state == WaveState.PREPARATION and countdown_active:
		wave_countdown -= delta
		wave_countdown_updated.emit(max(0.0, wave_countdown))
		if wave_countdown <= 0.0:
			start_next_wave()
	elif wave_state == WaveState.WAVE_ACTIVE:
		check_wave_cleared_status()
		
	# Sede da Flor Central (Consumo contínuo de hidratação)
	if wave_state != WaveState.DEFEAT and wave_state != WaveState.VICTORY:
		var prev_hydration_pct := int(flower_hydration)
		flower_hydration = maxf(0.0, flower_hydration - delta * 0.45)
		if int(flower_hydration) != prev_hydration_pct:
			flower_hydration_changed.emit(flower_hydration, MAX_FLOWER_HYDRATION)
		if flower_hydration <= 0.0:
			flower_dehydration_timer += delta
			if flower_dehydration_timer >= 3.0:
				flower_dehydration_timer = 0.0
				damage_flower(1.0)
				notify("⚠️ A Flor Central está ressecada e sofrendo dano! Regue-a com orvalho!", Tokens.PERIGO)
		else:
			flower_dehydration_timer = 0.0

var active_boss: Node3D = null
var active_boss_name: String = ""
var active_boss_max_hp: float = 100.0

func register_active_boss(boss_node: Node3D, boss_name: String, max_hp: float) -> void:
	active_boss = boss_node
	active_boss_name = boss_name
	active_boss_max_hp = max_hp
	boss_appeared.emit(boss_node, boss_name, max_hp)
	boss_health_updated.emit(max_hp, max_hp, boss_name)

func update_active_boss_hp(current_hp: float, max_hp: float, boss_name: String = "") -> void:
	var b_name = boss_name if boss_name != "" else active_boss_name
	boss_health_updated.emit(max(0.0, current_hp), max_hp, b_name)

func unregister_active_boss(boss_node: Node3D = null) -> void:
	if boss_node == null or boss_node == active_boss:
		active_boss = null
		active_boss_name = ""
		boss_vanished.emit()

func is_boss_active() -> bool:
	return current_period.begins_with("BOSS") or active_boss != null

func check_wave_cleared_status() -> void:
	if wave_state != WaveState.WAVE_ACTIVE:
		return
	if is_boss_active():
		return
		
	var tree = get_tree()
	if not tree:
		return
		
	var spawner = tree.get_first_node_in_group("spawner_manager")
	if spawner and spawner.has_method("is_spawning_active") and spawner.is_spawning_active():
		return
		
	var actual_enemies = tree.get_nodes_in_group("enemies")
	var count = 0
	for en in actual_enemies:
		if is_instance_valid(en) and not en.is_queued_for_deletion():
			count += 1
			
	enemies_alive = count
	if enemies_alive == 0:
		on_wave_cleared()

func emit_all_stats() -> void:
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	flower_stats_changed.emit(flower_hp, flower_max_hp)
	dew_flask_changed.emit(dew_flask_charges, MAX_DEW_CHARGES)
	flower_hydration_changed.emit(flower_hydration, MAX_FLOWER_HYDRATION)
	wave_state_changed.emit(get_wave_state_string(), current_wave)
	wave_countdown_updated.emit(wave_countdown)

func get_total_inventory_items() -> int:
	return twigs + gears + seeds

func can_add_item() -> bool:
	return get_total_inventory_items() < bag_capacity

func add_dew_flask_charge(amount: int = 1) -> bool:
	if dew_flask_charges >= MAX_DEW_CHARGES:
		notify("Frasco de orvalho cheio! (3/3)", Tokens.DOURADO_LUZ)
		return false
	dew_flask_charges = mini(MAX_DEW_CHARGES, dew_flask_charges + amount)
	dew_flask_changed.emit(dew_flask_charges, MAX_DEW_CHARGES)
	SoundManager.play_fairy_dust(-1.0)
	notify("💧 +%d Gota de Orvalho armazenada no frasco! (%d/%d)" % [amount, dew_flask_charges, MAX_DEW_CHARGES], Tokens.DOURADO_LUZ)
	return true

func consume_dew_flask_charge() -> bool:
	if dew_flask_charges <= 0:
		notify("Frasco de orvalho vazio! Colete gotas sobre folhas ou dentes-de-leão.", Tokens.PERIGO)
		return false
	dew_flask_charges -= 1
	dew_flask_changed.emit(dew_flask_charges, MAX_DEW_CHARGES)
	return true

func water_flower() -> bool:
	if dew_flask_charges <= 0:
		notify("Frasco de orvalho vazio! Colete gotas de orvalho para regar a flor.", Tokens.PERIGO)
		return false
	if consume_dew_flask_charge():
		flower_hydration = minf(MAX_FLOWER_HYDRATION, flower_hydration + 50.0)
		heal_flower(5.0)
		flower_hydration_changed.emit(flower_hydration, MAX_FLOWER_HYDRATION)
		SoundManager.play_fairy_dust(0.0)
		notify("🌸 Flor Central regada! +50% Hidratação e +5 HP!", Tokens.VERDE_FOLHA)
		return true
	return false

func add_twig(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		var now = Time.get_ticks_msec() * 0.001
		if now - last_bag_full_notify_time > 2.5:
			last_bag_full_notify_time = now
			notify("🎒 Mochila cheia! Construa torres ou plante grama para liberar espaço.", Color(1.0, 0.4, 0.4))
		return false
	twigs += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func add_gear(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		var now = Time.get_ticks_msec() * 0.001
		if now - last_bag_full_notify_time > 2.5:
			last_bag_full_notify_time = now
			notify("🎒 Mochila cheia! Construa torres ou plante grama para liberar espaço.", Color(1.0, 0.4, 0.4))
		return false
	gears += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func add_seed(amount: int = 1) -> bool:
	if get_total_inventory_items() + amount > bag_capacity:
		var now = Time.get_ticks_msec() * 0.001
		if now - last_bag_full_notify_time > 2.5:
			last_bag_full_notify_time = now
			notify("🎒 Mochila cheia! Construa torres ou plante grama para liberar espaço.", Color(1.0, 0.4, 0.4))
		return false
	seeds += amount
	resources_changed.emit(twigs, gears, seeds, bag_capacity)
	return true

func add_fairy_tear() -> bool:
	fairy_tears += 1
	if flower and is_instance_valid(flower) and flower.has_method("apply_fairy_tear"):
		flower.apply_fairy_tear()
	else:
		heal_flower(flower_max_hp * 0.60)
		flower_max_hp = 220.0
		flower_stats_changed.emit(flower_hp, flower_max_hp)
		notify("🌸 Lágrima de Fada absorvida pela Flor! +60% de Vida e Max HP expandido para 220!", Color(0.4, 1.0, 0.7))
	return true

func add_silver_pollen() -> bool:
	silver_pollens += 1
	heal_flower(50.0)
	add_gear(6)
	add_twig(10)
	notify("✨ Pólen Prateado coletado! Flor +50 HP e bônus de 6 engrenagens e 10 gravetos!", Color(0.8, 0.9, 1.0))
	return true

func add_magnet_amber() -> bool:
	magnet_ambers += 1
	has_magnet_upgrade = true
	magnet_radius = 6.0
	notify("🧲 Âmbar Magnético coletado! Campo de atração de itens expandido para 6.0 metros!", Color(1.0, 0.75, 0.2))
	return true

func add_revitalizing_nectar() -> bool:
	revitalizing_nectars += 1
	heal_flower(80.0)
	notify("🍯 Néctar Revigorante coletado! +80 HP para a Flor Central!", Color(0.4, 1.0, 0.6))
	return true

func add_royal_jelly() -> bool:
	royal_jellies += 1
	heal_flower(40.0)
	repair_all_towers()
	notify("👑 Geleia Real coletada! Flor +40 HP e todas as torres do jardim foram reparadas!", Color(1.0, 0.85, 0.3))
	return true

func repair_all_towers() -> void:
	var tree = get_tree()
	if not tree:
		return
	var towers = tree.get_nodes_in_group("towers")
	for t in towers:
		if is_instance_valid(t) and t.has_method("repair"):
			t.repair(true)

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
	var needed = pip_level * 100
	if pip_xp >= needed:
		pip_xp -= needed
		pip_level += 1
		pip_damage_bonus += 5.0
		pip_max_hp += 15.0
		pip_hp = min(pip_max_hp, pip_hp + 15.0)
		bag_capacity += 5
		notify("Pip subiu para o Nível %d! (+15 Max HP, +5 Dano, +5 Bolsa)" % pip_level, Tokens.DOURADO_LUZ)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	resources_changed.emit(twigs, gears, seeds, bag_capacity)

func damage_pip(amount: float) -> void:
	if wave_state == WaveState.DEFEAT:
		return
	pip_hp = max(0.0, pip_hp - amount)
	pip_stats_changed.emit(pip_hp, pip_max_hp, pip_xp, pip_level)
	if pip_hp <= 0.0:
		notify("Pip foi atordoada em combate! Recuperando-se junto à Flor...", Tokens.PERIGO)
		if heroine and is_instance_valid(heroine) and heroine.has_method("trigger_knockout"):
			heroine.trigger_knockout()
		else:
			pip_hp = pip_max_hp * 0.35
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
	
	if current_period == "NIGHT":
		notify("🌙 Noite %d - Onda %d iniciada! Defenda a flor!" % [current_night, current_wave], Color(0.7, 0.9, 1.0))
	else:
		notify("☀️ Dia %d - Onda %d iniciada! Defenda a flor!" % [current_day, current_wave], Color(1.0, 0.7, 0.2))
	return true

func register_enemy_spawned() -> void:
	enemies_alive += 1

func register_enemy_killed(enemy: Node3D) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	enemy_died.emit(enemy)
	check_wave_cleared_status()

func on_wave_cleared() -> void:
	# Padrão Rítmico v1.0:
	# Ao vencer a Onda 3 de qualquer período -> Entrada Imediata do Chefe correspondente
	if current_wave == 3:
		trigger_period_boss()
		return
		
	if current_wave >= max_waves:
		# Fim do ciclo de 7 ondas (ou 3 ondas na Noite 3)
		advance_campaign_period()
	else:
		setup_next_prep_wave()
		if current_period == "DAY" and current_day == 1 and current_wave == 1:
			trigger_tutorial_post_wave_1.emit()

func trigger_period_boss() -> void:
	if current_period == "DAY":
		match current_day:
			1: start_boss_snail()
			2: start_boss_mantis()
			3: start_boss_wasp_queen()
	elif current_period == "NIGHT":
		match current_night:
			1: start_boss_moth()
			2: start_boss_spider()
			3: start_boss_scorpion()

func start_boss_snail() -> void:
	current_period = "BOSS_SNAIL"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("🐌 CHEFE: O Caramujo Ancião rastejou até o jardim! Cuidado com o muco!", Color(1.0, 0.4, 0.2))
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_snail"):
			spawner.spawn_boss_snail()

func start_boss_moth() -> void:
	current_period = "BOSS_MOTH"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("🦋 CHEFE: A Mariposa Rainha desceu do céu estrelado!", Color(0.9, 0.6, 1.0))
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_moth"):
			spawner.spawn_boss_moth()

func start_boss_mantis() -> void:
	current_period = "BOSS_MANTIS"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("🪲 CHEFE: Louva-a-Deus Imperial emboscou o jardim! Use Dash para desviar!", Color(0.3, 1.0, 0.5))
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_mantis"):
			spawner.spawn_boss_mantis()

func start_boss_spider() -> void:
	current_period = "BOSS_SPIDER"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("🕷️ CHEFE: Aranha-Tecelã Sombria emergiu! Cuidado com casulos e teias!", Color(0.7, 0.4, 1.0))
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_spider"):
			spawner.spawn_boss_spider()

func start_boss_wasp_queen() -> void:
	current_period = "BOSS_WASP_QUEEN"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	notify("🐝 CHEFE: Vespa Imperatriz paira sobre o jardim com seu enxame!", Color(1.0, 0.85, 0.2))
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_wasp_queen"):
			spawner.spawn_boss_wasp_queen()

func start_boss_scorpion() -> void:
	current_period = "BOSS_SCORPION"
	wave_state = WaveState.WAVE_ACTIVE
	countdown_active = false
	wave_state_changed.emit("WAVE_ACTIVE", current_wave)
	var tree = get_tree()
	if tree:
		var spawner = tree.get_first_node_in_group("spawner_manager")
		if spawner and spawner.has_method("spawn_boss_scorpion"):
			spawner.spawn_boss_scorpion()

var has_night_2_checkpoint: bool = false

func set_night_2_checkpoint() -> void:
	has_night_2_checkpoint = true
	notify("🌟 CHECKPOINT ALCANÇADO: Progresso salvo na Noite 2!", Tokens.DOURADO_LUZ)
	SoundManager.play_fairy_dust(0.0)
	if heroine and is_instance_valid(heroine) and heroine.has_method("play_checkpoint_glow"):
		heroine.play_checkpoint_glow()

func on_boss_defeated(boss_id: String = "") -> void:
	if current_period == "BOSS_SCORPION" or boss_id == "SCORPION":
		trigger_victory()
		return
		
	# Restaura o período ativo
	if current_period == "BOSS_SNAIL" or boss_id == "SNAIL" or (current_period == "BOSS" and current_day == 1):
		current_period = "DAY"
		current_day = 1
	elif current_period == "BOSS_MOTH" or boss_id == "MOTH":
		current_period = "NIGHT"
		current_night = 1
	elif current_period == "BOSS_MANTIS" or boss_id == "MANTIS":
		current_period = "DAY"
		current_day = 2
	elif current_period == "BOSS_SPIDER" or boss_id == "SPIDER" or (current_period.begins_with("BOSS") and current_night == 2):
		current_period = "NIGHT"
		current_night = 2
		set_night_2_checkpoint()
	elif current_period == "BOSS_WASP_QUEEN" or boss_id == "WASP_QUEEN":
		current_period = "DAY"
		current_day = 3
	elif current_period.begins_with("BOSS"):
		current_period = "DAY"
		
	# Restaura a música normal do período (Dia ou Noite)
	if current_period == "DAY":
		SoundManager.play_day_music(2.5, -6.0)
	elif current_period == "NIGHT":
		SoundManager.play_night_music(2.5, -5.0)
			
	# Continua para as ondas restantes (4 a 7):
	current_wave = 3 # Ao preparar, a próxima onda iniciada será a Onda 4!
	setup_next_prep_wave()

func on_moth_boss_defeated() -> void:
	on_boss_defeated("MOTH")

func advance_campaign_period() -> void:
	if current_period == "DAY":
		match current_day:
			1: transition_to_night_1()
			2: transition_to_night_2()
			3: transition_to_night_3()
	elif current_period == "NIGHT":
		match current_night:
			1: transition_to_day_2()
			2: transition_to_day_3()
			3: trigger_victory()

func setup_next_prep_wave() -> void:
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_DURATION
	countdown_active = true
	wave_state_changed.emit("PREPARATION", current_wave)
	if current_period == "NIGHT":
		notify("Onda Noturna %d vencida! Próxima em 30 segundos..." % current_wave, Color(0.6, 0.85, 1.0))
	else:
		notify("Onda %d vencida! Próxima onda em 30 segundos..." % current_wave, Color(0.4, 0.9, 0.5))

func transition_to_night_1() -> void:
	current_period = "NIGHT"
	current_night = 1
	current_wave = 0
	max_waves = 7
	
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	heal_pip(pip_max_hp)
	SoundManager.play_night_music(3.5, -5.0)
	wave_state_changed.emit("PREPARATION", current_wave)
	notify("🌙 Noite 1 — A noite cai sobre o jardim... (Pip descansou e recuperou seu HP!)", Color(0.6, 0.8, 1.0))

func transition_to_day_2() -> void:
	current_period = "DAY"
	current_day = 2
	current_wave = 0
	max_waves = 7
	
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	heal_pip(pip_max_hp)
	SoundManager.play_day_music(2.5, -5.5)
	regrow_all_dandelions()
	
	wave_state_changed.emit("PREPARATION", current_wave)
	notify("☀️ Dia 2 — O sol raia novamente! Dentes-de-leão floresceram! (HP Restaurado)", Color(1.0, 0.9, 0.4))

func transition_to_night_2() -> void:
	current_period = "NIGHT"
	current_night = 2
	current_wave = 0
	max_waves = 7
	
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	heal_pip(pip_max_hp)
	SoundManager.play_night_music(3.5, -5.0)
	wave_state_changed.emit("PREPARATION", current_wave)
	notify("🌙 Noite 2 — A Teia Silenciosa se estende pelo jardim... (HP Restaurado)", Color(0.7, 0.8, 1.0))

func transition_to_day_3() -> void:
	current_period = "DAY"
	current_day = 3
	current_wave = 0
	max_waves = 7
	
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	heal_pip(pip_max_hp)
	SoundManager.play_day_music(2.5, -5.5)
	regrow_all_dandelions()
	
	wave_state_changed.emit("PREPARATION", current_wave)
	notify("☀️ Dia 3 — O Zumbido da Tempestade ecoa no horizonte! (HP Restaurado)", Color(1.0, 0.85, 0.3))

func transition_to_night_3() -> void:
	current_period = "NIGHT"
	current_night = 3
	current_wave = 0
	max_waves = 3 # 3 ondas densas
	
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	heal_pip(pip_max_hp)
	SoundManager.play_night_music(3.5, -5.0)
	wave_state_changed.emit("PREPARATION", current_wave)
	notify("🌕 Noite 3 — A Noite Final! Uma névoa roxa rasteja... Prepare suas defesas!", Color(0.8, 0.5, 1.0))

func regrow_all_dandelions() -> void:
	var tree = get_tree()
	if tree:
		var dandelions = tree.get_nodes_in_group("dandelion")
		for dand in dandelions:
			if is_instance_valid(dand) and dand.has_method("regrow_for_new_day"):
				dand.regrow_for_new_day()

func trigger_victory() -> void:
	wave_state = WaveState.VICTORY
	countdown_active = false
	wave_state_changed.emit("VICTORY", current_wave)
	notify("🎉 VITÓRIA TOTAL! O Jardim e a Flor Mágica estão a salvo para sempre!", Color(0.3, 1.0, 0.6))

func notify(text: String, color: Color = Color.WHITE) -> void:
	notification_requested.emit(text, color)

func get_wave_state_string() -> String:
	match wave_state:
		WaveState.PREPARATION: return "PREPARATION"
		WaveState.WAVE_ACTIVE: return "WAVE_ACTIVE"
		WaveState.VICTORY: return "VICTORY"
		WaveState.DEFEAT: return "DEFEAT"
	return "PREPARATION"

func load_night_2_checkpoint() -> void:
	wave_state = WaveState.PREPARATION
	current_period = "NIGHT"
	current_night = 2
	current_wave = 0
	max_waves = 7
	wave_countdown = COUNTDOWN_PERIOD_PREP
	countdown_active = true
	
	is_in_intro = false
	is_in_cutscene = false
	set_player_control_enabled(true)
	
	# Restaura HP da Pip e da Flor Central
	pip_hp = pip_max_hp
	flower_hp = flower_max_hp
	
	# Garante recursos adequados para a Noite 2
	twigs = max(twigs, 16)
	gears = max(gears, 8)
	seeds = max(seeds, 8)
	bag_capacity = max(bag_capacity, 35)
	
	emit_all_stats()
	
	# Limpa pragas restantes na cena
	var tree = get_tree()
	if tree:
		var enemies = tree.get_nodes_in_group("enemies")
		for en in enemies:
			if is_instance_valid(en):
				en.queue_free()
		var gnomes = tree.get_nodes_in_group("gnome")
		for g in gnomes:
			if is_instance_valid(g):
				g.queue_free()
				
	# Repara todas as torres existentes
	repair_all_towers()
	
	# Reposiciona a Pip junto à Flor Central
	if heroine and is_instance_valid(heroine):
		heroine.global_position = Vector3(0.0, 0.0, 3.2)
		if heroine.has_method("play_checkpoint_glow"):
			heroine.play_checkpoint_glow()
			
	SoundManager.play_night_music(2.5, -5.0)
	notify("🌙 REINICIANDO DA NOITE 2 (CHECKPOINT)! Defenda a Flor Central!", Tokens.DOURADO_LUZ)

func reset_game() -> void:
	twigs = 10
	gears = 4
	seeds = 6
	fairy_tears = 0
	silver_pollens = 0
	magnet_ambers = 0
	revitalizing_nectars = 0
	royal_jellies = 0
	has_magnet_upgrade = false
	magnet_radius = 2.2
	bag_capacity = 40
	pip_hp = 100.0
	pip_max_hp = 100.0
	pip_xp = 0
	pip_level = 1
	pip_damage_bonus = 0.0
	flower_hp = 200.0
	flower_max_hp = 200.0
	current_period = "DAY"
	current_day = 1
	current_night = 1
	current_wave = 0
	max_waves = 7
	enemies_alive = 0
	wave_state = WaveState.PREPARATION
	wave_countdown = COUNTDOWN_DURATION
	countdown_active = true
	
	SoundManager.play_day_music(1.5, -6.0)
	if NodePool:
		NodePool.clear_all()
		
	emit_all_stats()
	var tree = get_tree()
	if tree:
		tree.reload_current_scene()

func reset_to_intro() -> void:
	is_in_intro = true
	is_in_cutscene = false
	reset_game()
	SoundManager.play_intro_music(1.5, -4.0)
