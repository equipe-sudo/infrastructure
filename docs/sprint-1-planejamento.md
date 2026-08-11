# Sprint 1 — Planejamento

> **Período:** 28/07 (20h) → 01/08 (23h59) — 4 dias  
> **Entrega Final:** 07/08 (22h)  
> **Quadro:** https://trello.com/b/GrZTNYh8/equipe-sudo

---

## Estratégia

Todos trabalham em paralelo desde o início:

- **João Pedro** → provisiona a infra (VCN → VM → Docker)
- **Allan + Josi** → desenvolvem localmente (não precisam esperar a VM)
- **Fer + Thiago** → gestão roda em paralelo o tempo todo

---

## 🎯 Cards da Sprint 1 — Jogo de Slots

### 👤 JOÃO PEDRO — Infraestrutura (6 cards — inalterado)

| Card | Prioridade | Est. |
|---|---|---|
| 🔴 Provisionar VCN + Subnet + Security List (Terraform) | 🔥 Crítica | 1 dia |
| 🔴 Provisionar VM A1.Flex (Terraform) | 🔥 Crítica | 1 dia |
| 🔴 Configurar Docker e dependências (Ansible) | 🔥 Crítica | 1 dia |
| 🟡 Configurar Object Storage para tfstate | Alta | ½ dia |
| 🟡 Criar diagrama da arquitetura Cloud (rascunho) | Média | 1 dia |
| 🟡 Iniciar documento de justificativas técnicas | Média | ½ dia |

**Total estimado:** ~4 dias — apertado mas factível

> ⚠️ **Risco:** Se a VM não subir (limite OCI), usaremos Docker local para testes e subimos depois.

---

### 👥 ALLAN + JOSI — Jogo de Slots (dividido entre dupla)

**Allan — Backend (5 cards P0)**

| Card | Prioridade | Est. |
|---|---|---|
| 🔴 [B1] Criar estrutura do projeto backend (FastAPI) | 🔥 P0 | ½ dia |
| 🔴 [B2] Implementar RNG + lógica de sorteio (Épico A1) | 🔥 P0 | 1 dia |
| 🔴 [B3] Implementar detecção de prêmio (Épico A2) | 🔥 P0 | 1 dia |
| 🔴 [B5] API de aposta: POST /girar (A1+A2+B1) | 🔥 P0 | 1 dia |
| 🔴 [B6] API de depósito e reset de saldo (C2+C3) | 🔥 P0 | ½ dia |

**Total estimado Allan:** ~4 dias — bem apertado, foco total nos P0

**Josi — Frontend + BD (7 cards P0)**

| Card | Prioridade | Est. |
|---|---|---|
| 🔴 [F1] Definir tecnologia e estrutura do frontend | 🔥 P0 | ½ dia |
| 🔴 [F2] Criar tela do jogo: grade 5×3 + botão Girar (A1) | 🔥 P0 | 1 dia |
| 🔴 [F4] Tela de ajuste de aposta +/– e MÁX (B1) | 🔥 P0 | ½ dia |
| 🔴 [F6] Exibir saldo + botão Depositar (C1+C2) | 🔥 P0 | ½ dia |
| 🔴 [BD1] Modelar DER: usuário, giros, transações | 🔥 P0 | ½ dia |
| 🔴 [BD2] Criar schema SQL (usuario, giro, transacao) | 🔥 P0 | ½ dia |
| 🔴 [BD4] Configurar volume persistente do PostgreSQL | 🔥 P0 | ½ dia |

**Total estimado Josi:** ~4 dias — fazer BD primeiro (dia 1), depois frontend

---

### 🧑‍🤝‍🧑 FER + THIAGO — Gestão (4 cards)

| Card | Prioridade | Est. |
|---|---|---|
| 🔴 Cadastrar e organizar cards no Trello | 🔥 Crítica | Contínuo |
| 🔴 Priorizar backlog (ordenar dependências) | 🔥 Crítica | 1 dia |
| 🟡 Acompanhar daily e atualizar quadro | Alta | Contínuo |
| 🟡 Iniciar relatório de andamento da Sprint 1 | Média | 1 dia |

---

## 📊 O que teremos em 01/08

| Área | Entregue |
|---|---|
| ✅ **Infra** | VCN, VM, Docker, tfstate, diagrama rascunho |
| ✅ **Backend** | RNG + detecção de prêmio + API girar funcionando localmente |
| ✅ **BD** | DER + schema SQL (usuario/giro/transacao) + volume persistente |
| ✅ **Frontend** | Grade 5×3 com botão Girar, saldo, ajuste de aposta |
| ✅ **Gestão** | Trello organizado, daily rodando, relatório iniciado |

---

## ⚠️ Riscos da Sprint 1

| Risco | Impacto | Mitigação |
|---|---|---|
| Limite OCI Always Free (já tem 2+12 GB em uso) | Atraso infra | Testar local com Docker; se falhar, ajustar shape |
| Dependência: backend precisa do BD schema pronto | Bloqueio Allan | Josi faz BD no dia 1; Allan começa com estrutura e RNG (sem BD) |
| Escopo novo de slots mais complexo que CRUD | Prazo apertado | Priorizar apenas P0 na Sprint 1; P1/P2 ficam pra Sprint 2 |
| Fer/Thiago sem experiência com Scrum | Gestão fraca | João (SM) apoia nos primeiros dias |
