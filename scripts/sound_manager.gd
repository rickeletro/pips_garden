extends Node

# SoundManager (Singleton) para gerenciar Música (Dia, Noite e Boss) e Efeitos Sonoros (SFX)
# Jardim Miúdo

# Streams de Música
var music_day_stream: AudioStream = null
var music_night_stream: AudioStream = null
var music_boss_stream: AudioStream = null
var music_intro_stream: AudioStream = null
var music_gnome_stream: AudioStream = null

# Streams de SFX
var sfx_sparkle: AudioStream = null
var sfx_buzz: AudioStream = null
var sfx_leaf: AudioStream = null
var sfx_fairy_dust: AudioStream = null
var sfx_wind_dash: AudioStream = null
var sfx_rabbit_squeak: AudioStream = null

var music_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 12

var current_music_mode: String = "INTRO" # "INTRO", "DAY", "NIGHT", "BOSS", "GNOME"
var music_tween: Tween = null

var music_enabled: bool = true:
	set(val):
		music_enabled = val
		if music_player:
			if not music_enabled:
				music_player.stop()
			else:
				if music_player.stream:
					music_player.volume_db = -4.0
					music_player.play()

var sfx_enabled: bool = true:
	set(val):
		sfx_enabled = val
		for p in sfx_players:
			if is_instance_valid(p):
				if not sfx_enabled:
					p.stop()
					p.volume_db = -80.0
				else:
					p.volume_db = 0.0

func toggle_music() -> bool:
	music_enabled = not music_enabled
	return music_enabled

func toggle_sfx() -> bool:
	sfx_enabled = not sfx_enabled
	return sfx_enabled

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_resources()
	_setup_players()
	
	# Inicia com a música da introdução (Pizzicato)
	play_intro_music(0.5)

func _exit_tree() -> void:
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	if music_player:
		music_player.stop()
		music_player.stream = null
	for p in sfx_players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null

func _load_resources() -> void:
	if ResourceLoader.exists("res://audio/music/pizzicato.mp3"):
		music_intro_stream = load("res://audio/music/pizzicato.mp3")
		
	if ResourceLoader.exists("res://audio/music/Enchanted Garden (1).mp3"):
		music_day_stream = load("res://audio/music/Enchanted Garden (1).mp3")
		
	if ResourceLoader.exists("res://audio/music/night Garden.mp3"):
		music_night_stream = load("res://audio/music/night Garden.mp3")
		
	if ResourceLoader.exists("res://audio/music/Defesa do Jardim.mp3"):
		music_boss_stream = load("res://audio/music/Defesa do Jardim.mp3")
	elif ResourceLoader.exists("res://audio/music/boss_battle.wav"):
		music_boss_stream = load("res://audio/music/boss_battle.wav")
		
	if ResourceLoader.exists("res://audio/music/Campfire Sneaks.mp3"):
		music_gnome_stream = load("res://audio/music/Campfire Sneaks.mp3")
	
	if ResourceLoader.exists("res://audio/sfx/fairy_sparkle.wav"):
		sfx_sparkle = load("res://audio/sfx/fairy_sparkle.wav")
		
	if ResourceLoader.exists("res://audio/sfx/bee_buzz.wav"):
		sfx_buzz = load("res://audio/sfx/bee_buzz.wav")
		
	if ResourceLoader.exists("res://audio/sfx/leaf_rustle.wav"):
		sfx_leaf = load("res://audio/sfx/leaf_rustle.wav")
		
	if ResourceLoader.exists("res://audio/sfx/fairy_dust.wav"):
		sfx_fairy_dust = load("res://audio/sfx/fairy_dust.wav")
		
	if ResourceLoader.exists("res://audio/sfx/wind_dash_swoosh.wav"):
		sfx_wind_dash = load("res://audio/sfx/wind_dash_swoosh.wav")
		
	if ResourceLoader.exists("res://audio/sfx/rabbit_squeak.wav"):
		sfx_rabbit_squeak = load("res://audio/sfx/rabbit_squeak.wav")

func _setup_players() -> void:
	# Reprodutor de Música
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	
	# Pool de Reprodutores de SFX
	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

# --- CONTROLE DE MÚSICA (INTRO / DIA / NOITE / BOSS) ---

func play_intro_music(fade_duration: float = 1.5, target_volume_db: float = -4.0) -> void:
	current_music_mode = "INTRO"
	var stream_to_use = music_intro_stream if music_intro_stream else music_day_stream
	_switch_music_stream(stream_to_use, fade_duration, target_volume_db)

func play_day_music(fade_duration: float = 2.5, target_volume_db: float = -6.0) -> void:
	current_music_mode = "DAY"
	_switch_music_stream(music_day_stream, fade_duration, target_volume_db)

func play_night_music(fade_duration: float = 3.5, target_volume_db: float = -5.0) -> void:
	current_music_mode = "NIGHT"
	_switch_music_stream(music_night_stream, fade_duration, target_volume_db)

func play_boss_music(fade_duration: float = 1.8, target_volume_db: float = -4.5) -> void:
	current_music_mode = "BOSS"
	var stream_to_use = music_boss_stream if music_boss_stream else music_night_stream
	_switch_music_stream(stream_to_use, fade_duration, target_volume_db)

func play_gnome_sneaks_music(fade_duration: float = 1.6, target_volume_db: float = -4.0) -> void:
	current_music_mode = "GNOME"
	var stream_to_use = music_gnome_stream if music_gnome_stream else music_night_stream
	_switch_music_stream(stream_to_use, fade_duration, target_volume_db)

func _switch_music_stream(new_stream: AudioStream, fade_duration: float, target_vol: float) -> void:
	if not new_stream or not music_player:
		return
		
	if not music_enabled:
		target_vol = -80.0

	if music_tween and music_tween.is_valid():
		music_tween.kill()
		
	if music_player.playing and music_player.stream == new_stream:
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", target_vol, fade_duration)
		return
		
	if music_player.playing:
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -50.0, fade_duration * 0.4)
		music_tween.tween_callback(func():
			music_player.stream = new_stream
			music_player.play()
		)
		music_tween.tween_property(music_player, "volume_db", target_vol, fade_duration * 0.6)
	else:
		music_player.stream = new_stream
		music_player.volume_db = -50.0
		music_player.play()
		music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", target_vol, fade_duration)

func stop_music() -> void:
	if music_tween and music_tween.is_valid():
		music_tween.kill()
	if music_player:
		music_player.stop()

func _on_music_finished() -> void:
	# Loop contínuo da música atual
	if music_player and music_player.stream:
		music_player.play()

# --- SFX GERAIS ---

func play_sparkle(volume_db: float = -4.0, pitch_var: float = 0.15) -> void:
	if not sfx_enabled:
		return
	if sfx_sparkle:
		var p = _get_available_sfx_player()
		p.stream = sfx_sparkle
		p.volume_db = volume_db
		p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
		p.play()

func play_bee_buzz(volume_db: float = -14.0) -> void:
	if not sfx_enabled:
		return
	if sfx_buzz:
		var p = _get_available_sfx_player()
		p.stream = sfx_buzz
		p.volume_db = volume_db
		p.pitch_scale = randf_range(0.95, 1.1)
		p.play()

var last_pickup_time: float = 0.0
var consecutive_pickup_idx: int = 0
const PENTATONIC_PITCHES = [1.0, 1.122, 1.260, 1.498, 1.682] # Dó, Ré, Mi, Sol, Lá

func play_leaf_pickup(volume_db: float = -3.0, _pitch_var: float = 0.12) -> void:
	if not sfx_enabled:
		return
	var current_time = Time.get_ticks_msec() * 0.001
	if current_time - last_pickup_time < 1.5:
		consecutive_pickup_idx += 1
	else:
		consecutive_pickup_idx = 0
	last_pickup_time = current_time
	
	var note_idx = consecutive_pickup_idx % 5
	var pitch = PENTATONIC_PITCHES[note_idx]
	
	if sfx_leaf:
		var p = _get_available_sfx_player()
		p.stream = sfx_leaf
		p.volume_db = volume_db
		p.pitch_scale = pitch
		p.play()
	elif sfx_sparkle:
		var p = _get_available_sfx_player()
		p.stream = sfx_sparkle
		p.volume_db = volume_db
		p.pitch_scale = pitch
		p.play()
		
	# 5º item consecutivo emite brilho sonoro de sino de vento / harpa
	if consecutive_pickup_idx > 0 and (consecutive_pickup_idx % 5) == 4:
		play_sparkle(-2.0, 0.05)

func play_hit_flesh(pitch_scale: float = 1.0, volume_db: float = -4.0) -> void:
	if not sfx_enabled:
		return
	if sfx_sparkle:
		var p = _get_available_sfx_player()
		p.stream = sfx_sparkle
		p.volume_db = volume_db
		p.pitch_scale = pitch_scale * randf_range(0.9, 1.1)
		p.play()

func play_explosion(volume_db: float = -4.0) -> void:
	if not sfx_enabled:
		return
	if sfx_fairy_dust:
		var p = _get_available_sfx_player()
		p.stream = sfx_fairy_dust
		p.volume_db = volume_db
		p.pitch_scale = 0.8
		p.play()
	elif sfx_sparkle:
		play_sparkle(volume_db, 0.2)

func play_wind_dash(pitch_scale: float = 1.0, volume_db: float = -1.5) -> void:
	if not sfx_enabled:
		return
	if sfx_wind_dash:
		var p = _get_available_sfx_player()
		p.stream = sfx_wind_dash
		p.volume_db = volume_db
		p.pitch_scale = pitch_scale * randf_range(0.96, 1.06)
		p.play()
	elif sfx_fairy_dust:
		play_fairy_dust(volume_db)

func play_fairy_dust(volume_db: float = -3.0) -> void:
	if not sfx_enabled:
		return
	if sfx_fairy_dust:
		var p = _get_available_sfx_player()
		p.stream = sfx_fairy_dust
		p.volume_db = volume_db
		p.pitch_scale = randf_range(0.95, 1.05)
		p.play()
	elif sfx_sparkle:
		play_sparkle(volume_db, 0.2)

func play_rabbit_squeak(volume_db: float = -2.0, pitch_var: float = 0.1) -> void:
	if not sfx_enabled:
		return
	if sfx_rabbit_squeak:
		var p = _get_available_sfx_player()
		p.stream = sfx_rabbit_squeak
		p.volume_db = volume_db
		p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
		p.play()
	elif sfx_sparkle:
		play_sparkle(volume_db, 0.25)

func play_pop(volume_db: float = -4.0, pitch_var: float = 0.15) -> void:
	if not sfx_enabled:
		return
	if sfx_leaf:
		var p = _get_available_sfx_player()
		p.stream = sfx_leaf
		p.volume_db = volume_db
		p.pitch_scale = randf_range(1.2 - pitch_var, 1.2 + pitch_var)
		p.play()
	elif sfx_sparkle:
		play_sparkle(volume_db, pitch_var)

# --- FILTRO DE ÁUDIO PARA TUTORIAL ---
var tutorial_lp_filter: AudioEffectLowPassFilter = null
var tutorial_filter_idx: int = -1

func apply_tutorial_audio_filter(enabled: bool) -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		if enabled:
			if tutorial_lp_filter == null:
				tutorial_lp_filter = AudioEffectLowPassFilter.new()
				tutorial_lp_filter.cutoff_hz = 1200.0
				tutorial_lp_filter.resonance = 0.5
				AudioServer.add_bus_effect(master_idx, tutorial_lp_filter)
				tutorial_filter_idx = AudioServer.get_bus_effect_count(master_idx) - 1
			else:
				AudioServer.set_bus_effect_enabled(master_idx, tutorial_filter_idx, true)
			if music_player:
				music_player.volume_db = -12.0
		else:
			if tutorial_lp_filter != null and tutorial_filter_idx >= 0:
				AudioServer.set_bus_effect_enabled(master_idx, tutorial_filter_idx, false)
			if music_player:
				music_player.volume_db = -6.0


