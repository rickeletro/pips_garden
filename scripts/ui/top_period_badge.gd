extends PanelContainer
class_name TopPeriodBadge

var badge_label: Label

func _ready() -> void:
	name = "TopPeriodBadge"
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-110, 16)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(220, 42)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.18, 0.12, 0.88)
	sb.border_color = Tokens.DOURADO_LUZ
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	add_theme_stylebox_override("panel", sb)
	
	badge_label = Label.new()
	badge_label.text = "☀️ Dia 1"
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 18)
	badge_label.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
	badge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	badge_label.add_theme_constant_override("shadow_offset_x", 1)
	badge_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(badge_label)
	
	_connect_signals()
	update_badge()

func _connect_signals() -> void:
	if GameEvents:
		GameEvents.period_changed.connect(func(_p, _d, _n): update_badge())
		GameEvents.wave_state_changed.connect(func(_s, _w): update_badge())
	if GameManager:
		GameManager.wave_state_changed.connect(func(_s, _w): update_badge())

func update_badge() -> void:
	if not badge_label:
		return
		
	visible = not GameManager.is_in_intro and GameManager.wave_state != GameManager.WaveState.DEFEAT and GameManager.wave_state != GameManager.WaveState.VICTORY
	
	var period = GameManager.current_period
	var day_num = GameManager.current_day
	var night_num = GameManager.current_night
	
	if period.begins_with("BOSS"):
		match period:
			"BOSS_SNAIL": badge_label.text = "🐌 Dia 1 — Caramujo Ancião"
			"BOSS_MOTH": badge_label.text = "🦋 Noite 1 — Mariposa Rainha"
			"BOSS_MANTIS": badge_label.text = "🪲 Dia 2 — Louva-a-Deus Imperial"
			"BOSS_SPIDER": badge_label.text = "🕷️ Noite 2 — Aranha Sombria"
			"BOSS_WASP_QUEEN": badge_label.text = "🐝 Dia 3 — Vespa Imperatriz"
			"BOSS_SCORPION": badge_label.text = "🦂 Noite 3 — Tirano Noturno"
			_: badge_label.text = "⚔️ Batalha de Chefe"
		badge_label.add_theme_color_override("font_color", Tokens.PERIGO)
	elif period == "NIGHT":
		if night_num == 3:
			badge_label.text = "🌕 Noite 3 (Final)"
		else:
			badge_label.text = "🌙 Noite %d" % night_num
		badge_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	else:
		badge_label.text = "☀️ Dia %d" % day_num
		badge_label.add_theme_color_override("font_color", Tokens.DOURADO_LUZ)
