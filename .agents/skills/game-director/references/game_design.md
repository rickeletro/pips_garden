# ⚔️ Game Design & Economic Balance — Jardim Miúdo

---

## 1. Core Loop
```text
┌────────────────────────────────────────────────────────┐
│ 1. EXPLORATION & HARVEST (30s Countdown / Skip button) │
│    - Collect 14 ground items (9 twigs + 5 gears)       │
│    - Blow Dandelion Clocks (2 seeds each)              │
├────────────────────────────────────────────────────────┤
│ 2. TACTICAL DEFENSE SETUP                              │
│    - Plant slowing grass on key trail intersections    │
│    - Build / Upgrade Stick Towers (Lv1 -> Lv2 -> Lv3)  │
│    - Branch specialization at Lv 3 (3A Cannon / 3B Sap)│
│    - Repair collapsed towers (2 twigs)                 │
├────────────────────────────────────────────────────────┤
│ 3. ACTIVE WAVE COMBAT                                  │
│    - Towers fire automatic poison/acorn/sap bursts     │
│    - Pip uses Needle Combo & Dash to assist frontline  │
│    - Pop Giant Dew Drops to wet ground (+20% slow/DoT) │
│    - Caterpillars chew planted grass to clear path     │
├────────────────────────────────────────────────────────┤
│ 4. CYCLE ADVANCEMENT & BOSS FIGHTS                     │
│    - Day 1 (7 waves) ➡️ Night 1 (7 waves)              │
│    - Dawn Boss Snail ➡️ Day 2 (7 waves)                │
│    - Night 2 (3 waves) ➡️ Boss Moth                    │
└────────────────────────────────────────────────────────┘
```

---

## 2. Resource Economy Matrix

| Resource | Initial | Per-Wave Ground Spawn | Source | Primary Use |
| :--- | :--- | :--- | :--- | :--- |
| **Twigs (Gravetos)** | 10 | +8 down to +3 (Decay, Cap 20) | Ground spawn, enemy drops (~18%) | Building towers (3), repairs (2/4), upgrades (6, 12) |
| **Gears (Engrenagens)** | 4 | +4 down to +1 (Decay, Cap 20) | Ground spawn, enemy drops (~18%) | Building towers (2), rebuild (1), upgrades (4, 8) |
| **Seeds (Sementes)** | 8 | 0 (from ground) | 12 Dandelions (2 seeds each, 100s hydration) | Planting slowing grass (1 per tile) |
| **Dew Flask** | 0 | Max 3 Drops in Flask | Popping/gathering dew drops | Watering Dandelions & Central Flower |
| **Fairy Tear** | 0 | Boss Snail Drop | Dropped once on Snail defeat | Heals Central Flower 60% & +10% max HP |
| **Bag Capacity** | 30 | — | Global inventory cap | Prevents unbounded stockpiling |

---

## 3. Central Flower (Objective)
- **Base HP**: 200.0 HP.
- **Hydration System**: Flower consumes 1% hydration every ~2.2s. When 0%, suffers 1 damage every 3s. Watering with 1 dew charge restores +50% hydration and heals 5 HP.
- **Visual Damage & Dryness Gradient**: Flower petals shift from vibrant pink to burgundy on damage, while stem dries to brown on dehydration.
- **Evolution**: Upon applying Fairy Tear, max HP increases to 220.0 (+10%), petals take an enchanted hue, and a living green leaf sprouts from the stem.

---

## 4. Tower Balancing, Upgrades & Level 3 Specializations

```
Torre Nv 1 (Base: Projétil Único)
       │
       ▼
Torre Nv 2 (Dupla: Cadência Reforçada)
       │
       ├───────────────────────────────┐
       ▼                               ▼
Torre Nv 3A: Canhão de Espinho    Torre Nv 3B: Catapulta de Seiva
(Foco: Alvo Único / Blindados)   (Foco: Dano em Área / Enxame)
```

| Nível / Especialização | Custo Adicional | Custo Cumulativo | Dano por Disparo | Cadência (Tiros/s) | DPS Base | Alcance | Tipo de Dano |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Nível 1 (Básica)** | 3 Gravetos, 2 Engr. | 3 Gravetos, 2 Engr. | 15 | 0.8 (1.25s) | 12.0 | 4.5 m | Físico direto |
| **Nível 2 (Reforçada)** | +6 Gravetos, +4 Engr. | 9 Gravetos, 6 Engr. | 18 (x2 tiros) | 1.1 (0.91s) | 39.6 | 5.5 m | Físico duplo |
| **Nível 3A (Canhão Espinho)** | +12 Gravetos, +8 Engr. | 21 Gravetos, 14 Engr. | 110 | 0.5 (2.0s) | 55.0 | 7.0 m | Perfuração (ignora 50% de armadura) |
| **Nível 3B (Catapulta Seiva)** | +12 Gravetos, +8 Engr. | 21 Gravetos, 14 Engr. | 35 | 0.6 (1.67s) | 21.0 (Área) | 5.0 m | Splash 2.5m + poça de lodo (15% slow) |

### Aplicação dos Venenos Modulares (Multiplicadores)
- **🟢 Letárgico:** Reduz velocidade do alvo em **35% por 3.5s** (acumula com grama 40%: $0.60 \times 0.65 = 0.39$).
- **🧪 Ácido:** Causa **6 de dano por segundo por 4s** (24 de dano total garantido, ignora carapaça/armadura).
- **🟣 Névoa de Esporos:** Gera nuvem de 2.0m causando **40% do dano base** do projétil aos adjacentes.
- **Reparo Preventivo**: 2 Gravetos (0 engrenagens).
- **Reerguer Torre Caída**: 4 Gravetos + 1 Engrenagem (retorna no Nível 1; +2 gravetos por colapso sucessivo).

---

## 5. Spawner de Ondas (Dia 1 e Noite 1)

### Dia 1 (7 Ondas):
| Onda | Composição | Intervalo | Foco Estratégico |
| :--- | :--- | :--- | :--- |
| **1** | 8 Pulgões | 2.5s | Defender com 2 Torres Nv 1 e agulha da Pip |
| **2** | 12 Pulgões, 2 Lagartas | 2.0s | Proteger a grama; focar lagartas |
| **3** | 14 Pulgões, 3 Lagartas, 2 Vespas | 1.8s | Mira antiaérea das torres |
| **4** | 16 Pulgões, 4 Lagartas, 4 Vespas | 1.5s | Primeira Torre Nv 2 e veneno ácido |
| **5** | 18 Pulgões, 5 Lagartas, 6 Vespas | 1.2s | Manter reparos rápidos |
| **6** | 20 Pulgões, 6 Lagartas, 7 Vespas | 1.0s | Uso intensivo de grama |
| **7** | 22 Pulgões, 8 Lagartas, 10 Vespas | 0.8s | Pico do Dia: 3+ torres |

### Noite 1 (7 Ondas):
| Onda | Composição | Intervalo | Foco Estratégico |
| :--- | :--- | :--- | :--- |
| **1** | 6 Vaga-lumes, 2 Besouros | 2.2s | Testar blindagem |
| **2** | 8 Vaga-lumes, 4 Besouros | 2.0s | Reforço com veneno corrosivo |
| **3** | 10 Vaga-lumes, 5 Besouros, 6 Pulgões | 1.8s | Controle de enxame |
| **4** | 12 Vaga-lumes, 6 Besouros, 10 Pulgões | 1.5s | Torre Nv 3A Canhão recomendada |
| **5** | 14 Vaga-lumes, 8 Besouros, 4 Lagartas | 1.3s | Defesa pesada |
| **6** | 16 Vaga-lumes, 10 Besouros, 6 Lagartas | 1.1s | Manutenção da linha de frente |
| **7** | 20 Vaga-lumes, 12 Besouros, 8 Lagartas | 0.8s | Superenxame pré-chefe |

---

## 6. Pip: Parâmetros, Combate e Sobrevivência
- **Velocidade**: 6.0 m/s
- **Dash**: 4.5m (0.25s duração, 1.2s recarga, 0.15s invulnerabilidade, poeira e pétalas).
- **Combo de Agulha**:
  - Golpe 1: 18 de dano físico
  - Golpe 2: 22 de dano físico
  - Golpe 3: 32 de dano físico + **Recuo de 2.0 metros (Knockback)**
- **Interação Ecológica**:
  - Plantar Grama: 0.4s contínuo (custo 1 semente)
  - Dente-de-Leão: 1 golpe -> 2 sementes flutuantes (3m dispersão radial)
  - Coleta Magnética: Raio de 2.2 metros
- **Regras de HP e Regeneração**:
  - HP Base: 100.0 (XP por nível: `nível * 100`).
  - Level Up: +15 Max HP, +5 Dano, +5 Bolsa (sem cura total gratuita de 100%).
  - Regeneração por Ciclo: Transições de Anoitecer / Amanhecer restauram o HP em 100%.
  - Cura Ativa: Estourar uma Gota de Orvalho restaura **+25 HP**.
  - Nocaute em 0 HP: Atordoamento de 2.2s, retorno à Flor Central com 35% de HP e 1.5s de invulnerabilidade.

---

## 7. Game Feel & Sinergia de Terreno (Gotas de Orvalho)
- **Coleta Musical**: Escala pentatônica (Dó - Ré - Mi - Sol - Lá) ao coletar em <1.5s, brilho de sino de vento no 5º item.
- **Gotas de Orvalho Gigantes**: 6 gotas surgem ao amanhecer. Ao estourar com a agulha, criam poça de 3m por 20s.
  - *Efeito*: Inimigos na poça ganham **+20% de lentidão** e sofrem **+30% de dano de veneno ácido**.
