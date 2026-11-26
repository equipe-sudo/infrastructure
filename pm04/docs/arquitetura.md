# Arquitetura — PM-04 (Smart Construction)

> **Projeto:** PM-04 — aplicação "Smart Construction"
> **Stack:** Next.js (`web`) + FastAPI (`api`) + PostgreSQL 17 + 2× SeaweedFS
> **Provedor:** Amazon Web Services (AWS) — região `us-east-1` (variável `aws_region`)

---

## 1. Visão geral e justificativa do provedor

O PM-04 provisiona a aplicação "Smart Construction" em **duas instâncias EC2 `t3.micro`** (Amazon Linux 2023):

- **`app`** (subnet pública, IP público via Elastic IP) — Docker com gateway Nginx (TLS), `web`, `api`, `storage` (SeaweedFS editorial) e `private-storage` (SeaweedFS privado).
- **`db`** (subnet privada, **sem IP público**) — PostgreSQL 17 isolado; egress via NAT na VM `app`.

### 1.1 Decisão de arquitetura: migração OCI → AWS

A infraestrutura nasceu em **OCI Always Free** (região `sa-saopaulo-1`) e foi migrada para **AWS Free Tier** por dois bloqueios observados em produção:

| Fator | O que aconteceu | Consequência |
|---|---|---|
| **Capacidade de host esgotada** | A região OCI `sa-saopaulo-1` passou a retornar **"Out of host capacity"** ao provisionar shapes Always Free. | As VMs não conseguiam ser criadas — a infraestrutura ficava bloqueada, não por código, mas por indisponibilidade de recursos na região. |
| **Tenancy limitada a 1 região** | A tenancy OCI estava restrita a uma única região, sem possibilidade de trocar para outra região com capacidade disponível. | Não havia saída dentro do próprio provedor: a única alternativa seria outra conta/tenancy, o que anulava a vantagem do free tier. |

A AWS removeu os dois bloqueios: o Free Tier oferece `t3.micro` em múltiplas regiões (`us-east-1`/`us-east-2`), e a troca de região é trivial (variável `aws_region`), eliminando a dependência de capacidade de uma região específica.

**Por que AWS (visão resumida):**

| Critério | Justificativa |
|---|---|
| **Capacidade disponível** | `t3.micro` Free Tier amplamente disponível em `us-east-1`/`us-east-2`; sem o risco de "out of host capacity" de uma única região. |
| **Mobilidade de região** | Região parametrizada (`aws_region`); trocar de AZ/região não exige nova conta. |
| **Custo** | Free Tier: 750 h/mês de `t3.micro` por 12 meses + US$ 100 de crédito AWS (margem de segurança). |
| **Familiaridade** | VPC/Security Groups/EC2/EBS/S3 são conceitos amplamente dominados pelo time e pela comunidade. |
| **Trade-off** | Free Tier AWS expira em 12 meses (não é vitalício como o OCI Always Free). Aceito: a migração prioriza **funcionar agora** em vez de custo-zero vitalício que não consegue provisionar. |

> **Registro de decisão:** a migração é uma decisão de arquitetura deliberada — a OCI foi descartada **por capacidade e limite de região**, não por custo. Ver `custos.md` (§4) para o comparativo completo.

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
   │           VPC Smart Construction — 10.10.0.0/16 (us-east-1)                │
   │                                                                             │
   │  ┌────────────────────────────────────┐    ┌─────────────────────────────┐  │
   │  │  Subnet PÚBLICA  10.10.1.0/24       │    │  Subnet PRIVADA 10.10.2.0/24 │  │
   │  │  (app)  Security Group: sg-app     │    │  (db)  Security Group: sg-db │  │
   │  │                                    │    │                             │  │
   │  │  ┌──────────────────────────────┐  │    │  ┌───────────────────────┐  │  │
   │  │  │  EC2 app  (Elastic IP)       │  │    │  │  EC2 db               │  │  │
   │  │  │  Docker:                     │  │    │  │  (sem IP público)     │  │  │
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
   │                     │                          │  NAT na EC2 app     │       │  │
   │                     │                          │  (masquerade)       │       │  │
   │                     │                          │  source/dest check  │       │  │
   │                     │                          │  desabilitado       │       │  │
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
IGW → Nginx (EC2 app, TLS termina aqui)
   │
   ├── caminho "/" ..........→ web (Next.js) :3000   (páginas/UI)
   │
   └── caminho "/api/*" .....→ api (FastAPI) :8000
                                  │
                                  ├── leitura/escrita → storage (SeaweedFS editorial)  [objetos de conteúdo]
                                  ├── anexos/arquivos → private-storage (SeaweedFS privado) [só via api]
                                  │
                                  └── dados relacionais → PostgreSQL :5432 (EC2 db, subnet privada)
```

Regra de segregação: **tráfego de dados (5432) nunca atravessa a Internet** — a `api` na subnet pública alcança o PostgreSQL pelo IP privado da VPC, restringido por Security Group (`sg-db` aceita 5432 só do CIDR da subnet da app).

---

## 3. Justificativa da distribuição

| Decisão | Motivo |
|---|---|
| **PostgreSQL em instância exclusiva** (`db`) | Requisito da demanda: isolamento do banco. Porta 5432 nunca pública; sem IP público; sem exposição direta. O egress (Docker/pacotes/OS updates) sai pela EC2 `app`, que faz NAT/masquerade. Facilita auditoria e backup sem disputar recurso com os containers da app. |
| **App em 1 instância** (`app`) | Reaproveita o `docker-compose` já existente (Nginx + web + api + storage) sem fragmentar o deploy. Menor superfície operacional: um ponto de deploy e observação. |
| **SeaweedFS junto da app** | O storage serve conteúdo da própria aplicação (editorial e privado) e não é acessado externamente de forma direta. Fica colocalizado com `api`/`web`, reduzindo latência e saltos de rede. |
| **NAT via EC2 `app` (sem NAT Gateway pago)** | O NAT Gateway da AWS custa ~US$ 0,045/h (~US$ 32/mês) + taxa por GB processado — incompatível com o objetivo de custo zero. A EC2 `app` já existe e faz `MASQUERADE` para o egress do banco: route table da subnet privada aponta `0.0.0.0/0` para a ENI da `app` (com *source/destination check* desabilitado). Custo incremental: zero. |

**Trade-offs aceitos:**

- A EC2 `app` é **single point of failure** do frontend/API/storage **e** do NAT do banco. Se ela cair, o banco perde egress (não acessa a Internet) — aceitável no escopo acadêmico/demo (sem SLA).
- Banco na mesma VPC mas em instância separada: não é um serviço gerenciado (sem HA nativa). A separação em instância mitiga o risco de contenção de CPU/RAM com o Compose.
- NAT via instância (e não serviço gerenciado) é mais simples e zero-custo, mas perde a alta disponibilidade nativa do NAT Gateway. Como o próprio frontend já é single-AZ/single-node, a perda de HA no egress do banco não muda o patamar de disponibilidade do projeto.

---

## 4. Rede e segurança

| Controle | Implementação |
|---|---|
| **HTTPS (TLS)** | Terminação TLS no Nginx (`:443`). `:80` apenas redireciona para HTTPS (ou fica fechada). |
| **Origem permitida** | As únicas portas expostas à Internet na subnet pública são `22`, `80` e `443`. Nenhuma outra porta aberta em `0.0.0.0/0`. |
| **Cookies seguros** | Cookies de sessão emitidos com `Secure` e `HttpOnly`; cabeçalho `SameSite` configurado. Tudo transmitido sob TLS. |
| **Segredos fora do repo** | Credenciais de banco, token/keys e variáveis ficam em arquivo `.env` ignorado pelo Git (referenciado por nome, nunca versionado por valor). Modelo em `.env.example`. |
| **Porta 5432 nunca pública** | A EC2 `db` **não tem IP público** (subnet privada com `map_public_ip_on_launch = false`). O Security Group `sg-db` aceita `:5432` **somente** do CIDR da subnet da app (`10.10.1.0/24`). |
| **Acesso admin restrito** | SSH ao banco só via **bastion** (EC2 `app`): o time acessa a app por SSH com chave e, de lá, pula para `db`. `sg-db` aceita `:22` apenas da subnet da app. |
| **Egress da subnet do banco** | Saída da `db` para a Internet (Docker, pacotes, OS updates) passa pela **EC2 `app` como NAT (masquerade)** — sem NAT Gateway pago. A entrada continua bloqueada (só 5432/SSH da subnet da app). |

**Security Groups (resumo de regras de ingresso):**

```
sg-app (subnet pública 10.10.1.0/24)
   ingress: TCP 443  ← 0.0.0.0/0  (visitantes, via Nginx)
   ingress: TCP 80   ← 0.0.0.0/0  (redireciona p/ HTTPS)
   ingress: TCP 22   ← origem administrativa restrita (bastion/time)
   egress:  all      → 0.0.0.0/0

sg-db (subnet privada 10.10.2.0/24)
   ingress: TCP 5432 ← 10.10.1.0/24 (SÓ a subnet da app)
   ingress: TCP 22   ← 10.10.1.0/24 (bastion via EC2 app)
   egress:  all      → via NAT na EC2 app (masquerade)
```

> **Nota de mecanismo AWS:** para a EC2 `app` atuar como NAT, o *source/destination check* da ENI precisa ser desabilitado, e a route table da subnet privada aponta `0.0.0.0/0` para essa ENI. A regra `MASQUERADE` é aplicada no SO da `app` (iptables).

---

## 5. Persistência e backup/restauração

### 5.1 Persistência (volumes Docker + EBS)

| Serviço | Volume | Conteúdo |
|---|---|---|
| PostgreSQL | `pgdata` (bind ou volume nomeado) | Dados do cluster Postgres 17 (`/var/lib/postgresql/data`) |
| SeaweedFS editorial | `seaweed-editorial` | Objetos de conteúdo público/editorial |
| SeaweedFS privado | `seaweed-private` | Anexos/arquivos restritos |

Todos usam **volumes nomeados/bind** — sobrevivem a `docker compose down` e a recriação de container. O volume raiz (EBS `gp3`) da instância não é a camada de persistência (apenas o host).

### 5.2 Backup / restauração

| Item | Estratégia |
|---|---|
| **Banco (PostgreSQL)** | `pg_dump` periódico (cron, ex.: diário) gravado em **S3** (bucket de backup, dentro dos 5 GB Free Tier). Retenção: N últimos dumps. |
| **Storage (SeaweedFS)** | Sincronização incremental dos volumes para **S3** (ou replica para o outro volume), conforme janela de retenção definida. |
| **Restauração** | `pg_restore`/`psql` a partir do dump no S3; re-subir containers com os volumes restaurados. Procedimento documentado em runbook. |

**Ponto de atenção:** backup é **manual/agendado**, não há HA nem PITR nativo no free tier. Para o escopo acadêmico isso é suficiente; o risco é documentado, não silenciado.

---

## 6. Mapeamento requisito → recurso entregue

| Requisito da demanda | Recurso entregue |
|---|---|
| Aplicação web (frontend) | Next.js `web` (container, `:3000`) na EC2 `app` |
| API de backend | FastAPI `api` (container, `:8000`) na EC2 `app` |
| Banco de dados relacional | PostgreSQL 17 na EC2 `db` (instância dedicada, subnet privada) |
| Armazenamento de conteúdo/editorial | SeaweedFS `storage` na EC2 `app` |
| Armazenamento privado (anexos) | SeaweedFS `private-storage` na EC2 `app` |
| TLS / porta de entrada | Nginx `:443` (terminação TLS) na EC2 `app` |
| Isolamento do banco (5432 não público) | EC2 `db` sem IP público (subnet privada) + `sg-db` restrito à subnet da app + egress via NAT na EC2 `app` |
| Acesso administrativo seguro | SSH via bastion (EC2 `app`) + chaves; `:22` restrito |
| Custo zero | Free Tier (750 h/mês de `t3.micro`, S3 5 GB, egress 100 GB) + US$ 100 de crédito |
| Infra como código | Terraform (provider AWS) — VPC, subnets, security groups, IGW, EC2, ENI/NAT |

---

## Ações pendentes de aprovação

- Nenhuma execução de infraestrutura foi realizada por este documento (apenas documentação).
- Backups agendados e retenção dependem de definição do time (janela/frequência).
- A regra de origem exata do SSH administrativo (CIDR do time) precisa ser fixada no Security Group antes do apply.
- O código Terraform/Ansible ainda reflete OCI; a migração do IaC para o provider AWS é escopo separado desta documentação.
