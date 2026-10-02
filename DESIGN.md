# Plano de Direção de Arte: Jardim Miúdo v2

---

## 0. Como a IA deve trabalhar

- Antes de cada fase, fazer um commit no git para você poder voltar atrás.
- Ler este arquivo inteiro e propor um plano curto antes de mexer no código (no Claude Code, use o modo de plano).
- Tudo que for cor, tamanho, fonte ou espaçamento vai para **um único arquivo de design tokens** (`ui/theme/tokens.gd`) e para **um Theme do Godot** (`ui/theme/jardim.tres`). Nada de valor visual solto no código.
- Ao fim de cada fase: rodar o jogo, capturar screenshots, comparar com os critérios de aceite e corrigir antes de avançar.
- Não alterar a mecânica que já funciona. Esta mudança é visual, de UI e de escala do mapa.

## 1. Identidade visual

**Pilares:** miniatura vista de perto, luz dourada de fim de tarde, artesanal (tudo parece feito à mão com materiais achados) e aconchegante, nunca sombrio.

**Estilo:** pintura suave inspirada em animação de fantasia pastoral japonesa. É referência de clima e paleta. Todos os personagens e objetos são originais.

**Paleta (tokens)**

| Token | Hex | Uso |
|---|---|---|
| `verde_musgo` | `#4F6B3A` | Painéis, grama escura |
| `verde_folha` | `#8FB05A` | Grama, destaques positivos |
| `marrom_casca` | `#5A3E2B` | Molduras, madeira |
| `creme_pergaminho` | `#F3E6C4` | Texto e fundos claros |
| `dourado_luz` | `#E8B94A` | Destaque, seleção, luz |
| `ruivo_cobre` | `#B5471F` | Cabelo da heroína, alertas quentes |
| `latao_engrenagem` | `#C9953C` | Engrenagens e metal |
| `veneno_verde` | `#7ED957` | Veneno corrosivo |
| `veneno_ambar` | `#E39A2D` | Veneno lento (mel) |
| `veneno_violeta` | `#8E7CC3` | Veneno em névoa |
| `perigo` | `#C8402F` | Vida baixa, recurso insuficiente |

**Tipografia** (Google Fonts, licença OFL, confirme antes de usar): título em *Fondamento* ou *Cormorant Garamond*, interface em *Nunito*. A fonte da interface tem que ser legível em tamanho pequeno.

**Iluminação do cenário:** luz direcional quente baixa, sombras suaves, névoa leve, bloom discreto e um pouco de profundidade de campo. Poeira e esporos flutuando e orvalho brilhando dão vida sem pesar.

## 2. A heroína (Pip)

**Design:** menina ruiva de roupa estilo elfo.
- **Cabelo:** ruivo cobre, longo, com uma trança lateral.
- **Orelhas:** pontudas.
- **Capuz:** pequeno, marrom-dourado, ficando para trás nas costas.
- **Túnica:** verde-floresta escura com bordados dourados.
- **Detalhes:** cinto de couro, botas com cano de folha, bolsa de couro com fivela.
- **Espada:** a agulha, com linha vermelha enrolada no cabo e um dedal como guarda-mão.

**Regra de legibilidade:** a câmera é top-down e o chão é verde. Se ela for toda verde, some no cenário. O **cabelo ruivo e o capuz dourado são o ponto de contraste**. Além disso, ela precisa de um contorno fino claro (outline) e de uma luz de recorte (rim light).

**Proporção:** estilizada, cabeça grande (cerca de 1/3 da altura), para ler bem de cima.

**Animações:** parada (respiração e cabelo balançando), correr, combo de 3 golpes, estocada, esquiva, coletar item (abaixa e pega) e levar dano.

**Técnica:** montar o modelo de forma modular com malhas e materiais toon criados no Godot, e fazer as animações por AnimationPlayer ou tweens. A estrutura precisa permitir trocar depois por um modelo `.glb` feito em Blender, sem mexer no resto do jogo.

**Aceite:** a Pip é identificável só pela silhueta e pela cor, em câmera distante, sobre a grama.

## 3. A torre de gravetos

**Silhueta:** nada de caixa. Deve ser claramente uma **torre feita de gravetos amarrados**, com formato de tenda indígena, ou seja, gravetos inclinados que se encontram no topo, atados com barbante.

**Evolução em 3 níveis, visual diferente em cada um:**

| Nível | Visual |
|---|---|
| 1 | Tripé baixo de gravetos, um pequeno tanque feito de casca de bolota e um bico de palha |
| 2 | Mais alta, com plataforma de gravetos, 2 engrenagens de brinquedo de latão que giram ao atirar e uma mola |
| 3 | Alta, com engrenagem grande, lanterna de vaga-lume numa garrafinha e bandeirolas de folha |

**Mecanismo:** a engrenagem gira e o tanque de bolota pulsa a cada disparo. O bico é uma palha oca que se orienta para o alvo.

**Veneno:** a cor do líquido e das gotas identifica o tipo (âmbar, verde ou violeta, conforme a paleta). O visual de cada tipo precisa ser distinguível de longe.

**Estados:**
- **Danificada:** gravetos soltos e engrenagem emperrada.
- **Quebrada:** desmoronada.
- **Reparada:** efeito breve de gravetos se encaixando.
- **Fantasma de construção:** versão translúcida verde (válida) ou vermelha (inválida).

**Aceite:** dá para distinguir o nível e o tipo de veneno de cada torre só de olhar o mapa.

## 4. Cenário bem maior

- **Escala:** pelo menos **5 vezes a área atual**. A IA deve medir a área atual e definir o número exato antes de começar.
- **Estrutura:** o mapa único continua se abrindo em áreas (torre do jardim, horta, sob o arbusto), só que agora cada área é grande e tem pontos de referência marcantes: uma pedra grande, um regador virado, uma roda de carrinho, uma cerca.
- **Desempenho (meta de 60 fps no Mac):** dividir o mundo em chunks e usar MultiMeshInstance3D para grama, flores e pedrinhas. Usar LOD e visibility ranges, e carregar só o que está perto da câmera.
- **Pathfinding:** manter o AStar atual, mas em chunks, sem recalcular o mapa inteiro a cada plantio de grama.
- **Câmera:** limites por área liberada, zoom com mínimo e máximo, e movimento suave.
- **Navegação:** minimapa pequeno que revela áreas conforme são liberadas.
- **Cenário:** densidade de vegetação maior nas bordas (que dão a sensação de mundo grande) e mais baixa e legível na área de jogo.

**Aceite:** o mapa ocupa pelo menos 5x o tamanho anterior, mantém 60 fps nas áreas liberadas e a heroína nunca vê o "fim do mundo".

## 5. HUD e layout de tela

**Princípios**
1. **Hierarquia:** o jogo é a protagonista. A HUD ocupa pouco espaço e nunca cobre a ação.
2. **Margens seguras:** 3 a 5% das bordas livres.
3. **Posições por função:** informação de estado nos cantos superiores, ações na base, recursos agrupados.
4. **Consistência:** mesmo estilo de moldura, mesma lógica de estados em tudo.
5. **Legibilidade:** contraste alto, texto com contorno ou sombra suave.
6. **Feedback claro:** todo estado muda visualmente, sem depender só de cor.
7. **Detalhe sob demanda:** textos longos ficam em tooltip ao passar o mouse.

**Layout (resolução de referência 1920x1080)**

| Região | Conteúdo |
|---|---|
| Topo esquerdo | Vida das flores (ícone de flor e barra fina) e número da onda |
| Topo direito | Minimapa pequeno e botão de pausa |
| Base esquerda | Retrato da Pip com barras finas de vida e XP |
| Base centro | **Barra de ações** |
| Base direita | Recursos da bolsa: gravetos, engrenagens e sementes, em fileira compacta com ícone e número |

**Slots de ação (o pedido principal)**
- Tamanho pequeno: **cerca de 48 px** (tokenizado).
- Mostra **somente o ícone**, e abaixo o nome da ação em texto bem pequeno (cerca de 11 px a 1080p, fonte Nunito, com contorno).
- Selo da tecla (ex.: 1, Q) num cantinho do slot.
- Estados: normal, hover (brilho dourado), pressionado, desabilitado, recarga (preenchimento radial escuro com contagem) e recurso insuficiente (contorno `perigo` e ícone dessaturado).
- Espaçamento pequeno e uniforme entre os slots.

**Estilo natureza:** painéis em casca de árvore com cantos de folha, musgo nas bordas e fios de trepadeira como divisores. Fundo semitransparente, cerca de 85% de opacidade.

**Ícones:** feitos como SVG, em arte consistente (mesma espessura de traço, 2 tons mais um destaque), exportados em 64 px. A IA pode escrever os SVGs direto.

**Técnica no Godot**
- Tudo numa CanvasLayer, com Stretch Mode `canvas_items` e Aspect `expand`.
- Estilos via Theme com StyleBoxTexture e margens de 9-patch, para a moldura escalar sem distorcer.
- Layout com containers e âncoras, nunca posições fixas em pixels.
- Opção de escala da interface nas configurações.
- Animações curtas e sutis (menos de 200 ms) ao abrir, passar o mouse e usar.

**Aceite:** a HUD ocupa menos de cerca de 15% da tela, todos os textos são legíveis, e os 6 estados de slot estão implementados e testáveis.

## 6. Fases e ordem

1. **Fundação:** tokens, Theme, fontes e ícones SVG base.
2. **HUD completa** com o novo estilo e os slots pequenos.
3. **Torre de gravetos** (3 níveis, 3 venenos, estados de dano).
4. **Pip** com o novo design e animações.
5. **Escala do mapa** (chunks, MultiMesh, minimapa).
6. **Polimento visual:** iluminação, névoa, partículas e pós-processamento.

## 7. Prompt inicial para a IA

> Leia o arquivo DESIGN.md desta pasta por completo. O jogo "Jardim Miúdo" já tem a mecânica funcionando e não deve ser quebrado. Siga as fases em ordem. Antes de começar, faça um commit e me mostre um plano curto da Fase 1. Ao terminar cada fase, rode o jogo, capturar screenshots, confira os critérios de aceite e me mostre o resultado antes de passar para a próxima. Nenhum valor visual pode ficar solto no código: tudo vem dos tokens e do Theme.
