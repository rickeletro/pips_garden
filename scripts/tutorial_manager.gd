extends CanvasLayer
class_name TutorialManager

# TutorialManager - Jardim Miúdo (Pip's Garden)
# Gerencia o Tour Guiado pós-Onda 1 com interpolação de câmera e filtro de áudio

signal tutorial_completed

var current_step: int = 0
var is_tutorial_active: bool = false
var has_run_tutorial: bool = false

var dialog_container: PanelContainer = null
var lbl_title: Label = null
var lbl_text: Label = null
var lbl_counter: Label = null
var btn_next: Button = null
var btn_skip: Button = null
var step_icon: Label = null

var tour_points = [
	{
		"target_group": "flower",
		"icon": "🌸",
		"title": "A Flor do Jardim (Coração Vital)",
		"text": "Esta é a Flor Central! Se o HP ou a Hidratação dela zerarem, o jardim cai.\nMantenha-a protegida das pragas e regada com gotas de orvalho.",
		"zoom": 1.35
	},
	{
		"target_group": "dandelion",
		"icon": "🌾",
		"title": "Dentes-de-Leão & Sementes",
		"text": "Golpeie os dentes-de-leão com a agulha para dispersar sementes flutuantes!\nFique atento: dentes-de-leão têm sede e secam se não forem regados.",
		"zoom": 1.2
	},
	{
		"target_group": "dew_drop",
		"icon": "💧",
		"title": "Gotas de Orvalho & Frasco",
		"text": "Pip possui um Frasco dedicado (até 3 cargas). Golpeie gotas para coletar orvalho,\ncurar 25 HP e encharcar a terra, ou regue plantas com a tecla [F]!",
		"zoom": 1.15
	},
	{
		"target_group": "pickups",
		"icon": "🪵",
		"title": "Gravetos & Engrenagens",
		"text": "Recolha materiais no chão para erguer torres de gravetos e evoluí-las.\nTorres caídas podem ser reerguidas das ruínas com reparo tático!",
		"zoom": 1.25
	},
	{
		"target_group": "grid_manager",
		"icon": "🌱",
		"title": "Trilha & Grama Desaceleradora",
		"text": "Plante grama viçosa nas trilhas para reduzir em 40% a velocidade de pragas terrestres.\nUse o tempo de preparação com inteligência antes da próxima horda!",
		"zoom": 1.45
	}
]

func _ready() -> void:
	layer = 15 # Renderiza acima do HUD padrão
	_build_ui()
	GameManager.trigger_tutorial_post_wave_1.connect(start_tutorial)

func _build_ui() -> void:
	dialog_container = PanelContainer.new()
	dialog_container.name = "TutorialDialogBox"
	dialog_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog_container.position = Vector2(-280, -210)
	dialog_container.custom_minimum_size = Vector2(560, 175)
	dialog_container.visible = false
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.13, 0.94)
	sb.border_color = Tokens.DOURADO_LUZ
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	dialog_container.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	dialog_container.add_child(vbox)
	
	# Top Header (Icon + Title + Step Counter)
	var header_hbox = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)
	
	step_icon = Label.new()
	step_icon.text = "🌸"
	step_icon.add_theme_font_size_override("font_size", 22)
	header_hbox.add_child(step_icon)
	
	lbl_title = Label.new()
	lbl_title.text = "Tutorial do Jardim"
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_font_size_override("font_size", 17)
	lbl_title.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	header_hbox.add_child(lbl_title)
	
	lbl_counter = Label.new()
	lbl_counter.text = "1 / 5"
	lbl_counter.add_theme_font_size_override("font_size", 14)
	lbl_counter.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	header_hbox.add_child(lbl_counter)
	
	# Main Description
	lbl_text = Label.new()
	lbl_text.text = "Instruções do jardim..."
	lbl_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_text.add_theme_font_size_override("font_size", 14)
	lbl_text.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	lbl_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl_text)
	
	# Action Buttons (Next + Skip)
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_hbox)
	
	btn_skip = Button.new()
	btn_skip.text = "Pular Tutorial ⏩"
	btn_skip.custom_minimum_size = Vector2(130, 32)
	btn_skip.focus_mode = Control.FOCUS_NONE
	btn_skip.pressed.connect(finish_tutorial)
	btn_hbox.add_child(btn_skip)
	
	btn_next = Button.new()
	btn_next.text = "Próximo ➜"
	btn_next.custom_minimum_size = Vector2(120, 32)
	btn_next.focus_mode = Control.FOCUS_NONE
	btn_next.pressed.connect(_on_next_pressed)
	btn_hbox.add_child(btn_next)
	
	add_child(dialog_container)

func start_tutorial() -> void:
	if has_run_tutorial or is_tutorial_active:
		return
	has_run_tutorial = true
	is_tutorial_active = true
	current_step = 0
	
	# Congela o countdown e controles
	GameManager.countdown_active = false
	GameManager.set_player_control_enabled(false)
	
	# Ativa filtro de áudio low-pass
	SoundManager.apply_tutorial_audio_filter(true)
	
	if dialog_container:
		dialog_container.visible = true
		dialog_container.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(dialog_container, "modulate:a", 1.0, 0.3)
		
	_show_step(0)

func _show_step(index: int) -> void:
	if index >= tour_points.size():
		finish_tutorial()
		return
		
	var step_data = tour_points[index]
	step_icon.text = step_data["icon"]
	lbl_title.text = step_data["title"]
	lbl_text.text = step_data["text"]
	lbl_counter.text = "%d / %d" % [index + 1, tour_points.size()]
	
	if index == tour_points.size() - 1:
		btn_next.text = "Concluir ✔"
	else:
		btn_next.text = "Próximo ➜"
		
	SoundManager.play_sparkle(-3.0, 0.05)
	
	# Interpolação suave da Câmera
	var tree = get_tree()
	if tree:
		var targets = tree.get_nodes_in_group(step_data["target_group"])
		var target_node: Node3D = null
		if not targets.is_empty():
			target_node = targets[0] as Node3D
		elif GameManager.flower:
			target_node = GameManager.flower
			
		if target_node:
			var cam = tree.root.get_camera_3d() as GardenCameraController
			if cam:
				cam.focus_target(target_node, step_data["zoom"], 3.5)

func _on_next_pressed() -> void:
	current_step += 1
	if current_step < tour_points.size():
		_show_step(current_step)
	else:
		finish_tutorial()

func finish_tutorial() -> void:
	if not is_tutorial_active:
		return
	is_tutorial_active = false
	
	if dialog_container:
		var tw = create_tween()
		tw.tween_property(dialog_container, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): dialog_container.visible = false)
		
	# Restaura a câmera ao ombro da Pip
	var tree = get_tree()
	if tree:
		var cam = tree.root.get_camera_3d() as GardenCameraController
		if cam:
			cam.zoom_to_gameplay(1.8)
			
	# Restaura áudio e controles
	SoundManager.apply_tutorial_audio_filter(false)
	GameManager.set_player_control_enabled(true)
	
	# Reinicia o countdown de 30s da Onda 2
	GameManager.wave_countdown = GameManager.COUNTDOWN_DURATION
	GameManager.countdown_active = true
	
	GameManager.notify("🌱 Tutorial concluído! Prepare suas defesas para a Onda 2!", Tokens.DOURADO_LUZ)
	tutorial_completed.emit()
