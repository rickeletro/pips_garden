# 🌸 Jardim Miúdo (Godot 4 3D)

**Jardim Miúdo** é um jogo de Tower Defense 3D com câmera top-down inclinada (~55°), ambientado em um jardim visto pela perspectiva de uma criatura minúscula (estilo inspirado em *O Mundo Secreto de Arrietty* do Studio Ghibli).

---

## 🎮 Conceito e Mecânicas Principais

### 1. 🗡️ A Heroína: Pip
- **Movimentação**: Ágil com WASD ou setas direcionais.
- **Combate de Esgrima (Agulha de Costura)**:
  - **Combo de 3 Golpes** (`Espaço`, `J` ou botão no Hotbar):
    - Golpe 1: Estocada frontal rápida.
    - Golpe 2: Corte diagonal cruzado.
    - Golpe 3: Golpe giratório em área de 360° com knockback.
  - **Esquiva & Estocada Perfurante** (`Shift`, `K` ou botão no Hotbar): Dash com invulnerabilidade momentânea que atravessa e perfura pragas no caminho.
- **Progressão**: Derrotar pragas concede XP à Pip, aumentando seu nível, dano da agulha e capacidade da bolsa.

---

### 2. 🎒 Bolsa de Couro & Economia
Recursos espalhados pelo chão do jardim que Pip pode coletar por aproximação magnética:
- 🌿 **Gravetos**: Usados para construir e consertar torres.
- ⚙️ **Engrenagens de Brinquedo**: Usadas para construir e evoluir o nível das torres.
- 🌱 **Sementes**: Usadas para semear caminhos de grama no terreno.

---

### 3. 🌱 Caminhos de Grama & Desaceleração Seletiva
- **Mecânica de Terreno**: O terreno é estruturado em uma grade. A terra comum possui peso de deslocamento `3.5`.
- **Plantio (`Q` ou Slot no HUD)**: Ao usar 1 semente, Pip faz brotar tufos de grama viçosa naquela célula.
- **Desaceleração de Hordas Terrestres**: Pragas terrestres (pulgões, lagartas) que entram na grama alta sofrem uma redução de **40% na velocidade**, ficando vulneráveis por mais tempo ao alcance das torres!
- **Imunidade Aérea**: Unidades voadoras (como vespas) voam por cima da vegetação e **não sofrem nenhuma desaceleração da grama**!
- **Regra Crucial de Defesa**: O jogo impede a construção de torres que bloqueariam 100% de todas as rotas possíveis até a flor central.

---

### 4. 🏹 Torres de Gravetos e Engrenagens
- **Construção (`B` ou Slot no HUD)**: Custa 3 gravetos e 2 engrenagens.
- **Engrenagens Animadas**: As engrenagens de brinquedo no topo giram velozmente durante o disparo.
- **Tipos de Veneno (`T` ou Slot no HUD)**:
  1. ❄️ **Veneno Lento**: Reduz a velocidade da praga em 55% e causa dano contínuo.
  2. 🧪 **Veneno Corrosivo**: Causa dano ácido intenso ao longo do tempo (DoT).
  3. 💨 **Névoa em Área**: Dispara nuvem tóxica que atinge múltiplos insetos ao redor.
- **Manutenção e Reparo (`E` ou Slot no HUD)**: Torres sofrem dano de pragas próximas e quebram se o HP chegar a zero. Podem ser reparadas com 2 gravetos.
- **Evolução de Níveis**: Torres sobem até o Nível 3, ganhando maior alcance e cadência de tiro.

---

### 5. ⏳ Início Automático com Countdown de 15s
- Entre cada onda, o jogo ativa um **countdown automático de 15 segundos** com barra visual de progresso.
- O jogador pode explorar e coletar recursos livremente, ou clicar em **"⏩ Iniciar Agora"** (`Enter` ou `F`) para pular a espera.

---

### 6. 📈 Dificuldade Progressiva (7 Ondas da Área 1)
1. **Onda 1**: 10 Pulgões (aprendizado de plantio de grama e primeira torre)
2. **Onda 2**: 16 Pulgões + 3 Lagartas (introdução de pragas terrestres com armadura)
3. **Onda 3**: 14 Pulgões + 6 Lagartas + 4 Vespas (introdução de ameaça aérea!)
4. **Onda 4**: 20 Pulgões + 9 Lagartas + 7 Vespas (enxame misto acelerado)
5. **Onda 5**: 26 Pulgões + 13 Lagartas + 11 Vespas (alta pressão de enxame)
6. **Onda 6**: 34 Pulgões + 18 Lagartas + 15 Vespas (horda massiva de alta intensidade)
7. **Onda 7**: 45 Pulgões + 24 Lagartas + 22 Vespas (clímax épico da Área 1!)

---

## 🕹️ Hotbar de Ações (Slots Interativos)

No rodapé da tela, o jogador conta com slots interativos com ícones e atalhos:
- `🌱 Plantar [Q]`: Custo 1 🌱 (desativa se sem sementes).
- `🏹 Torre [B]`: Custo 3 🌿, 2 ⚙️ (desativa se sem recursos).
- `🗡️ Ataque [Espaço / Click]`: Dispara o combo de esgrima.
- `🧪 Veneno [T]`: Alterna o tipo de veneno da torre próxima.
- `💨 Esquiva [Shift / R-Click]`: Executa o dash com estocada.
- `🔨 Reparar [E]`: Custo 2 🌿 (conserta a torre mais próxima).

---

## 🚀 Como Executar

### No Godot Editor:
Abra a pasta `/Users/ricardosouza/.gemini/antigravity-ide/scratch/jardim-miudo` no **Godot Engine 4.7+** e pressione `F5`.

### Pelo Terminal no macOS:
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/ricardosouza/.gemini/antigravity-ide/scratch/jardim-miudo
```
