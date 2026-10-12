extends Control
class_name CreditsSequence

var credits_modal: Control = null
var ending_sequence_active: bool = false
var ending_container: Control = null

func _ready() -> void:
	name = "CreditsSequence"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_credits_modal()

func _setup_credits_modal() -> void:
	if credits_modal != null:
		return
		
	credits_modal = Control.new()
	credits_modal.name = "CreditsModal"
	credits_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_modal.visible = false
	add_child(credits_modal)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.04, 0.08, 0.05, 0.85)
	credits_modal.add_child(bg_overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits_modal.add_child(center)
	
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(680, 480)
	
	var sb_main = StyleBoxFlat.new()
	sb_main.bg_color = Color(0.12, 0.18, 0.12, 0.98)
	sb_main.border_color = Tokens.DOURADO_LUZ
	sb_main.set_border_width_all(3)
	sb_main.set_corner_radius_all(18)
	sb_main.shadow_color = Color(0, 0, 0, 0.6)
	sb_main.shadow_size = 16
	main_panel.add_theme_stylebox_override("panel", sb_main)
	center.add_child(main_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	main_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Título do Jogo
	var title_lbl = Label.new()
	title_lbl.text = "🌸 JARDIM MIÚDO 🌸\n(PIP'S GARDEN)"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02, 0.9))
	title_lbl.add_theme_constant_override("outline_size", 6)
	vbox.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "Fantasia Pastoral & Defesa Botânica em Miniatura"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 14)
	sub_lbl.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	vbox.add_child(sub_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Bloco de Créditos do Criador
	var credits_box = VBoxContainer.new()
	credits_box.add_theme_constant_override("separation", 8)
	vbox.add_child(credits_box)
	
	var c1 = Label.new()
	c1.text = "👑 Criação & Game Design:\nRicardo Ferreira de Souza"
	c1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c1.add_theme_font_size_override("font_size", 18)
	c1.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	credits_box.add_child(c1)
	
	var c2 = Label.new()
	c2.text = "🎨 Direção de Arte & Fantasia Pastoral: Ricardo Ferreira de Souza"
	c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c2.add_theme_font_size_override("font_size", 14)
	c2.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	credits_box.add_child(c2)
	
	var c3 = Label.new()
	c3.text = "💻 Desenvolvimento & Arquitetura de Sistemas: Ricardo Ferreira de Souza"
	c3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c3.add_theme_font_size_override("font_size", 14)
	c3.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	credits_box.add_child(c3)
	
	var c4 = Label.new()
	c4.text = "🎵 Trilha Sonora: Defesa do Jardim / Enchanted Garden"
	c4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c4.add_theme_font_size_override("font_size", 13)
	c4.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	credits_box.add_child(c4)
	
	var ded = Label.new()
	ded.text = "✨ Dedicado à bravura da heroína Pip e à sua fiel guardiã Joaninha."
	ded.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ded.add_theme_font_size_override("font_size", 13)
	ded.add_theme_color_override("font_color", Tokens.VERDE_FOLHA.lightened(0.3))
	credits_box.add_child(ded)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Botão de Fechar
	var close_btn = Button.new()
	close_btn.text = "❌ Fechar Créditos"
	close_btn.custom_minimum_size = Vector2(220, 42)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Tokens.VERDE_MUSGO
	sb_btn.set_corner_radius_all(10)
	close_btn.add_theme_stylebox_override("normal", sb_btn)
	close_btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(close_credits)
	vbox.add_child(close_btn)

func open_credits() -> void:
	if credits_modal:
		credits_modal.visible = true
		credits_modal.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(credits_modal, "modulate:a", 1.0, 0.2)

func close_credits() -> void:
	if credits_modal and credits_modal.visible:
		var tw = create_tween()
		tw.tween_property(credits_modal, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func():
			credits_modal.visible = false
		)

func start_cinematic_credits_sequence(margin_container: Control = null) -> void:
	if ending_sequence_active:
		return
	ending_sequence_active = true
	
	if credits_modal:
		credits_modal.visible = false
		
	# 2. Fade out suave do HUD de jogo
	if margin_container:
		var tw_hud = create_tween()
		tw_hud.tween_property(margin_container, "modulate:a", 0.0, 1.8)
		
	# 3. Zoom out super lento e cinematográfico da câmera sobre o jardim
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("start_credits_slow_zoom_out"):
		cam.start_credits_slow_zoom_out(20.0)
		
	# 4. Fade musical: Música inicial suave
	SoundManager.play_intro_music(3.5, -4.0)
	
	# 5. Constrói a camada cinematográfica com moldura botânica e texto subindo
	_build_and_run_cinematic_credits_crawl()

func _build_and_run_cinematic_credits_crawl() -> void:
	ending_container = Control.new()
	ending_container.name = "CinematicEndingLayer"
	ending_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ending_container)
	
	# Moldura Botânica Viva de Trepadeiras
	var ivy_script = load("res://scripts/ui/ivy_border.gd")
	if ivy_script:
		var ivy_frame = ivy_script.new()
		ivy_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		ivy_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ivy_frame.modulate.a = 0.0
		ending_container.add_child(ivy_frame)
		
		var tw_ivy = create_tween()
		tw_ivy.tween_property(ivy_frame, "modulate:a", 1.0, 2.5).set_trans(Tween.TRANS_SINE)
	
	# Container do texto rolando pelo centro da tela
	var crawl_box = VBoxContainer.new()
	crawl_box.name = "CreditsCrawlBox"
	crawl_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	crawl_box.custom_minimum_size = Vector2(760, 0)
	crawl_box.size = Vector2(760, 0)
	crawl_box.add_theme_constant_override("separation", 22)
	ending_container.add_child(crawl_box)
	
	crawl_box.anchor_left = 0.5
	crawl_box.anchor_right = 0.5
	crawl_box.offset_left = -380
	crawl_box.offset_right = 380
	
	var screen_h = get_viewport().get_visible_rect().size.y
	if screen_h <= 100: screen_h = 720.0
	crawl_box.position.y = screen_h + 40.0
	
	# Título do Jogo
	var title_lbl = Label.new()
	title_lbl.text = "🌸 JARDIM MIÚDO 🌸\n(PIP'S GARDEN)"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.02, 0.95))
	title_lbl.add_theme_constant_override("outline_size", 7)
	crawl_box.add_child(title_lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "Fantasia Pastoral & Defesa Botânica em Miniatura"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 16)
	sub_lbl.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	sub_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	sub_lbl.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(sub_lbl)
	
	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 20)
	crawl_box.add_child(sp1)
	
	# Poesia de Encerramento
	var victory_lbl = Label.new()
	victory_lbl.text = "✨ VITÓRIA TOTAL ✨\n\nO Jardim Miúdo resistiu com bravura a todas as pragas e tiranos.\nA Flor Central floresce em paz perpétua\ne a constelação da Joaninha vigia o céu estrelado para sempre."
	victory_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	victory_lbl.add_theme_font_size_override("font_size", 17)
	victory_lbl.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	victory_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.12, 0.95))
	victory_lbl.add_theme_constant_override("outline_size", 5)
	crawl_box.add_child(victory_lbl)
	
	var sp2 = Control.new()
	sp2.custom_minimum_size = Vector2(0, 28)
	crawl_box.add_child(sp2)
	
	# Créditos do Criador: RICARDO FERREIRA DE SOUZA
	var creator_title = Label.new()
	creator_title.text = "👑 CRIAÇÃO & GAME DESIGN"
	creator_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creator_title.add_theme_font_size_override("font_size", 14)
	creator_title.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	creator_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	creator_title.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(creator_title)
	
	var creator_name = Label.new()
	creator_name.text = "Ricardo Ferreira de Souza"
	creator_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creator_name.add_theme_font_size_override("font_size", 22)
	creator_name.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	creator_name.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.95))
	creator_name.add_theme_constant_override("outline_size", 6)
	crawl_box.add_child(creator_name)
	
	var sp3 = Control.new()
	sp3.custom_minimum_size = Vector2(0, 18)
	crawl_box.add_child(sp3)
	
	var art_title = Label.new()
	art_title.text = "🎨 DIREÇÃO DE ARTE & FANTASIA PASTORAL"
	art_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_title.add_theme_font_size_override("font_size", 14)
	art_title.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	art_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	art_title.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(art_title)
	
	var art_name = Label.new()
	art_name.text = "Ricardo Ferreira de Souza"
	art_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_name.add_theme_font_size_override("font_size", 20)
	art_name.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	art_name.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.95))
	art_name.add_theme_constant_override("outline_size", 5)
	crawl_box.add_child(art_name)
	
	var sp4 = Control.new()
	sp4.custom_minimum_size = Vector2(0, 18)
	crawl_box.add_child(sp4)
	
	var prog_title = Label.new()
	prog_title.text = "💻 DESENVOLVIMENTO & ARQUITETURA DE SISTEMAS"
	prog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_title.add_theme_font_size_override("font_size", 14)
	prog_title.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	prog_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prog_title.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(prog_title)
	
	var prog_name = Label.new()
	prog_name.text = "Ricardo Ferreira de Souza"
	prog_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_name.add_theme_font_size_override("font_size", 20)
	prog_name.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	prog_name.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.95))
	prog_name.add_theme_constant_override("outline_size", 5)
	crawl_box.add_child(prog_name)
	
	var sp5 = Control.new()
	sp5.custom_minimum_size = Vector2(0, 18)
	crawl_box.add_child(sp5)
	
	var music_title = Label.new()
	music_title.text = "🎵 TRILHA SONORA ORIGINAL"
	music_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_title.add_theme_font_size_override("font_size", 14)
	music_title.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	music_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	music_title.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(music_title)
	
	var music_desc = Label.new()
	music_desc.text = "Defesa do Jardim • Pizzicato • Enchanted Garden"
	music_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_desc.add_theme_font_size_override("font_size", 17)
	music_desc.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
	music_desc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	music_desc.add_theme_constant_override("outline_size", 4)
	crawl_box.add_child(music_desc)
	
	var sp6 = Control.new()
	sp6.custom_minimum_size = Vector2(0, 32)
	crawl_box.add_child(sp6)
	
	var thanks_lbl = Label.new()
	thanks_lbl.text = "🌿 Obrigado por jogar Jardim Miúdo! 🌿"
	thanks_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks_lbl.add_theme_font_size_override("font_size", 20)
	thanks_lbl.add_theme_color_override("font_color", Tokens.VERDE_FOLHA.lightened(0.35))
	thanks_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.15, 0.05, 0.95))
	thanks_lbl.add_theme_constant_override("outline_size", 6)
	crawl_box.add_child(thanks_lbl)
	
	var tw_crawl = create_tween()
	tw_crawl.tween_property(crawl_box, "position:y", -820.0, 20.0).set_trans(Tween.TRANS_LINEAR)
	
	var tree = get_tree()
	if tree:
		var timer = tree.create_timer(20.0)
		timer.timeout.connect(func():
			if ending_sequence_active:
				finish_ending_and_reload_intro()
		)

func finish_ending_and_reload_intro() -> void:
	if not ending_sequence_active:
		return
	ending_sequence_active = false
	
	if ending_container:
		var tw = create_tween()
		tw.tween_property(ending_container, "modulate:a", 0.0, 1.2)
		tw.tween_callback(func():
			GameManager.reset_to_intro()
		)
	else:
		GameManager.reset_to_intro()

func handle_input(event: InputEvent) -> bool:
	if ending_sequence_active:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
			finish_ending_and_reload_intro()
			return true
	if credits_modal and credits_modal.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			close_credits()
			return true
	return false
