extends Area3D
class_name GardenPickup

@export_enum("TWIG", "GEAR", "SEED", "FAIRY_TEAR", "SILVER_POLLEN", "MAGNET_AMBER", "REVITALIZING_NECTAR", "ROYAL_JELLY") var item_type: String = "TWIG"

@onready var mesh_twig: MeshInstance3D = $Visuals/TwigMesh
@onready var mesh_gear: MeshInstance3D = $Visuals/GearMesh
@onready var seed_visuals: Node3D = $Visuals.get_node_or_null("SeedVisuals")
@onready var mesh_seed: Node3D = $Visuals.get_node_or_null("SeedMesh") if not seed_visuals else seed_visuals
@onready var visuals: Node3D = $Visuals

var custom_reward_mesh: MeshInstance3D = null
var player_node: Node3D = null
var magnet_speed: float = 14.0
var is_collected: bool = false
var start_y: float = 0.25

func _ready() -> void:
	add_to_group("pickups")
	start_y = position.y
	setup_custom_reward_visual()
	update_type_visuals()
	body_entered.connect(_on_body_entered)

func setup_custom_reward_visual() -> void:
	if custom_reward_mesh:
		return
		
	var is_reward = item_type in ["FAIRY_TEAR", "SILVER_POLLEN", "MAGNET_AMBER", "REVITALIZING_NECTAR", "ROYAL_JELLY"]
	if not is_reward:
		return
		
	custom_reward_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.52
	sphere.radial_segments = 14
	sphere.rings = 8
	custom_reward_mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.5
	mat.roughness = 0.1
	mat.rim_enabled = true
	mat.rim = 0.8
	
	match item_type:
		"FAIRY_TEAR":
			mat.albedo_color = Color(0.45, 0.92, 1.0, 0.9)
			mat.emission = Color(0.4, 0.9, 1.0)
		"SILVER_POLLEN":
			mat.albedo_color = Color(0.92, 0.95, 1.0, 0.95)
			mat.emission = Color(0.85, 0.9, 1.0)
		"MAGNET_AMBER":
			mat.albedo_color = Color(1.0, 0.65, 0.15, 0.95)
			mat.emission = Color(1.0, 0.7, 0.2)
		"REVITALIZING_NECTAR":
			mat.albedo_color = Color(1.0, 0.25, 0.55, 0.95)
			mat.emission = Color(1.0, 0.3, 0.6)
		"ROYAL_JELLY":
			mat.albedo_color = Color(1.0, 0.88, 0.25, 0.95)
			mat.emission = Color(1.0, 0.85, 0.2)
			
	custom_reward_mesh.material_override = mat
	visuals.add_child(custom_reward_mesh)

func update_type_visuals() -> void:
	if mesh_twig: mesh_twig.visible = (item_type == "TWIG")
	if mesh_gear: mesh_gear.visible = (item_type == "GEAR")
	if seed_visuals:
		seed_visuals.visible = (item_type == "SEED")
	elif mesh_seed:
		mesh_seed.visible = (item_type == "SEED")
	if custom_reward_mesh:
		custom_reward_mesh.visible = item_type in ["FAIRY_TEAR", "SILVER_POLLEN", "MAGNET_AMBER", "REVITALIZING_NECTAR", "ROYAL_JELLY"]

func _process(delta: float) -> void:
	if is_collected:
		return
		
	var time = Time.get_ticks_msec() * 0.003
	visuals.position.y = sin(time * 2.0) * 0.1
	visuals.rotation.y += delta * 2.5
	
	if not player_node or not is_instance_valid(player_node):
		if GameManager.heroine:
			player_node = GameManager.heroine
		elif is_inside_tree() and get_tree():
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				player_node = players[0]
			
	if player_node and is_instance_valid(player_node):
		var dist = global_position.distance_to(player_node.global_position)
		var attract_range = GameManager.magnet_radius if GameManager.get("magnet_radius") != null else 2.2
		
		# Itens de recursos comuns (Graveto, Engrenagem, Semente) não são atraídos se a mochila estiver cheia
		var is_bag_resource = item_type in ["TWIG", "GEAR", "SEED"]
		if is_bag_resource and not GameManager.can_add_item():
			return
			
		if dist < attract_range:
			var dir = (player_node.global_position + Vector3(0, 0.4, 0) - global_position).normalized()
			global_position += dir * magnet_speed * delta
			if dist < 0.6:
				collect()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_collected:
		collect()

func collect() -> void:
	is_collected = true
	var success = false
	match item_type:
		"TWIG":
			success = GameManager.add_twig()
		"GEAR":
			success = GameManager.add_gear()
		"SEED":
			success = GameManager.add_seed()
		"FAIRY_TEAR":
			success = GameManager.add_fairy_tear()
		"SILVER_POLLEN":
			success = GameManager.add_silver_pollen()
		"MAGNET_AMBER":
			success = GameManager.add_magnet_amber()
		"REVITALIZING_NECTAR":
			success = GameManager.add_revitalizing_nectar()
		"ROYAL_JELLY":
			success = GameManager.add_royal_jelly()
			
	if success:
		if item_type in ["FAIRY_TEAR", "SILVER_POLLEN", "MAGNET_AMBER", "REVITALIZING_NECTAR", "ROYAL_JELLY"]:
			SoundManager.play_fairy_dust()
		else:
			SoundManager.play_leaf_pickup()
				
		if player_node and player_node.has_method("play_collect_hop"):
			player_node.play_collect_hop()
		var tree = get_tree()
		if tree:
			var tween = tree.create_tween()
			tween.tween_property(visuals, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
			tween.tween_callback(queue_free)
		else:
			queue_free()
	else:
		is_collected = false
