extends PanelContainer
class_name BossHUDBar

var boss_name_label: Label
var boss_bar: ProgressBar
var boss_hp_label: Label

func _ready() -> void:
	name = "BossHUDContainer"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	anchor_left = 0.28
	anchor_right = 0.72
	offset_top = 22.0
	offset_bottom = 80.0
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.12, 0.11, 0.14, 0.94)
	frame_style.border_color = Color(0.95, 0.78, 0.22, 1.0) # Dourado régio
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(10)
	frame_style.shadow_color = Color(0, 0, 0, 0.5)
	frame_style.shadow_size = 8
	frame_style.content_margin_left = 18.0
	frame_style.content_margin_right = 18.0
	frame_style.content_margin_top = 8.0
	frame_style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", frame_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	add_child(vbox)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	boss_name_label = Label.new()
	boss_name_label.text = "👑 CHEFE"
	boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	boss_name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(boss_name_label)
	
	boss_hp_label = Label.new()
	boss_hp_label.text = "100%"
	boss_hp_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	boss_hp_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(boss_hp_label)
	
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(0, 16)
	boss_bar.show_percentage = false
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.22, 0.15, 0.18, 0.95)
	bar_bg.set_corner_radius_all(6)
	boss_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.92, 0.22, 0.28, 1.0) # Vermelho rubi vibrante
	bar_fill.border_color = Color(1.0, 0.85, 0.35, 0.85)
	bar_fill.set_border_width_all(1)
	bar_fill.set_corner_radius_all(6)
	boss_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(boss_bar)

func _connect_signals() -> void:
	if GameEvents:
		GameEvents.boss_appeared.connect(_on_boss_appeared)
		GameEvents.boss_health_updated.connect(_on_boss_health_updated)
		GameEvents.boss_defeated.connect(func(_b): _on_boss_vanished())
	
	# Fallback para GameManager
	if GameManager:
		GameManager.boss_appeared.connect(_on_boss_appeared)
		GameManager.boss_health_updated.connect(_on_boss_health_updated)
		GameManager.boss_vanished.connect(_on_boss_vanished)

func _on_boss_appeared(_boss_node: Node3D, b_name: String, max_hp: float) -> void:
	boss_name_label.text = b_name
	boss_bar.max_value = max_hp
	boss_bar.value = max_hp
	boss_hp_label.text = "%d / %d (100%%)" % [int(max_hp), int(max_hp)]
	modulate.a = 0.0
	visible = true
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_boss_health_updated(current_hp: float, max_hp: float, b_name: String) -> void:
	if not visible and current_hp > 0.0:
		_on_boss_appeared(null, b_name, max_hp)
	if b_name != "" and boss_name_label:
		boss_name_label.text = b_name
	if boss_bar:
		boss_bar.max_value = max_hp
		var tw = boss_bar.create_tween()
		tw.tween_property(boss_bar, "value", current_hp, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var pct = clampf((current_hp / max_hp) * 100.0, 0.0, 100.0) if max_hp > 0.0 else 0.0
	if boss_hp_label:
		boss_hp_label.text = "%d / %d (%d%%)" % [int(max(0.0, current_hp)), int(max_hp), int(pct)]

func _on_boss_vanished() -> void:
	if not visible:
		return
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		visible = false
	)
