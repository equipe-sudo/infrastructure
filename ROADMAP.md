# Roadmap de Infraestrutura — João Pedro

> **Data:** 04/08/2026  
> **Entrega:** 07/08/2026 22:00 (3 dias)  
> **Contexto:** Jogo de Slots — OCI Always Free (tenancy kolpzs, sa-saopaulo-1)

---

## 📊 Resumo dos Cards P0

| # | Card | Ferramenta | Dia |
|---|---|---|---|
| 1 | VCN + Subnet + Security List | Terraform | Dia 1 |
| 2 | VM A1.Flex (2 OCPU + 12 GB) | Terraform | Dia 1 |
| 3 | Docker + dependências | Ansible | Dia 2 |
| 4 | Docker Compose (PG + backend + frontend) | Docker | Dia 2 |
| 5 | Volume persistente PostgreSQL | Docker | Dia 2 (junto com #4) |

---

## 🗓️ Cronograma

### 🔴 Dia 1 — 04/08 (Hoje!) — Terraform: Rede + VM

**Objetivo:** `terraform apply` → VCN e VM provisionadas e acessíveis via SSH

| Passo | O quê | Tempo |
|---|---|---|
| 1.1 | Criar estrutura `terraform/` com provider OCI | 20 min |
| 1.2 | Escrever `vcn.tf`: VCN, subnet pública, Internet Gateway, route table | 30 min |
| 1.3 | Escrever `security.tf`: security list (22, 80, 443, 8000) | 15 min |
| 1.4 | Escrever `compute.tf`: VM A1.Flex + chave SSH | 30 min |
| 1.5 | `terraform init && terraform plan && terraform apply` | 15 min |
| 1.6 | Testar `ssh opc@<ip_publico>` | 5 min |

**Resultado esperado:** VM Oracle Linux acessível via IP público

> ⚠️ **Risco:** OCI Always Free pode recusar a VM por limite de capacidade. Se isso acontecer, usar shape `VM.Standard.E2.1.Micro` (1 OCPU, 1 GB) como fallback — ainda gratuito.

---

### 🟡 Dia 2 — 05/08 — Ansible + Docker Compose

**Objetivo:** Playbook instala Docker na VM, docker-compose.yml sobe PostgreSQL + app

| Passo | O quê | Tempo |
|---|---|---|
| 2.1 | Criar playbook Ansible: instalar Docker, Docker Compose, git | 20 min |
| 2.2 | Rodar `ansible-playbook -i inventory.yml playbook.yml` | 10 min |
| 2.3 | Criar `docker-compose.yml`: postgres, backend, frontend, nginx | 30 min |
| 2.4 | Copiar docker-compose.yml para VM e rodar `docker compose up -d` | 10 min |
| 2.5 | Testar: `curl http://<ip>:8000/docs` (Swagger) e `http://<ip>` (frontend) | 10 min |

**Resultado esperado:** Aplicação de slots rodando na VM com PostgreSQL persistente

---

### 🟢 Dia 3 — 06/08 — Testes + Documentação

**Objetivo:** Validar tudo, documentar, preparar evidências

| Passo | O quê | Tempo |
|---|---|---|
| 3.1 | Testar persistência: `docker compose down && docker compose up -d` → dados intactos | 10 min |
| 3.2 | Testar acesso público: URL, portas, latência | 15 min |
| 3.3 | Criar diagrama da arquitetura (draw.io/Excalidraw) | 30 min |
| 3.4 | Documentar justificativas técnicas | 30 min |
| 3.5 | Coletar prints do deploy funcionando | 10 min |

---

### ⬜ Dia 4 — 07/08 (até 22:00) — Ajustes finais

**Objetivo:** Buffer para imprevistos e refinamentos

| Passo | O quê |
|---|---|
| 4.1 | Corrigir problemas encontrados nos testes |
| 4.2 | Ajudar o time com integração backend/frontend |
| 4.3 | Revisão final com Fer/Thiago para evidências |

---

## 📁 Estrutura de Diretórios

```
infrastructure/
├── terraform/               # IaC — provisionamento OCI
│   ├── main.tf              # Provider + locals
│   ├── variables.tf         # Variáveis de entrada
│   ├── outputs.tf           # Outputs (IP público, etc)
│   ├── vcn.tf               # VCN, subnet, gateway, security
│   ├── compute.tf           # VM A1.Flex
│   └── terraform.tfvars.example
├── ansible/                 # Configuração — pós-provisionamento
│   ├── playbook.yml         # Instalar Docker + dependências
│   └── inventory.yml        # Inventário dinâmico (IP da VM)
├── docker/                  # Orquestração — containers da aplicação
│   ├── docker-compose.yml   # postgres + backend + frontend + nginx
│   └── nginx/
│       └── nginx.conf       # Reverse proxy
├── docs/
│   ├── CONTRIBUTING.md      # Já existe
│   ├── arquitetura.md       # Diagrama e explicação
│   └── justificativas-tecnicas.md
├── .env.example             # Já existe
└── README.md                # Já existe
```

---

## 🔧 Stack Técnica

| Ferramenta | Versão | Propósito |
|---|---|---|
| Terraform | ≥ 1.5 | Provisionar VCN + VM na OCI |
| OCI Provider | ≥ 5.0 | Conectar na Oracle Cloud |
| Ansible | ≥ 2.15 | Instalar Docker na VM |
| Docker | ≥ 24 | Rodar containers da aplicação |
| Docker Compose | ≥ 2.20 | Orquestrar PostgreSQL + backend + frontend |

---

## ⚠️ Riscos e Mitigações

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| OCI recusar A1.Flex (sem capacity) | Média | Alto | Fallback para VM.Standard.E2.1.Micro |
| Chave SSH não configurada | Baixa | Alto | Verificar `~/.oci/oci_api_key.pem` antes |
| Allan/Josi não terem Dockerfile pronto | Média | Médio | Rodar backend/frontend com Python/Node direto na VM |
| Tempo insuficiente | Alta | Alto | P1/P2 ficam pra documentação; foco total nos P0 |
