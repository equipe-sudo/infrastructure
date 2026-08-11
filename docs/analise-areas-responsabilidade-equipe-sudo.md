# Análise de Áreas e Atividades — Equipe SUDO

> **Data:** 28/07/2026  
> **Org GitHub:** [equipe-sudo](https://github.com/equipe-sudo)  
> **Trello:** [Equipe SUDO](https://trello.com/b/GrZTNYh8/equipe-sudo)  
> **Stack:** OCI Always Free | Terraform | Ansible | Python | PostgreSQL | Docker  
> **Equipe:** 5 integrantes  
> **Entrega:** 1ª entrega do semestre — Aplicação Web em Nuvem

---

## 1. Requisitos da Entrega (Professor)

| # | O que entregar | Formato |
|---|---|---|
| 1 | Aplicação funcional acessível via navegador | URL publicada |
| 2 | Banco de dados operacional com persistência | Na cloud |
| 3 | Diagrama da arquitetura Cloud | Imagem/PDF |
| 4 | Justificativa técnica das escolhas | No documento |
| 5 | Kanban com evolução real (Backlog → Aprovado → Em Andamento → Em Testes → Finalizado) | Link Trello |
| 6 | Documento técnico da arquitetura | PDF ou MD |
| 7 | Evidências (prints ou vídeo até 5 min) | Anexo |
| 8 | Relatório de andamento (concluído, em desenvolvimento, dificuldades, próximos passos) | No documento |
| 9 | Identificação dos integrantes e papéis (PO e Scrum Master) | No documento |

> ⚠️ **Pipeline CI/CD não é avaliada nesta etapa.**  
> ✅ **Todos os integrantes devem saber explicar TUDO.**

---

## 2. Áreas de Responsabilidade

Dividi o projeto em **5 áreas** agrupadas em **3 grandes frentes** — garantindo que todos participem ativamente.

> **Todos devem entender o todo** para a apresentação. Não adianta só saber sua parte.

### 🔷 FRENTE A — Infraestrutura Cloud & DevOps
**Responsável:** João Pedro (Scrum Master / DevOps)  
**Escopo:** Toda a camada de cloud — provisionamento, rede, segurança, deploy

| Atividade | Descrição |
|---|---|
| Criar repos na org GitHub | `infrastructure`, `backend`, `frontend` |
| Provisionar VCN + Subnet + Security List (Terraform) | Rede isolada com portas 22, 80, 443 |
| Provisionar VM (A1.Flex — 2 OCPU + 12 GB RAM) via Terraform | Shape gratuito Always Free |
| Configurar Docker e dependências via Ansible | Docker, Docker Compose, Python, Nginx |
| Configurar Object Storage para tfstate | Backend remoto do Terraform |
| Subir PostgreSQL + backend + frontend via Docker Compose | Deploy completo da aplicação |
| Configurar domínio/DNS (se houver) | Acesso via navegador |
| Testar acesso público à aplicação | Validação de disponibilidade |
| Criar diagrama da arquitetura Cloud | Ferramenta: draw.io / Excalidraw |

---

### 🔷 FRENTE B — Aplicação (Backend + Frontend + Banco de Dados)
**Responsáveis:** Allan Marcos + Josiane Cristina  
**Apoio Técnico:** Thiago Andre (coringa)  
**Escopo:** Tudo que roda dentro da aplicação — API, interface, dados

#### Subárea B1 — Backend (API Python)

| Atividade | Descrição |
|---|---|
| Definir framework (FastAPI ou Flask) | Sugestão: FastAPI pela performance |
| Criar estrutura do projeto backend | Diretórios, requirements, entrypoint |
| Desenvolver models/entidades do sistema | Mapeamento ORM (SQLAlchemy) |
| Desenvolver rotas/endpoints da API | CRUD das entidades |
| Conectar ao PostgreSQL (via Docker) | String de conexão configurável |
| Testar endpoints localmente | Testes manuais + Postman/Insomnia |
| Containerizar backend (Dockerfile) | Imagem Docker do backend |
| Documentar API (Swagger/OpenAPI) | Documentação automática dos endpoints |

#### Subárea B2 — Frontend

| Atividade | Descrição |
|---|---|
| Definir tecnologia (React, Vue ou HTML/CSS/JS) | Decidir com o grupo |
| Criar estrutura do projeto frontend | Scaffold inicial |
| Desenvolver tela principal (dashboard/listas) | Consumir API backend |
| Desenvolver formulários (CRUD) | Criar, editar, excluir registros |
| Integrar frontend com API backend | Chamadas HTTP para o backend |
| Testar navegação e usabilidade | Fluxo completo do usuário |
| Containerizar frontend (Dockerfile) | Imagem Docker + Nginx |
| Responsividade e testes | Layout adaptável e validação visual |

#### Subárea B3 — Banco de Dados

| Atividade | Descrição |
|---|---|
| Modelar entidades e relacionamentos (DER) | Diagrama Entidade-Relacionamento |
| Criar script SQL de schema inicial | CREATE TABLEs, índices, constraints |
| Criar script de seed data | Dados de exemplo para testes |
| Validar schema com o backend ORM (SQLAlchemy) | Ajustar models para bater com SQL |
| Configurar volume persistente no Docker | Dados não serem perdidos com restart |
| Validar persistência pós-restart | Container parar/voltar sem perder dados |
| Documentar modelo de dados | Dicionário de dados |

---

### 🔷 FRENTE C — Gestão do Projeto & Documentação
**Responsável:** Fernanda Chini (P.O.)  
**Apoio:** Thiago Andre (coringa — ajuda em tudo que precisar)  
**Escopo:** Kanban, documentação, validação, evidências, apresentação

| Atividade | Descrição |
|---|---|
| Configurar quadro Trello com colunas | BACKLOG, PRÓXIMAS, EM ANDAMENTO, PAUSADAS, VALIDAÇÃO, FECHADAS |
| Cadastrar atividades no Backlog | Todas as atividades do projeto |
| Priorizar atividades (alto/médio/baixo) | Critério: dependências primeiro |
| Revisar e aprovar atividades concluídas | Movimentar para "FECHADAS" |
| Acompanhar Daily com a equipe | Remover impedimentos |
| Criar relatório de andamento | Concluído, em desenvolvimento, dificuldades, próximos passos |
| Coletar evidências (prints/vídeo até 5 min) | Comprovar funcionamento |
| Revisar documento técnico da arquitetura | Garantir coesão |
| Organizar apresentação final | Roteiro, quem fala o que |
| Validar entrega antes do prazo | Checklist completo |

---

## 3. Mapa: Frente ↔ Responsáveis

| Frente | Responsáveis | Papel |
|---|---|---|
| **A — Infraestrutura & DevOps** | **João Pedro** | Scrum Master e DevOps — executa e explica a infra |
| **B — Aplicação** (Back + Front + BD) | **Allan Marcos + Josiane Cristina** | Dupla de desenvolvimento — dividem as tasks entre si |
| **C — Gestão & Documentação** | **Fernanda Chini** (P.O.) | Product Owner — prioriza, valida, documenta |
| **Apoio Geral (Coringa)** | **Thiago Andre** | Ajuda onde precisar, especialmente com a Fer na gestão |

> **Thiago (coringa):** Fica alocado junto com a Fernanda para ajudar na gestão do quadro e documentação, mas pode reforçar qualquer frente que estiver atrasada.
>
> **Importante para a apresentação:** TODOS devem saber explicar a arquitetura, as decisões técnicas e o fluxo do projeto.

---

## 4. Dependências entre Frentes (ordem recomendada)

```
Semana 1                    Semana 2                    Semana 3
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ A. Infra        │──────▶│ B. Aplicação    │──────▶│ C. Gestão       │
│ - Terraform     │       │ - Backend API   │       │ - Documento     │
│ - VM + Docker   │       │ - Frontend      │       │ - Evidências    │
│ - GitHub        │       │ - Banco Dados   │       │ - Apresentação  │
└─────────────────┘       └────────┬────────┘       └────────┬────────┘
         │                        │                         │
         ▼                        ▼                         ▼
    João Pedro              Allan + Josi                 Fer + Thiago
    (infra primeiro)        (app em paralelo)            (fechamento)
```

> **Ordem crítica:** Infra (João) precisa estar pronta para a aplicação (Allan/Josi) poder rodar. Gestão (Fer/Thiago) acontece em paralelo durante todo o projeto.

---

## 5. Atividades para o Trello (prontas para cadastrar)

### BACKLOG (atividades a fazer — cadastre todas)

**Infraestrutura:**
1. Criar repositórios na organização GitHub equipe-sudo
2. Provisionar VCN + Subnet + Security List (Terraform)
3. Provisionar VM A1.Flex (Terraform)
4. Configurar Docker e dependências (Ansible)
5. Configurar Object Storage para estado do Terraform
6. Subir PostgreSQL + backend + frontend (Docker Compose)
7. Testar acesso público à aplicação

**Backend:**
8. Definir framework e estrutura do projeto Python
9. Desenvolver models e entidades
10. Desenvolver rotas/endpoints da API
11. Testar endpoints localmente
12. Containerizar backend (Dockerfile)
13. Integrar com banco de dados PostgreSQL
14. Documentar API (Swagger)

**Frontend:**
15. Definir tecnologia do frontend
16. Criar estrutura do projeto
17. Desenvolver telas da aplicação
18. Integrar frontend com API backend
19. Containerizar frontend (Dockerfile + Nginx)
20. Testar fluxo completo do usuário

**Banco de Dados:**
21. Modelar entidades e relacionamentos (DER)
22. Criar script SQL de schema
23. Criar script de seed data
24. Configurar volume persistente no Docker
25. Validar persistência pós-restart

**Gestão & Documentação:**
26. Configurar quadro Trello com colunas
27. Cadastrar atividades no Backlog
28. Acompanhar Daily e remover impedimentos
29. Criar relatório de andamento
30. Coletar evidências (prints/vídeo)
31. Criar documento técnico da arquitetura
32. Criar diagrama da arquitetura Cloud
33. Revisar entrega completa
34. Organizar apresentação

---

## 6. Cronograma Sugerido (3 semanas até entrega)

| Semana | Foco | Marcos |
|---|---|---|
| **Semana 1** (28/jul a 03/ago) | Setup inicial | Repos criados, Terraform aplicado, VM rodando, Kanban configurado |
| **Semana 2** (04/ago a 10/ago) | Desenvolvimento | Backend rodando, banco populado, frontend em desenvolvimento |
| **Semana 3** (11/ago a 17/ago) | Integração e entrega | Aplicação completa no ar, testes, documentação, evidências, apresentação |

---

## 7. Pontos de Atenção para Nota Zero

> ⚠️ Requisitos do professor que podem zerar nota individual:

- ❌ Integrante não souber explicar a arquitetura cloud → **nota zero individual**
- ❌ Integrante não participar da apresentação → **nota zero individual**
- ❌ Kanban criado só na véspera sem movimentação real → **prova de que não usaram**
- ❌ Aplicação fora do ar durante a correção → **entrega comprometida**
- ❌ Dados não persistirem (sumirem após restart) → **banco mal configurado**

> ✅ **Estratégia:** Cada área explica SUA parte, mas todos estudam o resumo geral. Sugiro fazer um ensaio geral 2 dias antes.
