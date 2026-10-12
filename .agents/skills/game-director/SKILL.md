---
name: game-director
description: >-
  Game Director, Game Designer, Art Supervisor, and Technical Architect for Jardim Miúdo.
  Use this skill whenever proposing, designing, implementing, balancing, or refactoring
  game features, combat mechanics, enemy AI, bosses, visual assets, shaders, audio, UI, or phase roadmaps.
---

# 🌿 Game Director: Jardim Miúdo (*Pip's Garden*)

This skill serves as the comprehensive development suite and consistency engine for **Jardim Miúdo**, maintaining harmony across **Art Direction**, **Game Design & Economy**, **Code Architecture**, and **Progressive Roadmap Delivery**.

---

## 🎯 When to Use This Skill
- Designing or coding new enemy types, behaviors, and bosses.
- Adding or adjusting weapons, skills, action slots, or tower variants.
- Balancing resources, drop tables, wave pacing, and difficulty curves.
- Creating or tuning 3D procedural meshes, toon materials, shaders, particle effects, and UI layouts.
- Implementing cutscenes, camera choreographies, and audio-visual cues.
- Expanding new phases, biomes, or day/night cycle events.

---

## 📚 Specialized References (Progressive Disclosure)

Read the specific reference when working on that domain:

1. 🎨 **[Art Bible & Visual Guidelines](./references/art_bible.md)**:
   - Color palettes and Design Tokens (`Tokens.gd`).
   - Pip character sheet (Arrietty chibi proportions, red ponytail, needle sword).
   - Lighting setups (Golden Sun Day, Moonlit Silver Night, Rose Dawn).
   - Shader principles (Toon shading, rim lighting, MultiMesh rendering).

2. ⚔️ **[Game Design & Economic Formulas](./references/game_design.md)**:
   - Core gameplay loop & action economy.
   - Resource matrix (twigs, gears, seeds, fairy tears).
   - Tower defense balance (3 levels, 3 poison types, repair economy).
   - Ground pests vs Flying pests rules (grass slow & caterpillar chewing).
   - Boss design patterns (Snail slug trail, Moth high-flight/dive attack).

3. 🏛️ **[Technical Architecture & GDScript Standards](./references/technical_architecture.md)**:
   - Godot 4 autoloads (`GameManager`, `SoundManager`) and signal pipelines.
   - 60 FPS performance rules (Mesh/Material caching, MultiMesh foliage).
   - Clean state management & node decoupling.
   - Automated testing with `test_runner.gd`.

4. 🗺️ **[Progressive Roadmap & Phase Tracking](./references/roadmap_and_phases.md)**:
   - Status of all completed phases (Day 1, Night 1, Boss Snail, Day 2, Night 2 Boss Moth).
   - Next milestones, backlog features, and validation criteria.

---

## ⚡ Step-by-Step Feature Implementation Workflow

When asked to build a new feature or phase:

1. **Check Specifications**: Review the relevant reference in `./references/`.
2. **Propose Architecture**: Outline the node structure, signals, and math balance before writing code.
3. **Preserve Tokens & Aesthetics**: Use tokens from `Tokens.gd` or `jardim.tres`. Ensure silhouette readability from top-down perspective.
4. **Implement Modularly**: Keep scripts focused, self-contained, and performant (cache shared meshes/materials).
5. **Run Validation Suite**:
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/test_runner.tscn
   ```
6. **Update Roadmap**: Keep `roadmap_and_phases.md` synchronized with newly added mechanics or phases.
