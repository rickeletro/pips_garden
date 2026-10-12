extends Node

# ==============================================================================
# 🌟 GAME EVENTS — GLOBAL EVENT BUS (JARDIM MIÚDO)
# ==============================================================================
# Padrão Event Bus desacoplado:
# Permite que nós, entidades e UI se comuniquem por sinais puros sem dependências cruzadas.
# ==============================================================================

# Eventos de Inimigos & Chefes
signal enemy_spawned(enemy: Node3D)
signal enemy_damaged(enemy: Node3D, amount: float, current_hp: float, max_hp: float)
signal enemy_defeated(enemy: Node3D, xp: int)
signal boss_appeared(boss: Node3D, boss_name: String, max_hp: float)
signal boss_health_updated(current_hp: float, max_hp: float, boss_name: String)
signal boss_defeated(boss: Node3D)

# Eventos de Torres & Defesas
signal tower_placed(tower: Node3D, cell: Vector2i)
signal tower_upgraded(tower: Node3D, new_level: int)
signal tower_damaged(tower: Node3D, current_hp: float, max_hp: float)
signal tower_collapsed(tower: Node3D)
signal tower_repaired(tower: Node3D)

# Eventos de Terreno & Natureza
signal grass_planted(cell: Vector2i)
signal flower_damaged(current_hp: float, max_hp: float)
signal flower_healed(current_hp: float, max_hp: float)
signal flower_hydration_changed(hydration: float, max_hydration: float)
signal dandelion_watered(dandelion: Node3D)
signal dew_collected(amount: int, current_charges: int)

# Eventos de Heroína (Pip)
signal pip_health_changed(current_hp: float, max_hp: float)
signal pip_leveled_up(new_level: int, total_xp: int)
signal pip_knocked_out()

# Eventos de Ondas e Ciclos
signal wave_state_changed(state_name: String, wave_number: int)
signal wave_countdown_tick(time_left: float)
signal period_changed(period_name: String, day_number: int, night_number: int)
signal notification_broadcast(text: String, color: Color)
