# Documentação de Infraestrutura — CyberVegas (Equipe Sudo)

> ⚠️ **DOCUMENTO HISTÓRICO / DESATUALIZADO.**
> Este texto descreve a versão **antiga** da aplicação (CyberVegas: FastAPI + PostgreSQL +
> Angular + OCIR). O ambiente atualmente em produção usa a **Todo App** (React + Node/Express +
> MongoDB) com imagens no **GHCR** e Cloudflare Tunnel.
> A documentação vigente está em **[`entrega-final-02/README.md`](entrega-final-02/README.md)** e
> em **[`ENTREGA_ATIVIDADE_INFRAESTRUTURA.md`](ENTREGA_ATIVIDADE_INFRAESTRUTURA.md)**.

> **Última atualização:** 2026-08-06
> **Ambiente:** Produção (dev) em `equipe-sudo.kolpzs.com`

---

## 1. Arquitetura Atual

### 1.1 Diagrama de Conexão dos Componentes

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        USER["👤 Usuário<br/>navegador web"]
    end

    subgraph Cloudflare["☁️ Cloudflare Edge"]
        CDN["CDN + DNS<br/>equipe-sudo.kolpzs.com"]
        TUNNEL_EDGE["Cloudflare Tunnel Edge<br/>(region1.v2.argotunnel.com)"]
    end

    subgraph OCI["🔶 Oracle Cloud — sa-saopaulo-1"]
        subgraph VCN["VCN: vcn-equipe-sudo-dev<br/>CIDR: 10.0.0.0/16"]
            subgraph Subnet["Subnet pública: sn-equipe-sudo-public-dev<br/>CIDR: 10.0.1.0/24"]
                VM["🖥️ VM: vm-equipe-sudo-dev<br/>Shape: VM.Standard.E2.1.Micro<br/>OS: Oracle Linux 8.10<br/>CPU: AMD EPYC 7551 (2 vCPU)<br/>RAM: 1 GB<br/>Disco: 36 GB<br/>IP público: 129.148.50.233<br/>IP privado: 10.0.1.x"]
            end
            IGW["Internet Gateway<br/>igw-equipe-sudo-dev"]
            SL["Security List<br/>(SSH:22 aberto,<br/>Egress total liberado)"]
        end
        OCIR["📦 OCIR (Container Registry)<br/>gru.ocir.io/grhkdi3glvat<br/>Repositórios:<br/>equipe-sudo/equipe-sudo-backend<br/>equipe-sudo/equipe-sudo-frontend"]
    end

    subgraph VM_Internals["🐳 Docker na VM"]
        subgraph Network["Docker Network: slots-net (bridge)"]
            CLOUDFLARED["cloudflared<br/>(Cloudflare Tunnel)<br/>QUIC → Cloudflare Edge"]
            NGINX["nginx:alpine<br/>(Frontend + Reverse Proxy)<br/>Porta interna: 80"]
            BACKEND["FastAPI + Uvicorn<br/>(Backend Python)<br/>Porta interna: 8000"]
            POSTGRES["PostgreSQL 16 Alpine<br/>(Banco de Dados)<br/>Porta interna: 5432<br/>Volume: slots-pgdata<br/>Tabelas: jogadores, jogadas, transacoes"]
        end
    end

    %% Conexões externas
    USER -->|"HTTPS :443"| CDN
    CDN -->|"QUIC (UDP)"| TUNNEL_EDGE
    TUNNEL_EDGE -->|"Túnel outbound (UDP)"| CLOUDFLARED

    %% Conexões internas Docker
    CLOUDFLARED -->|"HTTP :80"| NGINX
    NGINX -->|"/api/* → proxy_pass :8000"| BACKEND
    NGINX -->|"/* → arquivos estáticos"| NGINX
    BACKEND -->|"SQLAlchemy :5432"| POSTGRES

    %% Conexões de CI/CD
    OCIR -.->|"docker pull (HTTPS)"| VM

    %% Rotas
    VCN --> IGW
    IGW --> SL
    Subnet --> IGW

    style VM fill:#f9a825,color:#000
    style POSTGRES fill:#336791,color:#fff
    style BACKEND fill:#009688,color:#fff
    style NGINX fill:#269539,color:#fff
    style CLOUDFLARED fill:#f48120,color:#fff
    style OCIR fill:#c74634,color:#fff
```

### 1.2 Fluxo de uma Requisição

```
Usuário acessa https://equipe-sudo.kolpzs.com/cadastro
    │
    ▼
Cloudflare DNS resolve → CDN Edge (104.21.91.90 / 172.67.214.197)
    │
    ▼
Cloudflare Tunnel Edge encaminha via QUIC (UDP) para cloudflared na VM
    │
    ▼
cloudflared → nginx:80 (container slots-frontend)
    │
    ├── Rota /cadastro → SPA fallback: index.html (Angular)
    │       O Angular carrega, renderiza a página de cadastro
    │
    └── POST /api/cadastrar (quando usuário submete formulário)
            │
            ▼
        nginx location /api/ → proxy_pass http://backend:8000/
        (stripa o prefixo /api: /api/cadastrar → /cadastrar)
            │
            ▼
        FastAPI (container slots-backend)
            │
            ▼
        SQLAlchemy → PostgreSQL:5432 (container slots-postgres)
            │
            ▼
        INSERT INTO jogadores (...) VALUES (...)
            │
            ▼
        Resposta JSON → nginx → cloudflared → Cloudflare → Usuário
```

---

## 2. Terraform — Infraestrutura como Código

### 2.1 Especificações da VM

| Campo | Valor |
|---|---|
| **Shape** | `VM.Standard.E2.1.Micro` (Always Free) |
| **CPU** | 1 OCPU — AMD EPYC 7551 32-Core (2 vCPUs com SMT) |
| **RAM** | 1 GB |
| **Disco** | 36 GB (boot volume provisionado automaticamente) |
| **OS** | Oracle Linux 8.10 (x86_64) |
| **Região** | `sa-saopaulo-1` (São Paulo, Brasil) |
| **Rede** | VCN `vcn-equipe-sudo-dev` — CIDR `10.0.0.0/16` |
| **Subnet** | `sn-equipe-sudo-public-dev` — CIDR `10.0.1.0/24` |
| **IP Público** | `129.148.50.233` |
| **Firewall** | Apenas SSH (22) inbound; todo tráfego outbound liberado |

### 2.2 Estrutura de Arquivos

```
infrastructure/terraform/
├── main.tf                  # Provider OCI + backend config
├── variables.tf             # Declaração de variáveis (com defaults)
├── terraform.tfvars         # Valores reais (secrets — NUNCA commitar em plaintext)
├── vcn.tf                   # VCN, Subnet, Internet Gateway, Route Table, Security List
├── compute.tf               # VM (instância), imagem Oracle Linux, availability domain
├── container-registry.tf    # OCIR — repositórios de container Docker
├── outputs.tf               # Outputs (IP público, OCIDs, comando SSH)
├── terraform.tfstate        # Estado atual da infra (local)
└── .terraform.lock.hcl      # Lock de versões dos providers
```

### 2.3 Função de Cada Arquivo

#### `main.tf` — Provider e Configuração Global
- Define o **provider OCI** (`oracle/oci >= 5.0`)
- Configura autenticação via API Key (tenancy OCID, user OCID, fingerprint, private key)
- Possui backend S3 comentado — o estado (`terraform.tfstate`) hoje é local, mas pode ser migrado para OCI Object Storage

#### `variables.tf` — Variáveis Parametrizáveis
- **Autenticação:** `oci_tenancy_ocid`, `oci_user_ocid`, `oci_fingerprint`, `oci_private_key_path`
- **Rede:** `vcn_cidr` (default: `10.0.0.0/16`), `subnet_cidr` (default: `10.0.1.0/24`)
- **Compute:** `vm_shape`, `vm_ocpus`, `vm_memory_gb`, `ssh_public_key_path`
- **Tags:** `tag_project`, `tag_environment`, `tag_managed_by`

#### `terraform.tfvars` — Valores Reais (NÃO versionado)
- Contém os OCIDs reais do tenancy `kolpzs` (TENLS-6209)
- **Shape real:** `VM.Standard.E2.1.Micro` (Always Free AMD)
- Região: `sa-saopaulo-1`

#### `vcn.tf` — Rede (VCN + Segurança)
- Cria a **VCN** `vcn-equipe-sudo-dev` com range `10.0.0.0/16`
- Cria **Internet Gateway** `igw-equipe-sudo-dev`
- Configura **Route Table** padrão: `0.0.0.0/0 → Internet Gateway`
- Cria **Subnet pública** `sn-equipe-sudo-public-dev` com range `10.0.1.0/24`
- Configura **Security List** com regras:
  - **Inbound:** SSH (TCP 22) de qualquer IP
  - **Inbound:** ICMP (ping e path MTU discovery)
  - **Outbound:** TODO tráfego liberado (necessário para Cloudflare Tunnel QUIC, Docker pull do OCIR, atualizações)
- **Nenhuma porta de aplicação** (80, 443, 8000) exposta diretamente — todo tráfego web entra via Cloudflare Tunnel

#### `compute.tf` — Máquina Virtual
- Busca a imagem mais recente de **Oracle Linux 8** via data source
- Busca **availability domains** automaticamente
- Cria a instância `vm-equipe-sudo-dev`:
  - Usa o primeiro availability domain
  - VNIC na subnet pública com IP público
  - Injeção de chave SSH pública via metadata
  - Tags: `Project=equipe-sudo`, `Environment=dev`, `ManagedBy=terraform`

#### `container-registry.tf` — OCIR
- Namespace OCIR: `grhkdi3glvat` (tenancy KOLPZS)
- Cria dois repositórios Docker:
  - `equipe-sudo/equipe-sudo-backend`
  - `equipe-sudo/equipe-sudo-frontend`
- Configurados como **não imutáveis** (permite sobrescrever tags) e **privados**
- Outputs com URLs completas das imagens

#### `outputs.tf` — Informações Pós-Apply
- `vm_public_ip` — IP público da VM (usado nos secrets do GitHub Actions)
- `vm_private_ip` — IP privado
- `ssh_command` — Comando SSH pronto para uso
- `ocir_registry_url` — URL base do OCIR
- `ocir_backend_image` / `ocir_frontend_image` — Imagens completas com tag `:latest`

### 2.4 Comandos Essenciais

```bash
# Planejar mudanças
cd infrastructure/terraform
terraform plan -out=tfplan

# Aplicar
terraform apply tfplan

# Ver outputs
terraform output

# Destruir (⚠️ remove tudo)
terraform destroy
```

---

## 3. CI/CD — Build e Deploy Automatizados

### 3.1 Visão Geral dos Workflows

```mermaid
graph LR
    subgraph "Repositórios GitHub (equipe-sudo)"
        BACKEND_REPO["backend<br/>build-and-push.yml"]
        FRONTEND_REPO["frontend<br/>build-and-push.yml"]
        INFRA_REPO["infrastructure<br/>deploy-vm.yml"]
    end

    subgraph "OCI (Oracle Cloud)"
        OCIR_BUILD["OCIR<br/>gru.ocir.io"]
        VM_DEPLOY["VM OCI<br/>129.148.50.233"]
    end

    DEV["👤 Desenvolvedor<br/>push na main"] -->|"path filter: *.py, Dockerfile"| BACKEND_REPO
    DEV -->|"path filter: src/**, nginx.conf"| FRONTEND_REPO

    BACKEND_REPO -->|"docker build + push"| OCIR_BUILD
    FRONTEND_REPO -->|"docker build + push"| OCIR_BUILD

    DEV -->|"workflow_dispatch manual"| INFRA_REPO
    INFRA_REPO -->|"SSH: docker pull + compose up -d"| VM_DEPLOY
    OCIR_BUILD -.->|"imagens disponíveis para pull"| VM_DEPLOY

    style BACKEND_REPO fill:#009688,color:#fff
    style FRONTEND_REPO fill:#269539,color:#fff
    style INFRA_REPO fill:#f9a825,color:#000
    style OCIR_BUILD fill:#c74634,color:#fff
```

### 3.2 Workflow: Build & Push (Backend e Frontend)

**Arquivos:**
- `backend/.github/workflows/build-and-push.yml`
- `frontend/.github/workflows/build-and-push.yml`

**Triggers:**
- `push` na branch `main` com filtro de paths (só dispara se arquivos relevantes mudaram)
- `workflow_dispatch` (disparo manual via botão no GitHub)

**Path filters do Backend:**
```
**.py, Dockerfile, requirements.txt, .github/workflows/build-and-push.yml
```

**Path filters do Frontend:**
```
src/**, public/**, Dockerfile, nginx.conf, package.json, package-lock.json,
angular.json, tsconfig*.json, .github/workflows/build-and-push.yml
```

**Passos:**
1. **Checkout** (`actions/checkout@v4`)
2. **Login no OCIR** (`docker/login-action@v3`) — autentica com `OCIR_USERNAME` e `OCIR_AUTH_TOKEN`
3. **Build & Push** (`docker/build-push-action@v6`) — builda a imagem e sobe com duas tags:
   - `:latest` — usada pelo docker-compose na VM
   - `:<git-sha>` — tag imutável para rastreabilidade

**Nota importante:** O build **não usa cache** (`cache-from`/`cache-to` foram removidos). Isso evita falhas de cache no GitHub Actions com repositórios públicos no plano Free.

### 3.3 Workflow: Deploy to VM

**Arquivo:** `infrastructure/.github/workflows/deploy-vm.yml`

**Trigger:** `workflow_dispatch` (exclusivamente manual — deploy nunca é automático)

**Passos:**
1. **Checkout** do repositório `infrastructure`
2. **Gerar `.env`** com `CLOUDFLARE_TUNNEL_TOKEN` — cria o arquivo no runner antes de copiar pra VM
   ```bash
   cat > docker/.env << 'EOF'
   CLOUDFLARE_TUNNEL_TOKEN=${{ secrets.CLOUDFLARE_TUNNEL_TOKEN }}
   EOF
   ```
3. **SCP** (`appleboy/scp-action@v0.1.7`) — copia `docker/*` para `/home/opc/slots/` na VM
4. **SSH** (`appleboy/ssh-action@v1`) — executa na VM:
   ```bash
   docker login gru.ocir.io -u $OCIR_USERNAME --password-stdin
   docker compose pull          # baixa imagens :latest
   docker compose up -d --remove-orphans  # recria containers
   docker image prune -f        # remove imagens antigas
   ```

### 3.4 Secrets do GitHub Actions

| Secret | Repositório | Descrição |
|---|---|---|
| `OCIR_USERNAME` | backend, frontend, infrastructure | `grhkdi3glvat/kolpzs@proton.me` (tenancy KOLPZS) |
| `OCIR_AUTH_TOKEN` | backend, frontend, infrastructure | Auth token gerado no OCI Console |
| `SSH_PRIVATE_KEY` | infrastructure | Chave privada para acessar a VM (`opc@129.148.50.233`) |
| `VM_PUBLIC_IP` | infrastructure | `129.148.50.233` |
| `CLOUDFLARE_TUNNEL_TOKEN` | infrastructure | Token do túnel Cloudflare |

> **⚠️ GitHub Free Plan:** Secrets de organização **não** propagam para repositórios públicos. Cada repo tem seus próprios secrets.

### 3.5 Cloudflare Tunnel — Como o domínio funciona

```
┌────────────────────────────────────────────────────────────────┐
│                      CLOUDFLARE DASHBOARD                       │
│                                                                 │
│  DNS: equipe-sudo.kolpzs.com → CNAME → tunnel CF target         │
│  Tunnel: cybervegas-tunnel                                       │
│  Public Hostname: equipe-sudo.kolpzs.com → HTTP → frontend:80   │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ Token de autenticação
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                        VM (OCI)                                 │
│                                                                 │
│  docker/.env:                                                    │
│    CLOUDFLARE_TUNNEL_TOKEN=eyJh... (token JWT)                  │
│                                                                 │
│  container slots-tunnel (cloudflared):                           │
│    cloudflared tunnel --no-autoupdate run                        │
│    → Conexão QUIC outbound para Cloudflare Edge                  │
│    → Nenhuma porta inbound necessária                            │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

**Fluxo de configuração do túnel (feito manualmente uma vez):**

1. Criar túnel no Cloudflare Zero Trust Dashboard: `cloudflared tunnel create cybervegas-tunnel`
2. Configurar public hostname: `equipe-sudo.kolpzs.com → HTTP → frontend:80`
3. Obter o token: `cloudflared tunnel token cybervegas-tunnel`
4. Salvar token como secret `CLOUDFLARE_TUNNEL_TOKEN` no GitHub
5. O deploy-vm.yml gera `.env` com o token e o cloudflared se conecta automaticamente

**Vantagens do Tunnel sobre port-forwarding:**
- Zero portas expostas na VM (apenas SSH:22)
- TLS automático (certificado Cloudflare edge)
- Proteção DDoS da Cloudflare
- Sem necessidade de IP fixo ou NAT

---

## 4. Convenções DevOps — .env, Dockerfile e docker-compose

### 4.1 Arquivo `.env` — Variáveis de Ambiente

**Localização:** `infrastructure/docker/.env`

```env
# Gerado AUTOMATICAMENTE pelo workflow deploy-vm.yml
# NUNCA commitar este arquivo com secrets reais

CLOUDFLARE_TUNNEL_TOKEN=<token-jwt>
```

**Regras para o responsável de infra:**

| Regra | Motivo |
|---|---|
| `.env` é gerado pelo CI/CD, NUNCA manualmente | Evita vazamento de tokens |
| `.env.example` contém a estrutura sem valores | Referência para novos desenvolvedores |
| Secrets vêm dos GitHub Secrets, injetados no runner | Segurança — tokens nunca trafegam em plaintext no repositório |
| O `.env` **não** contém `DATABASE_URL` nem credenciais do DB | Essas são definidas diretamente no `docker-compose.yml` com defaults seguros |

### 4.2 Dockerfile — Padrão Multi-stage

#### Backend (`backend/Dockerfile`)

```dockerfile
FROM python:3.11-slim         # Imagem base leve (~50MB vs ~900MB do python:3.11)
WORKDIR /app
RUN apt-get install libpq-dev gcc && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get purge -y gcc       # Remove compilador após build (reduz imagem)
COPY . .
EXPOSE 8000
HEALTHCHECK --interval=15s CMD python -c "urllib.request.urlopen('http://localhost:8000/docs')"
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Padrões importantes:**
- **Single-stage** (não multi-stage) — Python não precisa de stage de build separado
- **Purge do gcc** após `pip install` — `psycopg2` precisa do compilador C só na instalação
- **Healthcheck** — usando `/docs` (Swagger UI) que sempre retorna 200
- **Sem `--reload`** em produção — uvicorn sem hot-reload

#### Frontend (`frontend/Dockerfile`)

```dockerfile
# Stage 1: Build Angular
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci                     # npm ci = determinístico, mais rápido que npm install
COPY . .
RUN npm run build

# Stage 2: Servir com nginx
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/cyber_vegas/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Padrões importantes:**
- **Multi-stage** — estágio de build (Node.js) é descartado, só o nginx vai pra produção
- **Imagem final:** `nginx:alpine` (~10MB) — extremamente leve
- **`npm ci`** em vez de `npm install` — build determinístico e reproduzível
- **nginx.conf** copiado como `default.conf` — substitui a config padrão do nginx

### 4.3 docker-compose.yml — Orquestração

**Localização:** `infrastructure/docker/docker-compose.yml`

```yaml
version: "3.8"

services:
  cloudflared:        # Túnel Cloudflare (entrada de tráfego)
    image: cloudflare/cloudflared:latest
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    restart: unless-stopped

  postgres:           # Banco de dados (isolado, sem porta exposta)
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-slots}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-slots123}
      POSTGRES_DB: ${POSTGRES_DB:-slots_db}
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-slots}"]

  backend:            # API FastAPI (interno, sem porta exposta)
    image: gru.ocir.io/grhkdi3glvat/equipe-sudo/equipe-sudo-backend:latest
    environment:
      DATABASE_URL: postgresql://slots:slots123@postgres:5432/slots_db
    depends_on:
      postgres:
        condition: service_healthy  # Só sobe quando PG responder pg_isready

  frontend:           # nginx + Angular (único exposto ao cloudflared)
    image: gru.ocir.io/grhkdi3glvat/equipe-sudo/equipe-sudo-frontend:latest
    depends_on:
      - backend
```

**Regras de ouro do docker-compose:**

| Regra | Explicação |
|---|---|
| **Nenhuma porta exposta** (exceto SSH 22 no security list) | Tudo acessado via Cloudflare Tunnel |
| **`depends_on` com `condition: service_healthy`** | Backend só inicia após PostgreSQL aceitar conexões |
| **Volume nomeado** (`slots-pgdata`) | Dados persistem entre deploys |
| **`init.sql` montado readonly** | Schema inicial do banco (executado apenas na primeira subida) |
| **Imagens via `:latest`** | O deploy sempre faz `docker compose pull` antes, garantindo a versão mais recente |
| **Rede bridge dedicada** (`slots-net`) | Isola os containers do resto do host |

### 4.4 Checklist para o DevOps receber um novo serviço

Quando um desenvolvedor entrega um novo microserviço, o responsável de infra precisa:

1. ✅ **Dockerfile** — builda e roda localmente? `docker build -t test . && docker run test`
2. ✅ **Healthcheck** — o container reporta saúde? `docker ps` mostra `(healthy)`?
3. ✅ **Variáveis de ambiente** — tudo configurável via env vars, sem hardcode?
4. ✅ **`.env.example`** — documenta quais variáveis são necessárias?
5. ✅ **Workflow de build** — `build-and-push.yml` existe e tem `workflow_dispatch`?
6. ✅ **docker-compose.yml** atualizado — novo serviço adicionado com `depends_on` correto?
7. ✅ **Sem portas expostas** — serviço só expõe porta internamente na rede Docker
8. ✅ **Teste de integração** — `curl localhost:8000/docs` do container backend alcança o banco?

---

## 5. Comunicação Backend ↔ Frontend ↔ Banco de Dados

### 5.1 Modelo de Dados (SQLAlchemy ORM)

```mermaid
erDiagram
    JOGADORES {
        int id PK
        string nome
        string email UK
        string senha
        float saldo
        datetime criado_em
    }
    JOGADAS {
        int id PK
        int jogador_id FK
        float aposta
        json grade
        json linhas_vencedoras
        float premio
        boolean jackpot_ativado
        float saldo_apos
        datetime criado_em
    }
    TRANSACOES {
        int id PK
        int jogador_id FK
        string tipo
        float valor
        float saldo_apos
        datetime criado_em
    }
    JOGADORES ||--o{ JOGADAS : "realiza"
    JOGADORES ||--o{ TRANSACOES : "possui"
```

### 5.2 Conexão com o Banco

**Arquivo:** `backend/database.py`

```python
# Conexão configurada via variável de ambiente DATABASE_URL
DATABASE_URL = os.getenv("DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/cybervegas")

# Fallback automático para SQLite se PostgreSQL não responder
# (útil para desenvolvimento local sem Docker)
try:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
except Exception:
    DATABASE_URL = "sqlite:///./cybervegas.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
```

**No docker-compose de produção:**
```
DATABASE_URL=postgresql://slots:slots123@postgres:5432/slots_db
```

- O host é `postgres` (nome do serviço no docker-compose) — resolução DNS interna do Docker
- Porta 5432 (padrão PostgreSQL)
- Tabelas criadas automaticamente via `Base.metadata.create_all(bind=engine)` no startup do FastAPI

### 5.3 Endpoints da API

| Método | Rota | Descrição | Autenticação |
|---|---|---|---|
| `GET` | `/` | Status da API | Pública |
| `POST` | `/cadastrar` | Criar novo jogador | Pública |
| `POST` | `/login` | Login (email + senha) | Pública |
| `POST` | `/girar` | Girar slot machine | ❌ (usa ID fixo no payload) |
| `POST` | `/depositar` | Adicionar saldo | ❌ (usa ID fixo no payload) |
| `POST` | `/reset` | Resetar saldo para R$100 | ❌ (usa ID fixo no payload) |
| `GET` | `/saldo` | Consultar saldo | ❌ (usa ID fixo no payload) |
| `GET` | `/pagamentos` | Tabela de multiplicadores | Pública |
| `GET` | `/historico` | Histórico de giros | ❌ (usa ID fixo no payload) |

### 5.4 Fluxo Completo: Cadastro de Usuário

```
1. Usuário preenche formulário em /cadastro
2. Angular chama: POST /api/cadastrar
   Body: { nome: "kolpzs", email: "kolpzs@kolpzs.com", senha: "123456" }
3. nginx recebe /api/cadastrar → proxy_pass http://backend:8000/
   Resultado: backend recebe POST /cadastrar
4. FastAPI → cadastrar_usuario() em main.py:
   - Valida se email já existe (HTTP 400 se duplicado)
   - Cria Jogador(nome, email, senha, saldo=SALDO_INICIAL)
   - db.add(jogador) → db.commit()
   - Retorna UsuarioResponse { id, nome, email, saldo, criado_em }
5. Resposta JSON volta: nginx → cloudflared → Cloudflare → navegador
6. Angular redireciona para /login ou /home
```

### 5.5 Comunicação Frontend → Backend

**Arquivo:** `frontend/src/environments/environment.ts`
```typescript
export const environment = {
  SERVIDOR: '/api'   // Caminho relativo → usa o mesmo domínio da app
};
```

**Arquivo:** `frontend/src/app/services/slot.service.ts`
```typescript
private readonly apiUrl = environment.SERVIDOR;  // '/api'

login(email, senha)    → POST /api/login
cadastrar(nome, email) → POST /api/cadastrar
getSaldo()             → GET  /api/saldo
girar(aposta)          → POST /api/girar
depositar(valor)       → POST /api/depositar
```

**Por que caminho relativo (`/api`)?**
- No browser do usuário, `localhost:8000` NÃO funciona (localhost é a máquina do cliente)
- Com `/api`, a requisição vai para o **mesmo domínio** (`equipe-sudo.kolpzs.com/api/...`)
- O nginx intercepta `/api/` e faz o proxy para o backend
- Funciona tanto em dev local (`localhost:4200`) quanto em produção

---

## 6. Proxy de Conexão — nginx

### 6.1 Arquivo de Configuração

**Localização:** `frontend/nginx.conf`

```nginx
server {
    listen       80;
    server_name  localhost;
    root         /usr/share/nginx/html;
    index        index.html;

    # ── Cache de assets (1 ano para arquivos com hash no nome) ──
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # ── API Proxy → Backend FastAPI ──
    # Exemplo: /api/cadastrar → http://backend:8000/cadastrar
    location /api/ {
        proxy_pass http://backend:8000/;    # ← Note a barra final (strip do prefixo)
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ── SPA Fallback ──
    # Qualquer rota que não seja /api/ nem arquivo estático → index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 6.2 Como o Proxy Funciona

```mermaid
flowchart LR
    subgraph "Requisições do Navegador"
        A1["GET /"] 
        A2["GET /cadastro"]
        A3["GET /home"]
        A4["POST /api/cadastrar"]
        A5["POST /api/login"]
        A6["GET /api/saldo"]
    end

    subgraph "nginx (container slots-frontend)"
        direction TB
        R1["location /"]
        R2["location /api/"]
        CACHE["Cache: 1 ano<br/>para assets estáticos"]
    end

    subgraph "Destino"
        D1["Arquivos estáticos<br/>index.html, main.js, styles.css"]
        D2["Backend FastAPI<br/>uvicorn :8000"]
    end

    A1 --> R1 --> D1
    A2 --> R1 --> D1
    A3 --> R1 --> D1
    A4 --> R2 --> D2
    A5 --> R2 --> D2
    A6 --> R2 --> D2
```

### 6.3 Regras de Roteamento

| URL da Requisição | Regra no nginx | Destino |
|---|---|---|
| `/` | `location /` | `/usr/share/nginx/html/index.html` |
| `/cadastro` | `try_files $uri /index.html` | `index.html` (Angular SPA) |
| `/home` | `try_files $uri /index.html` | `index.html` (Angular SPA) |
| `/api/cadastrar` | `location /api/` → `proxy_pass http://backend:8000/` | `backend:8000/cadastrar` |
| `/api/login` | `location /api/` → `proxy_pass http://backend:8000/` | `backend:8000/login` |
| `/api/saldo` | `location /api/` → `proxy_pass http://backend:8000/` | `backend:8000/saldo` |
| `/main.abc123.js` | `location ~* \.(js)$` | Arquivo com cache de 1 ano |

### 6.4 Detalhe Crítico: Strip do Prefixo `/api`

```nginx
# ✅ CORRETO — com barra final no proxy_pass:
location /api/ {
    proxy_pass http://backend:8000/;
}
# /api/cadastrar → backend:8000/cadastrar  (strip do /api)


# ❌ ERRADO — sem barra final:
location /api/ {
    proxy_pass http://backend:8000;
}
# /api/cadastrar → backend:8000/api/cadastrar  (mantém /api — backend não reconhece)
```

A barra final (`/`) no `proxy_pass` é **essencial** — sem ela, o backend receberia `/api/cadastrar` em vez de `/cadastrar` e retornaria 404.

---

## 7. Resumo Operacional

### Comandos Rápidos

```bash
# Ver status dos containers na VM
ssh opc@129.148.50.233 docker compose -f slots/docker-compose.yml ps

# Ver logs do backend
ssh opc@129.148.50.233 docker logs slots-backend --tail 50

# Ver logs do cloudflared
ssh opc@129.148.50.233 docker logs slots-tunnel --tail 20

# Acessar banco de dados
ssh opc@129.148.50.233 docker exec -it slots-postgres psql -U slots -d slots_db

# Disparar deploy manual
gh workflow run deploy-vm.yml --repo equipe-sudo/infrastructure

# Testar API
curl https://equipe-sudo.kolpzs.com/api/cadastrar \
  -X POST -H "Content-Type: application/json" \
  -d '{"nome":"teste","email":"test@test.com","senha":"123456"}'
```

### Links Úteis

| Recurso | URL |
|---|---|
| **Site** | https://equipe-sudo.kolpzs.com |
| **API Docs (Swagger)** | http://129.148.50.233:8000/docs (via SSH tunnel) |
| **OCIR Console** | https://console.sa-saopaulo-1.oraclecloud.com/containers |
| **Cloudflare Dashboard** | https://dash.cloudflare.com |
| **GitHub — Backend** | https://github.com/equipe-sudo/backend |
| **GitHub — Frontend** | https://github.com/equipe-sudo/frontend |
| **GitHub — Infra** | https://github.com/equipe-sudo/infrastructure |

---

> **Documento mantido por:** Equipe Sudo — Infraestrutura
> **Dúvidas?** Abra uma issue no repositório `equipe-sudo/infrastructure`
