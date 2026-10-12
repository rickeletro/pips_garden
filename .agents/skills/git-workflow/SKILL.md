---
name: git-workflow
description: >-
  Git Flow & GitHub Branch Automation Skill for Jardim Miúdo.
  Use this skill whenever starting a new feature, bug fix, balancing tweak,
  or refactoring task, to automatically create semantic branches, run test gates,
  commit with Conventional Commits, and publish/sync with the remote GitHub repository.
---

# 🌿 Git Workflow & Branch Automation (Jardim Miúdo)

Esta skill define e automatiza o ciclo de vida de desenvolvimento baseado em **Git Flow Ágil (GitHub Flow / Trunk-Based com Feature Branches)** conectado ao repositório oficial no GitHub:
`https://github.com/rickeletro/pips_garden.git`.

---

## 🎯 Por que o "Git Flow Ágil" é superior ao GitFlow tradicional aqui?

O **GitFlow Tradicional** (com `develop`, `release/*`, `hotfix/*` e `master`) foi concebido para empacotamento em caixas físicas com ciclos de meses. Em desenvolvimento moderno de jogos e pair programming com IA:
1. **Zero Sobrecarga**: Não há risco de divergência entre `develop` e `main` (elimina o clássico conflito de merge duplo).
2. **Qualidade Garantida (Quality Gates)**: Cada commit ou finalização de branch executa obrigatoriamente a suíte de testes headless do Godot (`scenes/test_runner.tscn`). Nenhuma alteração quebrada sobe para o GitHub.
3. **Histórico Limpo e Rastreável**: Branches semânticas com Conventional Commits (`feat:`, `fix:`, `balance:`, `refactor:`, `perf:`).

---

## 🛠️ Automação via CLI (`git_task.sh`)

O repositório conta com o script automatizado localizado em:
`.agents/skills/git-workflow/scripts/git_task.sh`

### Comandos Disponíveis:

| Comando | Descrição |
| :--- | :--- |
| `./.agents/skills/git-workflow/scripts/git_task.sh start <tipo> <nome>` | Atualiza a `main`, cria a branch semântica e publica no GitHub com upstream tracking. |
| `./.agents/skills/git-workflow/scripts/git_task.sh commit "<mensagem>"` | Roda os testes automatizados; se passarem, comita e dá push para o GitHub. |
| `./.agents/skills/git-workflow/scripts/git_task.sh finish` | Roda testes, faz merge semântico na `main`, publica no GitHub e limpa a branch. |
| `./.agents/skills/git-workflow/scripts/git_task.sh test` | Executa apenas os testes automatizados do Godot headless. |
| `./.agents/skills/git-workflow/scripts/git_task.sh status` | Exibe a branch atual, status de arquivos e remotes. |

---

## 📋 Convenção de Nomenclatura de Branches

Ao iniciar uma nova tarefa, use o prefixo adequado:

| Prefixo | Finalidade | Exemplo de Nome de Branch |
| :--- | :--- | :--- |
| `feature/` | Nova funcionalidade, inimigo, torre, shader ou HUD | `feature/boss-mantis-phase2` |
| `fix/` | Correção de bugs visuais, física, colisões ou lógica | `fix/enemy-floor-clamping` |
| `balance/` | Ajustes de economia, dano, HP, custos ou timings de ondas | `balance/wave-resource-costs` |
| `refactor/` | Melhorias de código, desacoplamento sem mudança funcional | `refactor/astar-grid-cleanup` |
| `perf/` | Otimizações de renderização, draw calls e MultiMesh | `perf/grass-multimesh-lod` |
| `chore/` | Atualização de assets, configurações ou testes | `chore/update-readme` |

---

## 🔄 Fluxo de Trabalho Passo a Passo para o Agente

Sempre que o usuário solicitar uma nova funcionalidade, correção ou melhoria:

### 1. Início da Tarefa (`start`)
Execute antes de iniciar as edições no código:
```bash
./.agents/skills/git-workflow/scripts/git_task.sh start <tipo> <nome-da-task>
```
*Exemplo*:
```bash
./.agents/skills/git-workflow/scripts/git_task.sh start feature water-flask-recharge
```
Isso garante que:
- A `main` local receba o último código remoto (`git pull --rebase origin main`).
- A branch `feature/water-flask-recharge` seja criada e publicada no GitHub imediatamente (`git push -u origin feature/...`).

### 2. Desenvolvimento & Commits Seguros (`commit`)
Conforme a task avança, comite usando Conventional Commits:
```bash
./.agents/skills/git-workflow/scripts/git_task.sh commit "feat(dew): add droplet collection particle and audio"
```
*Garantia*: O script executa automaticamente `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/test_runner.tscn`. Se qualquer teste quebrar, o commit é impedido de subir até que o erro seja corrigido.

### 3. Conclusão da Tarefa (`finish`)
Quando a task estiver pronta, revisada e testada:
```bash
./.agents/skills/git-workflow/scripts/git_task.sh finish
```
Isso:
- Roda uma rodada final de validação em headless.
- Faz merge de integração na `main`.
- Envia a `main` atualizada para o GitHub.
- Remove a branch de trabalho já integrada.
