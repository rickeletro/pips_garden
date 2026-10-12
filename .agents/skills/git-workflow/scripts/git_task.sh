#!/usr/bin/env bash
# ==============================================================================
# 🚀 Git Workflow Automation Script — Jardim Miúdo (Pip's Garden)
# ==============================================================================
# Padroniza criação de branches, testes automatizados e sincronização com o GitHub.
# ==============================================================================

set -e

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$REPO_ROOT"

COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[1;31m"
COLOR_RESET="\033[0m"

log_info() { echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_RESET}"; }
log_success() { echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}"; }
log_warn() { echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}"; }
log_error() { echo -e "${COLOR_RED}❌ $1${COLOR_RESET}"; }

run_tests() {
    log_info "Executando testes automatizados (test_runner.tscn)..."
    if [ -x "$GODOT_BIN" ]; then
        if "$GODOT_BIN" --headless --path . scenes/test_runner.tscn > /tmp/godot_test.log 2>&1; then
            log_success "Todos os testes automatizados passaram com 100% de sucesso!"
            return 0
        else
            log_error "Falha nos testes automatizados! Detalhes:"
            tail -n 25 /tmp/godot_test.log
            return 1
        fi
    else
        log_warn "Godot não encontrado em $GODOT_BIN. Pulando execução de testes."
        return 0
    fi
}

cmd_start() {
    local TYPE="$1"
    local NAME="$2"

    if [ -z "$TYPE" ] || [ -z "$NAME" ]; then
        log_error "Uso: ./git_task.sh start <feature|fix|balance|chore|perf> <nome-da-task>"
        exit 1
    fi

    # Normalizar nome da branch (substituir espaços por hífens e lowercase)
    NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
    local BRANCH="${TYPE}/${NAME}"

    # Verificar se há alterações não commitadas
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Working tree possui alterações pendentes. Faça commit ou stash antes de iniciar nova branch."
        git status -s
        exit 1
    fi

    log_info "Atualizando branch main com origin..."
    git checkout main
    git pull --rebase origin main

    log_info "Criando e mudando para a branch '$BRANCH'..."
    git checkout -b "$BRANCH"

    log_info "Publicando branch '$BRANCH' no repositório remoto (GitHub)..."
    git push -u origin "$BRANCH"

    log_success "Branch '$BRANCH' criada e sincronizada com origin!"
}

cmd_commit() {
    local MSG="$1"
    if [ -z "$MSG" ]; then
        log_error "Uso: ./git_task.sh commit \"feat: sua mensagem descritiva\""
        exit 1
    fi

    local CURRENT_BRANCH
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if [ "$CURRENT_BRANCH" == "main" ]; then
        log_warn "Você está comitando diretamente na branch 'main'."
    fi

    # Validação obrigatória por teste
    if ! run_tests; then
        log_error "Commit cancelado: os testes automatizados falharam!"
        exit 1
    fi

    log_info "Adicionando alterações e criando commit..."
    git add -A
    git commit -m "$MSG"

    log_info "Enviando alterações para o GitHub ($CURRENT_BRANCH)..."
    git push origin "$CURRENT_BRANCH"

    log_success "Commit enviado com sucesso para origin/$CURRENT_BRANCH!"
}

cmd_finish() {
    local CURRENT_BRANCH
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if [ "$CURRENT_BRANCH" == "main" ]; then
        log_error "Você já está na branch main. Use finish a partir de uma branch de feature/fix."
        exit 1
    fi

    # Validação obrigatória
    if ! run_tests; then
        log_error "Finalização cancelada: os testes automatizados falharam!"
        exit 1
    fi

    # Se houver pendências locais, avisa
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Existem alterações pendentes não commitadas. Execute 'commit' antes de finalizar."
        exit 1
    fi

    log_info "Garantindo que $CURRENT_BRANCH está sincronizada com o remoto..."
    git push origin "$CURRENT_BRANCH"

    log_info "Alternando para main e atualizando com origin..."
    git checkout main
    git pull --rebase origin main

    log_info "Integrando $CURRENT_BRANCH na main..."
    git merge --no-ff "$CURRENT_BRANCH" -m "merge: integrar $CURRENT_BRANCH na main"

    # Rodar testes novamente na main após o merge
    if ! run_tests; then
        log_error "Testes falharam após merge! Abortando push na main."
        git reset --hard HEAD~1
        git checkout "$CURRENT_BRANCH"
        exit 1
    fi

    log_info "Enviando main atualizada para o GitHub..."
    git push origin main

    log_info "Limpando branch de feature remota e local..."
    git push origin --delete "$CURRENT_BRANCH" || true
    git branch -d "$CURRENT_BRANCH" || true

    log_success "Task finalizada! Branch $CURRENT_BRANCH integrada na main e publicada no GitHub."
}

cmd_status() {
    local CURRENT_BRANCH
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${COLOR_BLUE}📌 Branch Atual:${COLOR_RESET} $CURRENT_BRANCH"
    echo -e "${COLOR_BLUE}🌐 Remotes:${COLOR_RESET}"
    git remote -v
    echo -e "${COLOR_BLUE}📝 Status do Repositório:${COLOR_RESET}"
    git status -s
}

case "$1" in
    start)
        cmd_start "$2" "$3"
        ;;
    commit)
        cmd_commit "$2"
        ;;
    finish)
        cmd_finish
        ;;
    test)
        run_tests
        ;;
    status)
        cmd_status
        ;;
    *)
        echo "Uso: $0 {start <tipo> <nome> | commit <msg> | finish | test | status}"
        echo "Exemplos:"
        echo "  $0 start feature enemy-beetle-ai"
        echo "  $0 start fix camera-occlusion"
        echo "  $0 commit \"feat(enemy): improve beetle charging logic\""
        echo "  $0 finish"
        echo "  $0 test"
        echo "  $0 status"
        exit 1
        ;;
esac
