extends EnemyBase
class_name Wasp

@onready var wing_left: MeshInstance3D = $Visuals/WingLeft
@onready var wing_right: MeshInstance3D = $Visuals/WingRight

func _init() -> void:
	max_hp = 75.0
	base_speed = 3.1
	attack_damage = 12.0
	attack_interval = 1.0
	xp_reward = 25
	is_flying = true

func _ready() -> void:
	super._ready()
	# Hover at 1.8m height
	global_position.y = 1.8

func _physics_process(delta: float) -> void:
	super(delta)
	
	# Rapid wing buzz animation
	var buzz = sin(Time.get_ticks_msec() * 0.08) * 35.0
	if wing_left:
		wing_left.rotation_degrees.z = buzz
	if wing_right:
		wing_right.rotation_degrees.z = -buzz
		
	# Gentle hover bobbing
	if visual_root:
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.008) * 0.15
