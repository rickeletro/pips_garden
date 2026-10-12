extends Area3D
class_name GiantDewDrop

var is_burst: bool = false

func _ready() -> void:
	add_to_group("dew_drop")
	add_to_group("dewdrops")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_burst:
		return
	if body.is_in_group("player") or body is CharacterBody3D:
		if GameManager.dew_flask_charges < GameManager.MAX_DEW_CHARGES:
			burst()

func on_attack_hit(_pos: Vector3 = Vector3.ZERO) -> void:
	if not is_burst:
		burst()

func burst() -> void:
	if is_burst:
		return
	if GameManager.dew_flask_charges >= GameManager.MAX_DEW_CHARGES:
		GameManager.notify("💧 Frasco de Orvalho cheio (%d/%d)!" % [GameManager.dew_flask_charges, GameManager.MAX_DEW_CHARGES], Tokens.DOURADO_LUZ)
		return
		
	is_burst = true
	
	GameManager.heal_pip(25.0)
	GameManager.add_dew_flask_charge(1)
	SoundManager.play_fairy_dust(-2.0)
	GameManager.notify("💧 Gota de Orvalho coletada! +25 HP e +1 Frasco", Tokens.DOURADO_LUZ)
	
	var tree = get_tree()
	if not tree:
		queue_free()
		return
		
	# Desaparece suavemente no ar sem criar efeito no chão
	var tween = tree.create_tween()
	var mesh_node = get_node_or_null("MeshInstance3D")
	if mesh_node:
		tween.tween_property(mesh_node, "scale", Vector3(1.3, 1.3, 1.3), 0.06)
		tween.tween_property(mesh_node, "scale", Vector3.ZERO, 0.12)
		tween.tween_callback(queue_free)
	else:
		queue_free()
