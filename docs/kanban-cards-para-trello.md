# Cards para o Trello — Equipe SUDO (Jogo de Slots 🎰)

> **Escopo definido pela PO Fernanda em 28/07.** Projeto migrou de CRUD genérico para Jogo de Caça-Níquel.
>
> **Prioridades:** 🔴 P0 — Essencial (MVP) | 🟡 P1 — Importante | 🟢 P2 — Melhoria
>
> **Épicos:** A=Núcleo do jogo | B=Apostas | C=Carteira/Saldo | D=Vitrine visual

---

## 🖥️ INFRAESTRUTURA & DEVOPS (João Pedro)

| # | Título | Prioridade |
|---|---|---|
| INFRA1 | 🔴 [P0] Provisionar VCN + Subnet + Security List (Terraform) | P0 |
| INFRA2 | 🔴 [P0] Provisionar VM A1.Flex (Terraform) | P0 |
| INFRA3 | 🔴 [P0] Configurar Docker e dependências (Ansible) | P0 |
| INFRA4 | 🟡 [P1] Configurar Object Storage para tfstate | P1 |
| INFRA5 | 🔴 [P0] Subir Docker Compose (PostgreSQL + backend + frontend) | P0 |
| INFRA6 | 🟡 [P1] Testar acesso público — URL, portas, latência | P1 |
| INFRA7 | 🟡 [P1] Criar diagrama da arquitetura Cloud | P1 |
| INFRA8 | 🟡 [P1] Documentar justificativas técnicas | P1 |

---

## ⚙️ BACKEND — API do Jogo (Allan Domini)

| # | Título | Épico | Prioridade |
|---|---|---|---|
| B1 | 🔴 [P0] Estrutura do projeto backend (FastAPI + pastas + requirements) | — | P0 |
| B2 | 🔴 [P0] RNG + lógica de sorteio (grade 5×3) | A1 | P0 |
| B3 | 🔴 [P0] Detecção de prêmio (linhas vencedoras + combinações) | A2 | P0 |
| B4 | 🟡 [P1] Tabela de pagamentos (símbolos × multiplicadores) | A3 | P1 |
| B5 | 🔴 [P0] API de aposta — POST /girar (sortear + debitar + creditar) | A1+A2+B1 | P0 |
| B6 | 🔴 [P0] API de depósito (POST /depositar) e reset (POST /reset) | C2+C3 | P0 |
| B7 | 🟡 [P1] API de histórico (GET /historico) | C4 | P1 |
| B8 | 🟡 [P1] Containerizar backend (Dockerfile multi-stage) | — | P1 |
| B9 | 🟢 [P2] Documentar API com Swagger/OpenAPI | — | P2 |

---

## 🎨 FRONTEND — Máquina Caça-Níquel (Josiane Cristina)

| # | Título | Épico | Prioridade |
|---|---|---|---|
| F1 | 🔴 [P0] Definir tecnologia e estrutura do frontend | — | P0 |
| F2 | 🔴 [P0] Grade 5×3 com símbolos + botão GIRAR | A1 | P0 |
| F3 | 🟡 [P1] Animação do giro (rotação visual dos símbolos) | A4 | P1 |
| F4 | 🔴 [P0] Ajuste de aposta (+/– e MÁX) | B1 | P0 |
| F5 | 🟡 [P1] Auto-giro (repetir aposta automática) | B2 | P1 |
| F6 | 🔴 [P0] Exibir saldo + botão DEPOSITAR | C1+C2 | P0 |
| F7 | 🟡 [P1] Botão REDEFINIR saldo | C3 | P1 |
| F8 | 🟡 [P1] Painel da tabela de pagamentos | A3 | P1 |
| F9 | 🟡 [P1] Destaque visual da linha vencedora | A4 | P1 |
| F10 | 🟡 [P1] Jackpot progressivo (acumulado entre jogadores) | D1 | P1 |
| F11 | 🟢 [P2] Feed de ganhos (notificações de prêmios) | D2 | P2 |
| F12 | 🟢 [P2] Vitrine de jogos (seleção de máquinas) | D3 | P2 |
| F13 | 🟢 [P2] Temas visuais (skin da máquina) | D4 | P2 |
| F14 | 🟡 [P1] Containerizar frontend (Dockerfile + Nginx) | — | P1 |
| F15 | 🟡 [P1] Testar fluxo completo (girar → premiar → saldo) | — | P1 |

---

## 🗄️ BANCO DE DADOS (Josiane + João)

| # | Título | Prioridade |
|---|---|---|
| BD1 | 🔴 [P0] Modelar DER: usuário, giros, transações | P0 |
| BD2 | 🔴 [P0] Criar schema SQL (usuario, giro, transacao) | P0 |
| BD3 | 🟡 [P1] Seed data para testes | P1 |
| BD4 | 🔴 [P0] Configurar volume persistente PostgreSQL | P0 |
| BD5 | 🟡 [P1] Validar persistência pós-restart | P1 |
| BD6 | 🟢 [P2] Dicionário de dados | P2 |

---

## 📋 GESTÃO & DOCUMENTAÇÃO (Fernanda + Thiago)

| # | Título | Prioridade |
|---|---|---|
| G1 | 🔴 Cadastrar e organizar cards no Trello | Contínuo |
| G2 | 🔴 Priorizar backlog com PO (P0/P1/P2) | Dia 1 |
| G3 | 🟡 Acompanhar daily + atualizar kanban | Contínuo |
| G4 | 🔴 Relatório final de andamento | Final |
| G5 | 🔴 Coletar evidências (prints + vídeo até 5min) | Final |
| G6 | 🟡 Lições aprendidas | Final |
| G7 | 🟡 Facilitar cerimônias (planning, review, retrô) | Contínuo |
| G8 | 🔴 Validar entrega final (checklist completo) | Final |
| G9 | 🟢 [FUTURO] Organizar apresentação para turma | Final |

---

## ✅ CHECKLIST DE ENTREGA (professor)

Antes de finalizar, verificar:

- [ ] Jogo de slots acessível via navegador (URL pública)
- [ ] Grade 5×3 funcional — girar sorteia e exibe prêmio
- [ ] Saldo — depositar, apostar, creditar prêmio
- [ ] Dados persistem após restart do container
- [ ] Diagrama da arquitetura Cloud pronto
- [ ] Justificativas técnicas documentadas
- [ ] Kanban com movimentação real (mínimo 5 colunas)
- [ ] Cada card: título, descrição, responsável, prioridade, histórico
- [ ] Documento técnico da arquitetura (PDF ou MD)
- [ ] Evidências (prints ou vídeo até 5 min)
- [ ] Relatório de andamento
- [ ] Link do repositório Git
- [ ] Link do Kanban
- [ ] Todos os integrantes sabem explicar tudo
