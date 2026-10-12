extends EnemyBase
class_name Firefly

# Vagalume Inimigo Noturno (Voador e Bioluminescente)
@onready var wing_left: MeshInstance3D = $Visuals/WingLeft
@onready var wing_right: MeshInstance3D = $Visuals/WingRight
@onready var glow_orb: MeshInstance3D = $Visuals/Lantern
@onready var glow_light: OmniLight3D = $Visuals/Lantern/OmniLight3D

var glow_mat: StandardMaterial3D = null

func _init() -> void:
	max_hp = 90.0
	base_speed = 3.2
	attack_damage = 13.0
	attack_interval = 0.95
	xp_reward = 35
	is_flying = true

func _ready() -> void:
	super._ready()
	global_position.y = 1.8
	
	if glow_orb:
		var mat = glow_orb.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			glow_mat = mat.duplicate() as StandardMaterial3D
			glow_orb.material_override = glow_mat

func _physics_process(delta: float) -> void:
	super(delta)
	
	# Batimento rápido de asas
	var buzz = sin(Time.get_ticks_msec() * 0.08) * 35.0
	if wing_left:
		wing_left.rotation_degrees.z = buzz
	if wing_right:
		wing_right.rotation_degrees.z = -buzz
		
	# Pulso de bioluminescência suave do abdômen na escuridão
	var pulse = (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5 # 0.0 a 1.0
	var energy = lerp(0.8, 2.5, pulse)
	if glow_light:
		glow_light.light_energy = energy
	if glow_mat:
		glow_mat.emission_energy_multiplier = energy * 1.5
		
	# Flutuação aérea
	if visual_root:
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.008) * 0.15
