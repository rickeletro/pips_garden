extends Node3D
class_name DirectionalSprite3D

## 2.5D 8-Directional Isometric Sprite Component
## Provides Ragnarok Online style 8-direction animated billboard sprites in Godot 3D.

signal animation_finished(anim_name: String)

const DIRECTIONS: Array[String] = [
	"south",
	"south-east",
	"east",
	"north-east",
	"north",
	"north-west",
	"west",
	"south-west"
]

@export var sprite_pixel_size: float = 0.032:
	set(v):
		sprite_pixel_size = v
		if sprite:
			sprite.pixel_size = v
@export var show_shadow: bool = true
@export var shadow_scale: Vector3 = Vector3(1.8, 1.8, 1.8):
	set(v):
		shadow_scale = v
		if shadow_sprite:
			shadow_sprite.scale = v
@export var sprite_offset_y: float = 1.0:
	set(v):
		sprite_offset_y = v
		if sprite:
			sprite.position.y = v

var sprite: Sprite3D
var shadow_sprite: Sprite3D

# Nested dict: animations[anim_name][dir_name] = Array[Texture2D]
var animations: Dictionary = {}
var current_anim: String = "idle"
var current_dir_idx: int = 0
var current_frame_idx: int = 0
var frame_timer: float = 0.0
var fps: float = 8.0
var is_looping: bool = true
var is_playing: bool = true

# Direction vector (in world XZ space) that the character is facing
var facing_vector: Vector3 = Vector3.BACK # +Z (South) by default

# Damage flash timer
var flash_timer: float = 0.0

func _ready() -> void:
	_setup_sprite_nodes()

func _setup_sprite_nodes() -> void:
	# Main Character Sprite
	sprite = Sprite3D.new()
	sprite.name = "CharacterSprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = sprite_pixel_size
	sprite.position.y = sprite_offset_y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)

	# Ground Oval Drop Shadow (Ragnarok Online style)
	if show_shadow:
		shadow_sprite = Sprite3D.new()
		shadow_sprite.name = "GroundShadow"
		shadow_sprite.axis = Vector3.AXIS_Y
		shadow_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		shadow_sprite.position = Vector3(0, 0.02, 0)
		shadow_sprite.scale = shadow_scale
		shadow_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var shadow_tex = _load_texture_file("res://textures/sprites/common/drop_shadow.png")
		if shadow_tex:
			shadow_sprite.texture = shadow_tex
		add_child(shadow_sprite)

func set_facing(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		facing_vector = Vector3(dir.x, 0.0, dir.z).normalized()

func update_direction_from_camera() -> void:
	if facing_vector.length_squared() < 0.001:
		return
		
	var viewport = get_viewport()
	if not viewport:
		return
	var cam = viewport.get_camera_3d()
	var cam_yaw = 0.0
	if cam:
		cam_yaw = cam.global_rotation.y
		
	# In Godot, +Z is South, -Z is North, +X is East, -X is West.
	var char_angle = atan2(facing_vector.x, facing_vector.z)
	var rel_angle = wrapf(char_angle - cam_yaw, -PI, PI)
	
	# Map rel_angle (-PI..PI) to 8 sectors:
	# 0 = South (facing +Z, toward camera)
	# PI/4 = South-East
	# PI/2 = East
	# 3PI/4 = North-East
	# PI / -PI = North (facing -Z, away from camera)
	# -3PI/4 = North-West
	# -PI/2 = West
	# -PI/4 = South-West
	var sector = round(rel_angle / (PI / 4.0))
	if sector < 0:
		sector += 8
	current_dir_idx = int(sector) % 8

func _process(delta: float) -> void:
	update_direction_from_camera()
	_update_animation(delta)
	
	if shadow_sprite:
		shadow_sprite.global_position.y = 0.02
	
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE

func _update_animation(delta: float) -> void:
	if not is_playing or not animations.has(current_anim):
		return
		
	var dir_name = DIRECTIONS[current_dir_idx]
	var anim_dict: Dictionary = animations[current_anim]
	
	# Fallback if specific direction missing
	var frames: Array = []
	if anim_dict.has(dir_name):
		frames = anim_dict[dir_name]
	elif anim_dict.has("south"):
		frames = anim_dict["south"]
	elif anim_dict.size() > 0:
		frames = anim_dict.values()[0]
		
	if frames.is_empty():
		return
		
	frame_timer += delta
	var frame_duration = 1.0 / maxf(fps, 1.0)
	
	if frame_timer >= frame_duration:
		frame_timer -= frame_duration
		current_frame_idx += 1
		
		if current_frame_idx >= frames.size():
			if is_looping:
				current_frame_idx = 0
			else:
				current_frame_idx = frames.size() - 1
				is_playing = false
				animation_finished.emit(current_anim)
				
	current_frame_idx = clampi(current_frame_idx, 0, frames.size() - 1)
	if sprite and frames.size() > 0:
		sprite.texture = frames[current_frame_idx]

func play(anim_name: String, loop: bool = true, target_fps: float = 8.0, restart: bool = false) -> void:
	if current_anim == anim_name and is_playing and not restart:
		return
		
	current_anim = anim_name
	is_looping = loop
	fps = target_fps
	is_playing = true
	frame_timer = 0.0
	current_frame_idx = 0
	
	# Apply frame immediately
	_update_animation(0.0)

func flash_hit(color: Color = Color(2.5, 0.4, 0.4, 1.0), duration: float = 0.15) -> void:
	if sprite:
		sprite.modulate = color
		flash_timer = duration

## Register animation frames from a directory structure
## Directory structure supported:
## root_path/rotations/{dir}.png -> "idle"
## root_path/animations/{AnimName}/{dir}/frame_{i}.png -> "{AnimName}"
func load_sprites_from_dir(base_dir: String) -> void:
	var global_dir = ProjectSettings.globalize_path(base_dir)
	if not DirAccess.dir_exists_absolute(global_dir):
		push_warning("Directory does not exist: %s" % base_dir)
		return
		
	# Check for "rotations" -> "idle"
	var rot_path = base_dir.path_join("rotations")
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(rot_path)):
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(base_dir.path_join("Idle/rotations"))):
			rot_path = base_dir.path_join("Idle/rotations")
		elif FileAccess.file_exists(ProjectSettings.globalize_path(base_dir.path_join("south.png"))):
			rot_path = base_dir
		
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(rot_path)):
		_load_rotations_as_idle(rot_path)
		
	# Check for animations folder
	var anim_root = base_dir.path_join("animations")
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(anim_root)):
		anim_root = base_dir.path_join("Idle/animations")
		
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(anim_root)):
		_load_animation_folders(anim_root)

	# Fallbacks: if walk, run, or attack don't exist yet, alias cleanly
	if not animations.has("walk") and animations.has("idle"):
		animations["walk"] = animations["idle"]
	if not animations.has("run") and animations.has("idle"):
		animations["run"] = animations["idle"]
	if not animations.has("attack") and animations.has("walk"):
		animations["attack"] = animations["walk"]
	elif not animations.has("attack") and animations.has("idle"):
		animations["attack"] = animations["idle"]

func _load_texture_file(file_path: String) -> Texture2D:
	if ResourceLoader.exists(file_path):
		var res = load(file_path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(file_path)
	if FileAccess.file_exists(global_path):
		var img = Image.new()
		var err = img.load(global_path)
		if err == OK:
			return ImageTexture.create_from_image(img)
	return null

func _load_rotations_as_idle(rot_path: String) -> void:
	animations["idle"] = {}
	for d in DIRECTIONS:
		var file_path = rot_path.path_join("%s.png" % d)
		var tex = _load_texture_file(file_path)
		if not tex:
			var alt_file = rot_path.path_join("%s.png" % d.replace("-", "_"))
			tex = _load_texture_file(alt_file)
		if tex:
			animations["idle"][d] = [tex]

func _load_animation_folders(anim_root: String) -> void:
	var dir = DirAccess.open(anim_root)
	if not dir:
		return
		
	dir.list_dir_begin()
	var sub_name = dir.get_next()
	while sub_name != "":
		if dir.current_is_dir() and not sub_name.begins_with("."):
			var anim_key = sub_name.to_lower()
			if anim_key.contains("run"):
				anim_key = "run"
			elif anim_key.contains("walk") or anim_key.contains("crawl") or anim_key.contains("move") or anim_key.contains("fly") or anim_key.contains("flight") or anim_key.contains("hover") or anim_key.contains("flapping") or anim_key.contains("stalk") or anim_key.contains("step") or anim_key.contains("scuttl"):
				anim_key = "walk"
			elif anim_key.contains("attack") or anim_key.contains("bite") or anim_key.contains("slash") or anim_key.contains("sting") or anim_key.contains("strike") or anim_key.contains("slam") or anim_key.contains("shoot") or anim_key.contains("lung") or anim_key.contains("smash") or anim_key.contains("crush"):
				anim_key = "attack"
			elif anim_key.contains("idle") or anim_key.contains("breath") or anim_key.contains("pulse") or anim_key.contains("glow") or anim_key.contains("sway") or anim_key.contains("bloom"):
				anim_key = "idle"
				
			if not animations.has(anim_key):
				animations[anim_key] = {}
				
			var anim_folder = anim_root.path_join(sub_name)
			_load_dir_frames_for_anim(anim_folder, anim_key)
		sub_name = dir.get_next()

func _load_dir_frames_for_anim(anim_folder: String, anim_key: String) -> void:
	for d in DIRECTIONS:
		var dir_folder = anim_folder.path_join(d)
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_folder)):
			dir_folder = anim_folder.path_join(d.replace("-", "_"))
			
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_folder)):
			var frames: Array[Texture2D] = []
			var frame_dir = DirAccess.open(dir_folder)
			if frame_dir:
				frame_dir.list_dir_begin()
				var fn = frame_dir.get_next()
				var frame_files: Array[String] = []
				while fn != "":
					if fn.ends_with(".png") and not fn.begins_with("."):
						frame_files.append(fn)
					fn = frame_dir.get_next()
				frame_files.sort()
				for ff in frame_files:
					var f_path = dir_folder.path_join(ff)
					var tex = _load_texture_file(f_path)
					if tex:
						frames.append(tex)
			if not frames.is_empty():
				animations[anim_key][d] = frames

