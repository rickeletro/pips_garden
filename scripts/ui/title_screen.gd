extends Control
class_name TitleScreen

## TitleScreen — Tela Inicial Profissional com Estética Studio Ghibli
## Apresenta arte pastoral em aquarela (Pip na folha de dente-de-leão), sementes e pólen flutuantes,
## moldura viva botânica e menu 100% centralizado com botões de vidro translúcido (Glassmorphism).

signal start_adventure_pressed
signal skip_to_game_pressed
signal credits_pressed

const IvyBorderCanvasClass = preload("res://scripts/ui/ivy_border.gd")

@onready var bg_texture_rect: TextureRect
@onready var bg_vignette: ColorRect
@onready var ivy_border_node: Control
@onready var center_container: CenterContainer
@onready var glass_card: PanelContainer
@onready var title_label: Label
@onready var subtitle_label: Label
@onready var tagline_label: Label
@onready var btn_adventure: Button
@onready var btn_quick_play: Button
@onready var btn_credits: Button

var bg_tween: Tween = null
var pulse_tween: Tween = null
var particle_canvas: Control = null

var dandelion_seeds: Array[Dictionary] = []
var pollen_particles: Array[Dictionary] = []

# Camada de Desenho de Partículas Atmosféricas (Sementes de Dente-de-Leão e Pólen Dourado)
class AmbientBotanicalLayer extends Control:
	var seeds_ref: Array[Dictionary] = []
	var pollen_ref: Array[Dictionary] = []

	func _draw() -> void:
		# 1. Desenha Pólen Dourado e Vaga-lumes
		for p in pollen_ref:
			var col = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, p["alpha"])
			var col_halo = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, p["alpha"] * 0.25)
			draw_circle(p["pos"], p["radius"] * 2.4, col_halo)
			draw_circle(p["pos"], p["radius"], col)

		# 2. Desenha Sementes de Dente-de-Leão Flutuantes (Plumas e Filamentos com Movimento)
		for s in seeds_ref:
			var pos: Vector2 = s["pos"]
			var stem_len: float = s["stem_len"]
			var angle: float = s["angle"]
			var alpha: float = s["alpha"]
			var scale_m: float = s["scale"]

			var col_seed = Color(0.32, 0.22, 0.14, alpha)
			var col_stem = Color(0.88, 0.92, 0.86, alpha * 0.75)
			var col_tuft = Color(0.98, 1.0, 0.96, alpha * 0.9)

			# Direção da haste ondulando
			var dir = Vector2(cos(angle), sin(angle))
			var top_pos = pos - dir * (stem_len * scale_m)

			# Talo fino da semente
			draw_line(pos, top_pos, col_stem, 1.2 * scale_m)

			# Grãozinho da semente na base
			draw_circle(pos, 1.8 * scale_m, col_seed)

			# Guarda-chuvinha de plumas radiantes (Tuft fibers)
			var rays = 8
			var spread = 0.80 # radianos
			var ray_len = stem_len * 0.85 * scale_m
			for i in range(rays):
				var ray_ang = angle + PI + lerpf(-spread, spread, float(i) / float(rays - 1))
				var ray_end = top_pos + Vector2(cos(ray_ang), sin(ray_ang)) * ray_len
				draw_line(top_pos, ray_end, col_tuft, 1.0 * scale_m)
				# Delicado pontinho na ponta de cada filamento
				draw_circle(ray_end, 0.9 * scale_m, col_tuft)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_ambient_animations()

func _build_ui() -> void:
	# 1. Pintura de Fundo em Alta Definição (Studio Ghibli: Pip na Folha de Dente-de-Leão)
	bg_texture_rect = TextureRect.new()
	bg_texture_rect.name = "BackgroundArt"
	bg_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture_rect.pivot_offset = Vector2(640, 360)

	var art_tex = load("res://textures/cinematic/title_screen_art.jpg") as Texture2D
	if art_tex:
		bg_texture_rect.texture = art_tex
	add_child(bg_texture_rect)

	# 2. Vinheta e Iluminação Suave de Atmosfera
	bg_vignette = ColorRect.new()
	bg_vignette.name = "Vignette"
	bg_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_vignette.color = Color(0.03, 0.07, 0.04, 0.22)
	add_child(bg_vignette)

	# 3. Camada de Partículas Vivas (Sementes de Dente-de-Leão + Pólen Mágico)
	var layer = AmbientBotanicalLayer.new()
	layer.name = "BotanicalParticles"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	particle_canvas = layer
	_init_particles()

	# 4. Moldura Botânica Viva de Hera e Trepadeiras
	ivy_border_node = IvyBorderCanvasClass.new()
	ivy_border_node.name = "IvyBorder"
	ivy_border_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ivy_border_node)

	# 5. Container de Centralização Absoluta (CenterContainer garante alinhamento matemático perfeito)
	center_container = CenterContainer.new()
	center_container.name = "CenterRoot"
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_container)

	# 6. Cartão de Vidro Translúcido Pastoral (Glassmorphism Suave)
	glass_card = PanelContainer.new()
	glass_card.name = "GlassMenuCard"
	glass_card.custom_minimum_size = Vector2(460, 480)

	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.06, 0.12, 0.07, 0.46) # Vidro verde-musgo translúcido
	card_sb.border_color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.38)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(32)
	card_sb.shadow_color = Color(0.01, 0.04, 0.02, 0.40)
	card_sb.shadow_size = 24
	card_sb.shadow_offset = Vector2(0, 6)
	glass_card.add_theme_stylebox_override("panel", card_sb)
	center_container.add_child(glass_card)

	# Margens internas da placa de vidro
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 36)
	card_margin.add_theme_constant_override("margin_right", 36)
	card_margin.add_theme_constant_override("margin_top", 32)
	card_margin.add_theme_constant_override("margin_bottom", 32)
	glass_card.add_child(card_margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 22)
	card_margin.add_child(main_vbox)

	# 6.1 Logotipo & Identidade Visual
	var header_vbox = VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(header_vbox)

	var emblem_lbl = Label.new()
	emblem_lbl.text = "✦   🌸   PIP'S GARDEN   🌸   ✦"
	emblem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	emblem_lbl.add_theme_font_size_override("font_size", 13)
	header_vbox.add_child(emblem_lbl)

	title_label = Label.new()
	title_label.text = "Jardim Miúdo"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_title = load("res://ui/fonts/Fondamento-Regular.ttf") as FontFile
	if font_title:
		title_label.add_theme_font_override("font", font_title)
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.02, 0.95))
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.06, 0.95))
	title_label.add_theme_constant_override("outline_size", 6)
	header_vbox.add_child(title_label)

	tagline_label = Label.new()
	tagline_label.text = "Um Conto Pastoral em Miniatura"
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_label.add_theme_font_size_override("font_size", 14)
	tagline_label.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	tagline_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	tagline_label.add_theme_constant_override("shadow_offset_y", 2)
	header_vbox.add_child(tagline_label)

	# Divisor decorativo
	var sep_box = HBoxContainer.new()
	sep_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var sep_line1 = ColorRect.new()
	sep_line1.custom_minimum_size = Vector2(50, 1)
	sep_line1.color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.35)
	var sep_dot = Label.new()
	sep_dot.text = " 🍃 "
	sep_dot.add_theme_font_size_override("font_size", 12)
	sep_dot.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	var sep_line2 = ColorRect.new()
	sep_line2.custom_minimum_size = Vector2(50, 1)
	sep_line2.color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.35)
	sep_box.add_child(sep_line1)
	sep_box.add_child(sep_dot)
	sep_box.add_child(sep_line2)
	main_vbox.add_child(sep_box)

	# 6.2 Botões do Menu com Design Suave e Transparência
	var btn_box = VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 12)
	main_vbox.add_child(btn_box)

	# Botão 1: Começar Aventura (com História e Prólogo)
	btn_adventure = Button.new()
	btn_adventure.text = "🌸 Iniciar Aventura"
	btn_adventure.custom_minimum_size = Vector2(310, 52)
	btn_adventure.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_adventure.pivot_offset = Vector2(155, 26)
	_style_glass_button(btn_adventure, true)
	btn_adventure.pressed.connect(func():
		SoundManager.play_sparkle(-2.0)
		start_adventure_pressed.emit()
	)
	_setup_button_hover_effects(btn_adventure)
	btn_box.add_child(btn_adventure)

	# Botão 2: Jogar Direto (Partida Direta)
	btn_quick_play = Button.new()
	btn_quick_play.text = "⏩ Jogar Direto"
	btn_quick_play.custom_minimum_size = Vector2(310, 46)
	btn_quick_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_quick_play.pivot_offset = Vector2(155, 23)
	_style_glass_button(btn_quick_play, false)
	btn_quick_play.pressed.connect(func():
		SoundManager.play_pop(-4.0)
		skip_to_game_pressed.emit()
	)
	_setup_button_hover_effects(btn_quick_play)
	btn_box.add_child(btn_quick_play)

	# Botão 3: Créditos
	btn_credits = Button.new()
	btn_credits.text = "📜 Créditos & Equipe"
	btn_credits.custom_minimum_size = Vector2(310, 42)
	btn_credits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_credits.pivot_offset = Vector2(155, 21)
	_style_glass_button(btn_credits, false, true)
	btn_credits.pressed.connect(func():
		SoundManager.play_pop(-6.0)
		credits_pressed.emit()
	)
	_setup_button_hover_effects(btn_credits)
	btn_box.add_child(btn_credits)

	# 7. Rodapé Discreto e Elegante
	var footer_lbl = Label.new()
	footer_lbl.text = "Jardim Miúdo • Fantasia Pastoral em Aquarela"
	footer_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_lbl.offset_top = -38.0
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.82, 0.55))
	footer_lbl.add_theme_font_size_override("font_size", 12)
	add_child(footer_lbl)

func _style_glass_button(btn: Button, is_primary: bool = false, is_tertiary: bool = false) -> void:
	var sb = StyleBoxFlat.new()
	if is_primary:
		sb.bg_color = Color(0.16, 0.32, 0.18, 0.65) # Verde floresta translúcido
		sb.border_color = Tokens.DOURADO_LUZ
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(24)
		sb.shadow_color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.22)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 3)
	elif is_tertiary:
		sb.bg_color = Color(0.08, 0.14, 0.09, 0.40) # Fundo bem sutil
		sb.border_color = Color(Tokens.CREME_PERGAMINHO.r, Tokens.CREME_PERGAMINHO.g, Tokens.CREME_PERGAMINHO.b, 0.35)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(20)
	else:
		sb.bg_color = Color(0.10, 0.20, 0.11, 0.52) # Translúcido equilibrado
		sb.border_color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.60)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(22)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 6

	var sb_hover = sb.duplicate()
	if is_primary:
		sb_hover.bg_color = Color(0.24, 0.48, 0.26, 0.88)
		sb_hover.border_color = Color(1.0, 0.95, 0.65, 1.0)
		sb_hover.shadow_size = 14
		sb_hover.shadow_color = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, 0.45)
	else:
		sb_hover.bg_color = Color(0.18, 0.34, 0.19, 0.80)
		sb_hover.border_color = Tokens.DOURADO_LUZ
		sb_hover.set_border_width_all(2)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16 if is_primary else (15 if not is_tertiary else 13))

func _setup_button_hover_effects(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.025, 1.025), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

func _start_ambient_animations() -> void:
	# 1. Animação de respiração cinematográfica suave na arte de fundo
	if bg_texture_rect:
		bg_tween = create_tween().set_loops()
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.025, 1.025), 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.0, 1.0), 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Pulso sutil no botão principal para convidar o jogador
	if btn_adventure:
		pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(btn_adventure, "scale", Vector2(1.02, 1.02), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_property(btn_adventure, "scale", Vector2(1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _init_particles() -> void:
	dandelion_seeds.clear()
	pollen_particles.clear()

	# Gera 18 sementes de dente-de-leão com profundidades e tamanhos variados
	for i in range(18):
		dandelion_seeds.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed_y": randf_range(16.0, 36.0),
			"sway_speed": randf_range(0.8, 1.8),
			"sway_amp": randf_range(14.0, 32.0),
			"stem_len": randf_range(14.0, 22.0),
			"scale": randf_range(0.75, 1.25),
			"phase": randf() * TAU,
			"angle": -PI * 0.5 + randf_range(-0.25, 0.25),
			"alpha": randf_range(0.40, 0.85)
		})

	# Gera 22 partículas de pólen dourado flutuante
	for i in range(22):
		pollen_particles.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed": randf_range(12.0, 28.0),
			"radius": randf_range(1.8, 3.8),
			"phase": randf() * TAU,
			"alpha": randf_range(0.35, 0.80)
		})

func _process(delta: float) -> void:
	if not visible:
		return
	var vp_size = get_viewport_rect().size
	var current_time = Time.get_ticks_msec() * 0.001

	# Atualiza sementes de dente-de-leão
	for s in dandelion_seeds:
		s["pos"].y -= s["speed_y"] * delta
		var sway = sin(s["phase"] + current_time * s["sway_speed"])
		s["pos"].x += sway * s["sway_amp"] * delta
		s["angle"] = -PI * 0.5 + (sway * 0.22)

		if s["pos"].y < -30.0:
			s["pos"].y = vp_size.y + 20.0
			s["pos"].x = randf() * vp_size.x

	# Atualiza pólen dourado
	for p in pollen_particles:
		p["pos"].y -= p["speed"] * delta
		p["pos"].x += sin(p["phase"] + current_time * 1.5) * 10.0 * delta
		if p["pos"].y < -10.0:
			p["pos"].y = vp_size.y + 10.0
			p["pos"].x = randf() * vp_size.x

	if particle_canvas:
		var botanical_layer = particle_canvas as AmbientBotanicalLayer
		botanical_layer.seeds_ref = dandelion_seeds
		botanical_layer.pollen_ref = pollen_particles
		botanical_layer.queue_redraw()
