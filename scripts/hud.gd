extends CanvasLayer
class_name GameHUD

# Top Left - Flower & Wave
@onready var flower_hp_bar: ProgressBar = $Margin/TopLeft/Panel/VBox/FlowerHBox/FlowerBar
@onready var flower_hp_label: Label = $Margin/TopLeft/Panel/VBox/FlowerHBox/FlowerHPLabel
@onready var wave_label: Label = $Margin/TopLeft/Panel/VBox/WaveHBox/WaveLabel
@onready var countdown_label: Label = $Margin/TopLeft/Panel/VBox/WaveHBox/CountdownLabel
@onready var countdown_bar: ProgressBar = $Margin/TopLeft/Panel/VBox/CountdownBar
@onready var skip_wait_button: Button = $Margin/TopLeft/Panel/VBox/WaveHBox/SkipButton

# Top Right - Minimap & Pause
@onready var pause_button: Button = $Margin/TopRight/HBox/PauseButton
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

# Bottom Right - Inventory
@onready var twigs_label: Label = $Margin/BottomRight/Panel/HBox/TwigsHBox/TwigsLabel
@onready var gears_label: Label = $Margin/BottomRight/Panel/HBox/GearsHBox/GearsLabel
@onready var seeds_label: Label = $Margin/BottomRight/Panel/HBox/SeedsHBox/SeedsLabel
@onready var bag_cap_label: Label = $Margin/BottomRight/Panel/HBox/CapLabel

# Banner & Overlays
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
	pause_button.pressed.connect(_on_pause_pressed)
	
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
	
	# Initial render
	GameManager.emit_all_stats()

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0:
			banner_label.visible = false

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

func _on_wave_state_changed(state: String, wave_number: int) -> void:
	match state:
		"PREPARATION":
			wave_label.text = "Onda %d / %d" % [wave_number + 1, GameManager.max_waves]
			countdown_bar.visible = true
			countdown_label.visible = true
			skip_wait_button.visible = true
		"WAVE_ACTIVE":
			wave_label.text = "⚔️ Onda %d / %d" % [wave_number, GameManager.max_waves]
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false
		"VICTORY":
			victory_panel.visible = true
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false
		"DEFEAT":
			game_over_panel.visible = true
			countdown_bar.visible = false
			countdown_label.visible = false
			skip_wait_button.visible = false

func _on_countdown_updated(time_left: float) -> void:
	if countdown_label and countdown_bar.visible:
		countdown_label.text = "%02.0fs" % ceil(time_left)
		countdown_bar.max_value = GameManager.COUNTDOWN_DURATION
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
	var paused = get_tree().paused
	get_tree().paused = not paused
	pause_button.text = "▶" if not paused else "⏸"

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
