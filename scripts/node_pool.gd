extends Node

# ==============================================================================
# 💧 NODE POOL — HIGH PERFORMANCE OBJECT POOLING (JARDIM MIÚDO)
# ==============================================================================
# Reutiliza nós de projéteis, faíscas, poças e efeitos visuais durante hordas intensas,
# eliminando 'stutters' de GC e micro-alocações repetidas de memória.
# ==============================================================================

var _projectile_pool: Array[Node3D] = []
var _puddle_pool: Array[MeshInstance3D] = []
var _spark_pool: Array[MeshInstance3D] = []

var _pool_container_3d: Node3D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_pool_containers()
	prewarm(30)

func _create_pool_containers() -> void:
	if _pool_container_3d == null:
		_pool_container_3d = Node3D.new()
		_pool_container_3d.name = "GlobalNodePool3D"
		add_child(_pool_container_3d)

## Pré-aquece instâncias no pool para que não haja overhead inicial de compilação/alocação
func prewarm(count: int = 20) -> void:
	for i in range(count):
		var proj = _create_new_projectile_node()
		_recycle_projectile(proj)
		
		var puddle = _create_new_puddle_node()
		_recycle_puddle(puddle)

# ==============================================================================
# PROJÉTEIS (TORRES E INIMIGOS)
# ==============================================================================

func _create_new_projectile_node() -> Node3D:
	var root = Node3D.new()
	root.name = "PooledProjectile"
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	root.add_child(mesh_inst)
	_pool_container_3d.add_child(root)
	root.visible = false
	return root

func acquire_projectile() -> Node3D:
	var proj: Node3D = null
	while _projectile_pool.size() > 0:
		var candidate = _projectile_pool.pop_back()
		if is_instance_valid(candidate):
			proj = candidate
			break
	
	if proj == null:
		proj = _create_new_projectile_node()
		
	proj.visible = true
	return proj

func _recycle_projectile(proj: Node3D) -> void:
	if not is_instance_valid(proj):
		return
	proj.visible = false
	proj.global_position = Vector3(0, -500, 0) # Afasta da câmera
	if proj.get_parent() != _pool_container_3d:
		proj.reparent(_pool_container_3d)
	_projectile_pool.append(proj)

## Spawna e anima um projétil entre 2 pontos com reciclagem automática
func spawn_projectile(
	from_pos: Vector3,
	to_pos: Vector3,
	duration: float,
	mesh: Mesh,
	material: Material,
	rotation_x: float = 0.0,
	on_hit_callback: Callable = Callable()
) -> Node3D:
	var proj = acquire_projectile()
	proj.global_position = from_pos
	
	var mesh_inst = proj.get_node_or_null("Mesh") as MeshInstance3D
	if mesh_inst:
		mesh_inst.mesh = mesh
		mesh_inst.material_override = material
		mesh_inst.rotation_degrees.x = rotation_x
	
	var tree = get_tree()
	if tree:
		var tw = tree.create_tween()
		tw.tween_property(proj, "global_position", to_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			if on_hit_callback.is_valid():
				on_hit_callback.call()
			_recycle_projectile(proj)
		)
	else:
		if on_hit_callback.is_valid():
			on_hit_callback.call()
		_recycle_projectile(proj)
		
	return proj

# ==============================================================================
# POÇAS E EFEITOS NO CHÃO (SEIVA / VENENO)
# ==============================================================================

func _create_new_puddle_node() -> MeshInstance3D:
	var puddle = MeshInstance3D.new()
	puddle.name = "PooledPuddle"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.3
	cyl.height = 0.04
	puddle.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.92, 0.65, 0.15, 0.65)
	mat.roughness = 0.1
	puddle.material_override = mat
	
	_pool_container_3d.add_child(puddle)
	puddle.visible = false
	return puddle

func acquire_puddle() -> MeshInstance3D:
	var puddle: MeshInstance3D = null
	while _puddle_pool.size() > 0:
		var candidate = _puddle_pool.pop_back()
		if is_instance_valid(candidate):
			puddle = candidate
			break
			
	if puddle == null:
		puddle = _create_new_puddle_node()
		
	puddle.visible = true
	return puddle

func _recycle_puddle(puddle: MeshInstance3D) -> void:
	if not is_instance_valid(puddle):
		return
	puddle.visible = false
	puddle.global_position = Vector3(0, -500, 0)
	if puddle.get_parent() != _pool_container_3d:
		puddle.reparent(_pool_container_3d)
	_puddle_pool.append(puddle)

## Spawna e faz fade de poça no chão (ex: Catapulta de Seiva)
func spawn_puddle_fx(pos: Vector3, color: Color = Color(0.92, 0.65, 0.15, 0.65), radius: float = 1.3, duration: float = 2.5) -> void:
	var puddle = acquire_puddle()
	puddle.global_position = Vector3(pos.x, 0.05, pos.z)
	
	var cyl = puddle.mesh as CylinderMesh
	if cyl:
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		
	var mat = puddle.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		
	var tree = get_tree()
	if tree and mat:
		var tw = tree.create_tween()
		tw.tween_interval(duration)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(func():
			_recycle_puddle(puddle)
		)
	else:
		_recycle_puddle(puddle)

# ==============================================================================
# LIMPEZA GLOBAL
# ==============================================================================

func clear_all() -> void:
	for p in _projectile_pool:
		if is_instance_valid(p):
			p.queue_free()
	_projectile_pool.clear()
	
	for pu in _puddle_pool:
		if is_instance_valid(pu):
			pu.queue_free()
	_puddle_pool.clear()
	
	for s in _spark_pool:
		if is_instance_valid(s):
			s.queue_free()
	_spark_pool.clear()
