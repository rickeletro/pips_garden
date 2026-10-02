extends Node3D
class_name TowerGhost

@onready var tent_mesh: MeshInstance3D = $TentMesh
@onready var indicator_ring: MeshInstance3D = $IndicatorRing

var valid_mat: StandardMaterial3D
var invalid_mat: StandardMaterial3D

func _ready() -> void:
	valid_mat = StandardMaterial3D.new()
	valid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	valid_mat.albedo_color = Color(Tokens.VERDE_FOLHA.r, Tokens.VERDE_FOLHA.g, Tokens.VERDE_FOLHA.b, 0.45)
	valid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	invalid_mat = StandardMaterial3D.new()
	invalid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_mat.albedo_color = Color(Tokens.PERIGO.r, Tokens.PERIGO.g, Tokens.PERIGO.b, 0.45)
	invalid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	set_valid(true)

func set_valid(is_valid: bool) -> void:
	var mat = valid_mat if is_valid else invalid_mat
	if tent_mesh: tent_mesh.material_override = mat
	if indicator_ring: indicator_ring.material_override = mat
