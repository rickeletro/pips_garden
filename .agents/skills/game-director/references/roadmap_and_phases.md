# 🗺️ Progressive Roadmap & Phase Tracking — Jardim Miúdo

---

## 🟢 Concluído & Validado no Motor (Current State)

| Fase / Recurso | Status | Descrição & Destaques |
| :--- | :--- | :--- |
| **Intro & Tela Inicial** | ✅ Concluído | Moldura botânica de trepadeiras e heras (`ivy_border.gd`), título caligráfico "Pip's Garden" e zoom in dinâmico. |
| **Fase 1: Dia 1 (7 Ondas Calibradas)** | ✅ Concluído | Tabela exata de pulgões, lagartas e vespas. 30s de intervalo e 14 itens de solo por onda. |
| **Fase 2: Noite 1 (7 Ondas Noturnas)** | ✅ Concluído | Céu com iluminação de lua cheia, música noturna suave, vaga-lumes e besouros com blindagem. |
| **Fase 3: Amanhecer & Caramujo** | ✅ Concluído | Chefe Caramujo com rastro pegajoso, ataque pesado e drop de Lágrima de Fada (cura 60% e +10% max HP). |
| **Fase 4: Dia 2 (7 Ondas)** | ✅ Concluído | Dentes-de-leão renascem pelo mapa fornecendo sementes. Hordas intensificadas. |
| **Fase 5: Noite 2 & Mariposa Rainha**| ✅ Concluído | Chefe Mariposa com 1600 HP, voo alto, mergulho rasante de 3 ataques e entrada cinematográfica. |
| **Torres: Nv 1, Nv 2 e Nv 3A / 3B** | ✅ Concluído | Especializações 3A (Canhão Espinho 110 dmg/perfuração 50%) e 3B (Catapulta Seiva 35 dmg/splash 2.5m/poça). |
| **Pip: Combate, Dash & Físicas** | ✅ Concluído | Velocidade 6.0 m/s, Dash 4.5m (0.25s / cd 1.2s), Combo 18/22/32 dmg com knockback de 2.0m. |
| **Game Feel & Sinergias** | ✅ Concluído | Coleta musical na escala pentatônica e 6 Gotas de Orvalho gigantes (+20% lentidão / +30% ácido). |
| **Suíte de Testes Automatizados** | ✅ Concluído | `test_runner.tscn` executando e passando 100% dos testes sem falhas no Godot 4. |

---

## 🎯 Roteiro de Produção da Demonstração (Steam Next Fest)

```text
[Mês 1: Núcleo Mecânico] ───> [Mês 2: Conteúdo & Polimento] ───> [Mês 3: Validação & Demo]
  - Torres Nv 1, 2, 3A e 3B     - Ciclo Dia 1 / Noite 1           - Batalha Caramujo Ancião
  - Combate e Dash da Pip       - Audiovisual Ghibli/Zelda        - Página Steam & Trailer
  - Drop rates e Spawner        - Áudio dinâmico (Suno/SFX)       - Playtest externo e corte
```

1. **Marco 1 — Loop Funcional (Concluído no código)**:
   - Dados de atributos e fórmulas das torres (Nv 1, Nv 2, Nv 3A e Nv 3B).
   - Curvas de spawn de ondas do Dia 1 e Noite 1 calibradas.
   - Resposta física da Pip: combo de agulha com recuo de 2.0m, dash de 4.5m e coleta magnética.
2. **Marco 2 — Atmosfera e Identidade (Concluído no código)**:
   - Ciclo visual de iluminação (sol dourado diurno, noite de lua cheia).
   - Efeitos sonoros de coleta em escala pentatônica com brilho harmônico no 5º item.
   - Sinergia de terreno com Gotas de Orvalho gigantes (+20% lentidão / +30% dano de veneno ácido).
3. **Marco 3 — Batalha de Chefe & Vertical Slice (Preparação para Demo Steam)**:
   - Inteligência artificial refinada do Caramujo Ancião (rastro de muco, cabeçada, drop de Lágrima de Fada).
   - Corte da demo no amanhecer pós-chefe direcionando para Wishlist na Steam.
