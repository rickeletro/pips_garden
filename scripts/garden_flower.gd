extends StaticBody3D
class_name GardenFlower

@onready var visuals: Node3D = $Visuals
@onready var petals: Node3D = $Visuals/Petals
@onready var pollen_core: MeshInstance3D = $Visuals/PollenCore

func _ready() -> void:
	add_to_group("flower")
	GameManager.flower = self

func _process(delta: float) -> void:
	# Gentle wind sway
	var time = Time.get_ticks_msec() * 0.001
	if visuals:
		visuals.rotation.z = sin(time * 1.5) * 0.04
		visuals.rotation.x = cos(time * 1.2) * 0.03
	if petals:
		petals.rotation.y += delta * 0.15

func take_damage(amount: float) -> void:
	GameManager.damage_flower(amount)
	# Twitch on hit
	if visuals:
		var tween = get_tree().create_tween()
		tween.tween_property(visuals, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
		tween.tween_property(visuals, "scale", Vector3.ONE, 0.12)
