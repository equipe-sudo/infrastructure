# Análise de Impacto — Novo Escopo: Jogo de Slots

> **Data:** 28/07/2026  
> **Escopo antigo:** CRUD genérico (backend + frontend + BD)  
> **Novo escopo:** Jogo de caça-níquel (slots) com saldo, prêmios e persistência  
> **Fonte:** Requisitos enviados pela PO Fernanda

---

## 🔄 Mapeamento: Cards antigos × Novos requisitos

### 🖥️ INFRAESTRUTURA (João Pedro) — ✅ Quase tudo continua igual

| Card Antigo | No novo escopo? | Ação |
|---|---|---|
| VCN + Subnet + Security List | ✅ Sim, precisa | Manter |
| VM A1.Flex | ✅ Sim, precisa | Manter |
| Docker + Ansible | ✅ Sim, precisa | Manter |
| Object Storage tfstate | ✅ Sim, precisa | Manter |
| Subir PostgreSQL + Docker Compose | ✅ Sim, precisa | Manter |
| Testar acesso público | ✅ Sim, precisa | Manter |
| Diagrama arquitetura | ✅ Sim, precisa | Manter |
| Justificativas técnicas | ✅ Sim, precisa | Manter |

> **Conclusão:** Infra não muda — continua servindo qualquer aplicação web.

---

### 💻 BACKEND (Allan) — 🔴 MUDANÇA COMPLETA

| Card Antigo | Status | Novo Card |
|---|---|---|
| ~~Definir framework e estrutura~~ | ❌ Substituir | **B1 — Criar estrutura do projeto backend (FastAPI)** |
| ~~Models e entidades ORM~~ | ❌ Substituir | **B2 — Implementar RNG + lógica de sorteio (A1)** |
| ~~Rotas e endpoints CRUD~~ | ❌ Substituir | **B3 — Implementar detecção de prêmio (A2)** |
| ~~Conexão PostgreSQL~~ | ❌ Substituir | **B4 — Criar tabela de pagamentos na API (A3)** |
| ~~Testar endpoints~~ | ❌ Substituir | **B5 — API de aposta: girar, creditar, validar (A1+A2)** |
| ~~Containerizar backend~~ | ✅ Manter | **B6 — API de depósito e reset de saldo (C2+C3)** |
| ~~Documentar Swagger~~ | ✅ Manter | **B7 — API de histórico de giros (C4)** |
| | | **B8 — Containerizar backend (Dockerfile)** |
| | | **B9 — Documentar API (Swagger)** |

---

### 🎨 FRONTEND (Josi) — 🔴 MUDANÇA COMPLETA

| Card Antigo | Status | Novo Card |
|---|---|---|
| ~~Definir tecnologia~~ | ❌ Substituir | **F1 — Definir tecnologia e estrutura frontend** |
| ~~Estrutura do projeto~~ | ❌ Substituir | **F2 — Criar tela do jogo: grade 5×3 + botão Girar (A1)** |
| ~~Tela principal~~ | ❌ Substituir | **F3 — Implementar animação do giro (A4)** |
| ~~Formulários CRUD~~ | ❌ Substituir | **F4 — Tela de ajuste de aposta +/– e MÁX (B1)** |
| ~~Integrar API~~ | ❌ Substituir | **F5 — Giro automático (B2)** |
| ~~Containerizar~~ | ❌ Substituir | **F6 — Exibir saldo + botão Depositar (C1+C2)** |
| ~~Testar fluxo~~ | ❌ Substituir | **F7 — Botão Redefinir saldo (C3)** |
| ~~Responsividade~~ | ❌ Substituir | **F8 — Painel de tabela de pagamentos (A3)** |
| | | **F9 — Destaque na linha vencedora (A4)** |
| | | **F10 — Jackpot progressivo (D1)** |
| | | **F11 — Ganhos ao vivo / feed (D2)** |
| | | **F12 — Vitrine de outros jogos (D3)** |
| | | **F13 — Seletor de temas AWS/CyberVegas (D4)** |
| | | **F14 — Containerizar frontend (Dockerfile + Nginx)** |
| | | **F15 — Testar fluxo completo** |

---

### 🗄️ BANCO DE DADOS (Josi) — 🔴 MUDANÇA PARCIAL

| Card Antigo | Status | Novo Card |
|---|---|---|
| ~~Modelar DER genérico~~ | ❌ Substituir | **BD1 — Modelar DER: usuário, giros, transações** |
| ~~Schema SQL genérico~~ | ❌ Substituir | **BD2 — Criar schema SQL (usuario, giro, transacao)** |
| ~~Seed data~~ | ❌ Substituir | **BD3 — Seed data para testes** |
| ~~Volume persistente~~ | ✅ Manter | **BD4 — Configurar volume persistente** |
| ~~Validar persistência~~ | ✅ Manter | **BD5 — Validar persistência pós-restart** |
| ~~Dicionário de dados~~ | ✅ Manter | **BD6 — Dicionário de dados** |

---

### 📋 GESTÃO (Fer + Thiago) — ✅ Continua igual

| Card Antigo | Ação |
|---|---|
| Cadastrar cards no Trello | ✅ Manter |
| Priorizar backlog | ✅ Manter |
| Acompanhar sprint | ✅ Manter |
| Relatório final | ✅ Manter |
| Evidências | ✅ Manter |
| Apresentação | ✅ Manter |
| Validar entrega | ✅ Manter |
| Facilitar cerimônias | ✅ Manter |
| Lições aprendidas | ✅ Manter |

---

## 📊 Resumo do impacto

| Área | Cards atuais | Cards necessários | Ação |
|---|---|---|---|
| Infra | 8 | 8 | ✅ Manter todos |
| Backend | 7 | 9 | ❌ Substituir 5, manter 2 |
| Frontend | 8 | 15 | ❌ Substituir todos (8 → 15) |
| BD | 6 | 6 | ❌ Substituir 3, manter 3 |
| Gestão | 9 | 9 | ✅ Manter todos |
| **Total** | **38** | **47** | **9 cards mantidos, 29 substituídos/criados** |

---

## 🏁 Proposta de Sprint 1 ajustada (até 01/08)

Com o novo escopo, a prioridade muda para:

### 🔥 Prioridade MÁXIMA (P0 — sem isso não entrega)

| Quem | O que |
|---|---|
| **João** | Infra: VCN → VM → Docker (mesmo de antes) |
| **Allan** | RNG + lógica de sorteio + detecção de prêmio + API girar |
| **Josi** | Tela do jogo (grade 5×3), botão Girar, exibir saldo |
| **Ambos** | BD: schema usuario/giro + conexão |
| **Fer+Thiago** | Trello atualizado + daily |

### O que fica pra Sprint 2 (02/08 → 07/08)

- Jackpot, temas, feed de ganhos (P1/P2)
- Animações
- Testes finais
- Relatório + apresentação
