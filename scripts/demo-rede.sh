#!/usr/bin/env bash
# ============================================================
# Demo — Redes e Isolamento (VPC / Subnets / Security Groups)
# ============================================================
# Prova, na prática, que a infraestrutura da equipe libera
# apenas o necessário:
#   - Site público: acessível (via Cloudflare Tunnel)
#   - Back-end (5000): bloqueado da internet
#   - Banco (27017): bloqueado da internet
#   - SSH (22): única porta de gerenciamento aberta
#
# Uso:
#   ./demo-rede.sh            # interativo (Enter para avançar)
#   DOMAIN=... VM_IP=... ./demo-rede.sh   # sobrescrever valores
#   AUTO=1 SLEEP=3 ./demo-rede.sh         # modo automático (3s entre passos)
# ============================================================

set -u

# ---- Configuração (sobrescreva via variáveis de ambiente) ----
DOMAIN="${DOMAIN:-equipe-sudo.kolpzs.com}"
VM_IP="${VM_IP:-129.148.50.233}"
SSH_PORT="${SSH_PORT:-22}"
BACKEND_PORT="${BACKEND_PORT:-5000}"
DB_PORT="${DB_PORT:-27017}"
TIMEOUT="${TIMEOUT:-5}"   # segundos de tolerância p/ considerar "bloqueado"

# ---- Cores (desativa quando não é terminal, ex.: CI) ----
if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; RED=$'\033[31m'
  YELLOW=$'\033[33m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  BOLD=''; GREEN=''; RED=''; YELLOW=''; CYAN=''; RESET=''
fi

ok()   { printf '%s\n' "${GREEN}${BOLD}[ OK ]${RESET} $*"; }
block() { printf '%s\n' "${YELLOW}${BOLD}[ BLOQUEADO ]${RESET} $*"; }
warn() { printf '%s\n' "${RED}${BOLD}[ ATENÇÃO ]${RESET} $*"; }
info() { printf '%s\n' "${CYAN}[INFO]${RESET} $*"; }

pause() {
  if [ "${AUTO:-0}" = "1" ]; then
    sleep "${SLEEP:-3}"
  else
    read -r -p "  ... [Enter] para continuar " _ || true
  fi
  printf '\n'
}

banner() {
  printf '%s\n' "${BOLD}==================================================${RESET}"
  printf '%s\n' "${BOLD}  DEMO — Redes e Isolamento (VPC/Subnets/SG/NAT)${RESET}"
  printf '%s\n' "${BOLD}  Infra da equipe: ${DOMAIN}  (VM ${VM_IP})${RESET}"
  printf '%s\n' "${BOLD}==================================================${RESET}"
  printf '\n'
}

summary() {
  printf '%s\n' "${BOLD}--------------------------------------------------${RESET}"
  printf '%s\n' "${BOLD} RESUMO DA DEMO${RESET}"
  printf '%s\n' "  Site https://${DOMAIN} ......... ACESSÍVEL (Cloudflare Tunnel)"
  printf '%s\n' "  Back-end ${VM_IP}:${BACKEND_PORT} ...... BLOQUEADO"
  printf '%s\n' "  Banco    ${VM_IP}:${DB_PORT} ...... BLOQUEADO"
  printf '%s\n' "  SSH      ${VM_IP}:${SSH_PORT} ......... ABERTO (gerenciamento)"
  printf '%s\n' "${BOLD}--------------------------------------------------${RESET}"
  printf '%s\n' "  Conclusão: rede bem configurada = só o necessário acessível."
  printf '%s\n' "  (Mesmo princípio de VPC + Subnets + Security Groups na AWS.)"
  printf '\n'
}

# ---- Passo 1: site deve estar acessível ----
step_site() {
  info "1) Site público — esperado: HTTP 200"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -m "$TIMEOUT" "https://${DOMAIN}")
  if [ "$code" = "200" ]; then
    ok "https://${DOMAIN} -> HTTP ${code} (acessível pela internet)"
    info "   Entra pelo Cloudflare Tunnel — NÃO abre porta 80/443 na VM."
  else
    warn "Site respondeu HTTP ${code} (esperado 200). Verificar antes de apresentar."
  fi
  pause
}

# ---- Passo genérico: porta deve estar BLOQUEADA ----
step_blocked() {
  local name="$1" port="$2"
  info "${name} (porta ${port}) — esperado: BLOQUEADO"
  if curl -s -o /dev/null -m "$TIMEOUT" "http://${VM_IP}:${port}" 2>/dev/null; then
    warn "Porta ${port} ${name} está ACESSÍVEL da internet — revisar Security List!"
  else
    block "${name} :${port} inacessível da internet (isolamento OK)"
  fi
  pause
}

# ---- Passo: SSH deve estar ABERTO ----
step_ssh() {
  info "SSH (porta ${SSH_PORT}) — esperado: ABERTO (única de gerenciamento)"
  if timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/${VM_IP}/${SSH_PORT}" 2>/dev/null; then
    ok "SSH ${VM_IP}:${SSH_PORT} aberto"
  else
    info "SSH não respondeu (pode estar restrito por IP — verificar no Security List)"
  fi
  pause
}

# ---- Fluxo principal ----
banner
step_site
step_blocked "Back-end (Express)" "$BACKEND_PORT"
step_blocked "Banco (MongoDB)"  "$DB_PORT"
step_ssh
summary
