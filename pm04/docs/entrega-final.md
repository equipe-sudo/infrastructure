# PM-04 · Projeto Final — Automação de infraestrutura com Terraform, Ansible e CI/CD

> **Sistema:** Smart Construction (Bubikas Holdings)
> **Equipe:** SUDO
> **Repositório:** https://github.com/equipe-sudo/infrastructure
> **Data de entrega:** 27/11/2026

---

## Integrantes

- Fernanda Andrieli Chini Konzen
- João Pedro Pereira dos Santos

---

## 1. Análise da demanda

A **Bubikas Holdings** contratou (simuladamente) um especialista de infraestrutura para publicar o **Smart Construction** — plataforma que conecta serviços, materiais e profissionais da construção civil — em um endereço HTTPS, com persistência e administração protegidas, operada por pipelines.

**Componentes do sistema (já desenvolvidos, entregues no repositório de origem):**

| Componente | Tecnologia | Papel |
|---|---|---|
| Frontend | Next.js | Catálogo (93 soluções / 186 materiais), páginas públicas, formulários de cadastro |
| API | FastAPI | Autenticação administrativa, profissões, cadastros, análise, auditoria, publicação |
| Banco | PostgreSQL 17 | Dados relacionais; migrações Alembic |
| Storage editorial | SeaweedFS | Imagens/objetos públicos do catálogo |
| Storage privado | SeaweedFS | Arquivos/anexos restritos dos cadastros |
| Gateway | Nginx | Única porta exposta; TLS; roteamento |

**Requisitos de infraestrutura extraídos da demanda:**

1. Provedor de nuvem justificado (custos, operação, limitações).
2. **Mínimo 2 VMs**; PostgreSQL em **VM exclusiva**, separado da aplicação.
3. API ↔ banco por **rede privada**; porta 5432 **nunca** exposta à internet.
4. Distribuição justificada de Next.js, API, Nginx e storages; buckets privados sem acesso público direto.
5. **HTTPS**, origem permitida, cookies seguros, acesso administrativo restrito, segredos fora do repositório/logs.
6. Persistência de dados e imagens em reinícios/atualizações, com **backup/restauração** testado.
7. Pipelines para provisionar, configurar, atualizar e **encerrar**, integrados ao CI/CD.

---

## 2. Decisões de arquitetura

### 2.1 Provedor: AWS (a partir de OCI)

- **Tentativa inicial — OCI Always Free:** escolhida pelo custo zero vitalício e pela experiência do time. **Descartada** por dois bloqueios operacionais: a região `sa-saopaulo-1` retornou **"Out of host capacity"** nos shapes Always Free (A1.Flex e E2.1.Micro), e a tenancy estava **limitada a 1 região** (impossível migrar para `us-ashburn-1`).
- **Decisão final — AWS Free Tier:** multi-região, `t3.micro` com 750 h/mês, S3 e egress gratuitos. Mantém **custo $0** para uso de demonstração, com **US$ 100 de crédito** como margem de segurança.

### 2.2 Topologia (2 VMs)

| VM | Subnet | IP público | Conteúdo |
|---|---|---|---|
| `vm-sc-app` | pública | sim | Docker: Nginx (TLS), Next.js, FastAPI, SeaweedFS editorial + privado |
| `vm-sc-db` | privada | **não** | PostgreSQL 17 exclusivo |

### 2.3 Rede e isolamento do banco

- VPC `10.10.0.0/16`, subnets pública (`10.10.1.0/24`) e privada (`10.10.2.0/24`).
- **Porta 5432**: Security Group `sg-db` aceita ingress **somente** do CIDR da subnet da app — **nunca** de `0.0.0.0/0`. A VM do banco fica em subnet privada (`map_public_ip_on_launch=false`).
- **Egress do banco (sem NAT Gateway pago):** a VM `app` atua como NAT (masquerade + `ip_forward` + `FORWARD`), e a rota da subnet privada aponta para a ENI da app. Mantém custo $0 (NAT Gateway custaria ~US$32/mês).
- **HTTPS**: terminação TLS no Nginx (`:443`), `:80` só redireciona; cookies `Secure`; origem permitida restrita ao domínio.

### 2.4 Automação (Terraform + Ansible + GitHub Actions)

```
GitHub Actions (workflow_dispatch, parâmetros)
   │ 1. terraform init/plan/apply   → VPC, subnets, SGs, 2× EC2, key pair
   │ 2. gera inventory (bastion)     → IPs dos outputs do Terraform
   │ 3. ansible-playbook             → nat, os_updates, docker, postgres, smartapp
   │ 4. smoke test                   → /healthz responde 200
```

**Parâmetros da pipeline:** `environment`, `instance_name`, `instance_type`, `docker_tag`, `update_os`, `extra_packages`.

**Segredos:** armazenados em GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `SSH_PUBLIC_KEY`, `SSH_PRIVATE_KEY`); credenciais de banco geradas no host sob `.secrets/`, **nunca** versionadas.

---

## 3. Repositório

- **https://github.com/equipe-sudo/infrastructure** — diretório `pm04/`:
  - `pm04/terraform/` — IaC AWS (VPC, subnets, SGs, EC2, backend S3).
  - `pm04/ansible/` — 5 roles (`nat`, `os_updates`, `docker`, `postgres`, `smartapp`).
  - `.github/workflows/` — `pm04-deploy`, `pm04-destroy`, `pm04-build-images`, `pm04-infra-report`.
  - `pm04/docs/` — arquitetura, custos e decisões.

---

## 4. Evidências de execução

A solução completa (**Terraform + Ansible + GitHub Actions**) foi implementada e a infraestrutura foi **provisionada na AWS**. Os três cenários exigidos são executados pela pipeline e serão demonstrados ao vivo na apresentação.

### Cenário 1 — Criação inicial (do zero)

A pipeline `pm04-deploy` provisiona a infraestrutura (`terraform apply`: VPC `10.10.0.0/16`, 2 subnets, Internet Gateway, rota NAT via ENI da app, Security Groups, 2× EC2 `t3.micro` e key pair) e configura as VMs (`ansible-playbook`: NAT, Docker CE, PostgreSQL 17 isolado, secrets no host, TLS e a aplicação). **Executado** — infraestrutura provisionada na AWS (VM app com IP público `44.200.87.27`; VM do banco em subnet privada, sem IP público).

### Cenário 2 — Atualização (mudança de parâmetro)

A pipeline aceita parâmetros (`environment`, `instance_type`, `docker_tag`, `update_os`, `extra_packages`) via `workflow_dispatch`. Reexecutá-la com parâmetros alterados faz o Terraform aplicar a mudança de infraestrutura e o Ansible atualizar imagem/pacotes/OS de forma controlada. **Implementado.**

### Cenário 3 — Reexecução sem alterações (idempotência)

Com os mesmos parâmetros, o `terraform apply` reporta "No changes" e o Ansible reporta zero `changed` (roles idempotentes: `creates`, estado desejado, `force: false`, `pull: missing`). **Implementado.**

### Validação da demanda

- **Banco em VM exclusiva, sem porta pública** — implementado: a VM `db` fica em subnet privada e o Security Group `sc-db` aceita ingress 5432/22 somente da subnet da app.
- **HTTPS no domínio** (`equipe-sudo.kolpzs.com` via Cloudflare Tunnel) — implementado; a demonstração do acesso HTTPS será feita na apresentação.

---

## Requisitos do enunciado (PM-04) — mapeamento e evidências

### 3.1 Pipeline CI/CD

| Requisito | Evidência |
|---|---|
| Ferramenta de CI/CD | GitHub Actions — `.github/workflows/pm04-deploy.yml` |
| Execução manual com parâmetros | `workflow_dispatch` com inputs `environment`, `instance_name`, `instance_type`, `docker_tag`, `update_os`, `extra_packages` |
| Terraform + Ansible em sequência | passos ordenados: `init → plan → apply → inventory → ansible-playbook → smoke test` |
| Logs claros + interromper em erro | `set -euo pipefail` + `::error::` (falha interrompe o job) |

### 3.2 Terraform — provisionamento

| Requisito | Evidência |
|---|---|
| VM + rede + regras de acesso | VPC `10.10.0.0/16`, 2 subnets, Internet Gateway, route tables, Security Groups, 2× EC2 `t3.micro` (`app` pública + `db` privada) |
| Variáveis | `variables.tf` — 8 variáveis com validação |
| `init`/`plan`/`apply` pela pipeline | passos do workflow `pm04-deploy` |
| Preservar o Terraform State | backend S3 (`equipe-sudo-tfstate`) |
| Atualização sem recriação | `ignore_changes` (AMI) + `pull: missing` (imagens) |

### 3.3 Ansible — configuração e manutenção

| Requisito | Evidência |
|---|---|
| Preparar o SO do zero | roles `os_updates` + `docker` (dnf, swap de 2 GB) |
| Instalar/Configurar Docker | role `docker` (Docker CE + plugin compose) |
| Criar/iniciar/manter contêineres | role `smartapp` (docker compose: nginx, web, api, storage, private-storage) |
| Verificar tags e atualizar imagens | parâmetro `docker_tag` + `pull: missing` |
| Atualização de SO (`update_os`) | role `os_updates` (`dnf update` condicional) |
| Instalar pacotes (`extra_packages`) | role `docker` (dnf install) |
| Verificar serviços + idempotência | `wait_for` (5432/healthz) + roles idempotentes |

### 4. Parâmetros da pipeline

`environment`, `instance_name`, `instance_type`, `docker_tag`, `update_os`, `extra_packages` — todos presentes como inputs do `workflow_dispatch`, repassados ao Terraform (`-var`) e ao Ansible (`--extra-vars`).

---

## Requisitos da demanda (Smart Construction) — mapeamento e evidências

| # | Requisito | Implementação | Evidência |
|---|---|---|---|
| 1 | Escolher e justificar o provedor | AWS Free Tier (decisão OCI→AWS) | `arquitetura.md` |
| 2 | Mín. 2 VMs; PostgreSQL em VM exclusiva | 2× EC2 (`app` + `db`); PostgreSQL só na `db` | `compute.tf` |
| 3 | API↔DB por rede privada; 5432 nunca na internet | subnet privada + SG `sc-db` (5432/22 só da subnet da app) | `security.tf` |
| 4 | Distribuição justificada (Next.js, API, Nginx, storages) | `app` (Docker: nginx/web/api/storages) + `db` (PostgreSQL) | `arquitetura.md` |
| 5 | HTTPS, origem, cookies, admin, segredos | nginx TLS, `SMART_API_ALLOWED_ORIGINS`, secrets em `.secrets/` (0700) | nginx + roles |
| 6 | Persistência + backup/restauração | volumes Docker + `pg_dump` (documentado) | `arquitetura.md` |
| 7 | Pipelines (provisionar/configurar/atualizar/encerrar) | `pm04-deploy`, `pm04-destroy`, `pm04-build-images` | `.github/workflows/` |
| 8 | Estimativa mensal + justificativa | US$ 0,00 (Free Tier) | `custos.md` |

### Critérios de aceite

| Critério | Evidência |
|---|---|
| Página inicial, busca e catálogo em HTTPS | Next.js `web` + nginx (TLS) |
| Cadastro sintético de profissional/empresa persistido | PostgreSQL 17 + volumes nomeados |
| Login administrativo, consulta, edição, aprovação | API FastAPI (autenticação administrativa) |
| Profissional aprovado público; demais privados | lógica da API (controles preservados) |
| Banco em VM exclusiva, sem porta pública | subnet privada + SG `sc-db` restritivo |
| Dados e imagens preservados após reinício/atualização | volumes Docker (`storage-data`, `private-storage-data`, `db-data`) |
| Pipelines reproduzíveis com segredos protegidos | workflows + GitHub Secrets (nunca no código) |
| Backup restaurado em ambiente isolado | documentado em `arquitetura.md` (runbook) |
| Documentação (arquitetura, custos, acessos, logs, recuperação, encerramento) | `arquitetura.md` + `custos.md` + este relatório |

---

## 5. Custos

- **Estimativa mensal: US$ 0,00** no uso de demo (Free Tier: 2× `t3.micro` dentro de 750 h/mês, 30 GB EBS, 5 GB S3, 100 GB egress).
- NAT feito pela VM `app` (sem NAT Gateway pago).
- **Margem:** US$ 100 de crédito AWS.
- Monitorado pelo workflow `pm04-infra-report` (relatório diário de EC2/EBS/EIP/S3/custo).

---

## 6. Encerramento

- `pm04-destroy.yml` executa `terraform destroy` e remove VPC, subnets, SGs e EC2.
- Nada permanece gerando cobrança após o encerramento.
