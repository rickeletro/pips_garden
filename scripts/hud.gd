extends CanvasLayer
class_name GameHUD

# ==============================================================================
# 🎮 GAME HUD — MODULAR & EVENT-DRIVEN (JARDIM MIÚDO)
# ==============================================================================

# Top Left - Flower & Wave
@onready var flower_hp_bar: ProgressBar = $Margin/TopLeft/Panel/VBox/FlowerHBox/FlowerBar
@onready var flower_hp_label: Label = $Margin/TopLeft/Panel/VBox/FlowerHBox/FlowerHPLabel
@onready var wave_label: Label = $Margin/TopLeft/Panel/VBox/WaveHBox/WaveLabel
@onready var countdown_label: Label = $Margin/TopLeft/Panel/VBox/WaveHBox/CountdownLabel
@onready var countdown_bar: ProgressBar = $Margin/TopLeft/Panel/VBox/CountdownBar
@onready var skip_wait_button: Button = $Margin/TopLeft/Panel/VBox/WaveHBox/SkipButton

# Top Right - Minimap & Zoom Controls
@onready var pause_button: Button = $Margin/TopRight/HBox/RightButtons/PauseButton
@onready var zoom_in_button: Button = $Margin/TopRight/HBox/RightButtons/ZoomInButton
@onready var zoom_out_button: Button = $Margin/TopRight/HBox/RightButtons/ZoomOutButton
@onready var minimap_panel: Panel = $Margin/TopRight/HBox/MinimapPanel

# Bottom Left - Pip
@onready var pip_hp_bar: ProgressBar = $Margin/BottomLeft/Panel/VBox/HPHBox/HPBar
@onready var pip_hp_label: Label = $Margin/BottomLeft/Panel/VBox/HPHBox/HPLabel
@onready var pip_xp_bar: ProgressBar = $Margin/BottomLeft/Panel/VBox/XPBar
@onready var pip_level_label: Label = $Margin/BottomLeft/Panel/VBox/NameHBox/LevelLabel

# Bottom Center - Action Hotbar Slots
@onready var slot_grass: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotGrass
@onready var slot_tower: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotTower
@onready var slot_attack: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotAttack
@onready var slot_poison: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotPoison
@onready var slot_dash: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotDash
@onready var slot_repair: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotRepair
@onready var slot_water: ActionSlot = $Margin/BottomCenter/HotbarPanel/HBox/SlotWater

# Bottom Right - Inventory
@onready var twigs_label: Label = $Margin/BottomRight/Panel/HBox/TwigsHBox/TwigsLabel
@onready var gears_label: Label = $Margin/BottomRight/Panel/HBox/GearsHBox/GearsLabel
@onready var seeds_label: Label = $Margin/BottomRight/Panel/HBox/SeedsHBox/SeedsLabel
@onready var bag_cap_label: Label = $Margin/BottomRight/Panel/HBox/CapLabel

# Banner & Overlays
@onready var margin_container: MarginContainer = $Margin
@onready var banner_label: Label = $BannerContainer/BannerLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel
@onready var intro_panel: Control = $IntroPanel
@onready var intro_title: Label = $IntroPanel/CenterBox/Title
@onready var enter_btn: Button = $IntroPanel/CenterBox/EnterButton

const TopPeriodBadgeClass = preload("res://scripts/ui/top_period_badge.gd")
const BossHUDBarClass = preload("res://scripts/ui/boss_hud_bar.gd")
const TowerSpecDialogClass = preload("res://scripts/ui/tower_spec_dialog.gd")
const CreditsSequenceClass = preload("res://scripts/ui/credits_sequence.gd")

var banner_timer: float = 0.0
var tutorial_manager: Node = null
var flower_hydration_bar: ProgressBar = null
var flower_hydration_label: Label = null
var dew_flask_label: Label = null

# Submódulos desacoplados
var top_period_badge: Node = null
var boss_hud_bar: Node = null
var spec_dialog: Node = null
var credits_sequence: Node = null

# Propriedades de compatibilidade
var spec_modal: Control:
	get: return spec_dialog as Control

var ending_sequence_active: bool:
	get: return credits_sequence.ending_sequence_active if credits_sequence else false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.visible = false
	victory_panel.visible = false
	banner_label.visible = false
	
	if GameManager.is_in_intro:
		margin_container.visible = false
		intro_panel.visible = true
	else:
		margin_container.visible = true
		intro_panel.visible = false
	
	_connect_game_events()
	_setup_tutorial_manager()
	_setup_dew_and_hydration_ui()
	_setup_submodules()
	_setup_intro_credits_button()
	
	skip_wait_button.pressed.connect(_on_skip_wait_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	
	if zoom_in_button:
		zoom_in_button.pressed.connect(func():
			var cam = get_viewport().get_camera_3d()
			if cam and cam.has_method("zoom_in"):
				cam.zoom_in()
		)
	if zoom_out_button:
		zoom_out_button.pressed.connect(func():
			var cam = get_viewport().get_camera_3d()
			if cam and cam.has_method("zoom_out"):
				cam.zoom_out()
		)
	
	# Connect Action Slots
	slot_grass.slot_activated.connect(func(): GameManager.request_plant_grass.emit())
	slot_tower.slot_activated.connect(func(): GameManager.request_build_tower.emit())
	slot_attack.slot_activated.connect(func(): GameManager.request_attack.emit())
	slot_poison.slot_activated.connect(_on_cycle_poison_clicked)
	slot_dash.slot_activated.connect(func():
		GameManager.request_dash.emit()
		slot_dash.trigger_cooldown(0.65)
	)
	slot_repair.slot_activated.connect(func(): GameManager.request_repair.emit())
	if slot_water:
		slot_water.slot_activated.connect(func(): GameManager.request_water.emit())
	
	# Initial render
	GameManager.emit_all_stats()

func _connect_game_events() -> void:
	GameManager.resources_changed.connect(_on_resources_changed)
	GameManager.pip_stats_changed.connect(_on_pip_stats_changed)
	GameManager.flower_stats_changed.connect(_on_flower_stats_changed)
	GameManager.dew_flask_changed.connect(_on_dew_flask_changed)
	GameManager.flower_hydration_changed.connect(_on_flower_hydration_changed)
	GameManager.wave_state_changed.connect(_on_wave_state_changed)
	GameManager.wave_countdown_updated.connect(_on_countdown_updated)
	GameManager.notification_requested.connect(show_notification)
	
	if GameEvents:
		GameEvents.notification_broadcast.connect(show_notification)

func _setup_submodules() -> void:
	# 1. Top Period Badge
	top_period_badge = TopPeriodBadgeClass.new()
	add_child(top_period_badge)
	
	# 2. Boss Health Bar
	boss_hud_bar = BossHUDBarClass.new()
	add_child(boss_hud_bar)
	
	# 3. Tower Specialization Dialog
	spec_dialog = TowerSpecDialogClass.new()
	add_child(spec_dialog)
	
	# 4. Credits & Ending Sequence
	credits_sequence = CreditsSequenceClass.new()
	add_child(credits_sequence)

func _select_specialization(spec: GardenTower.Specialization) -> void:
	if spec_dialog and spec_dialog.has_method("_select_specialization"):
		spec_dialog._select_specialization(spec)

func open_credits() -> void:
	if credits_sequence and credits_sequence.has_method("open_credits"):
		credits_sequence.open_credits()

func close_credits() -> void:
	if credits_sequence and credits_sequence.has_method("close_credits"):
		credits_sequence.close_credits()

func start_cinematic_credits_sequence() -> void:
	if credits_sequence and credits_sequence.has_method("start_cinematic_credits_sequence"):
		credits_sequence.start_cinematic_credits_sequence(margin_container)

func _process(delta: float) -> void:
	if credits_sequence and credits_sequence.ending_sequence_active:
		if banner_label: banner_label.visible = false
		banner_timer = 0.0
	elif banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0:
			banner_label.visible = false
			
	if intro_panel and intro_panel.visible:
		var t = Time.get_ticks_msec() * 0.003
		if enter_btn:
			enter_btn.pivot_offset = enter_btn.size * 0.5
			enter_btn.scale = Vector2.ONE * (1.0 + sin(t * 1.8) * 0.035)
		if intro_title:
			intro_title.pivot_offset = intro_title.size * 0.5
			intro_title.scale = Vector2.ONE * (1.0 + cos(t * 1.2) * 0.015)

func _on_resources_changed(twigs: int, gears: int, seeds: int, capacity: int) -> void:
	twigs_label.text = "%d" % twigs
	gears_label.text = "%d" % gears
	seeds_label.text = "%d" % seeds
	bag_cap_label.text = "🎒 %d/%d" % [twigs + gears + seeds, capacity]
	
	# Update Slot states (insufficient resources check)
	slot_grass.set_insufficient(seeds < 1)
	slot_tower.set_insufficient(twigs < 3 or gears < 2)
	slot_repair.set_insufficient(twigs < 2)

func _on_pip_stats_changed(hp: float, max_hp: float, xp: int, level: int) -> void:
	pip_hp_bar.max_value = max_hp
	pip_hp_bar.value = hp
	pip_hp_label.text = "%d / %d" % [int(hp), int(max_hp)]
	
	var needed_xp = level * 50
	pip_xp_bar.max_value = needed_xp
	pip_xp_bar.value = xp
	pip_level_label.text = "Nível %d (XP: %d/%d)" % [level, xp, needed_xp]

func _on_flower_stats_changed(hp: float, max_hp: float) -> void:
	flower_hp_bar.max_value = max_hp
	flower_hp_bar.value = hp
	flower_hp_label.text = "%d / %d" % [int(hp), int(max_hp)]

func _setup_tutorial_manager() -> void:
	if tutorial_manager == null:
		var tut_scn = load("res://scripts/tutorial_manager.gd")
		if tut_scn:
			tutorial_manager = tut_scn.new()
			add_child(tutorial_manager)

func _setup_dew_and_hydration_ui() -> void:
	# 1. Barra de Hidratação da Flor (Top Left)
	var flower_vbox = $Margin/TopLeft/Panel/VBox
	if flower_vbox and flower_hydration_bar == null:
		var hyd_hbox = HBoxContainer.new()
		hyd_hbox.name = "HydrationHBox"
		hyd_hbox.add_theme_constant_override("separation", 6)
		
		var icon_lbl = Label.new()
		icon_lbl.text = "💧"
		icon_lbl.add_theme_font_size_override("font_size", 13)
		hyd_hbox.add_child(icon_lbl)
		
		flower_hydration_bar = ProgressBar.new()
		flower_hydration_bar.name = "FlowerHydrationBar"
		flower_hydration_bar.custom_minimum_size = Vector2(90, 8)
		flower_hydration_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flower_hydration_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flower_hydration_bar.show_percentage = false
		
		var sb_fill = StyleBoxFlat.new()
		sb_fill.bg_color = Color(0.35, 0.72, 1.0, 0.9)
		sb_fill.set_corner_radius_all(4)
		flower_hydration_bar.add_theme_stylebox_override("fill", sb_fill)
		hyd_hbox.add_child(flower_hydration_bar)
		
		flower_hydration_label = Label.new()
		flower_hydration_label.text = "100%"
		flower_hydration_label.add_theme_font_size_override("font_size", 11)
		flower_hydration_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		hyd_hbox.add_child(flower_hydration_label)
		
		flower_vbox.add_child(hyd_hbox)
		flower_vbox.move_child(hyd_hbox, 1)

	# 2. Frasco de Orvalho no Painel de Recursos (Bottom Right)
	var res_hbox = $Margin/BottomRight/Panel/HBox
	if res_hbox and dew_flask_label == null:
		var flask_box = HBoxContainer.new()
		flask_box.name = "DewFlaskHBox"
		flask_box.add_theme_constant_override("separation", 4)
		
		var flask_icon = Label.new()
		flask_icon.text = "💧"
		flask_icon.add_theme_font_size_override("font_size", 14)
		flask_box.add_child(flask_icon)
		
		dew_flask_label = Label.new()
		dew_flask_label.text = "0/3"
		dew_flask_label.add_theme_font_size_override("font_size", 14)
		dew_flask_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		flask_box.add_child(dew_flask_label)
		
		res_hbox.add_child(flask_box)

func _on_dew_flask_changed(charges: int, max_charges: int) -> void:
	if dew_flask_label:
		dew_flask_label.text = "%d/%d" % [charges, max_charges]
	if slot_water:
		slot_water.set_insufficient(charges <= 0)

func _on_flower_hydration_changed(hydration: float, max_hydration: float) -> void:
	if flower_hydration_bar:
		flower_hydration_bar.max_value = max_hydration
		flower_hydration_bar.value = hydration
	if flower_hydration_label and max_hydration > 0:
		flower_hydration_label.text = "%d%%" % int(round((hydration / max_hydration) * 100.0))

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	if top_period_badge:
		top_period_badge.update_badge()
	var period = GameManager.current_period
	match state:
		"PREPARATION":
			if period == "BOSS_PREP":
				wave_label.text = "🌅 Amanhecer - Chefe em breve!"
			elif period == "NIGHT":
				if wave_number == 0:
					wave_label.text = "🌙 Noite %d - Preparação" % GameManager.current_night
				else:
					wave_label.text = "🌙 Noite %d (Onda %d/%d)" % [GameManager.current_night, wave_number + 1, GameManager.max_waves]
			else:
				wave_label.text = "☀️ Onda %d / %d" % [wave_number + 1, GameManager.max_waves]
			countdown_bar.visible = true
			countdown_label.visible = true
			skip_wait_button.visible = true
		"WAVE_ACTIVE":
			if period.begins_with("BOSS"):
				wave_label.text = "👑 BATALHA DE CHEFE"
			elif period == "NIGHT":
				wave_label.text = "⚔️ Noite %d (Onda %d/%d)" % [GameManager.current_night, wave_number, GameManager.max_waves]
			else:
				wave_label.text = "⚔️ Onda %d / %d" % [wave_number, GameManager.max_waves]
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false
		"VICTORY":
			if credits_sequence:
				credits_sequence.start_cinematic_credits_sequence(margin_container)
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false
		"DEFEAT":
			game_over_panel.visible = true
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false
			
			var restart_btn = game_over_panel.get_node_or_null("VBox/RestartBtn") as Button
			var desc_lbl = game_over_panel.get_node_or_null("VBox/Desc") as Label
			if GameManager.has_night_2_checkpoint:
				if restart_btn:
					restart_btn.text = "Inicie na Noite 2 🌙"
				if desc_lbl:
					desc_lbl.text = "A flor foi destruída pelas pragas!\nVocê pode continuar sua jornada a partir do Checkpoint da Noite 2."
			else:
				if restart_btn:
					restart_btn.text = "Tentar Novamente"
				if desc_lbl:
					desc_lbl.text = "A flor foi destruída pelas pragas!"

func _on_countdown_updated(time_left: float) -> void:
	if countdown_label and countdown_bar.visible:
		var total_sec = int(ceil(time_left))
		var mins = total_sec / 60
		var secs = total_sec % 60
		if mins > 0:
			countdown_label.text = "%02d:%02d" % [mins, secs]
		else:
			countdown_label.text = "%02ds" % secs
			
		var max_dur = GameManager.COUNTDOWN_DURATION
		if GameManager.current_period == "BOSS_PREP":
			max_dur = GameManager.COUNTDOWN_BOSS_PREP
		elif GameManager.current_period == "NIGHT" and GameManager.current_wave == 0:
			max_dur = GameManager.COUNTDOWN_NIGHT_PREP
			
		countdown_bar.max_value = max_dur
		countdown_bar.value = time_left

func _on_skip_wait_pressed() -> void:
	GameManager.start_next_wave()

func _on_cycle_poison_clicked() -> void:
	GameManager.active_poison_mode = (GameManager.active_poison_mode + 1) % 3
	update_poison_slot_visual()
	GameManager.request_cycle_poison.emit()

func update_poison_slot_visual() -> void:
	match GameManager.active_poison_mode:
		0:
			slot_poison.update_poison_badge("Lento", Tokens.VENENO_AMBAR)
		1:
			slot_poison.update_poison_badge("Ácido", Tokens.VENENO_VERDE)
		2:
			slot_poison.update_poison_badge("Névoa", Tokens.VENENO_VIOLETA)

func _on_pause_pressed() -> void:
	var was_paused = get_tree().paused
	get_tree().paused = not was_paused
	pause_button.text = "⏸" if was_paused else "▶"
	if not was_paused:
		show_notification("Jogo Pausado ⏸", Tokens.DOURADO_LUZ)
	else:
		show_notification("Jogo Retomado ▶", Tokens.VERDE_FOLHA)

func show_notification(text: String, color: Color = Tokens.DOURADO_LUZ) -> void:
	banner_label.text = text
	banner_label.modulate = color
	banner_label.visible = true
	banner_timer = 3.0
	
	banner_label.scale = Vector2(1.15, 1.15)
	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		tween.tween_property(banner_label, "scale", Vector2.ONE, 0.2)

func _on_enter_pressed() -> void:
	SoundManager.play_sparkle(-2.0)
		
	var tree = get_tree()
	if tree and intro_panel:
		var tween = tree.create_tween()
		tween.tween_property(intro_panel, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			intro_panel.visible = false
			margin_container.visible = true
			margin_container.modulate.a = 0.0
			var t2 = tree.create_tween()
			t2.tween_property(margin_container, "modulate:a", 1.0, 0.4)
			GameManager.start_game_from_intro()
		)
	else:
		if intro_panel: intro_panel.visible = false
		margin_container.visible = true
		GameManager.start_game_from_intro()

func _on_restart_pressed() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if GameManager.has_night_2_checkpoint:
		GameManager.load_night_2_checkpoint()
	else:
		GameManager.reset_game()

func _setup_intro_credits_button() -> void:
	if not intro_panel:
		return
	var center_box = intro_panel.get_node_or_null("CenterBox")
	if center_box:
		var credits_intro_btn = Button.new()
		credits_intro_btn.text = "📜 Créditos"
		credits_intro_btn.custom_minimum_size = Vector2(180, 40)
		credits_intro_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.42, 0.22, 0.85)
		sb.border_color = Tokens.DOURADO_LUZ
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(20)
		credits_intro_btn.add_theme_stylebox_override("normal", sb)
		credits_intro_btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
		credits_intro_btn.add_theme_font_size_override("font_size", 18)
		credits_intro_btn.pressed.connect(func():
			if credits_sequence:
				credits_sequence.open_credits()
		)
		center_box.add_child(credits_intro_btn)

func _unhandled_input(event: InputEvent) -> void:
	if credits_sequence and credits_sequence.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if spec_dialog and spec_dialog.handle_input(event):
		get_viewport().set_input_as_handled()
		return
