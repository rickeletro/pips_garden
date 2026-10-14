extends CanvasLayer
class_name StoryCinematic

## StoryCinematic — Narrativa Visual em Tela Cheia do Jardim Miúdo (Pip's Garden)
## Apresenta o conto da semente sagrada, Pip, o Rei Escorpião e a agulha de costura.

signal story_completed

var current_chapter: int = 0
var current_chapter_idx: int:
	get: return current_chapter
var is_active: bool = false
var is_transitioning: bool = false

# Nós de UI
var root_control: Control
var bg_color_rect: ColorRect
var texture_rect_current: TextureRect
var texture_rect_next: TextureRect
var particles_container: Control
var vignette_rect: ColorRect

var dialog_panel: PanelContainer
var chapter_badge: Label
var title_label: Label
var text_label: Label
var dots_container: HBoxContainer
var btn_next: Button
var btn_skip: Button

var full_text_to_display: String = ""
var text_tween: Tween = null
var ken_burns_tween: Tween = null

var chapters: Array[Dictionary]:
	get: return CHAPTERS

const CHAPTERS: Array[Dictionary] = [
	{
		"image": "res://textures/cinematic/scene_1_seed_falling.jpg",
		"chapter_num": "Capítulo I",
		"title": "A Dádiva dos Céus",
		"text": "Em uma manhã orvalhada de céu azul, uma pequena e misteriosa sementinha celestial caiu das alturas, deixando um rastro de luz dourada como uma estrela cadente entre os trevos gigantes."
	},
	{
		"image": "res://textures/cinematic/scene_2_pip_planting.jpg",
		"chapter_num": "Capítulo II",
		"title": "O Despertar da Flor",
		"text": "Pip, a diminuta guardiã de cabelos de fogo, admirou a pureza e a energia radiante da semente mágica. Com reverência e esperança, ela a plantou com amor no coração fértil do jardim."
	},
	{
		"image": "res://textures/cinematic/scene_3_scorpion_threat.jpg",
		"chapter_num": "Capítulo III",
		"title": "A Cobiça das Sombras",
		"text": "Mas o brilho sagrado despertou a cobiça nas profundezas espinhosas. O temível Rei Escorpião ergueu suas garras e enviou suas hordas de insetos para roubar a semente e dominar o jardim!"
	},
	{
		"image": "res://textures/cinematic/scene_4_pip_guardian.jpg",
		"chapter_num": "Capítulo IV",
		"title": "O Juramento da Protetora",
		"text": "Sem hesitar, Pip empunhou sua afiada agulha de costura prateada como espada. Como defensora jurada do Jardim Miúdo, ela prometeu proteger a flor sagrada e lutar com coragem até o fim!"
	}
]

func _ready() -> void:
	layer = 25 # Renderiza em tela cheia com prioridade sobre HUD
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "Root"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	# Fundo escuro base
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = Color(0.04, 0.06, 0.04, 1.0)
	bg_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(bg_color_rect)

	# Camada de imagem anterior (crossfade)
	texture_rect_current = TextureRect.new()
	texture_rect_current.name = "ImageCurrent"
	texture_rect_current.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect_current.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect_current.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect_current.pivot_offset = Vector2(640, 360)
	root_control.add_child(texture_rect_current)

	# Camada de imagem próxima (crossfade)
	texture_rect_next = TextureRect.new()
	texture_rect_next.name = "ImageNext"
	texture_rect_next.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect_next.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect_next.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect_next.pivot_offset = Vector2(640, 360)
	texture_rect_next.modulate.a = 0.0
	root_control.add_child(texture_rect_next)

	# Vinheta cinematográfica suave
	vignette_rect = ColorRect.new()
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_rect.color = Color(0, 0, 0, 0.25)
	root_control.add_child(vignette_rect)

	# Indicador de Capítulos no Topo
	var top_bar = HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 28.0
	top_bar.offset_left = 40.0
	top_bar.offset_right = -40.0
	top_bar.offset_bottom = 70.0
	root_control.add_child(top_bar)

	chapter_badge = Label.new()
	chapter_badge.text = "Capítulo I / IV"
	chapter_badge.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	chapter_badge.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(chapter_badge)

	# Espaçador
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Bolinhas de progresso
	dots_container = HBoxContainer.new()
	dots_container.add_theme_constant_override("separation", 10)
	top_bar.add_child(dots_container)
	_setup_progress_dots()

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(30, 0)
	top_bar.add_child(spacer2)

	# Botão Pular História
	btn_skip = Button.new()
	btn_skip.text = "⏩ Pular História"
	btn_skip.custom_minimum_size = Vector2(140, 36)
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(0.12, 0.16, 0.10, 0.70)
	skip_style.border_color = Color(Tokens.DOURADO_LUZ, 0.6)
	skip_style.set_border_width_all(1)
	skip_style.set_corner_radius_all(18)
	btn_skip.add_theme_stylebox_override("normal", skip_style)
	btn_skip.add_theme_stylebox_override("hover", skip_style)
	btn_skip.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn_skip.add_theme_font_size_override("font_size", 14)
	btn_skip.pressed.connect(_on_skip_pressed)
	top_bar.add_child(btn_skip)

	# Painel de Narrativa / Legenda na Parte Inferior
	var bottom_margin = MarginContainer.new()
	bottom_margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_margin.offset_top = -220.0
	bottom_margin.offset_left = 60.0
	bottom_margin.offset_right = -60.0
	bottom_margin.offset_bottom = -30.0
	root_control.add_child(bottom_margin)

	dialog_panel = PanelContainer.new()
	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.10, 0.15, 0.08, 0.88) # Tom botânico musgo com transparência
	panel_sb.border_color = Tokens.DOURADO_LUZ
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(16)
	panel_sb.shadow_color = Color(0, 0, 0, 0.5)
	panel_sb.shadow_size = 12
	panel_sb.shadow_offset = Vector2(0, 4)
	dialog_panel.add_theme_stylebox_override("panel", panel_sb)
	bottom_margin.add_child(dialog_panel)

	var panel_vbox = VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 8)
	var panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 28)
	panel_margin.add_theme_constant_override("margin_top", 16)
	panel_margin.add_theme_constant_override("margin_right", 28)
	panel_margin.add_theme_constant_override("margin_bottom", 16)
	panel_margin.add_child(panel_vbox)
	dialog_panel.add_child(panel_margin)

	# Título do Capítulo
	title_label = Label.new()
	title_label.text = "A Dádiva dos Céus"
	title_label.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.add_theme_font_size_override("font_size", 22)
	panel_vbox.add_child(title_label)

	# Texto da Legenda / Narrador
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	text_label.add_theme_constant_override("shadow_offset_y", 1)
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.custom_minimum_size = Vector2(0, 68)
	panel_vbox.add_child(text_label)

	# Linha inferior com botão de avançar
	var action_hbox = HBoxContainer.new()
	action_hbox.alignment = BoxContainer.ALIGNMENT_END
	panel_vbox.add_child(action_hbox)

	var tip_label = Label.new()
	tip_label.text = "[Clique na tela ou pressione Espaço]"
	tip_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.75, 0.65))
	tip_label.add_theme_font_size_override("font_size", 12)
	tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_hbox.add_child(tip_label)

	btn_next = Button.new()
	btn_next.text = "Continuar ➡️"
	btn_next.custom_minimum_size = Vector2(170, 42)
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Tokens.VERDE_FOLHA
	btn_sb.border_color = Tokens.DOURADO_LUZ
	btn_sb.set_border_width_all(2)
	btn_sb.set_corner_radius_all(21)
	btn_sb.shadow_color = Color(0.1, 0.3, 0.1, 0.4)
	btn_sb.shadow_size = 6
	btn_next.add_theme_stylebox_override("normal", btn_sb)
	btn_next.add_theme_stylebox_override("hover", btn_sb)
	btn_next.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn_next.add_theme_font_size_override("font_size", 16)
	btn_next.pressed.connect(_on_next_pressed)
	action_hbox.add_child(btn_next)

func _setup_progress_dots() -> void:
	for child in dots_container.get_children():
		child.queue_free()
	for i in range(CHAPTERS.size()):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = Tokens.DOURADO_LUZ if i == 0 else Color(0.5, 0.55, 0.45, 0.5)
		dots_container.add_child(dot)

func _update_progress_dots() -> void:
	var dots = dots_container.get_children()
	for i in range(dots.size()):
		var dot = dots[i] as ColorRect
		if dot:
			dot.color = Tokens.DOURADO_LUZ if i == current_chapter else Color(0.5, 0.55, 0.45, 0.4)

func start_story() -> void:
	is_active = true
	current_chapter = 0
	visible = true
	root_control.modulate.a = 0.0

	var tw = create_tween()
	tw.tween_property(root_control, "modulate:a", 1.0, 0.6)
	tw.tween_callback(func():
		_display_chapter(0, true)
	)

func _display_chapter(idx: int, is_first: bool = false) -> void:
	if idx < 0 or idx >= CHAPTERS.size():
		_finish_story()
		return

	is_transitioning = true
	current_chapter = idx
	_update_progress_dots()

	var data = CHAPTERS[idx]
	chapter_badge.text = "%s / IV" % data["chapter_num"]
	title_label.text = data["title"]
	full_text_to_display = data["text"]

	if idx == CHAPTERS.size() - 1:
		btn_next.text = "Defender o Jardim! ⚔️"
	else:
		btn_next.text = "Continuar ➡️"

	var tex = load(data["image"]) as Texture2D

	if is_first:
		texture_rect_current.texture = tex
		texture_rect_current.modulate.a = 1.0
		texture_rect_next.modulate.a = 0.0
		_apply_ken_burns(texture_rect_current)
		_animate_text()
		is_transitioning = false
		SoundManager.play_sparkle(-3.0)
	else:
		texture_rect_next.texture = tex
		texture_rect_next.modulate.a = 0.0
		_apply_ken_burns(texture_rect_next)

		var tw = create_tween()
		tw.tween_property(texture_rect_next, "modulate:a", 1.0, 0.7)
		tw.tween_callback(func():
			texture_rect_current.texture = tex
			texture_rect_next.modulate.a = 0.0
			is_transitioning = false
		)
		_animate_text()
		SoundManager.play_sparkle(-3.0)

func _apply_ken_burns(target_rect: TextureRect) -> void:
	if ken_burns_tween and ken_burns_tween.is_valid():
		ken_burns_tween.kill()

	target_rect.scale = Vector2(1.0, 1.0)
	ken_burns_tween = create_tween()
	# Zoom sutil anime 1.0 -> 1.04 em 12 segundos
	ken_burns_tween.tween_property(target_rect, "scale", Vector2(1.04, 1.04), 12.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _animate_text() -> void:
	if text_tween and text_tween.is_valid():
		text_tween.kill()

	text_label.text = full_text_to_display
	text_label.visible_ratio = 0.0
	var char_count = full_text_to_display.length()
	var duration = clampf(char_count * 0.022, 1.2, 3.2)

	text_tween = create_tween()
	text_tween.tween_property(text_label, "visible_ratio", 1.0, duration)

func next_chapter() -> void:
	if current_chapter + 1 < CHAPTERS.size():
		_display_chapter(current_chapter + 1)
	else:
		_finish_story()

func skip_story(immediate: bool = false) -> void:
	_finish_story(immediate)

func _on_next_pressed() -> void:
	if is_transitioning:
		return

	# Se o texto ainda estiver digitando, revela tudo primeiro
	if text_label.visible_ratio < 0.95:
		if text_tween and text_tween.is_valid():
			text_tween.kill()
		text_label.visible_ratio = 1.0
		return

	next_chapter()

func _on_skip_pressed() -> void:
	skip_story()

func _finish_story(immediate: bool = false) -> void:
	if not is_active:
		return
	is_active = false

	if immediate:
		visible = false
		story_completed.emit()
		return

	var tw = create_tween()
	tw.tween_property(root_control, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		visible = false
		story_completed.emit()
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		_on_next_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Permite avançar clicando em qualquer lugar exceto nos botões
		var m_pos = event.position
		if not dialog_panel.get_global_rect().has_point(m_pos) and not btn_skip.get_global_rect().has_point(m_pos):
			get_viewport().set_input_as_handled()
			_on_next_pressed()
