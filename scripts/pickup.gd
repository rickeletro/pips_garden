extends Area3D
class_name GardenPickup

@export_enum("TWIG", "GEAR", "SEED") var item_type: String = "TWIG"

@onready var mesh_twig: MeshInstance3D = $Visuals/TwigMesh
@onready var mesh_gear: MeshInstance3D = $Visuals/GearMesh
@onready var mesh_seed: MeshInstance3D = $Visuals/SeedMesh
@onready var visuals: Node3D = $Visuals

var player_node: Node3D = null
var magnet_speed: float = 12.0
var is_collected: bool = false
var start_y: float = 0.25

func _ready() -> void:
	add_to_group("pickups")
	start_y = position.y
	update_type_visuals()
	body_entered.connect(_on_body_entered)

func update_type_visuals() -> void:
	if mesh_twig: mesh_twig.visible = (item_type == "TWIG")
	if mesh_gear: mesh_gear.visible = (item_type == "GEAR")
	if mesh_seed: mesh_seed.visible = (item_type == "SEED")

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
		if dist < 2.2:
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
			
	if success:
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
