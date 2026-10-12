extends Node3D
class_name LadybugEgg

# Ovo de Joaninha - Drop especial deixado no chão após derrotar a Mariposa
# Fica no chão pulsando com energia acolhedora por 15 segundos até eclodir uma Joaninha Companheira NPC.

var time_left: float = 15.0
var is_hatched: bool = false

var egg_mesh: MeshInstance3D = null
var glow_light: OmniLight3D = null
var status_label: Label3D = null

func _ready() -> void:
	add_to_group("ladybug_eggs")
	_build_visuals_if_needed()
	GameManager.notify("🥚 Um Ovo de Joaninha caiu suavemente no chão! Eclodirá em 15 segundos.", Tokens.DOURADO_LUZ)

func _build_visuals_if_needed() -> void:
	if not has_node("Visuals"):
		var vis = Node3D.new()
		vis.name = "Visuals"
		add_child(vis)
		
		var egg = MeshInstance3D.new()
		egg.name = "EggMesh"
		var sph = SphereMesh.new()
		sph.radius = 0.32
		sph.height = 0.58
		sph.radial_segments = 16
		sph.rings = 10
		egg.mesh = sph
		egg.position = Vector3(0, 0.29, 0)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.28, 0.18, 1.0) # Vermelho joaninha suave
		mat.roughness = 0.28
		mat.metallic = 0.15
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.65, 0.25)
		mat.emission_energy_multiplier = 0.85
		egg.material_override = mat
		vis.add_child(egg)
		egg_mesh = egg
		
		# Pontinhos pretos decorativos no ovo
		for i in range(4):
			var spot = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.06
			sm.height = 0.04
			spot.mesh = sm
			var spot_mat = StandardMaterial3D.new()
			spot_mat.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
			spot.material_override = spot_mat
			var ang = (i / 4.0) * TAU
			spot.position = Vector3(cos(ang) * 0.28, 0.28 + sin(ang * 2.0) * 0.08, sin(ang) * 0.28)
			egg.add_child(spot)
		
		# Luz aconchegante
		var light = OmniLight3D.new()
		light.name = "OmniLight3D"
		light.light_color = Color(1.0, 0.75, 0.4)
		light.light_energy = 0.9
		light.omni_range = 3.0
		light.position = Vector3(0, 0.4, 0)
		vis.add_child(light)
		glow_light = light
		
		# Label 3D flutuante
		var lbl = Label3D.new()
		lbl.name = "StatusLabel"
		lbl.text = "🥚 Ovo de Joaninha (15s)"
		lbl.font_size = 20
		lbl.outline_size = 4
		lbl.outline_modulate = Color(0.1, 0.08, 0.05, 0.9)
		lbl.modulate = Tokens.CREME_PERGAMINHO
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = Vector3(0, 0.75, 0)
		vis.add_child(lbl)
		status_label = lbl

func _process(delta: float) -> void:
	if is_hatched:
		return
		
	time_left -= delta
	
	var t = Time.get_ticks_msec() * 0.005
	# Pulso suave de incubação do ovo
	var pulse = 1.0 + sin(t * 3.5) * 0.08
	scale = Vector3(pulse, 1.0 + cos(t * 3.5) * 0.05, pulse)
	
	if glow_light:
		glow_light.light_energy = 0.8 + sin(t * 4.0) * 0.4
		
	if status_label:
		var sec = maxi(0, int(ceil(time_left)))
		status_label.text = "🥚 Ovo de Joaninha (%ds)" % sec
		
	if time_left <= 0.0:
		hatch()

func hatch() -> void:
	if is_hatched:
		return
	is_hatched = true
	
	SoundManager.play_sparkle(1.5)
	
	var tree = get_tree()
	if tree:
		var existing_comps = tree.get_nodes_in_group("companions")
		if existing_comps.is_empty():
			var parent_node = get_parent()
			if parent_node:
				var companion_script = load("res://scripts/ladybug_companion.gd")
				if companion_script:
					var companion = companion_script.new()
					parent_node.add_child(companion)
					companion.global_position = Vector3(global_position.x, 0.0, global_position.z)
					GameManager.notify("🐞 A Joaninha Companheira nasceu! Ela patrulha o jardim e caça todos os pulgões!", Tokens.DOURADO_LUZ)
	
	# Efeito de casca se abrindo com partículas e desaparecimento suave
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.4, 0.2, 1.4), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25) if has_method("set_modulate") else null
	tw.tween_callback(queue_free)
