extends Node
## Perf Probe — roda o jogo real em headless, força ondas e mede o custo de CPU por frame.
## Uso: Godot --headless --path . scenes/tools/perf_probe.tscn

const TOTAL_FRAMES := 3600
const SPIKE_MS := 25.0

var root_node: Node = null
var heroine: Node = null
var frame := 0
var samples: Array[float] = []
var spikes: Array[String] = []
var last_usec := 0

func _ready() -> void:
	var main_scene = load("res://scenes/main.tscn")
	root_node = main_scene.instantiate()
	add_child(root_node)
	await get_tree().process_frame
	await get_tree().process_frame
	heroine = root_node.get_node_or_null("Heroine")
	GameManager.start_game_from_intro()
	last_usec = Time.get_ticks_usec()
	print("[probe] start nodes=%d objects=%d" % [_nodes(), _objs()])

func _nodes() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

func _objs() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))

func _process(_delta: float) -> void:
	if heroine == null:
		return
	frame += 1
	var now := Time.get_ticks_usec()
	var frame_ms := (now - last_usec) / 1000.0
	last_usec = now
	samples.append(frame_ms)

	# Pula countdown e força próxima onda sempre que estiver em preparação
	if GameManager.wave_state == GameManager.WaveState.PREPARATION:
		GameManager.start_next_wave()

	# Fase de estresse: horda de 60 pragas simultâneas
	if frame == 1800:
		var scenes := [load("res://scenes/enemies/aphid.tscn"), load("res://scenes/enemies/caterpillar.tscn"), load("res://scenes/enemies/wasp.tscn")]
		for i in range(60):
			var e = scenes[i % scenes.size()].instantiate()
			root_node.add_child(e)
			var ang := randf() * TAU
			e.global_position = Vector3(cos(ang) * 20.0, 0.0, sin(ang) * 20.0)
		print("[probe] STRESS: +60 inimigos injetados")

	# Simula a Pip lutando: ataca e dá dash periodicamente perto dos inimigos
	if frame % 20 == 0 and heroine.has_method("execute_attack_combo"):
		heroine.execute_attack_combo()
	if frame % 90 == 0 and heroine.has_method("start_dash"):
		heroine.start_dash()

	if frame_ms > SPIKE_MS and frame > 5:
		spikes.append("f%d %.1fms enemies=%d nodes=%d wave=%d %s" % [
			frame, frame_ms, get_tree().get_nodes_in_group("enemies").size(),
			_nodes(), GameManager.current_wave, GameManager.current_period])

	if frame % 600 == 0:
		var recent := samples.slice(samples.size() - 600)
		var total := 0.0
		var worst := 0.0
		for s in recent:
			total += s
			worst = maxf(worst, s)
		print("[probe] f%d avg=%.2fms worst=%.1fms nodes=%d objs=%d orphans=%d enemies=%d pickups=%d wave=%d %s" % [
			frame, total / recent.size(), worst, _nodes(), _objs(),
			int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
			get_tree().get_nodes_in_group("enemies").size(),
			get_tree().get_nodes_in_group("pickups").size(),
			GameManager.current_wave, GameManager.current_period])

	if frame >= TOTAL_FRAMES:
		print("[probe] spikes>%.0fms: %d" % [SPIKE_MS, spikes.size()])
		for s in spikes.slice(0, 40):
			print("  ", s)
		get_tree().quit(0)
	last_usec = Time.get_ticks_usec()
