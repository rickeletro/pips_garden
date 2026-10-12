# 🎨 Art Bible & Visual Guidelines — Jardim Miúdo

---

## 1. Visual Identity & Pillars
- **Theme**: Pastoral miniature fantasy (*"O Mundo dos Pequeninos" / Ghibli meets Zelda TotK*).
- **Core Feeling**: Handcrafted, cozy, sunlit, vibrant, and warm. Never dark, gritty, or post-apocalyptic.
- **Scale**: Camera looks from above at an angle (~55° pitch). The world feels enormous to Pip (clover leaves are big umbrellas, dandelions are towers, raindrops/dewdrops sparkle).

---

## 2. Color Palette & Design Tokens
All visual values **must** come from `ui/theme/tokens.gd` or `ui/theme/jardim.tres`:

| Token | Color Code | Role / Meaning |
| :--- | :--- | :--- |
| `verde_musgo` | `#4F6B3A` | Dark grass patches, container backdrops |
| `verde_folha` | `#8FB05A` | Lush grass, positive notifications, vitality |
| `marrom_casca` | `#5A3E2B` | Wooden twigs, frames, earthy bark |
| `creme_pergaminho`| `#F3E6C4` | Calligraphy text, parchment cards, UI labels |
| `dourado_luz` | `#E8B94A` | Highlights, buttons, amber seeds, sunlight |
| `ruivo_cobre` | `#B5471F` | Pip's ponytail, fiery warm accents, urgency |
| `latao_engrenagem`| `#C9953C` | Clockwork gears, brass mechanics |
| `veneno_verde` | `#7ED957` | Acid poison (corrosive DoT) |
| `veneno_ambar` | `#E39A2D` | Slow poison (honey sap) |
| `veneno_violeta` | `#8E7CC3` | Spore mist poison (AoE burst) |
| `perigo` | `#C8402F` | Critical health, danger, insufficient resources |

---

## 3. Character Design Sheet: Pip
- **Silhouette**: Chibi proportions (head is ~1/3 of total height). Total height ~0.7 units.
- **Key Contrast Rule**: The garden floor is green. To make Pip easily visible from top-down distance:
  - Long **Copper-Red Ponytail (`ruivo_cobre`)** swinging dynamically.
  - Golden/Amber Hood resting on the shoulders.
  - White needle blade with red thread wrap.
  - Subtle rim-lighting on edges.
- **Animations (Procedural / Tween / AnimationPlayer)**:
  1. *Idle*: Gentle breathing and ponytail sway.
  2. *Run*: Agile 8-way run with slight body tilt.
  3. *Attack Combo*: 3-stage swordplay slash (Jab 18 dmg -> Cross 22 dmg -> Spin 32 dmg with 2.0m knockback).
  4. *Dash*: Forward glide 4.5m in 0.25s with dust puff and petal particles.
  5. *Collect Hop*: Joyful bounce upon grabbing items or blowing dandelions.
  6. *Damage Flash*: Brief white-tint recoil.

---

## 4. Tower Design (Torre de Gravetos) & Specializations
- **Concept**: Organic tripod teepee of tied twigs with clockwork contraptions.
- **Level 1 (Básica)**: Low twig tripod, acorn bowl liquid tank, hollow straw nozzle (15 dmg, 0.8 tiros/s, 4.5m).
- **Level 2 (Reforçada)**: Taller cross-braced structure with dual brass gears that rotate during firing (18 dmg x2, 1.1 tiros/s, 5.5m).
- **Level 3A (Canhão de Espinho)**: Long wooden cannon barrel with barbed spike, master brass gear crown and firefly lantern (110 dmg, 0.5 tiros/s, 7.0m, 50% perfuração de armadura).
- **Level 3B (Catapulta de Seiva)**: Spring-loaded catapult spoon arm with glowing amber sap glob (35 dmg splash 2.5m, 0.6 tiros/s, 5.0m + poça de lentidão 15%).
- **Damage States**:
  - *Normal*: Upright, pulsing with fluid light.
  - *Broken*: Collapsed pile of twigs with smoke particles.

---

## 5. Terreno, Gotas de Orvalho & Game Feel
- **Gotas de Orvalho Gigantes**: Esferas de água translúcidas com alto brilho especular e toon rim light. Ao estourar com a agulha, espalham poça d'água de 3m por 20s.
- **Impacto em Carapaças**: Faíscas metálicas brancas e som de clink ao golpear o Besouro Blindado; impacto suave e orgânico em pulgões e lagartas.
- **Deformação de Grama**: Lagartas mastigam a grama em fases visuais antes de abrir caminho.

---

## 6. Lighting & Day/Night Atmosphere
- **Day**: Sun pitch 45°, warm golden light (`#fff4d6`), soft ambient shadows, gentle wind particles.
- **Night**: Full-moon silver/cyan illumination (`#8ab4f8` / `#b0d0ff`), maintaining clear visual gameplay without frustrating dark spots. No harsh insect noises; smooth peaceful night melody.
- **Dawn**: Horizon blooms in rose gold, casting long dramatic shadows before boss encounters.
- **Intro Screen**: Frameless organic presentation framed by waving ivy vines (`ivy_border.gd`) and jasmine blossoms with subtle wind physics.
