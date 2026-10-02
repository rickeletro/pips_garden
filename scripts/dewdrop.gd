extends Area3D
class_name GiantDewDrop

var is_burst: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_burst:
		return
	if body.is_in_group("player"):
		burst()

func burst() -> void:
	is_burst = true
	var tree = get_tree()
	if not tree:
		queue_free()
		return
		
	# Water splash scale pop
	var tween = tree.create_tween()
	tween.tween_property($MeshInstance3D, "scale", Vector3(1.6, 0.2, 1.6), 0.1)
	tween.parallel().tween_property($MeshInstance3D, "position:y", 0.02, 0.1)
	tween.tween_property($MeshInstance3D, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(queue_free)
