extends Control
class_name TitleScreen

## TitleScreen — Tela Inicial Minimalista & Poética (Studio Ghibli)
## Imagem da Pip na folha de dente-de-leão com sementes e pólen em movimento.
## Botões em texto puro, claros e cintilantes com alto contraste, sem fundos ou bordas pesadas.
## Apenas duas opções principais: "Começar a Jogar" e "Menu" (com opções de áudio).

signal start_adventure_pressed
signal skip_to_game_pressed
signal credits_pressed

const IvyBorderCanvasClass = preload("res://scripts/ui/ivy_border.gd")

@onready var bg_texture_rect: TextureRect
@onready var bg_vignette: ColorRect
@onready var ivy_border_node: Control

# Containers
@onready var center_container: CenterContainer
@onready var main_menu_vbox: VBoxContainer
@onready var options_menu_vbox: VBoxContainer

# Botões Principais (Texto Puro Sintilante)
@onready var btn_start: Button
@onready var btn_menu: Button

# Botões do Submenu de Opções
@onready var btn_toggle_music: Button
@onready var btn_toggle_sfx: Button
@onready var btn_back: Button

var bg_tween: Tween = null
var particle_canvas: Control = null

var dandelion_seeds: Array[Dictionary] = []
var pollen_particles: Array[Dictionary] = []
var text_shimmer_phase: float = 0.0

# Camada de Desenho de Partículas Vivas (Sementes de Dente-de-Leão e Pólen Cintilante)
class BotanicalParticlesLayer extends Control:
	var seeds_ref: Array[Dictionary] = []
	var pollen_ref: Array[Dictionary] = []

	func _draw() -> void:
		# 1. Desenha Pólen Mágico Dourado / Vaga-lumes
		for p in pollen_ref:
			var col = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, p["alpha"])
			var col_halo = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, p["alpha"] * 0.3)
			draw_circle(p["pos"], p["radius"] * 2.5, col_halo)
			draw_circle(p["pos"], p["radius"], col)

		# 2. Desenha Sementes de Dente-de-Leão Flutuantes (Plumas Brancas Delicadas com Talo)
		for s in seeds_ref:
			var pos: Vector2 = s["pos"]
			var stem_len: float = s["stem_len"]
			var angle: float = s["angle"]
			var alpha: float = s["alpha"]
			var scale_m: float = s["scale"]

			var col_seed = Color(0.35, 0.24, 0.14, alpha)
			var col_stem = Color(0.92, 0.95, 0.90, alpha * 0.75)
			var col_tuft = Color(0.98, 1.0, 0.98, alpha * 0.9)

			var dir = Vector2(cos(angle), sin(angle))
			var top_pos = pos - dir * (stem_len * scale_m)

			# Haste delgada
			draw_line(pos, top_pos, col_stem, 1.2 * scale_m)
			# Semente
			draw_circle(pos, 1.8 * scale_m, col_seed)

			# Filamentos radiantes da pluma
			var rays = 8
			var spread = 0.85
			var ray_len = stem_len * 0.85 * scale_m
			for i in range(rays):
				var ray_ang = angle + PI + lerpf(-spread, spread, float(i) / float(rays - 1))
				var ray_end = top_pos + Vector2(cos(ray_ang), sin(ray_ang)) * ray_len
				draw_line(top_pos, ray_end, col_tuft, 1.0 * scale_m)
				draw_circle(ray_end, 0.85 * scale_m, col_tuft)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_ambient_animations()

func _build_ui() -> void:
	# 1. Imagem de Fundo em Tela Cheia (Pip na Folha de Dente-de-Leão)
	bg_texture_rect = TextureRect.new()
	bg_texture_rect.name = "BackgroundArt"
	bg_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_texture_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg_texture_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture_rect.pivot_offset = Vector2(640, 360)

	var art_tex = load("res://textures/cinematic/title_screen_art.jpg") as Texture2D
	if art_tex:
		bg_texture_rect.texture = art_tex
	add_child(bg_texture_rect)

	# 2. Vinheta Suave para Profundidade e Contraste Natural
	bg_vignette = ColorRect.new()
	bg_vignette.name = "Vignette"
	bg_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_vignette.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg_vignette.grow_vertical = Control.GROW_DIRECTION_BOTH
	bg_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_vignette.color = Color(0.02, 0.05, 0.02, 0.18)
	add_child(bg_vignette)

	# 3. Camada de Partículas Vivas (Sementes de Dente-de-Leão + Pólen)
	var layer = BotanicalParticlesLayer.new()
	layer.name = "BotanicalParticles"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	particle_canvas = layer
	_init_particles()

	# 4. Moldura Botânica Viva de Hera
	ivy_border_node = IvyBorderCanvasClass.new()
	ivy_border_node.name = "IvyBorder"
	ivy_border_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ivy_border_node)

	# 5. Container de Centralização Perfeita (Sem caixas ou fundos)
	center_container = CenterContainer.new()
	center_container.name = "CenterRoot"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_container)

	# 5.1 Container Principal do Menu (Título + Opções)
	var root_vbox = VBoxContainer.new()
	root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root_vbox.add_theme_constant_override("separation", 36)
	center_container.add_child(root_vbox)

	# Título do Jogo (Tipografia Poética com Contraste Marcante)
	var title_box = VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.add_theme_constant_override("separation", 2)
	root_vbox.add_child(title_box)

	var emblem_lbl = Label.new()
	emblem_lbl.text = "✦   🌸   PIP'S GARDEN   🌸   ✦"
	emblem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	emblem_lbl.add_theme_font_size_override("font_size", 13)
	emblem_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	emblem_lbl.add_theme_constant_override("shadow_offset_y", 2)
	title_box.add_child(emblem_lbl)

	var title_lbl = Label.new()
	title_lbl.text = "Jardim Miúdo"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_title = load("res://ui/fonts/Fondamento-Regular.ttf") as FontFile
	if font_title:
		title_lbl.add_theme_font_override("font", font_title)
	title_lbl.add_theme_font_size_override("font_size", 66)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82)) # Dourado-marfim radiante
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.08, 0.03, 0.98))
	title_lbl.add_theme_constant_override("shadow_offset_y", 4)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.16, 0.08, 0.98))
	title_lbl.add_theme_constant_override("outline_size", 8)
	title_box.add_child(title_lbl)

	var tagline_lbl = Label.new()
	tagline_lbl.text = "Um Conto Pastoral em Miniatura"
	tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_lbl.add_theme_font_size_override("font_size", 14)
	tagline_lbl.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	tagline_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	tagline_lbl.add_theme_constant_override("shadow_offset_y", 2)
	tagline_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.10, 0.04, 0.9))
	tagline_lbl.add_theme_constant_override("outline_size", 4)
	title_box.add_child(tagline_lbl)

	# 5.2 Menu Inicial: SÓ "Começar a Jogar" e "Menu"
	main_menu_vbox = VBoxContainer.new()
	main_menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_menu_vbox.add_theme_constant_override("separation", 18)
	root_vbox.add_child(main_menu_vbox)

	# Botão 1: Começar a Jogar
	btn_start = Button.new()
	btn_start.text = "Começar a Jogar"
	btn_start.custom_minimum_size = Vector2(340, 52)
	_setup_shimmer_text_button(btn_start, 26, true)
	btn_start.pressed.connect(func():
		SoundManager.play_sparkle(-2.0)
		start_adventure_pressed.emit()
	)
	main_menu_vbox.add_child(btn_start)

	# Botão 2: Menu
	btn_menu = Button.new()
	btn_menu.text = "Menu"
	btn_menu.custom_minimum_size = Vector2(340, 46)
	_setup_shimmer_text_button(btn_menu, 22, false)
	btn_menu.pressed.connect(func():
		SoundManager.play_pop(-4.0)
		_show_options_menu(true)
	)
	main_menu_vbox.add_child(btn_menu)

	# 5.3 Submenu de Opções (Desligar som, desligar efeitos sonoros)
	options_menu_vbox = VBoxContainer.new()
	options_menu_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	options_menu_vbox.add_theme_constant_override("separation", 16)
	options_menu_vbox.visible = false
	root_vbox.add_child(options_menu_vbox)

	var opt_title = Label.new()
	opt_title.text = "✦  Configurações de Áudio  ✦"
	opt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt_title.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	opt_title.add_theme_font_size_override("font_size", 16)
	opt_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	opt_title.add_theme_constant_override("shadow_offset_y", 2)
	options_menu_vbox.add_child(opt_title)

	# Opção: Música
	btn_toggle_music = Button.new()
	_update_music_button_text()
	btn_toggle_music.custom_minimum_size = Vector2(340, 44)
	_setup_shimmer_text_button(btn_toggle_music, 18, false)
	btn_toggle_music.pressed.connect(func():
		SoundManager.toggle_music()
		_update_music_button_text()
		SoundManager.play_pop(-4.0)
	)
	options_menu_vbox.add_child(btn_toggle_music)

	# Opção: Efeitos Sonoros
	btn_toggle_sfx = Button.new()
	_update_sfx_button_text()
	btn_toggle_sfx.custom_minimum_size = Vector2(340, 44)
	_setup_shimmer_text_button(btn_toggle_sfx, 18, false)
	btn_toggle_sfx.pressed.connect(func():
		SoundManager.toggle_sfx()
		_update_sfx_button_text()
		if SoundManager.sfx_enabled:
			SoundManager.play_sparkle(-3.0)
	)
	options_menu_vbox.add_child(btn_toggle_sfx)

	# Opção: Voltar
	btn_back = Button.new()
	btn_back.text = "⬅️ Voltar"
	btn_back.custom_minimum_size = Vector2(340, 42)
	_setup_shimmer_text_button(btn_back, 18, false)
	btn_back.pressed.connect(func():
		SoundManager.play_pop(-5.0)
		_show_options_menu(false)
	)
	options_menu_vbox.add_child(btn_back)

	# 6. Rodapé Minimalista
	var footer_lbl = Label.new()
	footer_lbl.text = "Jardim Miúdo • Pip's Garden"
	footer_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_lbl.offset_top = -34.0
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
	footer_lbl.add_theme_font_size_override("font_size", 12)
	footer_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	footer_lbl.add_theme_constant_override("shadow_offset_y", 2)
	add_child(footer_lbl)

func _setup_shimmer_text_button(btn: Button, font_size: int, is_hero: bool = false) -> void:
	# 100% estilo transparente (sem fundos coloridos, sem caixas, sem bordas)
	var empty_sb = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)

	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x * 0.5, btn.custom_minimum_size.y * 0.5)

	# Tipografia clara e cintilante com alto contraste garantido sobre a pintura
	var col_normal = Color(1.0, 0.98, 0.92) if not is_hero else Color(1.0, 0.97, 0.85)
	btn.add_theme_color_override("font_color", col_normal)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.55)) # Ouro cintilante radiante
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.85, 0.45))
	btn.add_theme_font_size_override("font_size", font_size)

	# Sombra escura e contorno para leitura cristalina sobre qualquer elemento da arte
	btn.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.02, 0.98))
	btn.add_theme_constant_override("shadow_offset_y", 3)
	btn.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.06, 0.98))
	btn.add_theme_constant_override("outline_size", 8)

	var font_ttf = load("res://ui/fonts/Fondamento-Regular.ttf") as FontFile
	if font_ttf:
		btn.add_theme_font_override("font", font_ttf)

	# Micro-interações táteis de hover
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		SoundManager.play_sparkle(-8.0)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _update_music_button_text() -> void:
	if btn_toggle_music:
		if SoundManager.music_enabled:
			btn_toggle_music.text = "🎵 Música: Ligada"
		else:
			btn_toggle_music.text = "🔇 Música: Desligada"

func _update_sfx_button_text() -> void:
	if btn_toggle_sfx:
		if SoundManager.sfx_enabled:
			btn_toggle_sfx.text = "🔔 Efeitos Sonoros: Ligados"
		else:
			btn_toggle_sfx.text = "🔕 Efeitos Sonoros: Desligados"

func _show_options_menu(show_options: bool) -> void:
	if show_options:
		main_menu_vbox.visible = false
		options_menu_vbox.visible = true
		_update_music_button_text()
		_update_sfx_button_text()
	else:
		options_menu_vbox.visible = false
		main_menu_vbox.visible = true

func _start_ambient_animations() -> void:
	# Respiração suave na arte de fundo
	if bg_texture_rect:
		bg_tween = create_tween().set_loops()
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.025, 1.025), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.0, 1.0), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _init_particles() -> void:
	dandelion_seeds.clear()
	pollen_particles.clear()

	# 18 sementes de dente-de-leão flutuantes
	for i in range(18):
		dandelion_seeds.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed_y": randf_range(16.0, 34.0),
			"sway_speed": randf_range(0.8, 1.8),
			"sway_amp": randf_range(16.0, 32.0),
			"stem_len": randf_range(14.0, 22.0),
			"scale": randf_range(0.8, 1.25),
			"phase": randf() * TAU,
			"angle": -PI * 0.5 + randf_range(-0.25, 0.25),
			"alpha": randf_range(0.40, 0.85)
		})

	# 22 partículas de pólen cintilante
	for i in range(22):
		pollen_particles.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed": randf_range(12.0, 26.0),
			"radius": randf_range(1.8, 3.8),
			"phase": randf() * TAU,
			"alpha": randf_range(0.35, 0.85)
		})

func _process(delta: float) -> void:
	if not visible:
		return
	var vp_size = get_viewport_rect().size
	var current_time = Time.get_ticks_msec() * 0.001

	# Cintilação suave no botão principal
	text_shimmer_phase += delta * 2.5
	var shimmer_factor = 0.88 + 0.12 * sin(text_shimmer_phase)
	if btn_start and is_instance_valid(btn_start):
		var gold_val = lerpf(0.82, 0.98, shimmer_factor)
		btn_start.add_theme_color_override("font_color", Color(1.0, gold_val, 0.80))

	# Atualiza sementes de dente-de-leão
	for s in dandelion_seeds:
		s["pos"].y -= s["speed_y"] * delta
		var sway = sin(s["phase"] + current_time * s["sway_speed"])
		s["pos"].x += sway * s["sway_amp"] * delta
		s["angle"] = -PI * 0.5 + (sway * 0.22)

		if s["pos"].y < -30.0:
			s["pos"].y = vp_size.y + 20.0
			s["pos"].x = randf() * vp_size.x

	# Atualiza pólen cintilante
	for p in pollen_particles:
		p["pos"].y -= p["speed"] * delta
		p["pos"].x += sin(p["phase"] + current_time * 1.5) * 10.0 * delta
		if p["pos"].y < -10.0:
			p["pos"].y = vp_size.y + 10.0
			p["pos"].x = randf() * vp_size.x

	if particle_canvas:
		var botanical_layer = particle_canvas as BotanicalParticlesLayer
		botanical_layer.seeds_ref = dandelion_seeds
		botanical_layer.pollen_ref = pollen_particles
		botanical_layer.queue_redraw()
