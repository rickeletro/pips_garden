extends Node3D
class_name DandelionClock

@onready var visuals: Node3D = $Visuals
@onready var stem: MeshInstance3D = $Visuals/Stem
@onready var clock_head: Node3D = $Visuals/ClockHead
@onready var fluff_globe: Node3D = $Visuals/ClockHead/FluffGlobe
@onready var receptacle: MeshInstance3D = $Visuals/ClockHead/Receptacle

const REGROW_TIME: float = 22.0
var is_harvested: bool = false
var regrow_timer: float = 0.0
var sway_offset: float = 0.0

var pappus_scene: PackedScene = preload("res://scenes/environment/flying_seed_pappus.tscn")

func _ready() -> void:
	add_to_group("dandelion")
	sway_offset = randf() * 100.0

func _process(delta: float) -> void:
	# Suave oscilação ao vento
	var t = Time.get_ticks_msec() * 0.001 + sway_offset
	if visuals:
		visuals.rotation.x = sin(t * 1.5) * 0.035
		visuals.rotation.z = cos(t * 1.2) * 0.035
		
	# Regeneração das sementes ao longo do tempo
	if is_harvested:
		regrow_timer -= delta
		var progress = clampf(1.0 - (regrow_timer / REGROW_TIME), 0.0, 1.0)
		if fluff_globe:
			fluff_globe.scale = Vector3.ONE * progress
			fluff_globe.visible = (progress > 0.02)
			
		if regrow_timer <= 0.0:
			is_harvested = false
			if fluff_globe:
				fluff_globe.visible = true
				var pop_tween = create_tween()
				pop_tween.tween_property(fluff_globe, "scale", Vector3(1.22, 1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				pop_tween.tween_property(fluff_globe, "scale", Vector3.ONE, 0.16)

func on_attack_hit(attacker_pos: Vector3) -> void:
	if is_harvested:
		# Pequeno tremor indicando que ainda está recarregando
		if visuals:
			var tw = create_tween()
			tw.tween_property(visuals, "position:x", 0.08, 0.05)
			tw.tween_property(visuals, "position:x", -0.08, 0.05)
			tw.tween_property(visuals, "position:x", 0.0, 0.08)
		return
		
	is_harvested = true
	regrow_timer = REGROW_TIME
	
	# Recuo orgânico do caule para longe do golpe
	var bend_dir = (global_position - attacker_pos).normalized()
	bend_dir.y = 0.0
	if bend_dir.length_squared() < 0.01:
		bend_dir = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
		
	if visuals:
		var stem_tween = create_tween()
		stem_tween.tween_property(visuals, "rotation:z", bend_dir.x * 0.45, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stem_tween.tween_property(visuals, "rotation:z", -bend_dir.x * 0.25, 0.12)
		stem_tween.tween_property(visuals, "rotation:z", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	# Animação de dispersão da pluma (pom-pom de sementes estoura suavemente)
	if fluff_globe:
		var burst_tween = create_tween()
		burst_tween.tween_property(fluff_globe, "scale", Vector3(1.35, 1.35, 1.35), 0.08)
		burst_tween.tween_property(fluff_globe, "scale", Vector3.ZERO, 0.14)
		burst_tween.tween_callback(func(): fluff_globe.visible = false)
		
	# Dispara as sementes voando com paraquedas (pappus) pelo ar!
	spawn_flying_pappus(bend_dir)
	GameManager.notify("Dente-de-leão soprado! Recolha as sementes que estão voando!", Tokens.DOURADO_LUZ)

func spawn_flying_pappus(impact_dir: Vector3) -> void:
	if not pappus_scene:
		return
		
	var parent_node = get_parent()
	if not parent_node:
		parent_node = self
		
	var spawn_origin = clock_head.global_position if clock_head else (global_position + Vector3(0, 2.5, 0))
	var seed_count = randi_range(5, 7)
	
	for i in range(seed_count):
		var pappus = pappus_scene.instantiate()
		if pappus:
			parent_node.add_child(pappus)
			
			# Espalhamento radial em 360° com viés na direção do golpe
			var base_angle = (float(i) / seed_count) * TAU
			var angle = base_angle + randf_range(-0.35, 0.35)
			var spread_dir = Vector3(cos(angle), 0.0, sin(angle))
			# Mistura direção do vento/golpe
			var final_dir = (spread_dir * 0.75 + impact_dir * 0.55).normalized()
			
			if pappus.has_method("launch"):
				pappus.launch(spawn_origin, final_dir)
