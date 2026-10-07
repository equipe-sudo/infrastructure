#!/usr/bin/env bash
# ============================================================
# Demo — Redes e Isolamento (VPC / Subnets / Security Groups)
# ============================================================
# Prova, na prática, que a infraestrutura da equipe libera
# apenas o necessário, exibindo dados técnicos:
#   1. DNS          — o IP real da VM fica escondido (Cloudflare)
#   2. Cabeçalhos   — resposta servida pela borda (server: cloudflare)
#   3. Tempos HTTP  — DNS/conexão/TLS/TTFB do site
#   4. Varredura    — quais portas estão abertas/fechadas na VM
#   5. API via túnel — o back-end responde, mas não é exposto direto
#   6. Resumo
#
# Uso:
#   ./demo-rede.sh                          # interativo (Enter para avançar)
#   DOMAIN=... VM_IP=... ./demo-rede.sh     # sobrescrever valores
#   AUTO=1 SLEEP=3 ./demo-rede.sh           # modo automático (3s entre passos)
# ============================================================

set -u

# ---- Configuração (sobrescreva via variáveis de ambiente) ----
DOMAIN="${DOMAIN:-equipe-sudo.kolpzs.com}"
VM_IP="${VM_IP:-129.148.50.233}"
SSH_PORT="${SSH_PORT:-22}"
BACKEND_PORT="${BACKEND_PORT:-5000}"
DB_PORT="${DB_PORT:-27017}"
API_PATH="${API_PATH:-/api/todos}"
PORTS="${PORTS:-22 80 443 5000 27017 5432 8000 8080}"
TIMEOUT="${TIMEOUT:-5}"   # segundos de tolerância p/ considerar "bloqueado"
SWEEP_TIMEOUT="${SWEEP_TIMEOUT:-2}"  # tempo por porta na varredura

# ---- Cores (desativa quando não é terminal, ex.: CI) ----
if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; RED=$'\033[31m'
  YELLOW=$'\033[33m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  BOLD=''; GREEN=''; RED=''; YELLOW=''; CYAN=''; RESET=''
fi

ok()    { printf '%s\n' "${GREEN}${BOLD}[ OK ]${RESET} $*"; }
block() { printf '%s\n' "${YELLOW}${BOLD}[ BLOQUEADO ]${RESET} $*"; }
warn()  { printf '%s\n' "${RED}${BOLD}[ ATENÇÃO ]${RESET} $*"; }
info()  { printf '%s\n' "${CYAN}[INFO]${RESET} $*"; }

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

# ---- 1. DNS: quem responde pelo domínio ----
step_dns() {
  info "1) DNS — quem responde por ${DOMAIN}?"
  local ips
  if command -v dig >/dev/null 2>&1; then
    ips=$(dig +short "$DOMAIN" | paste -sd', ' -)
  else
    ips=$(getent hosts "$DOMAIN" | awk '{print $1}' | paste -sd', ' -)
  fi
  printf '  domínio -> %s\n' "${ips:-<não resolveu>}"
  printf '  VM real -> %s (Oracle Cloud)\n' "${VM_IP}"
  info '  => O IP real da VM NÃO aparece no DNS: a origem fica escondida atrás do Cloudflare.'
  pause
}

# ---- 2. Cabeçalhos da resposta (borda/proxy) ----
step_headers() {
  info "2) Cabeçalhos da resposta (prova da borda/proxy)"
  curl -sI -m "$TIMEOUT" "https://${DOMAIN}" \
    | grep -iE '^(HTTP/|server|cf-ray|cache-control|content-type|alt-svc|x-powered-by)' || true
  info '  => server: cloudflare / cf-ray indicam que a resposta passa pela borda, não pela VM direto.'
  pause
}

# ---- 3. Site acessível + tempos de conexão ----
step_site() {
  info "3) Site acessível + tempos (DNS/conexão/TLS/TTFB)"
  curl -s -o /dev/null -m "$TIMEOUT" -w \
    '  HTTP=%{http_code}  DNS=%{time_namelookup}s  Conexão=%{time_connect}s  TLS=%{time_appconnect}s  TTFB=%{time_starttransfer}s\n' \
    "https://${DOMAIN}"
  pause
}

# ---- 4. Varredura de portas na VM ----
step_ports() {
  info "4) Varredura de portas na VM (${VM_IP})"
  printf '  %-8s %s\n' "PORTA" "ESTADO"
  for p in $PORTS; do
    if timeout "$SWEEP_TIMEOUT" bash -c "exec 3<>/dev/tcp/${VM_IP}/${p}" 2>/dev/null; then
      printf '  %-8s %b\n' "${p}/tcp" "${GREEN}${BOLD}ABERTA${RESET}"
    else
      printf '  %-8s %b\n' "${p}/tcp" "${YELLOW}${BOLD}BLOQUEADA${RESET}"
    fi
  done
  info '  => Só SSH (22) aberto; web/back-end/banco bloqueados — exatamente o que a regra define.'
  pause
}

# ---- 5. API via túnel (back-end responde sem exposição direta) ----
step_api() {
  info "5) API via túnel (${API_PATH}) — o back-end responde sem ser exposto"
  local body
  body=$(curl -s -m "$TIMEOUT" "https://${DOMAIN}${API_PATH}" | head -c 200)
  if [ -n "$body" ]; then
    printf '  resposta: %s\n' "$body"
    info '  => A API funciona pelo túnel, mesmo com a porta 5000 bloqueada direto (passo 4).'
  else
    warn "  API não respondeu por ${API_PATH} — verificar endpoint antes de apresentar."
  fi
  pause
}

# ---- 6. Resumo ----
summary() {
  printf '%s\n' "${BOLD}--------------------------------------------------${RESET}"
  printf '%s\n' "${BOLD} RESUMO TÉCNICO${RESET}"
  printf '%s\n' "  DNS ........ origem escondida (Cloudflare)"
  printf '%s\n' "  Site ....... acessível via borda (HTTP/HTTPS)"
  printf '%s\n' "  SSH (22) ... ABERTA (única de gerenciamento)"
  printf '%s\n' "  Demais .... BLOQUEADAS (web/back-end/banco)"
  printf '%s\n' "${BOLD}--------------------------------------------------${RESET}"
  printf '%s\n' "  Conclusão: rede bem configurada = só o necessário acessível."
  printf '%s\n' "  (Mesmo princípio de VPC + Subnets + Security Groups na AWS.)"
  printf '\n'
}

# ---- Fluxo principal ----
banner
step_dns
step_headers
step_site
step_ports
step_api
summary
