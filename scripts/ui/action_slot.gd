extends Control
class_name ActionSlot

signal slot_activated

@export var action_name: String = "Ação"
@export var key_shortcut: String = "Q"
@export var icon_texture: Texture2D
@export var cost_description: String = ""
@export var tooltip_info: String = ""

@onready var button: Button = $Button
@onready var icon_rect: TextureRect = $Button/IconRect
@onready var key_badge: Label = $Button/KeyBadge
@onready var action_label: Label = $ActionLabel
@onready var cooldown_overlay: ColorRect = $Button/CooldownOverlay
@onready var cooldown_label: Label = $Button/CooldownOverlay/CooldownLabel
@onready var warning_border: ReferenceRect = $Button/WarningBorder

var is_on_cooldown: bool = false
var cooldown_time: float = 0.0
var cooldown_max: float = 0.0
var is_insufficient: bool = false

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	setup_display()
	set_cooldown(0.0)
	set_insufficient(false)

func setup_display() -> void:
	if icon_rect and icon_texture:
		icon_rect.texture = icon_texture
	if key_badge:
		key_badge.text = key_shortcut
	if action_label:
		action_label.text = action_name
		
	# Rich tooltip
	var tip = "%s [%s]" % [action_name, key_shortcut]
	if not cost_description.is_empty():
		tip += "\nCusto: %s" % cost_description
	if not tooltip_info.is_empty():
		tip += "\n%s" % tooltip_info
	button.tooltip_text = tip

func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_time -= delta
		if cooldown_time <= 0.0:
			set_cooldown(0.0)
		else:
			update_cooldown_visual()

func _on_button_pressed() -> void:
	if not is_on_cooldown:
		slot_activated.emit()
		# Micro-scale punch on click
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(0.92, 0.92), 0.06)
		tween.tween_property(button, "scale", Vector2.ONE, 0.08)

func _on_mouse_entered() -> void:
	if not is_on_cooldown and not button.disabled:
		var tween = create_tween()
		tween.tween_property(icon_rect, "scale", Vector2(1.12, 1.12), 0.1)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(icon_rect, "scale", Vector2.ONE, 0.1)

func set_insufficient(insufficient: bool) -> void:
	is_insufficient = insufficient
	if warning_border:
		warning_border.visible = insufficient
	if icon_rect:
		icon_rect.modulate = Color(0.7, 0.7, 0.7, 0.65) if insufficient else Color.WHITE

func trigger_cooldown(duration: float) -> void:
	cooldown_max = duration
	cooldown_time = duration
	is_on_cooldown = true
	if cooldown_overlay:
		cooldown_overlay.visible = true
	update_cooldown_visual()

func set_cooldown(time_left: float) -> void:
	cooldown_time = time_left
	is_on_cooldown = (cooldown_time > 0.0)
	if cooldown_overlay:
		cooldown_overlay.visible = is_on_cooldown
	if not is_on_cooldown and icon_rect:
		icon_rect.modulate = Color(0.7, 0.7, 0.7, 0.65) if is_insufficient else Color.WHITE

func update_cooldown_visual() -> void:
	if cooldown_label and is_on_cooldown:
		cooldown_label.text = "%0.1fs" % cooldown_time
	if cooldown_overlay and cooldown_max > 0.0:
		var progress = cooldown_time / cooldown_max
		cooldown_overlay.size.y = button.size.y * progress

func update_poison_badge(poison_name: String, poison_color: Color) -> void:
	action_label.text = poison_name
	if icon_rect:
		icon_rect.modulate = poison_color
