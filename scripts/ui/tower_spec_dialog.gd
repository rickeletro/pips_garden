extends Control
class_name TowerSpecDialog

var active_spec_tower: Node3D = null
var spec_cost_label: Label = null
var spec_btn_3a: Button = null
var spec_btn_3b: Button = null

func _ready() -> void:
	name = "SpecializationModal"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	# Fundo escurecido translúcido
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.04, 0.08, 0.05, 0.75)
	add_child(bg_overlay)
	
	# Container Central
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(720, 440)
	
	var sb_main = StyleBoxFlat.new()
	sb_main.bg_color = Color(0.16, 0.22, 0.14, 0.96)
	sb_main.border_color = Tokens.DOURADO_LUZ
	sb_main.set_border_width_all(3)
	sb_main.set_corner_radius_all(16)
	sb_main.shadow_color = Color(0, 0, 0, 0.5)
	sb_main.shadow_size = 14
	main_panel.add_theme_stylebox_override("panel", sb_main)
	center.add_child(main_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	main_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Cabeçalho
	var title_lbl = Label.new()
	title_lbl.text = "🌿 Evolução de Torre — Nível 3"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05, 0.9))
	title_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title_lbl)
	
	spec_cost_label = Label.new()
	spec_cost_label.text = "Custo de Evolução: +6 Gravetos, +4 Engrenagens"
	spec_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spec_cost_label.add_theme_font_size_override("font_size", 14)
	spec_cost_label.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	vbox.add_child(spec_cost_label)
	
	# HBox dos 2 Cards de Especialização
	var cards_hbox = HBoxContainer.new()
	cards_hbox.add_theme_constant_override("separation", 20)
	cards_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(cards_hbox)
	
	# --- CARD 3A: CANHÃO DE ESPINHO ---
	var card_3a = _create_spec_card(
		"🌵 Canhão de Espinho (Nv 3A)",
		"Foco: Alvo Único & Blindados",
		[
			"• Dano por Disparo: 110",
			"• Cadência: 0.5 tiros/s (2.0s)",
			"• DPS Base: 55.0",
			"• Alcance (Raio): 7.0 m",
			"• Especial: Ignora 50% da Armadura"
		],
		Tokens.RUIVO_COBRE,
		"[ 1 ] Escolher Canhão de Espinho"
	)
	cards_hbox.add_child(card_3a.panel)
	spec_btn_3a = card_3a.btn
	spec_btn_3a.pressed.connect(func(): _select_specialization(GardenTower.Specialization.THORN_CANNON))
	
	# --- CARD 3B: CATAPULTA DE SEIVA ---
	var card_3b = _create_spec_card(
		"🍯 Catapulta de Seiva (Nv 3B)",
		"Foco: Dano em Área & Enxame",
		[
			"• Dano por Disparo: 35",
			"• Cadência: 0.6 tiros/s (1.67s)",
			"• DPS Base: 21.0 (Área)",
			"• Alcance (Raio): 5.0 m",
			"• Especial: Splash 2.5m + Poça 15% Slow"
		],
		Tokens.VERDE_FOLHA,
		"[ 2 ] Escolher Catapulta de Seiva"
	)
	cards_hbox.add_child(card_3b.panel)
	spec_btn_3b = card_3b.btn
	spec_btn_3b.pressed.connect(func(): _select_specialization(GardenTower.Specialization.SAP_CATAPULT))
	
	# Rodapé com Botão Cancelar
	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer_hbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Fechar [ESC]"
	cancel_btn.custom_minimum_size = Vector2(160, 36)
	var sb_btn_cancel = StyleBoxFlat.new()
	sb_btn_cancel.bg_color = Color(0.25, 0.15, 0.12, 0.85)
	sb_btn_cancel.set_corner_radius_all(8)
	cancel_btn.add_theme_stylebox_override("normal", sb_btn_cancel)
	cancel_btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	cancel_btn.pressed.connect(close_dialog)
	footer_hbox.add_child(cancel_btn)

func _create_spec_card(title: String, subtitle: String, stats: Array, accent_color: Color, btn_text: String) -> Dictionary:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.17, 0.10, 0.92)
	sb.border_color = accent_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(m)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	m.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 17)
	lbl_title.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	vbox.add_child(lbl_title)
	
	var lbl_sub = Label.new()
	lbl_sub.text = subtitle
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.add_theme_color_override("font_color", accent_color)
	vbox.add_child(lbl_sub)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	for st in stats:
		var lbl_stat = Label.new()
		lbl_stat.text = st
		lbl_stat.add_theme_font_size_override("font_size", 12)
		lbl_stat.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
		vbox.add_child(lbl_stat)
		
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(0, 40)
	var sb_b = StyleBoxFlat.new()
	sb_b.bg_color = accent_color.darkened(0.3)
	sb_b.set_corner_radius_all(8)
	var sb_bh = StyleBoxFlat.new()
	sb_bh.bg_color = accent_color
	sb_bh.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", sb_b)
	btn.add_theme_stylebox_override("hover", sb_bh)
	btn.add_theme_color_override("font_color", Tokens.CREME_PERGAMINHO)
	btn.add_theme_font_size_override("font_size", 13)
	vbox.add_child(btn)
	
	return { "panel": panel, "btn": btn }

func _connect_signals() -> void:
	if GameManager:
		GameManager.request_tower_specialization_dialog.connect(open_dialog)

func open_dialog(tower: Node3D) -> void:
	if not tower or not is_instance_valid(tower):
		return
	active_spec_tower = tower
	
	if spec_cost_label:
		if tower.level == 2:
			spec_cost_label.text = "Evolução Nv 2 ➔ Nv 3 | Custo: +6 Gravetos, +4 Engrenagens (Mochila: %d Gravetos, %d Engrenagens)" % [GameManager.twigs, GameManager.gears]
		else:
			spec_cost_label.text = "Torre Nível 3 ativa! Selecione para alternar a especialização tática."
			
	visible = true
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)

func _select_specialization(spec: GardenTower.Specialization) -> void:
	if not active_spec_tower or not is_instance_valid(active_spec_tower):
		close_dialog()
		return
		
	if active_spec_tower.level == 2:
		active_spec_tower.try_upgrade(spec)
	elif active_spec_tower.level == 3:
		if active_spec_tower.specialization != spec:
			active_spec_tower.toggle_specialization()
		else:
			GameManager.notify("Esta torre já está com esta especialização ativa!", Tokens.DOURADO_LUZ)
			
	close_dialog()

func close_dialog() -> void:
	if visible:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func():
			visible = false
			active_spec_tower = null
		)
	else:
		active_spec_tower = null

func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_E)):
		close_dialog()
		return true
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_select_specialization(GardenTower.Specialization.THORN_CANNON)
			return true
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_select_specialization(GardenTower.Specialization.SAP_CATAPULT)
			return true
	return false
