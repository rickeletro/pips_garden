extends Control
class_name TitleScreen

## TitleScreen — Tela Inicial Profissional com Estética Studio Ghibli
## Apresenta arte em aquarela pastoral, logotipo estilizado, moldura de hera e menu polido.

signal start_adventure_pressed
signal skip_to_game_pressed
signal credits_pressed

const IvyBorderCanvasClass = preload("res://scripts/ui/ivy_border.gd")

@onready var bg_texture_rect: TextureRect
@onready var bg_vignette: ColorRect
@onready var ivy_border_node: Control
@onready var logo_container: VBoxContainer
@onready var title_label: Label
@onready var subtitle_label: Label
@onready var tagline_label: Label
@onready var btn_adventure: Button
@onready var btn_quick_play: Button
@onready var btn_credits: Button

var bg_tween: Tween = null
var pulse_tween: Tween = null
var particles: Array[Dictionary] = []
var particle_canvas: Control = null

class PollenLayer extends Control:
	var particles_ref: Array[Dictionary] = []
	func _draw() -> void:
		for p in particles_ref:
			var col = Color(Tokens.DOURADO_LUZ.r, Tokens.DOURADO_LUZ.g, Tokens.DOURADO_LUZ.b, p["alpha"])
			draw_circle(p["pos"], p["radius"], col)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_ambient_animations()

func _build_ui() -> void:
	# 1. Camada de Fundo (Arte Ghibli em Aquarela)
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

	# 2. Vinheta e gradiente cinematográfico (escurece sutilmente as bordas e centro inferior)
	bg_vignette = ColorRect.new()
	bg_vignette.name = "Vignette"
	bg_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_vignette.color = Color(0.04, 0.08, 0.04, 0.32)
	add_child(bg_vignette)

	# 3. Canvas de Partículas Flutuantes de Pólen Dourado
	var layer = PollenLayer.new()
	layer.name = "PollenParticles"
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

	# 5. Painel Central (Logotipo e Menus)
	var center_wrapper = VBoxContainer.new()
	center_wrapper.set_anchors_preset(Control.PRESET_CENTER)
	center_wrapper.custom_minimum_size = Vector2(600, 480)
	center_wrapper.offset_left = -300.0
	center_wrapper.offset_top = -240.0
	center_wrapper.offset_right = 300.0
	center_wrapper.offset_bottom = 240.0
	center_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	center_wrapper.add_theme_constant_override("separation", 32)
	add_child(center_wrapper)

	# 5.1 Bloco do Título
	logo_container = VBoxContainer.new()
	logo_container.add_theme_constant_override("separation", 4)
	logo_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center_wrapper.add_child(logo_container)

	# Emblema / Flor decorativa
	var emblem_lbl = Label.new()
	emblem_lbl.text = "✦   🌸   ✦"
	emblem_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	emblem_lbl.add_theme_font_size_override("font_size", 16)
	logo_container.add_child(emblem_lbl)

	title_label = Label.new()
	title_label.text = "Jardim Miúdo"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_title = load("res://ui/fonts/Fondamento-Regular.ttf") as FontFile
	if font_title:
		title_label.add_theme_font_override("font", font_title)
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.95))
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.add_theme_color_override("font_outline_color", Color(0.20, 0.14, 0.08, 0.95))
	title_label.add_theme_constant_override("outline_size", 8)
	logo_container.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Pip's Garden"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 22)
	subtitle_label.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	logo_container.add_child(subtitle_label)

	tagline_label = Label.new()
	tagline_label.text = "Um Conto Pastoral em Miniatura"
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline_label.add_theme_font_size_override("font_size", 14)
	tagline_label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.80, 0.85))
	logo_container.add_child(tagline_label)

	# 5.2 Bloco de Botões
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 14)
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_wrapper.add_child(btn_box)

	# Botão 1: Começar Aventura (com História)
	btn_adventure = Button.new()
	btn_adventure.text = "🌸 Iniciar Aventura"
	btn_adventure.custom_minimum_size = Vector2(280, 52)
	btn_adventure.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_primary_button(btn_adventure)
	btn_adventure.pressed.connect(func():
		SoundManager.play_sparkle(-2.0)
		start_adventure_pressed.emit()
	)
	btn_box.add_child(btn_adventure)

	# Botão 2: Jogar Direto (Pular história)
	btn_quick_play = Button.new()
	btn_quick_play.text = "⏩ Jogar Direto"
	btn_quick_play.custom_minimum_size = Vector2(240, 44)
	btn_quick_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_secondary_button(btn_quick_play)
	btn_quick_play.pressed.connect(func():
		SoundManager.play_pop(-4.0)
		skip_to_game_pressed.emit()
	)
	btn_box.add_child(btn_quick_play)

	# Botão 3: Créditos
	btn_credits = Button.new()
	btn_credits.text = "📜 Créditos"
	btn_credits.custom_minimum_size = Vector2(190, 38)
	btn_credits.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_tertiary_button(btn_credits)
	btn_credits.pressed.connect(func():
		SoundManager.play_pop(-6.0)
		credits_pressed.emit()
	)
	btn_box.add_child(btn_credits)

	# Rodapé
	var footer_lbl = Label.new()
	footer_lbl.text = "Jardim Miúdo • Fantasia Pastoral em Aquarela"
	footer_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer_lbl.offset_top = -42.0
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.65, 0.55))
	footer_lbl.add_theme_font_size_override("font_size", 12)
	add_child(footer_lbl)

func _style_primary_button(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.46, 0.25, 0.92) # Verde floresta vivo
	sb.border_color = Tokens.DOURADO_LUZ
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(26)
	sb.shadow_color = Color(0.1, 0.35, 0.15, 0.5)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.28, 0.58, 0.30, 0.98)
	sb_hover.border_color = Color(1.0, 0.92, 0.55, 1.0)
	sb_hover.shadow_size = 14

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn.add_theme_font_size_override("font_size", 18)

func _style_secondary_button(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.28, 0.18, 0.82)
	sb.border_color = Color(Tokens.DOURADO_LUZ, 0.75)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.22, 0.38, 0.24, 0.92)
	sb_hover.border_color = Tokens.DOURADO_LUZ

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn.add_theme_font_size_override("font_size", 15)

func _style_tertiary_button(btn: Button) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.18, 0.12, 0.70)
	sb.border_color = Color(0.65, 0.75, 0.60, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(19)

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.18, 0.28, 0.18, 0.85)
	sb_hover.border_color = Tokens.DOURADO_LUZ

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color(0.88, 0.92, 0.84, 0.9))
	btn.add_theme_font_size_override("font_size", 13)

func _start_ambient_animations() -> void:
	# 1. Animação de respiração sutil na arte de fundo
	if bg_texture_rect:
		bg_tween = create_tween().set_loops()
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.025, 1.025), 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bg_tween.tween_property(bg_texture_rect, "scale", Vector2(1.0, 1.0), 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Pulso suave e acolhedor no botão principal
	if btn_adventure:
		pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(btn_adventure, "scale", Vector2(1.03, 1.03), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_property(btn_adventure, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _init_particles() -> void:
	particles.clear()
	for i in range(24):
		particles.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed": randf_range(15.0, 35.0),
			"radius": randf_range(2.0, 4.5),
			"phase": randf() * TAU,
			"alpha": randf_range(0.3, 0.8)
		})

func _process(delta: float) -> void:
	if not visible:
		return
	var vp_size = get_viewport_rect().size
	for p in particles:
		p["pos"].y -= p["speed"] * delta
		p["pos"].x += sin(p["phase"] + Time.get_ticks_msec() * 0.002) * 12.0 * delta
		if p["pos"].y < -10.0:
			p["pos"].y = vp_size.y + 10.0
			p["pos"].x = randf() * vp_size.x
	if particle_canvas:
		(particle_canvas as PollenLayer).particles_ref = particles
		particle_canvas.queue_redraw()
