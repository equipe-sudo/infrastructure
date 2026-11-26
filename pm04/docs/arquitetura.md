# Arquitetura — PM-04 (Smart Construction)

> **Projeto:** PM-04 — aplicação "Smart Construction"
> **Stack:** Next.js (`web`) + FastAPI (`api`) + PostgreSQL 17 + 2× SeaweedFS
> **Provedor:** Oracle Cloud Infrastructure (OCI) — Always Free, região `sa-saopaulo-1`

---

## 1. Visão geral e justificativa do provedor

O PM-04 provisiona a aplicação "Smart Construction" em **duas VMs OCI Always Free**:

- **`vm-sc-app`** (subnet pública, IP público) — Docker com gateway Nginx (TLS), `web`, `api`, `storage` (SeaweedFS editorial) e `private-storage` (SeaweedFS privado).
- **`vm-sc-db`** (subnet privada, **sem IP público**) — PostgreSQL 17 isolado; egress via NAT na VM app.

**Por que OCI:**

| Critério | Justificativa |
|---|---|
| **Custo** | Always Free é vitalício (sem cartão de crédito), não os 12 meses do AWS Free Tier. |
| **Experiência do time** | O time já opera OCI (`sa-saopaulo-1`), tem perfil CLI, Terraform provider e estado remoto em Object Storage. |
| **Recursos gratuitos** | 2 VMs `E2.1.Micro` (ou A1.Flex até 4 OCPU/24 GB), 200 GB de block/boot volume, 10 TB de egress/mês, 20 GB de Object Storage. |
| **Região** | `sa-saopaulo-1` (São Paulo) — baixa latência para o time e para a demonstração acadêmica. |
| **Trade-off** | Lock-in na OCI (nomenclatura VCN/security list própria). Aceito: o custo zero pesa mais que a portabilidade neste contexto acadêmico. |

---

## 2. Diagrama ASCII

### 2.1 Topologia de rede

```
                              Internet
                                 │
                        ┌────────▼─────────┐
                        │ Internet Gateway │  rota 0.0.0.0/0 → IGW (subnet pública)
                        └────────┬─────────┘
                                 │
   ┌─────────────────────────────┼──────────────────────────────────────────────┐
   │          VCN Smart Construction — 10.10.0.0/16 (sa-saopaulo-1)              │
   │                                                                             │
   │  ┌────────────────────────────────────┐    ┌─────────────────────────────┐  │
   │  │  Subnet PÚBLICA  10.10.1.0/24       │    │  Subnet PRIVADA 10.10.2.0/24 │  │
   │  │  (app)  Security List: SL-APP      │    │  (db)  Security List: SL-DB  │  │
   │  │                                    │    │                             │  │
   │  │  ┌──────────────────────────────┐  │    │  ┌───────────────────────┐  │  │
   │  │  │  VM vm-sc-app  (IP público)  │  │    │  │  VM vm-sc-db          │  │  │
   │  │  │  Docker:                     │  │    │  │  (sem IP público)│  │  │
   │  │  │   ├ nginx           :443 TLS │  │    │  │  PostgreSQL 17        │  │  │
   │  │  │   ├ web (Next.js)   :3000    │  │    │  │  porta :5432          │  │  │
   │  │  │   ├ api (FastAPI)   :8000    │  │    │  └──────────▲────────────┘  │  │
   │  │  │   ├ storage         SeaweedFS│  │    │             │ :5432        │  │  │
   │  │  │   └ private-storage SeaweedFS│  │    │             │ (SÓ da subnet │  │  │
   │  │  └───────────────▲──────────────┘  │    │             │  da app)     │  │  │
   │  │                  │ :443            │    └─────────────┼──────────────┘  │  │
   │  └──────────────────┼─────────────────┘                  │                 │  │
   │                     │                                    │                 │  │
   │                     │                          ┌─────────▼─────────┐       │  │
   │                     │                          │  NAT na VM app      │       │  │
   │                     │                          │  (masquerade) │       │  │
   │                     │                          └───────────────────┘       │  │
   └─────────────────────┼───────────────────────────────────────────────────────┘  │
                         │
                     Visitante (HTTPS :443)
```

### 2.2 Fluxo de uma requisição

```
Visitante
   │  HTTPS :443
   ▼
IGW → Nginx (vm-sc-app, TLS termina aqui)
   │
   ├── caminho "/" ..........→ web (Next.js) :3000   (páginas/UI)
   │
   └── caminho "/api/*" .....→ api (FastAPI) :8000
                                 │
                                 ├── leitura/escrita → storage (SeaweedFS editorial)  [objetos de conteúdo]
                                 ├── anexos/arquivos → private-storage (SeaweedFS privado) [só via api]
                                 │
                                 └── dados relacionais → PostgreSQL :5432 (vm-sc-db, subnet privada)
```

Regra de segregação: **tráfego de dados (5432) nunca atravessa a Internet** — a `api` na subnet pública alcança o PostgreSQL pela rota interna da VCN, restringida por security list.

---

## 3. Justificativa da distribuição

| Decisão | Motivo |
|---|---|
| **PostgreSQL em VM exclusiva** (`vm-sc-db`) | Requisito da demanda: isolamento do banco. Porta 5432 nunca pública; sem IP público; sem exposição direta. O egress (Docker/pacotes/OS updates) sai pela VM app, que faz NAT/masquerade. Facilita auditoria e backup sem disputar recurso com os containers da app. |
| **App em 1 VM** (`vm-sc-app`) | Reaproveita o `docker-compose` já existente (Nginx + web + api + storage) sem fragmentar o deploy. Menor superfície operacional: um ponto de deploy e observação. |
| **SeaweedFS junto da app** | O storage serve conteúdo da própria aplicação (editorial e privado) e não é acessado externamente de forma direta. Fica colocalizado com `api`/`web`, reduzindo latência e saltos de rede. |

**Trade-offs aceitos:**

- `vm-sc-app` é **single point of failure** do frontend/API/storage. Aceitável no escopo acadêmico e no free tier (sem SLA).
- Banco na mesma VCN mas em VM separada: não é um serviço gerenciado (sem HA nativa). A separação em VM mitiga o risco de contenção de CPU/RAM com o Compose.

---

## 4. Rede e segurança

| Controle | Implementação |
|---|---|
| **HTTPS (TLS)** | Terminação TLS no Nginx (`:443`). `:80` apenas redireciona para HTTPS (ou fica fechada). |
| **Origem permitida** | A única porta exposta à Internet na subnet pública é `443` (e `22` para gerenciamento). Nenhuma outra porta aberta em `0.0.0.0/0`. |
| **Cookies seguros** | Cookies de sessão emitidos com `Secure` e `HttpOnly`; cabeçalho `SameSite` configurado. Tudo transmitido sob TLS. |
| **Segredos fora do repo** | Credenciais de banco, token/keys e variáveis ficam em arquivo `.env` ignorado pelo Git (referenciado por nome, nunca versionado por valor). Modelo em `.env.example`. |
| **Porta 5432 nunca pública** | `vm-sc-db` **não tem IP público** (subnet privada). Security list `SL-DB` aceita `:5432` **somente** da subnet da app (`10.10.1.0/24`). |
| **Acesso admin restrito** | SSH ao banco só via **bastion** (`vm-sc-app`): o time acessa a app por SSH com chave e, de lá, pula para `vm-sc-db`. `SL-DB` aceita `:22` apenas da subnet da app. |
| **Egress da subnet do banco** | Saída da `vm-sc-db` para a Internet (Docker, pacotes, OS updates) passa pela **VM app como NAT (masquerade)** — o Always Free desta tenancy tem **limite 0 de NAT gateways** nativos. A entrada continua bloqueada (só 5432/SSH da subnet da app). |

**Security lists (resumo de regras de ingresso):**

```
SL-APP (subnet pública 10.10.1.0/24)
   ingress: TCP 443  ← 0.0.0.0/0  (visitantes, via Nginx)
   ingress: TCP 22   ← origem administrativa restrita (bastion/time)
   egress:  all      → 0.0.0.0/0

SL-DB (subnet privada 10.10.2.0/24)
   ingress: TCP 5432 ← 10.10.1.0/24 (SÓ a subnet da app)
   ingress: TCP 22   ← 10.10.1.0/24 (bastion via vm-sc-app)
   egress:  all      → via NAT na VM app (masquerade)
```

---

## 5. Persistência e backup/restauração

### 5.1 Persistência (volumes Docker)

| Serviço | Volume | Conteúdo |
|---|---|---|
| PostgreSQL | `pgdata` (bind ou volume nomeado) | Dados do cluster Postgres 17 (`/var/lib/postgresql/data`) |
| SeaweedFS editorial | `seaweed-editorial` | Objetos de conteúdo público/editorial |
| SeaweedFS privado | `seaweed-private` | Anexos/arquivos restritos |

Todos usam **volumes nomeados/bind** — sobrevivem a `docker compose down` e a recriação de container. O boot volume da VM não é a camada de persistência (apenas o host).

### 5.2 Backup / restauração

| Item | Estratégia |
|---|---|
| **Banco (PostgreSQL)** | `pg_dump` periódico (cron, ex.: diário) gravado em Object Storage (bucket de backup, dentro dos 20 GB free). Retenção: N últimos dumps. |
| **Storage (SeaweedFS)** | Sincronização incremental dos volumes para Object Storage (ou replica para o outro volume), conforme janela de retenção definida. |
| **Restauração** | `pg_restore`/`psql` a partir do dump no Object Storage; re-subir containers com os volumes restaurados. Procedimento documentado em runbook. |

**Ponto de atenção:** backup é **manual/agendado**, não há HA nem PITR nativo no free tier. Para o escopo acadêmico isso é suficiente; o risco é documentado, não silenciado.

---

## 6. Mapeamento requisito → recurso entregue

| Requisito da demanda | Recurso entregue |
|---|---|
| Aplicação web (frontend) | Next.js `web` (container, `:3000`) na `vm-sc-app` |
| API de backend | FastAPI `api` (container, `:8000`) na `vm-sc-app` |
| Banco de dados relacional | PostgreSQL 17 em `vm-sc-db` (VM dedicada, subnet privada) |
| Armazenamento de conteúdo/editorial | SeaweedFS `storage` na `vm-sc-app` |
| Armazenamento privado (anexos) | SeaweedFS `private-storage` na `vm-sc-app` |
| TLS / porta de entrada | Nginx `:443` (terminação TLS) na `vm-sc-app` |
| Isolamento do banco (5432 não público) | `vm-sc-db` sem IP público (subnet privada) + `SL-DB` restrito à subnet da app + egress via NAT na VM app |
| Acesso administrativo seguro | SSH via bastion (`vm-sc-app`) + chaves; `:22` restrito |
| Custo zero | Shapes Always Free, volumes ≤ 200 GB, egress dentro de 10 TB |
| Infra como código | Terraform (provider OCI) — VCN, subnets, security lists, gateways, VMs |

---

## Ações pendentes de aprovação

- Nenhuma execução de infraestrutura foi realizada por este documento (apenas documentação).
- Backups agendados e retenção dependem de definição do time (janela/frequência).
- A regra de origem exata do SSH administrativo (CIDR do time) precisa ser fixada na security list antes do apply.
