# AGENTS.md — Diretrizes Permanentes de Jardim Miúdo

Este documento define os princípios obrigatórios para desenvolvimento, design de arte, game design e arquitetura técnica no projeto **Jardim Miúdo** (*Pip's Garden*). Qualquer agente trabalhando neste repositório DEVE seguir rigorosamente estas diretrizes.

---

## 1. Pilares Fundamentais do Jogo
1. **Arte & Estética**: Fantasia pastoral em aquarela (estilo *Ghibli / Zelda: Tears of the Kingdom*). Tudo parece orgânico e feito à mão com materiais encontrados.
2. **Heroína**: **Pip** — heroína em miniatura estilo *Arrietty / Chibi* (altura ~0.7m), cabelo ruivo com rabo de cavalo (ponto de contraste), túnica verde floresta com contorno/rim light e agulha de costura como espada.
3. **Loop Principal**: Exploração + Coleta (30s) ➡️ Fortificação e Plantio ➡️ Defesa contra Hordas ➡️ Batalhas Épicas de Chefes ➡️ Evolução da Flor Central.
4. **Flor Central**: HP base de **200**, escala visual de integridade (cor/vitalidade) e evolução permanente ao derrotar chefes (+10% HP max e novas folhas).

---

## 2. Padrões de Design de Arte e UI
- **Design Tokens**: Todas as cores, tamanhos e constantes visuais DEVEM utilizar a paleta de `ui/theme/tokens.gd` ou `ui/theme/jardim.tres`. Não usar valores hexadecimais soltos no código.
- **Iluminação**:
  - *Dia*: Luz solar quente e dourada, céu suave, sombras suaves.
  - *Noite*: Iluminação de lua cheia (azulada/prateada suave), mantendo visibilidade confortável sem escuridão excessiva.
  - *Amanhecer*: Transição dourada e rosada anunciando a chegada de chefes.
- **Interface e HUD**:
  - A HUD deve ser minimalista, limpa e nunca cobrir a ação central.
  - Margens livres e cantos reservados para status (HP Pip, HP Flor, Recursos, Minimapa).
  - A tela de introdução é sem molduras de caixa pesadas, utilizando a moldura botânica viva de heras/trepadeiras (`ivy_border.gd`).

---

## 3. Economia e Regras de Game Design
- **Custos e Inventário**:
  - Inventário Inicial: 10 Gravetos, 4 Engrenagens, 8 Sementes (Mochila: 30 itens).
  - Torre Nível 1: 3 Gravetos + 2 Engrenagens (15 dano, 0.8 tiros/s, 4.5m alcance).
  - Torre Nível 2: +6 Gravetos + 4 Engrenagens (18 dano x 2 tiros, 1.1 tiros/s, 5.5m alcance).
  - Torre Nível 3A (Canhão Espinho): +12 Gravetos + 8 Engrenagens (110 dano, 0.5 tiros/s, 7.0m alcance, 50% perfuração de armadura).
  - Torre Nível 3B (Catapulta Seiva): +12 Gravetos + 8 Engrenagens (35 dano splash 2.5m, 0.6 tiros/s, 5.0m alcance, poça de lentidão 15%).
  - Reparo Preventivo (Torre em pé com dano): 2 Gravetos.
  - Reerguer Torre Caída (1º Colapso): 4 Gravetos + 1 Engrenagem (retorna no Nível 1; +2 Gravetos por colapso sucessivo).
  - Plantio de Grama: 1 Semente (reduz velocidade de pragas terrestres em 40%).
- **Sementes e Dentes-de-Leão**:
  - 12 Dentes-de-leão pelo mapa de 100m (com barra de hidratação de 100s).
  - Cada dente-de-leão produz **2 sementes flutuantes** ao ser golpeado/soprado.
  - Dentes-de-leão secam se a hidratação zerar e só renascem no amanhecer ou ao receber orvalho.
- **Frasco de Orvalho & Sede**:
  - Pip possui um **Frasco de Orvalho** (capacidade até 3 gotas).
  - Gotas surgem sobre folhas ao amanhecer e anoitecer (4 a 6 gotas espalhadas).
  - Coletar gota de orvalho: recupera **+25 HP** para a Pip e adiciona **+1 carga ao frasco** (coleta direta e limpa, sem poça no solo).
  - Regar Dente-de-Leão (`[F]`): restaura 100% da hidratação da planta.
  - Regar Flor Central (`[F]`): restaura +50% de hidratação e cura +5 HP perdidos por desidratação.
- **Spawn de Recursos no Chão & Teto Global**:
  - Spawn inicial: 8 Gravetos + 4 Engrenagens.
  - A cada intervalo entre ondas, gera recursos dinamicamente com curva decrescente ($\max(3, 8 - \lfloor 0.7 \times w \rfloor)$ gravetos e $\max(1, 4 - \lfloor 0.5 \times w \rfloor)$ engrenagens), respeitando o **teto global de 20 pickups no solo**.
- **Regras de HP e Sobrevivência da Pip**:
  - HP Inicial: 100.0 (XP por nível: `nível * 100`).
  - Subida de Nível: +15 Max HP, +5 Dano, +5 Bolsa (sem cura total gratuita; apenas adiciona o bônus de +15 HP).
  - Regeneração por Ciclo: Transições de Anoitecer / Amanhecer restauram o HP da Pip em 100%.
  - Nocaute em 0 HP: Atordoamento de 2.2s, reposicionamento suave junto à Flor Central com 35% de HP e 1.5s de invulnerabilidade.
- **Tempo de Pacing**:
  - Intervalo padrão entre ondas: **30.0 segundos** (com botão de Pular ⏩).
  - Transições especiais (Anoitecer / Amanhecer Pré-Boss): **60.0 segundos**.
- **Comportamento e Drops de Chefes**:
  - **Caramujo Ancião**: HP balanceado para o Dia 1 (480). Ao ser derrotado, dropa **exclusivamente 1 Lágrima de Fada** (sem outros itens).
  - **Mariposa da Lua Cheia**: HP (880) e dano (32) balanceados. Prioriza destruir defesas (torres e flor); só ataca a Pip caso ela se aproxime muito (<= 3.2m). Ao morrer, dropa **no chão** (y=0.0) **1 Ovo de Joaninha**.
  - **Ovo de Joaninha & Companheira**: O ovo pulsa no solo por 15 segundos até eclodir na **Joaninha Companheira NPC** que patrulha o jardim, caçando ativamente e eliminando pulgões (Aphids).
- **Passagem Livre em Defesas Destruídas**:
  - Quando uma torre é destruída/colapsada, sua colisão física é desativada (`CollisionShape3D.disabled = true`) e o ponto no pathfinding AStar é liberado para que os inimigos nunca fiquem presos nos escombros. Ao ser reparada, a colisão e o bloqueio no grid são restaurados.

---

## 4. Arquitetura Técnica em Godot 4 (GDScript)
- **Acesso a Singletons**: Usar referências diretas de Autoloads (`GameManager`, `SoundManager`) em vez de verificações de caminho `/root` propensas a falha durante `tree_exited`.
- **Desempenho e Memória (Meta 60 FPS)**:
  - Reutilizar malhas e materiais estáticos compartilhados (`static var shared_mesh / mat`) para instâncias em massa (plumas, sementes, dentes-de-leão, efeitos de hit flash).
  - Usar `MultiMeshInstance3D` para a grama densa do terreno.
  - Evitar alocações repetidas de `Material.duplicate()` a cada frame ou hit.
- **Validação Automatizada**:
  - Ao fazer alterações no código ou balanceamento, SEMPRE executar a suíte de testes automatizados via Godot headless:
    `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/test_runner.tscn`
  - Manter as asserções de `scripts/test_runner.gd` sincronizadas com as regras atuais do jogo.
