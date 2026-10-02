extends CanvasLayer
class_name GameHUD

@onready var pip_hp_bar: ProgressBar = $Margin/TopLeft/VBox/HPBar
@onready var pip_hp_label: Label = $Margin/TopLeft/VBox/HPLabel
@onready var pip_xp_bar: ProgressBar = $Margin/TopLeft/VBox/XPBar
@onready var pip_level_label: Label = $Margin/TopLeft/VBox/LevelLabel

@onready var flower_hp_bar: ProgressBar = $Margin/TopCenter/VBox/FlowerHPBar
@onready var flower_hp_label: Label = $Margin/TopCenter/VBox/FlowerLabel
@onready var wave_label: Label = $Margin/TopCenter/VBox/WaveLabel
@onready var countdown_container: HBoxContainer = $Margin/TopCenter/VBox/CountdownContainer
@onready var countdown_label: Label = $Margin/TopCenter/VBox/CountdownContainer/CountdownLabel
@onready var countdown_bar: ProgressBar = $Margin/TopCenter/VBox/CountdownContainer/CountdownBar
@onready var skip_wait_button: Button = $Margin/TopCenter/VBox/SkipWaitButton

@onready var twigs_label: Label = $Margin/TopRight/Panel/VBox/TwigsLabel
@onready var gears_label: Label = $Margin/TopRight/Panel/VBox/GearsLabel
@onready var seeds_label: Label = $Margin/TopRight/Panel/VBox/SeedsLabel
@onready var bag_cap_label: Label = $Margin/TopRight/Panel/VBox/CapacityLabel

# Hotbar Action Slots
@onready var slot_grass_btn: Button = $Margin/BottomBar/HotbarContainer/SlotGrass
@onready var slot_tower_btn: Button = $Margin/BottomBar/HotbarContainer/SlotTower
@onready var slot_attack_btn: Button = $Margin/BottomBar/HotbarContainer/SlotAttack
@onready var slot_poison_btn: Button = $Margin/BottomBar/HotbarContainer/SlotPoison
@onready var slot_dash_btn: Button = $Margin/BottomBar/HotbarContainer/SlotDash
@onready var slot_repair_btn: Button = $Margin/BottomBar/HotbarContainer/SlotRepair

@onready var banner_label: Label = $BannerContainer/BannerLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel

var banner_timer: float = 0.0

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	banner_label.visible = false
	
	GameManager.resources_changed.connect(_on_resources_changed)
	GameManager.pip_stats_changed.connect(_on_pip_stats_changed)
	GameManager.flower_stats_changed.connect(_on_flower_stats_changed)
	GameManager.wave_state_changed.connect(_on_wave_state_changed)
	GameManager.wave_countdown_updated.connect(_on_countdown_updated)
	GameManager.notification_requested.connect(show_notification)
	
	skip_wait_button.pressed.connect(_on_skip_wait_pressed)
	
	# Connect Action Slot Buttons
	slot_grass_btn.pressed.connect(func(): GameManager.request_plant_grass.emit())
	slot_tower_btn.pressed.connect(func(): GameManager.request_build_tower.emit())
	slot_attack_btn.pressed.connect(func(): GameManager.request_attack.emit())
	slot_poison_btn.pressed.connect(func(): GameManager.request_cycle_poison.emit())
	slot_dash_btn.pressed.connect(func(): GameManager.request_dash.emit())
	slot_repair_btn.pressed.connect(func(): GameManager.request_repair.emit())
	
	# Initial render
	GameManager.emit_all_stats()

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0:
			banner_label.visible = false

func _on_resources_changed(twigs: int, gears: int, seeds: int, capacity: int) -> void:
	twigs_label.text = "🌿 Gravetos: %d" % twigs
	gears_label.text = "⚙️ Engrenagens: %d" % gears
	seeds_label.text = "🌱 Sementes: %d" % seeds
	bag_cap_label.text = "Bolsa: %d / %d" % [twigs + gears + seeds, capacity]
	
	# Update Action Slot availability
	slot_grass_btn.disabled = (seeds < 1)
	slot_tower_btn.disabled = (twigs < 3 or gears < 2)
	slot_repair_btn.disabled = (twigs < 2)

func _on_pip_stats_changed(hp: float, max_hp: float, xp: int, level: int) -> void:
	pip_hp_bar.max_value = max_hp
	pip_hp_bar.value = hp
	pip_hp_label.text = "Pip HP: %d / %d" % [int(hp), int(max_hp)]
	
	var needed_xp = level * 50
	pip_xp_bar.max_value = needed_xp
	pip_xp_bar.value = xp
	pip_level_label.text = "Nível %d (XP: %d/%d)" % [level, xp, needed_xp]

func _on_flower_stats_changed(hp: float, max_hp: float) -> void:
	flower_hp_bar.max_value = max_hp
	flower_hp_bar.value = hp
	flower_hp_label.text = "🌸 Flor do Jardim: %d / %d" % [int(hp), int(max_hp)]

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	match state:
		"PREPARATION":
			wave_label.text = "Onda %d / %d - Preparação" % [wave_number + 1, GameManager.max_waves]
			countdown_container.visible = true
			skip_wait_button.visible = true
			skip_wait_button.text = "⏩ Iniciar Agora (Enter/F)"
		"WAVE_ACTIVE":
			wave_label.text = "⚔️ Onda %d / %d - EM ANDAMENTO! Defenda a flor!" % [wave_number, GameManager.max_waves]
			countdown_container.visible = false
			skip_wait_button.visible = false
		"VICTORY":
			victory_panel.visible = true
			countdown_container.visible = false
			skip_wait_button.visible = false
		"DEFEAT":
			game_over_panel.visible = true
			countdown_container.visible = false
			skip_wait_button.visible = false

func _on_countdown_updated(time_left: float) -> void:
	if countdown_label and countdown_container.visible:
		countdown_label.text = "⏳ Início automático em: %02.0fs" % ceil(time_left)
		countdown_bar.max_value = GameManager.COUNTDOWN_DURATION
		countdown_bar.value = time_left

func _on_skip_wait_pressed() -> void:
	GameManager.start_next_wave()

func show_notification(text: String, color: Color) -> void:
	banner_label.text = text
	banner_label.modulate = color
	banner_label.visible = true
	banner_timer = 3.0
	
	banner_label.scale = Vector2(1.15, 1.15)
	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		tween.tween_property(banner_label, "scale", Vector2.ONE, 0.2)

func _on_restart_pressed() -> void:
	GameManager.reset_game()
