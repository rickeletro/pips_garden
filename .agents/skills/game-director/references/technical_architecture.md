# 🏛️ Technical Architecture & GDScript Standards — Jardim Miúdo

---

## 1. Engine & Environment
- **Godot Version**: Godot 4.x (Standard GDScript).
- **Core Autoloads**:
  - `GameManager` (`scripts/game_manager.gd`): Master game state, cycle progression, inventory, player/flower health, and event dispatching.
  - `SoundManager` (`scripts/sound_manager.gd`): Music track crossfading, SFX pools, pentatonic collection feedback, ambient garden sounds.
  - `Tokens` (`ui/theme/tokens.gd`): Central color and style token constants.

---

## 2. Coding Patterns & Best Practices

### A. Autoload Access
- **Do**: Access autoloads directly (`GameManager.pip_hp`, `SoundManager.play_day_music()`).
- **Don't**: Use fragile string searches like `get_node("/root/GameManager")` or `Engine.has_singleton()`, which fail when nodes detach during `tree_exited`.

### B. Memory & 60 FPS Performance Rules
- **Static Mesh/Material Caching**:
  ```gdscript
  # Pre-cache static meshes/materials for high-count objects (spores, seeds, projectiles, hit flashes, dew drops)
  static var shared_seed_mesh: CylinderMesh = null
  static var mat_seed: StandardMaterial3D = null
  ```
- **Preload for Custom Classes**:
  - Use `const DewDropScript = preload("res://scripts/dew_drop.gd")` or instance scenes directly to prevent headless parse cache delay.
- **Avoid Repeated `.duplicate()` in `_process` or Damage Callbacks**:
  - Duplicate once at `_ready()` or use shared pre-allocated hit-flash materials.
- **MultiMesh Foliage**:
  - All large-scale decorative grass is batched via `MultiMeshInstance3D` managed by `grid_manager.gd`.
- **Minimap Geometry Caching**:
  - Cache static trail coordinates as `PackedVector2Array` rather than iterating dictionary maps every frame.

---

## 3. Combat & Specialization Pipeline
- **Tower Specializations (`GardenTower.Specialization`)**:
  - `THORN_CANNON` (3A): Disparos de longo alcance (7.0m), 110 dmg com `armor_pierce = 0.5`.
  - `SAP_CATAPULT` (3B): Projéteis de seiva com splash de 2.5m, 35 dmg e poça de lodo de 15% slow.
- **Armor Piercing Handling**:
  - `EnemyBase.take_damage(amount, knockback, is_dot, armor_pierce)`
  - In `Beetle`: `var armor_reduction = 0.30 * clampf(1.0 - armor_pierce, 0.0, 1.0)`.

---

## 4. Signal Pipeline
- `GameManager.resources_changed(twigs, gears, seeds, capacity)`
- `GameManager.pip_stats_changed(hp, max_hp, xp, level)`
- `GameManager.flower_stats_changed(hp, max_hp)`
- `GameManager.wave_state_changed(state, wave_number)`
- `GameManager.request_plant_grass`, `request_build_tower`, `request_cycle_poison`

---

## 5. Test Verification Protocol
Whenever modifying gameplay code or tuning values, run the automated headless test runner:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/test_runner.tscn
```
- Verify zero runtime errors and exit code 0.
- Update `scripts/test_runner.gd` assertions if intentional balance changes (e.g. wave counts, countdowns, health) are introduced.
